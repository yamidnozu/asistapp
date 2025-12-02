import { prisma } from '../config/database';
import logger from '../utils/logger';
import { ConsoleAdapter, EmailAdapter, INotificationAdapter, NotificationMessage, NotificationResult, TwilioAdapter, WhatsAppAdapter } from './notification/notification.adapter';
import { buildAttendanceTemplate, buildDailySummaryTemplate, buildAbsenceAlertTemplate, buildWelcomeTemplate, buildTestTemplate, getStatusText } from './notification/whatsapp-templates';

/**
 * Estrategias de notificación disponibles
 */
export enum NotificationStrategy {
    /** Notificación inmediata al registrar asistencia */
    INSTANT = 'INSTANT',
    /** Resumen al final del día */
    END_OF_DAY = 'END_OF_DAY',
    /** Solo envío manual desde el panel de admin */
    MANUAL_ONLY = 'MANUAL_ONLY'
}

/**
 * Canales de notificación disponibles
 */
export enum NotificationChannel {
    WHATSAPP = 'WHATSAPP',
    SMS = 'SMS',
    EMAIL = 'EMAIL',
    CONSOLE = 'CONSOLE',
    NONE = 'NONE'
}

export class NotificationService {
    
    /**
     * Obtiene el adaptador correcto según la configuración de la institución
     */
    private getAdapterForInstitution(channel: string): INotificationAdapter {
        switch (channel) {
            case NotificationChannel.WHATSAPP:
                return new WhatsAppAdapter();
            case NotificationChannel.SMS:
                return new TwilioAdapter();
            case NotificationChannel.EMAIL:
                return new EmailAdapter();
            default:
                return new ConsoleAdapter();
        }
    }

    /**
     * Obtiene la configuración de notificaciones de una institución
     */
    private async getInstitutionConfig(institucionId: string) {
        const config = await prisma.configuracion.findUnique({
            where: { institucionId }
        });
        
        return {
            enabled: config?.notificacionesActivas ?? false,
            channel: (config?.canalNotificacion ?? 'NONE') as NotificationChannel,
            strategy: (config?.modoNotificacionAsistencia ?? 'MANUAL_ONLY') as NotificationStrategy,
            scheduledTime: config?.horaDisparoNotificacion ?? '18:00:00',
            absenceThreshold: config?.umbralFaltas ?? 3
        };
    }

