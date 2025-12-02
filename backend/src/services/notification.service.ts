import { prisma } from '../config/database';
import logger from '../utils/logger';
import { ConsoleAdapter, EmailAdapter, INotificationAdapter, NotificationResult, TwilioAdapter, WhatsAppAdapter } from './notification/notification.adapter';

export class NotificationService {
    private getAdapterForInstitution(institucionId: string): INotificationAdapter {
        // In a real app, cache this or get from config
        // For now, check env or institution config
        const provider = process.env.NOTIFICATION_PROVIDER || 'CONSOLE';
        
        if (provider === 'WHATSAPP') {
            return new WhatsAppAdapter();
        } else if (provider === 'SMS') {
            return new TwilioAdapter();
        } else if (provider === 'EMAIL') {
            return new EmailAdapter();
        } else {
            return new ConsoleAdapter();
        }
    }

    /**
     * Main entry point when an attendance record is created.
     */
    public async notifyAttendanceCreated(attendanceId: string): Promise<void> {
        try {
            const attendance = await prisma.asistencia.findUnique({
                where: { id: attendanceId },
                include: {
                    estudiante: true,
                    institucion: {
                        include: {
                            configuraciones: true
                        }
                    },
                    horario: {
                        include: {
                            materia: true
                        }
                    }
                }
            });

            if (!attendance) {
                logger.warn(`[NotificationService] Attendance ${attendanceId} not found`);
                return;
            }

            const config = attendance.institucion.configuraciones;
            // @ts-ignore: Prisma client might not be updated in IDE context yet
            if (!config || !config.notificacionesActivas || config.canalNotificacion === 'NONE') {
                return;
            }

            const student = attendance.estudiante;
            // @ts-ignore: Prisma client might not be updated in IDE context yet
            if (!student.aceptaNotificaciones || !student.telefonoResponsable) {
                return;
            }

            // @ts-ignore: Prisma client might not be updated in IDE context yet
            const mode = config.modoNotificacionAsistencia; // INSTANT, END_OF_DAY, MANUAL_ONLY

            if (mode === 'INSTANT') {
                await this.sendInstantNotification(attendance, student.telefonoResponsable!);
            } else {
                // Queue for later (END_OF_DAY or MANUAL_ONLY)
                // @ts-ignore: Prisma client might not be updated in IDE context yet
                await this.queueNotification(attendance, mode, config.horaDisparoNotificacion);
            }

        } catch (error) {
            logger.error('[NotificationService] Error processing attendance notification', error);
        }
    }

    public async sendRawMessage(
        institucionId: string,
        studentId: string,
        message: string,
        type: 'ATTENDANCE' | 'REMINDER' | 'ALERT' = 'ATTENDANCE'
    ): Promise<NotificationResult> {
        // Get student phone number
        const student = await prisma.estudiante.findUnique({
            where: { id: studentId },
            select: { telefonoResponsable: true }
        });

        const adapter = this.getAdapterForInstitution(institucionId);
        const result = await adapter.send({
            to: student?.telefonoResponsable || '',
            body: message
        });

        // Log to database (usando solo campos disponibles en el schema actual de Prisma client)
        await prisma.logNotificacion.create({
            data: {
                estudianteId: studentId,
                telefonoDestino: student?.telefonoResponsable || '',
                mensaje: message,
                exitoso: result.success,
                errorMensaje: result.error || null
            }
        });

        return result;
    }

    private async sendInstantNotification(attendance: any, phone: string): Promise<void> {
        const body = `Hola, le informamos que ${attendance.estudiante.nombreResponsable || 'su acudido'} faltó a la clase de ${attendance.horario.materia.nombre} el día ${attendance.fecha.toISOString().split('T')[0]}. Estado: ${attendance.estado}.`;
        await this.sendRawMessage(attendance.institucionId, attendance.estudianteId, body, 'ATTENDANCE');
    }

    private async queueNotification(attendance: any, mode: string, scheduledTime?: string | null): Promise<void> {
        let scheduledFor = new Date();

        if (mode === 'END_OF_DAY' && scheduledTime) {
            // Parse HH:MM:SS
            const [hours, minutes] = scheduledTime.split(':').map(Number);
            scheduledFor.setHours(hours, minutes, 0, 0);
        }

        // Crear entrada en la cola de notificaciones (el modelo no contiene institucionId)
        await prisma.colaNotificacion.create({
            data: {
                estudianteId: attendance.estudianteId,
                asistenciaId: attendance.id,
                estado: 'PENDING',
                programadoPara: scheduledFor,
            }
        });
    }

    /**
     * Process the queue for batch sending.
     * This would be called by the Cron Job.
     */
    public async processQueue(): Promise<void> {
        // Logic to fetch PENDING items where programadoPara <= now
        // Group by Guardian
        // Send batch messages
        // Update status
        // This logic is complex, maybe move to NotificationQueueService?
        // For now, let's keep it simple here or delegate.
    }
}

export const notificationService = new NotificationService();
