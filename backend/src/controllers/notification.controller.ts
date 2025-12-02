import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { notificationService, NotificationChannel } from '../services/notification.service';
import { notificationQueueService } from '../services/notification-queue.service';
import logger from '../utils/logger';

export class NotificationController {

    /**
     * Dispara notificaciones manualmente para un rango de asistencias
     */
    public static async triggerManual(req: FastifyRequest, reply: FastifyReply) {
        const { scope, institutionId, classId } = req.body as any;

        try {
            // 1. Construir filtro de búsqueda
            const where: any = {
                institucionId: institutionId,
                estado: { in: ['AUSENTE', 'TARDANZA'] }
            };

            if (classId) {
                where.horarioId = classId;
            }

            const now = new Date();
            if (scope === 'LAST_DAY') {
                const yesterday = new Date(now);
                yesterday.setDate(yesterday.getDate() - 1);
                where.fecha = { gte: yesterday };
            } else if (scope === 'LAST_WEEK') {
                const lastWeek = new Date(now);
                lastWeek.setDate(lastWeek.getDate() - 7);
                where.fecha = { gte: lastWeek };
            }

            const attendances = await prisma.asistencia.findMany({
                where,
                include: {
                    estudiante: true
                }
            });

            logger.info(`[NotificationController] Found ${attendances.length} records for manual trigger.`);

            let count = 0;
            for (const att of attendances) {
                await prisma.colaNotificacion.create({
                    data: {
                        estudianteId: att.estudianteId,
                        asistenciaId: att.id,
                        estado: 'PENDING',
                        programadoPara: new Date()
                    }
                });
                count++;
            }

            // Disparar procesamiento de cola de forma asíncrona
            notificationQueueService.processPendingNotifications().catch(err => logger.error(err));

            return reply.send({ success: true, queued: count, message: 'Notifications queued successfully.' });

        } catch (error) {
            logger.error('[NotificationController] Error triggering manual notifications', error);
            return reply.status(500).send({ error: 'Internal Server Error' });
        }
    }

    /**
     * Actualiza la configuración de notificaciones de una institución
     */
    public static async updateConfig(req: FastifyRequest, reply: FastifyReply) {
        const { institutionId } = req.params as any;
        const { notificacionesActivas, canalNotificacion, modoNotificacionAsistencia, horaDisparoNotificacion } = req.body as any;

        try {
            const config = await prisma.configuracion.upsert({
                where: { institucionId: institutionId },
                update: {
                    notificacionesActivas,
                    canalNotificacion,
                    modoNotificacionAsistencia,
                    horaDisparoNotificacion
                },
                create: {
                    institucionId: institutionId,
                    notificacionesActivas: notificacionesActivas ?? false,
                    canalNotificacion: canalNotificacion ?? 'NONE',
                    modoNotificacionAsistencia: modoNotificacionAsistencia ?? 'MANUAL_ONLY',
                    horaDisparoNotificacion
                }
            });

            return reply.send({ success: true, config });
        } catch (error) {
            logger.error('[NotificationController] Error updating config', error);
            return reply.status(500).send({ error: 'Internal Server Error' });
        }
    }

    /**
     * 🧪 Endpoint de prueba: Envía un mensaje de prueba a un número específico
     * Solo disponible para super_admin
     */
    public static async sendTestMessage(req: FastifyRequest, reply: FastifyReply) {
        const { phone, channel } = req.body as { phone: string; channel?: string };
        const user = (req as any).user;

        // Solo super_admin puede usar este endpoint
        if (user.rol !== 'super_admin') {
            return reply.status(403).send({ error: 'Only super_admin can send test messages' });
        }

        if (!phone) {
            return reply.status(400).send({ error: 'Phone number is required' });
        }

        try {
            const notificationChannel = (channel as NotificationChannel) || NotificationChannel.WHATSAPP;
            const result = await notificationService.sendTestMessage(phone, notificationChannel);

            return reply.send({
                success: result.success,
                messageId: result.messageId,
                error: result.error,
                provider: result.provider,
                rawResponse: result.rawResponse
            });

        } catch (error: any) {
            logger.error('[NotificationController] Error sending test message', error);
            return reply.status(500).send({ error: error.message || 'Internal Server Error' });
        }
    }

    /**
     * 📊 Obtiene estadísticas de la cola de notificaciones
     */
    public static async getQueueStats(req: FastifyRequest, reply: FastifyReply) {
        try {
            const stats = await notificationQueueService.getQueueStats();
            return reply.send({ success: true, stats });
        } catch (error) {
            logger.error('[NotificationController] Error getting queue stats', error);
            return reply.status(500).send({ error: 'Internal Server Error' });
        }
    }

    /**
     * 🔄 Reintenta enviar notificaciones en DEAD_LETTER
     */
    public static async retryDeadLetter(req: FastifyRequest, reply: FastifyReply) {
        const user = (req as any).user;

        if (user.rol !== 'super_admin' && user.rol !== 'admin_institucion') {
            return reply.status(403).send({ error: 'Insufficient permissions' });
        }

        try {
            const count = await notificationQueueService.retryDeadLetterItems();
            
            // Disparar procesamiento
            notificationQueueService.processPendingNotifications().catch(err => logger.error(err));

            return reply.send({ success: true, retriedCount: count });
        } catch (error) {
            logger.error('[NotificationController] Error retrying dead letter', error);
            return reply.status(500).send({ error: 'Internal Server Error' });
        }
    }

    /**
     * 📜 Obtiene el historial de notificaciones enviadas
     */
    public static async getNotificationLogs(req: FastifyRequest, reply: FastifyReply) {
        const { studentId, institutionId, limit = 50, offset = 0 } = req.query as any;

        try {
            const where: any = {};
            
            if (studentId) {
                where.estudianteId = studentId;
            }

            const logs = await prisma.logNotificacion.findMany({
                where,
                orderBy: { fechaEnvio: 'desc' },
                take: parseInt(limit),
                skip: parseInt(offset),
                include: {
                    estudiante: {
                        include: {
                            usuario: {
                                select: {
                                    nombres: true,
                                    apellidos: true
                                }
                            }
                        }
                    }
                }
            });

            const total = await prisma.logNotificacion.count({ where });

            return reply.send({
                success: true,
                data: logs,
                pagination: {
                    total,
                    limit: parseInt(limit),
                    offset: parseInt(offset)
                }
            });

        } catch (error) {
            logger.error('[NotificationController] Error getting logs', error);
            return reply.status(500).send({ error: 'Internal Server Error' });
        }
    }
}