    /**
     * 🎯 PUNTO DE ENTRADA PRINCIPAL
     * Se llama automáticamente cuando se registra una asistencia
     */
    public async notifyAttendanceCreated(attendanceId: string): Promise<void> {
        try {
            const attendance = await prisma.asistencia.findUnique({
                where: { id: attendanceId },
                include: {
                    estudiante: {
                        include: {
                            usuario: true
                        }
                    },
                    institucion: true,
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

            // Obtener configuración de la institución
            const config = await this.getInstitutionConfig(attendance.institucionId);
            
            // Verificar si las notificaciones están activas
            if (!config.enabled || config.channel === NotificationChannel.NONE) {
                logger.debug(`[NotificationService] Notifications disabled for institution ${attendance.institucionId}`);
                return;
            }

            const student = attendance.estudiante;
            
            // Verificar que el estudiante acepta notificaciones y tiene teléfono de responsable
            if (!student.aceptaNotificaciones) {
                logger.debug(`[NotificationService] Student ${student.id} has notifications disabled`);
                return;
            }
            
            if (!student.telefonoResponsable) {
                logger.warn(`[NotificationService] Student ${student.id} has no guardian phone number`);
                return;
            }

            // Aplicar estrategia según configuración
            switch (config.strategy) {
                case NotificationStrategy.INSTANT:
                    await this.sendInstantNotification(attendance, student, config.channel);
                    break;
                    
                case NotificationStrategy.END_OF_DAY:
                    await this.queueForEndOfDay(attendance, config.scheduledTime);
                    break;
                    
                case NotificationStrategy.MANUAL_ONLY:
                default:
                    logger.debug(`[NotificationService] Manual mode - attendance queued but not auto-sent`);
                    // Opcionalmente encolar para revisión manual
                    break;
            }

            // Verificar umbral de faltas para alertas especiales
            if (attendance.estado === 'AUSENTE') {
                await this.checkAbsenceThreshold(student.id, attendance.institucionId, config);
            }

        } catch (error) {
            logger.error('[NotificationService] Error processing attendance notification', error);
        }
    }

    /**
     * 📲 ESTRATEGIA 1: Notificación Instantánea
     * Envía notificación inmediatamente al registrar asistencia
     */
    private async sendInstantNotification(
        attendance: any, 
        student: any,
        channel: NotificationChannel
    ): Promise<void> {
        const guardianName = student.nombreResponsable || 'Estimado acudiente';
        const studentName = `${student.usuario.nombres} ${student.usuario.apellidos}`;
        const status = getStatusText(attendance.estado);
        const subjectName = attendance.horario.materia.nombre;
        const date = attendance.fecha.toISOString().split('T')[0];

        const adapter = this.getAdapterForInstitution(channel);
        
        // Si es WhatsApp, usar template (requerido para iniciar conversación)
        const message: NotificationMessage = {
            to: student.telefonoResponsable!,
            body: `Hola ${guardianName}, ${studentName} registró ${status} en ${subjectName} el ${date}.`
        };

        // Para WhatsApp, añadir template
        if (channel === NotificationChannel.WHATSAPP) {
            message.template = buildAttendanceTemplate(
                guardianName,
                studentName,
                status,
                subjectName,
                date
            );
        }

        const result = await adapter.send(message);
        
        // Registrar en log
        await this.logNotification(student.id, student.telefonoResponsable!, message.body, result, channel);
        
        logger.info(`[NotificationService] ${channel} notification sent to ${student.telefonoResponsable}: ${result.success ? 'OK' : 'FAILED'}`);
    }

    /**
     * 📅 ESTRATEGIA 2: Encolar para Final del Día
     * Agrupa notificaciones y las envía a una hora específica
     */
    private async queueForEndOfDay(attendance: any, scheduledTime: string): Promise<void> {
        // Calcular hora de envío para hoy
        const now = new Date();
        const [hours, minutes] = scheduledTime.split(':').map(Number);
        const scheduledFor = new Date(now);
        scheduledFor.setHours(hours, minutes, 0, 0);
        
        // Si ya pasó la hora, programar para mañana
        if (scheduledFor <= now) {
            scheduledFor.setDate(scheduledFor.getDate() + 1);
        }

        await prisma.colaNotificacion.create({
            data: {
                estudianteId: attendance.estudianteId,
                asistenciaId: attendance.id,
                estado: 'PENDING',
                programadoPara: scheduledFor
            }
        });

        logger.info(`[NotificationService] Attendance ${attendance.id} queued for ${scheduledFor.toISOString()}`);
    }

    /**
     * 🚨 Verificar umbral de faltas y enviar alerta si se supera
     */
    private async checkAbsenceThreshold(
        studentId: string, 
        institucionId: string,
        config: { absenceThreshold: number; channel: NotificationChannel }
    ): Promise<void> {
        // Contar faltas en el periodo actual
        const absenceCount = await prisma.asistencia.count({
            where: {
                estudianteId: studentId,
                estado: 'AUSENTE',
                horario: {
                    periodoAcademico: {
                        activo: true
                    }
                }
            }
        });

        // Si supera el umbral, enviar alerta especial
        if (absenceCount >= config.absenceThreshold) {
            const student = await prisma.estudiante.findUnique({
                where: { id: studentId },
                include: { usuario: true }
            });

            if (student?.telefonoResponsable) {
                const adapter = this.getAdapterForInstitution(config.channel);
                const guardianName = student.nombreResponsable || 'Estimado acudiente';
                const studentName = `${student.usuario.nombres} ${student.usuario.apellidos}`;

                const message: NotificationMessage = {
                    to: student.telefonoResponsable,
                    body: `⚠️ Alerta: ${studentName} ha acumulado ${absenceCount} inasistencias. Por favor comuníquese con la institución.`
                };

                if (config.channel === NotificationChannel.WHATSAPP) {
                    message.template = buildAbsenceAlertTemplate(guardianName, studentName, absenceCount);
                }

                const result = await adapter.send(message);
                await this.logNotification(studentId, student.telefonoResponsable, message.body, result, config.channel);
                
                logger.warn(`[NotificationService] Absence threshold alert sent for student ${studentId}: ${absenceCount} absences`);
            }
        }
    }

    /**
     * 📤 Envía un mensaje directo (para uso desde API/Admin)
     */
    public async sendRawMessage(
        institucionId: string,
        studentId: string,
        message: string,
        type: 'ATTENDANCE' | 'REMINDER' | 'ALERT' = 'ATTENDANCE'
    ): Promise<NotificationResult> {
        const config = await this.getInstitutionConfig(institucionId);
        
        const student = await prisma.estudiante.findUnique({
            where: { id: studentId },
            select: { telefonoResponsable: true }
        });

        if (!student?.telefonoResponsable) {
            return {
                success: false,
                error: 'Student has no guardian phone number',
                provider: config.channel
            };
        }

        const adapter = this.getAdapterForInstitution(config.channel);
        const result = await adapter.send({
            to: student.telefonoResponsable,
            body: message
        });

        await this.logNotification(studentId, student.telefonoResponsable, message, result, config.channel);

        return result;
    }

    /**
     * 🧪 Envía un mensaje de prueba (usa template hello_world preaprobado)
     */
    public async sendTestMessage(phone: string, channel: NotificationChannel = NotificationChannel.WHATSAPP): Promise<NotificationResult> {
        const adapter = this.getAdapterForInstitution(channel);
        
        const message: NotificationMessage = {
            to: phone,
            body: 'Este es un mensaje de prueba de AsistApp 🎉'
        };

        // Para WhatsApp, usar template de prueba (hello_world viene preaprobado)
        if (channel === NotificationChannel.WHATSAPP) {
            message.template = buildTestTemplate();
        }

        const result = await adapter.send(message);
        
        logger.info(`[NotificationService] Test message to ${phone}: ${result.success ? 'OK' : 'FAILED'}`);
        
        return result;
    }

    /**
     * 📊 Registra la notificación en el historial
     */
    private async logNotification(
        studentId: string,
        phone: string,
        message: string,
        result: NotificationResult,
        channel: NotificationChannel
    ): Promise<void> {
        try {
            await prisma.logNotificacion.create({
                data: {
                    estudianteId: studentId,
                    telefonoDestino: phone,
                    mensaje: message,
                    proveedor: channel,
                    providerMessageId: result.messageId,
                    rawResponse: result.rawResponse as any,
                    exitoso: result.success,
                    errorMensaje: result.error || null
                }
            });
        } catch (error) {
            logger.error('[NotificationService] Error logging notification', error);
        }
    }

    /**
     * 📬 Envía resumen diario agrupado (llamado por el cron)
     */
    public async sendDailySummary(studentId: string, items: any[]): Promise<NotificationResult> {
        const student = await prisma.estudiante.findUnique({
            where: { id: studentId },
            include: { usuario: true }
        });

        if (!student?.telefonoResponsable) {
            return { success: false, error: 'No guardian phone', provider: 'NONE' };
        }

        const institucionId = items[0]?.asistencia?.institucionId;
        if (!institucionId) {
            return { success: false, error: 'No institution found', provider: 'NONE' };
        }

        const config = await this.getInstitutionConfig(institucionId);
        const adapter = this.getAdapterForInstitution(config.channel);

        const guardianName = student.nombreResponsable || 'Estimado acudiente';
        const studentName = `${student.usuario.nombres} ${student.usuario.apellidos}`;
        
        // Construir resumen
        const summaryLines = items.map(item => {
            const materia = item.asistencia?.horario?.materia?.nombre || 'Clase';
            const estado = getStatusText(item.asistencia?.estado || 'AUSENTE');
            return `• ${materia}: ${estado}`;
        });
        const summary = summaryLines.join('\n');

        const message: NotificationMessage = {
            to: student.telefonoResponsable,
            body: `Hola ${guardianName}, resumen de asistencia de ${studentName} para hoy:\n${summary}`
        };

        if (config.channel === NotificationChannel.WHATSAPP) {
            message.template = buildDailySummaryTemplate(guardianName, studentName, summary);
        }

        const result = await adapter.send(message);
        await this.logNotification(studentId, student.telefonoResponsable, message.body, result, config.channel);

        return result;
    }
}

export const notificationService = new NotificationService();
