import { prisma } from '../config/database';
import logger from '../utils/logger';
import { notificationService } from './notification.service';

export class NotificationQueueService {

    public async processPendingNotifications(): Promise<void> {
        logger.info('[NotificationQueueService] Checking for pending notifications...');

        try {
            // Fetch pending notifications scheduled for now or past
            // @ts-ignore: Prisma client might not be updated in IDE context yet
            const pendingItems = await prisma.colaNotificacion.findMany({
                where: {
                    estado: 'PENDING',
                    programadoPara: {
                        lte: new Date()
                    }
                },
                include: {
                    estudiante: true,
                    asistencia: {
                        include: {
                            horario: {
                                include: {
                                    materia: true
                                }
                            }
                        }
                    }
                },
                take: 100 // Process in batches
            });

            if (pendingItems.length === 0) {
                logger.info('[NotificationQueueService] No pending notifications found.');
                return;
            }

            logger.info(`[NotificationQueueService] Found ${pendingItems.length} pending notifications.`);

            // Group by Student (Guardian)
            const groups = new Map<string, typeof pendingItems>();

            for (const item of pendingItems) {
                const key = item.estudianteId;
                if (!groups.has(key)) {
                    groups.set(key, []);
                }
                groups.get(key)?.push(item);
            }

            // Process each group
            for (const [studentId, items] of groups) {
                await this.processGroup(studentId, items);
            }

        } catch (error) {
            logger.error('[NotificationQueueService] Error processing queue', error);
        }
    }

    private async processGroup(studentId: string, items: any[]): Promise<void> {
        const student = items[0].estudiante;
        const phone = student.telefonoResponsable;

        if (!phone) {
            logger.warn(`[NotificationQueueService] Student ${studentId} has no guardian phone. Marking as FAILED.`);
            await this.updateStatus(items, 'FAILED');
            return;
        }

        // Construct message
        const lines = items.map(item => {
            const materia = item.asistencia?.horario?.materia?.nombre || 'Clase desconocida';
            const estado = item.asistencia?.estado || 'Falta';
            return `- ${materia}: ${estado}`;
        });

        const body = `Hola, reporte de asistencia para ${student.nombreResponsable || 'su acudido'}:\n${lines.join('\n')}`;

        // Set to PROCESSING
        await this.updateStatus(items, 'PROCESSING');

        try {
            const result = await notificationService.sendRawMessage(items[0].institucionId, studentId, body, 'ATTENDANCE');

            const status = result.success ? 'SENT' : 'FAILED';
            await this.updateStatus(items, status);
        } catch (error: any) {
            logger.error(`[NotificationQueueService] Error sending to ${studentId}`, error);

            // Check retry count
            const currentIntentos = items[0].intentos || 0;
            const maxIntentos = 3; // Could be configurable per institution

            if (currentIntentos < maxIntentos) {
                // Increment intentos and reschedule with backoff
                const backoffMinutes = Math.pow(2, currentIntentos) * 5; // 5, 10, 20 minutes
                const retryTime = new Date(Date.now() + backoffMinutes * 60 * 1000);

                await this.updateStatusWithRetry(items, 'PENDING', currentIntentos + 1, error.message, retryTime);
            } else {
                // Move to DEAD_LETTER
                await this.updateStatus(items, 'DEAD_LETTER', error.message);
            }
        }
    }

    private async updateStatus(items: any[], status: string, ultimoError?: string): Promise<void> {
        const ids = items.map(i => i.id);
        // @ts-ignore
        await prisma.colaNotificacion.updateMany({
            where: {
                id: { in: ids }
            },
            data: {
                estado: status,
                ultimoError: ultimoError,
                updatedAt: new Date()
            }
        });
    }

    private async updateStatusWithRetry(items: any[], status: string, intentos: number, ultimoError: string, retryTime: Date): Promise<void> {
        const ids = items.map(i => i.id);
        // @ts-ignore
        await prisma.colaNotificacion.updateMany({
            where: {
                id: { in: ids }
            },
            data: {
                estado: status,
                intentos: intentos,
                ultimoError: ultimoError,
                programadoPara: retryTime,
                updatedAt: new Date()
            }
        });
    }
}

export const notificationQueueService = new NotificationQueueService();
