import { prisma } from '../config/database';
import logger from '../utils/logger';
import { GuardianNotificationGroup, notificationService } from './notification.service';

/**
 * Servicio de cola de notificaciones
 * Procesa notificaciones pendientes según la estrategia configurada
 * 
 * MEJORA: Agrupa por teléfono del responsable para enviar un solo mensaje
 * consolidado cuando un padre tiene múltiples hijos o múltiples ausencias.
 */
export class NotificationQueueService {

    /**
     * Procesa todas las notificaciones pendientes cuya hora programada ya pasó
     * Llamado por el CronService cada 15 minutos
     * 
     * LÓGICA MEJORADA:
     * 1. Agrupa por teléfono del responsable (no por estudiante)
     * 2. Consolida todas las faltas de todos los hijos en un solo mensaje
     * 3. Incluye contexto completo: fecha, hora, materia, nombre del alumno
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

            // MEJORA: Agrupar por teléfono del responsable (no por estudiante)
            // Esto permite consolidar notificaciones de múltiples hijos en un solo mensaje
            const groupedByGuardianPhone = new Map<string, GuardianNotificationGroup>();

            for (const item of pendingItems) {
                const phone = item.estudiante.telefonoResponsable;
                // Nombre del responsable guardado en este estudiante específico
                const currentGuardianName = item.estudiante.nombreResponsable || 'Estimado acudiente';
                
                // Si no tiene teléfono, marcar como fallido y continuar
                if (!phone) {
                    await this.updateItemsStatus([item], 'FAILED', 'No guardian phone number');
                    continue;
                }

                if (!groupedByGuardianPhone.has(phone)) {
                    // Si es el primer mensaje para este teléfono, creamos el grupo
                    groupedByGuardianPhone.set(phone, {
                        phone,
                        guardianName: currentGuardianName,
                        students: [],
                        allItems: [],
                        institucionId: item.asistencia?.institucionId || ''
                    });
                } else {
                    // El grupo ya existe (ej. es el segundo hermano)
                    const group = groupedByGuardianPhone.get(phone)!;
                    
                    // --- CORRECCIÓN DE NOMBRES INCONSISTENTES ---
                    // Si el nombre del responsable actual difiere del que ya guardamos en el grupo,
                    // y el grupo no ha sido marcado ya como genérico, lo forzamos a genérico.
                    // Esto evita: "Hola Pepito" cuando el segundo hijo dice que el papá se llama "Benito".
                    if (group.guardianName !== 'Estimado Acudiente' && 
                        group.guardianName.trim().toLowerCase() !== currentGuardianName.trim().toLowerCase()) {
                        
                        logger.info(`[NotificationQueueService] ⚠️ Conflict in guardian names for phone ${phone}: "${group.guardianName}" vs "${currentGuardianName}". Switching to generic "Estimado Acudiente".`);
                        group.guardianName = 'Estimado Acudiente';
                    }
                }

                const group = groupedByGuardianPhone.get(phone)!;
                group.allItems.push(item);

                // Agregar información del estudiante si no existe
                let studentInfo = group.students.find(s => s.estudianteId === item.estudianteId);
                if (!studentInfo) {
                    const usuario = item.estudiante.usuario;
                    studentInfo = {
                        estudianteId: item.estudianteId,
                        nombreCompleto: `${usuario.nombres} ${usuario.apellidos}`,
                        items: []
                    };
                    group.students.push(studentInfo);
                }
                studentInfo.items.push(item);
            }

            logger.info(`[NotificationQueueService] 📱 Grouped into ${groupedByGuardianPhone.size} guardian phones.`);

            // Procesar cada grupo de responsable
            let successCount = 0;
            let failCount = 0;

            for (const [phone, group] of groupedByGuardianPhone) {
                const success = await this.processGuardianGroup(group);
                if (success) successCount++; else failCount++;
            }

            logger.info(`[NotificationQueueService] 📊 Processing complete: ${successCount} success, ${failCount} failed.`);

        } catch (error) {
            logger.error('[NotificationQueueService] ❌ Error processing queue', error);
        }
    }

    /**
     * Procesa un grupo de notificaciones para un responsable
     * Envía un mensaje consolidado con todas las asistencias de todos sus hijos
     */
    private async processGuardianGroup(group: GuardianNotificationGroup): Promise<boolean> {
        const { phone, allItems } = group;

        // Marcar como procesando
        await this.updateItemsStatus(allItems, 'PROCESSING');

        try {
            // Usar el servicio de notificaciones mejorado con consolidación por responsable
            const result = await notificationService.sendConsolidatedSummary(group);

            if (result.success) {
                await this.updateItemsStatus(allItems, 'SENT');
                logger.info(`[NotificationQueueService] ✅ Sent consolidated summary to ${phone} for ${group.students.length} student(s)`);
                return true;
            } else {
                throw new Error(result.error || 'Unknown error');
            }

        } catch (error: any) {
            logger.error(`[NotificationQueueService] ❌ Error sending to ${phone}:`, error.message);

            const currentRetries = allItems[0].intentos || 0;
            const maxRetries = allItems[0].maxIntentos || 3;

            if (currentRetries < maxRetries) {
                // Reintentar con backoff exponencial: 5, 10, 20 minutos
                const backoffMinutes = Math.pow(2, currentRetries) * 5;
                const retryTime = new Date(Date.now() + backoffMinutes * 60 * 1000);

                await this.updateItemsWithRetry(allItems, currentRetries + 1, error.message, retryTime);
                logger.info(`[NotificationQueueService] 🔄 Scheduled retry ${currentRetries + 1}/${maxRetries} at ${retryTime.toISOString()}`);
            } else {
                // Mover a dead letter después de agotar reintentos
                await this.updateItemsStatus(allItems, 'DEAD_LETTER', error.message);
                logger.error(`[NotificationQueueService] 💀 Max retries exceeded for ${phone}. Moved to DEAD_LETTER.`);
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
