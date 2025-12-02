import { prisma } from '../config/database';
import logger from '../utils/logger';
import { notificationService } from './notification.service';

/**
 * Servicio de cola de notificaciones
 * Procesa notificaciones pendientes según la estrategia configurada
 */
export class NotificationQueueService {

    /**
     * Procesa todas las notificaciones pendientes cuya hora programada ya pasó
     * Llamado por el CronService cada 15 minutos
     */
    public async processPendingNotifications(): Promise<void> {
        logger.info('[NotificationQueueService] 🔄 Checking for pending notifications...');

        try {
            // Obtener notificaciones pendientes cuya hora ya llegó
            const pendingItems = await prisma.colaNotificacion.findMany({
                where: {
                    estado: 'PENDING',
                    programadoPara: {
                        lte: new Date()
                    }
                },
                include: {
                    estudiante: {
                        include: {
                            usuario: true
                        }
                    },
                    asistencia: {
                        include: {
                            institucion: true,
                            horario: {
                                include: {
                                    materia: true
                                }
                            }
                        }
                    }
                },
                take: 100, // Procesar en lotes de 100
                orderBy: {
                    programadoPara: 'asc'
                }
            });

            if (pendingItems.length === 0) {
                logger.info('[NotificationQueueService] ✅ No pending notifications found.');
                return;
            }

            logger.info(`[NotificationQueueService] 📬 Found ${pendingItems.length} pending notifications.`);

            // Agrupar por estudiante (para enviar resumen consolidado)
            const groupedByStudent = new Map<string, typeof pendingItems>();

            for (const item of pendingItems) {
                const key = item.estudianteId;
                if (!groupedByStudent.has(key)) {
                    groupedByStudent.set(key, []);
                }
                groupedByStudent.get(key)?.push(item);
            }

            logger.info(`[NotificationQueueService] 👥 Grouped into ${groupedByStudent.size} students.`);

            // Procesar cada grupo de estudiante
            let successCount = 0;
            let failCount = 0;

            for (const [studentId, items] of groupedByStudent) {
                const success = await this.processStudentGroup(studentId, items);
                if (success) successCount++; else failCount++;
            }

            logger.info(`[NotificationQueueService] 📊 Processing complete: ${successCount} success, ${failCount} failed.`);

        } catch (error) {
            logger.error('[NotificationQueueService] ❌ Error processing queue', error);
        }
    }

    /**
     * Procesa un grupo de notificaciones para un estudiante
     * Envía un mensaje consolidado con todas las asistencias del día
     */
    private async processStudentGroup(studentId: string, items: any[]): Promise<boolean> {
        const student = items[0].estudiante;
        const phone = student.telefonoResponsable;

        if (!phone) {
            logger.warn(`[NotificationQueueService] ⚠️ Student ${studentId} has no guardian phone. Marking as FAILED.`);
            await this.updateItemsStatus(items, 'FAILED', 'No guardian phone number');
            return false;
        }

        // Marcar como procesando
        await this.updateItemsStatus(items, 'PROCESSING');

        try {
            // Usar el servicio de notificaciones mejorado
            const result = await notificationService.sendDailySummary(studentId, items);

            if (result.success) {
                await this.updateItemsStatus(items, 'SENT');
                logger.info(`[NotificationQueueService] ✅ Sent summary to ${phone} for student ${studentId}`);
                return true;
            } else {
                throw new Error(result.error || 'Unknown error');
            }

        } catch (error: any) {
            logger.error(`[NotificationQueueService] ❌ Error sending to ${studentId}:`, error.message);

            const currentRetries = items[0].intentos || 0;
            const maxRetries = items[0].maxIntentos || 3;

            if (currentRetries < maxRetries) {
                // Reintentar con backoff exponencial: 5, 10, 20 minutos
                const backoffMinutes = Math.pow(2, currentRetries) * 5;
                const retryTime = new Date(Date.now() + backoffMinutes * 60 * 1000);

                await this.updateItemsWithRetry(items, currentRetries + 1, error.message, retryTime);
                logger.info(`[NotificationQueueService] 🔄 Scheduled retry ${currentRetries + 1}/${maxRetries} at ${retryTime.toISOString()}`);
            } else {
                // Mover a dead letter después de agotar reintentos
                await this.updateItemsStatus(items, 'DEAD_LETTER', error.message);
                logger.error(`[NotificationQueueService] 💀 Max retries exceeded for student ${studentId}. Moved to DEAD_LETTER.`);
            }

            return false;
        }
    }

    /**
     * Actualiza el estado de múltiples items
     */
    private async updateItemsStatus(items: any[], status: string, error?: string): Promise<void> {
        const ids = items.map(i => i.id);
        await prisma.colaNotificacion.updateMany({
            where: { id: { in: ids } },
            data: {
                estado: status,
                ultimoError: error,
                updatedAt: new Date()
            }
        });
    }

    /**
     * Actualiza items para reintento con nueva hora programada
     */
    private async updateItemsWithRetry(items: any[], retryCount: number, error: string, retryTime: Date): Promise<void> {
        const ids = items.map(i => i.id);
        await prisma.colaNotificacion.updateMany({
            where: { id: { in: ids } },
            data: {
                estado: 'PENDING',
                intentos: retryCount,
                ultimoError: error,
                programadoPara: retryTime,
                updatedAt: new Date()
            }
        });
    }

    /**
     * Obtiene estadísticas de la cola de notificaciones
     */
    public async getQueueStats(): Promise<{
        pending: number;
        processing: number;
        sent: number;
        failed: number;
        deadLetter: number;
    }> {
        const [pending, processing, sent, failed, deadLetter] = await Promise.all([
            prisma.colaNotificacion.count({ where: { estado: 'PENDING' } }),
            prisma.colaNotificacion.count({ where: { estado: 'PROCESSING' } }),
            prisma.colaNotificacion.count({ where: { estado: 'SENT' } }),
            prisma.colaNotificacion.count({ where: { estado: 'FAILED' } }),
            prisma.colaNotificacion.count({ where: { estado: 'DEAD_LETTER' } })
        ]);

        return { pending, processing, sent, failed, deadLetter };
    }

    /**
     * Reintenta enviar notificaciones en DEAD_LETTER (para uso manual)
     */
    public async retryDeadLetterItems(): Promise<number> {
        const result = await prisma.colaNotificacion.updateMany({
            where: { estado: 'DEAD_LETTER' },
            data: {
                estado: 'PENDING',
                intentos: 0,
                programadoPara: new Date(),
                updatedAt: new Date()
            }
        });

        logger.info(`[NotificationQueueService] 🔄 Reset ${result.count} DEAD_LETTER items to PENDING`);
        return result.count;
    }
}

export const notificationQueueService = new NotificationQueueService();
