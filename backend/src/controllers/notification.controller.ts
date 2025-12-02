import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { notificationService } from '../services/notification.service';
import { notificationQueueService } from '../services/notification-queue.service';
import logger from '../utils/logger';

export class NotificationController {

    public static async triggerManual(req: FastifyRequest, reply: FastifyReply) {
        const { scope, institutionId, classId } = req.body as any;

        try {
            // 1. Find relevant attendance records
            const where: any = {
                institucionId: institutionId,
                estado: { in: ['AUSENTE', 'TARDANZA'] } // Only notify bad stuff? Or everything? Requirement says "Falta" -> "Plantilla_Falta_Hijo".
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
                // Check if already notified?
                // Check if exists in ColaNotificacion?
                // For manual trigger, maybe we force re-send or check if SENT?
                // Let's check if there is a successful log?
                // For simplicity, let's just queue them as PENDING.

                // @ts-ignore
                await prisma.colaNotificacion.create({
                    data: {
                        estudianteId: att.estudianteId,
                        asistenciaId: att.id,
                        estado: 'PENDING',
                        programadoPara: new Date() // Now
                    }
                });
                count++;
            }

            // Trigger processing async
            notificationQueueService.processPendingNotifications().catch(err => logger.error(err));

            return reply.send({ success: true, queued: count, message: 'Notifications queued successfully.' });

        } catch (error) {
            logger.error('[NotificationController] Error triggering manual notifications', error);
            return reply.status(500).send({ error: 'Internal Server Error' });
        }
    }

    public static async updateConfig(req: FastifyRequest, reply: FastifyReply) {
        const { institutionId } = req.params as any;
        const { notificacionesActivas, canalNotificacion, modoNotificacionAsistencia, horaDisparoNotificacion } = req.body as any;

        try {
            const config = await prisma.configuracion.update({
                where: { institucionId: institutionId },
                data: {
                    notificacionesActivas,
                    // @ts-ignore
                    canalNotificacion,
                    modoNotificacionAsistencia,
                    horaDisparoNotificacion
                }
            });

            return reply.send({ success: true, config });
        } catch (error) {
            logger.error('[NotificationController] Error updating config', error);
            return reply.status(500).send({ error: 'Internal Server Error' });
        }
    }
}
