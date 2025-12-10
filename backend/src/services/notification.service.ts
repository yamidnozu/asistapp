import { prisma } from '../config/database';
import logger from '../utils/logger';
import PushNotificationService from './push-notification.service';
import { ConsoleAdapter, EmailAdapter, INotificationAdapter, NotificationMessage, NotificationResult, TwilioAdapter, WhatsAppAdapter } from './notification/notification.adapter';
import { formatDateTime, getStatusEmoji, getStatusText } from './notification/whatsapp-templates';

/**
 * Información de un estudiante para agrupación de notificaciones
 */
export interface StudentNotificationInfo {
    estudianteId: string;
    nombreCompleto: string;
    items: any[];
}

/**
 * Grupo de notificaciones por teléfono de responsable
 */
export interface GuardianNotificationGroup {
    phone: string;
    guardianName: string;
    students: StudentNotificationInfo[];
    allItems: any[];
    institucionId: string;
}

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
            absenceThreshold: 3 // Default hardcoded value as field is deprecated
        };
    }

    /**
     * PUNTO DE ENTRADA PRINCIPAL
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

            // NUEVO: Llamar al servicio que SÍ envía notificaciones PUSH
            if (attendance.estado === 'AUSENTE' || attendance.estado === 'TARDANZA') {
                logger.info(`[NotificationService] Handing off to PushNotificationService for state: ${attendance.estado}`);
                PushNotificationService.notificarAcudientes(
                    attendance.estudianteId,
                    attendance.estado === 'AUSENTE' ? 'ausencia' : 'tardanza',
                    {
                        materiaNombre: attendance.horario.materia?.nombre,
                        materiaId: attendance.horario.materiaId,
                        hora: attendance.horario.horaInicio,
                        fecha: formatDateTime(attendance.fecha, 'date'),
                        asistenciaId: attendance.id
                    }
                ).catch(err => {
                    logger.error('[NotificationService] Error during PushNotificationService.notificarAcudientes call:', err);
                });
            }

            // Obtener configuración de la institución
            const config = await this.getInstitutionConfig(attendance.institucionId);

            // Verificar si las notificaciones WhatsApp/SMS están activas
            if (!config.enabled || config.channel === NotificationChannel.NONE) {
                logger.debug(`[NotificationService] External notifications disabled for institution ${attendance.institucionId}`);
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
                    // Solo notificar instantáneamente si es AUSENTE o TARDANZA
                    if (attendance.estado === 'AUSENTE' || attendance.estado === 'TARDANZA') {
                        await this.sendInstantNotification(attendance, student, config.channel);
                    } else {
                        logger.debug(`[NotificationService] INSTANT mode: Skipping notification for state ${attendance.estado} (only AUSENTE/TARDANZA trigger notifications)`);
                    }
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
     * 🔔 Notifica a los acudientes del estudiante via notificaciones in-app
     * Estas notificaciones aparecen en la app del acudiente (push + in-app)
     */
    private async notifyGuardiansInApp(attendance: any): Promise<void> {
        try {
            const studentName = `${attendance.estudiante.usuario.nombres} ${attendance.estudiante.usuario.apellidos}`;
            const materiaName = attendance.horario.materia?.nombre || 'una clase';
            const horaInicio = attendance.horario.horaInicio || '';
            const estado = attendance.estado;

            // Buscar acudientes activos del estudiante
            const acudientes = await prisma.acudienteEstudiante.findMany({
                where: {
                    estudianteId: attendance.estudiante.id,
                    activo: true
                },
                select: {
                    acudienteId: true,
                    acudiente: {
                        select: { nombres: true }
                    }
                }
            });

            if (acudientes.length === 0) {
                logger.debug(`[NotificationService] No guardians found for student ${attendance.estudiante.id}`);
                return;
            }

            // Construir notificación
            const tipo = estado === 'AUSENTE' ? 'ausencia' : 'tardanza';
            const titulo = estado === 'AUSENTE'
                ? `⚠️ Ausencia de ${attendance.estudiante.usuario.nombres}`
                : `⏰ Tardanza de ${attendance.estudiante.usuario.nombres}`;
            const mensaje = estado === 'AUSENTE'
                ? `${studentName} ha sido marcado como AUSENTE en ${materiaName}${horaInicio ? ` a las ${horaInicio}` : ''}.`
                : `${studentName} llegó tarde a ${materiaName}${horaInicio ? ` (${horaInicio})` : ''}.`;

            // Crear notificación in-app para cada acudiente
            for (const acudiente of acudientes) {
                await prisma.notificacionInApp.create({
                    data: {
                        usuarioId: acudiente.acudienteId,
                        titulo,
                        mensaje,
                        tipo,
                        estudianteId: attendance.estudiante.id,
                        materiaId: attendance.horario.materiaId,
                        asistenciaId: attendance.id,
                        datos: {
                            horaInicio,
                            horaFin: attendance.horario.horaFin,
                            fecha: attendance.fecha.toISOString(),
                            institucionId: attendance.institucionId
                        }
                    }
                });

                logger.info(`[NotificationService] In-app notification created for guardian ${acudiente.acudienteId}`);
            }

            logger.info(`[NotificationService] Notified ${acudientes.length} guardians for student ${attendance.estudiante.id}`);

        } catch (error) {
            logger.error('[NotificationService] Error notifying guardians in-app', error);
        }
    }


    /**
     * 📲 ESTRATEGIA 1: Notificación Instantánea
     * Envía notificación inmediatamente al registrar asistencia
     * 
     * NOTA: El WhatsAppAdapter ahora usa estrategia simplificada:
     * 1. Intenta texto libre (personalizado)
     * 2. Si falla (24h window), usa template hello_world como fallback
     */
    private async sendInstantNotification(
        attendance: any,
        student: any,
        channel: NotificationChannel
    ): Promise<void> {
        const guardianName = student.nombreResponsable || 'Estimado acudiente';
        const studentName = `${student.usuario.nombres} ${student.usuario.apellidos}`;
        const status = getStatusText(attendance.estado);
        const statusEmoji = getStatusEmoji(attendance.estado);
        const subjectName = attendance.horario.materia.nombre;
        const horaClase = attendance.horario.horaInicio || '';
        const date = formatDateTime(attendance.fecha, 'date');

        const adapter = this.getAdapterForInstitution(channel);

        // Mensaje personalizado y rico en contexto
        const message: NotificationMessage = {
            to: student.telefonoResponsable!,
            body: `📚 *AsistApp - Notificación de Asistencia*\n\n` +
                `Hola ${guardianName},\n\n` +
                `${statusEmoji} *${studentName}* registró *${status}*\n` +
                `📖 Materia: ${subjectName}\n` +
                `⏰ Hora: ${horaClase}\n` +
                `📅 Fecha: ${date}\n\n` +
                `_Mensaje automático de AsistApp_`,
            // Parámetros para el template de fallback (si está configurado)
            templateParams: {
                guardianName,
                studentName,
                status,
                subjectName,
                date
            }
        };
        // El adapter intenta texto primero, template con parámetros como fallback

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

                // Mensaje de alerta mejorado
                const message: NotificationMessage = {
                    to: student.telefonoResponsable,
                    body: `⚠️ *ALERTA DE INASISTENCIAS*\n\n` +
                        `Hola ${guardianName},\n\n` +
                        `*${studentName}* ha acumulado *${absenceCount} inasistencias* en el periodo actual.\n\n` +
                        `Por favor comuníquese con la institución lo antes posible.\n\n` +
                        `_Mensaje automático de AsistApp_`
                };
                // NO pasamos template - el adapter usa texto primero

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
     * 🧪 Envía un mensaje de prueba
     * NOTA: Ahora usa texto primero, hello_world solo como fallback si falla por ventana 24h
     */
    public async sendTestMessage(phone: string, channel: NotificationChannel = NotificationChannel.WHATSAPP): Promise<NotificationResult> {
        const adapter = this.getAdapterForInstitution(channel);

        const message: NotificationMessage = {
            to: phone,
            body: `🎉 *Mensaje de Prueba - AsistApp*\n\n` +
                `¡Hola! Este es un mensaje de prueba del sistema de notificaciones.\n\n` +
                `Si recibió este mensaje, las notificaciones están funcionando correctamente.\n\n` +
                `_Mensaje automático de AsistApp_`
        };
        // NO pasamos template - el adapter intenta texto primero

        const result = await adapter.send(message);

        logger.info(`[NotificationService] Test message to ${phone}: ${result.success ? 'OK' : 'FAILED'}`);

        return result;
    }

    /**
     * Registra la notificación en el historial
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
     * 📬 Envía resumen diario agrupado (llamado por el cron) - LEGACY
     * Mantener para compatibilidad pero usar sendConsolidatedSummary para nuevos envíos
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
            const emoji = getStatusEmoji(item.asistencia?.estado || 'AUSENTE');
            return `${emoji} ${materia}: ${estado}`;
        });
        const summary = summaryLines.join('\n');

        // Mensaje mejorado con formato
        const message: NotificationMessage = {
            to: student.telefonoResponsable,
            body: `📚 *AsistApp - Resumen de Asistencia*\n\n` +
                `Hola ${guardianName},\n\n` +
                `Resumen de asistencia de *${studentName}* para hoy:\n\n` +
                `${summary}\n\n` +
                `_Mensaje automático de AsistApp_`
        };
        // NO pasamos template - el adapter usa texto primero

        const result = await adapter.send(message);
        await this.logNotification(studentId, student.telefonoResponsable, message.body, result, config.channel);

        return result;
    }

    /**
     * MÉTODO MEJORADO: Envía resumen consolidado por responsable
     * 
     * Agrupa todas las notificaciones de todos los hijos de un responsable
     * en un solo mensaje bien estructurado con contexto completo.
     * 
     * Formato del mensaje:
     * - Saludo con nombre del responsable
     * - Fecha del reporte
     * - Por cada hijo: nombre + lista de materias con hora y estado
     * - Información de contacto
     */
    public async sendConsolidatedSummary(group: GuardianNotificationGroup): Promise<NotificationResult> {
        const { phone, guardianName, students, institucionId } = group;

        if (!institucionId) {
            return { success: false, error: 'No institution found', provider: 'NONE' };
        }

        const config = await this.getInstitutionConfig(institucionId);
        const adapter = this.getAdapterForInstitution(config.channel);

        // Obtener nombre de la institución
        const institucion = await prisma.institucion.findUnique({
            where: { id: institucionId },
            select: { nombre: true }
        });
        const institutionName = institucion?.nombre || 'la institución';

        // Construir resumen consolidado con formato rico
        const messageBody = this.buildConsolidatedMessage(guardianName, students, institutionName);

        // Construir resumen compacto para el template (sin formato rico)
        const summaryForTemplate = this.buildConsolidatedSummaryForTemplate(students);

        // El adapter intenta texto primero, template con parámetros como fallback
        const message: NotificationMessage = {
            to: phone,
            body: messageBody,
            // Parámetros para template de fallback (resumen consolidado)
            templateParams: {
                guardianName,
                summary: summaryForTemplate
            }
        };

        const result = await adapter.send(message);

        // Registrar log para cada estudiante involucrado
        for (const student of students) {
            await this.logNotification(student.estudianteId, phone, messageBody, result, config.channel);
        }

        return result;
    }

    /**
     * Construye el mensaje consolidado con formato completo
     */
    private buildConsolidatedMessage(
        guardianName: string,
        students: StudentNotificationInfo[],
        institutionName: string
    ): string {
        const now = new Date();
        const dateStr = formatDateTime(now, 'date');

        let message = `📚 *AsistApp - Reporte de Asistencia*\n`;
        message += `━━━━━━━━━━━━━━━━━━━━━━\n\n`;
        message += `Hola ${guardianName},\n\n`;
        message += `📅 *Fecha:* ${dateStr}\n`;
        message += `🏫 *Institución:* ${institutionName}\n\n`;

        // Si hay múltiples hijos, indicarlo
        if (students.length > 1) {
            message += `👨‍👩‍👧‍👦 Resumen de ${students.length} estudiantes:\n\n`;
        }

        // Por cada estudiante
        for (const student of students) {
            message += `👤 *${student.nombreCompleto}*\n`;
            message += `┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄\n`;

            // Agrupar items por fecha (por si hay notificaciones de varios días)
            const itemsByDate = new Map<string, any[]>();
            for (const item of student.items) {
                const fecha = item.asistencia?.fecha
                    ? formatDateTime(new Date(item.asistencia.fecha), 'date')
                    : dateStr;

                if (!itemsByDate.has(fecha)) {
                    itemsByDate.set(fecha, []);
                }
                itemsByDate.get(fecha)!.push(item);
            }

            // Mostrar items organizados por fecha
            for (const [fecha, items] of itemsByDate) {
                if (itemsByDate.size > 1) {
                    message += `  📅 ${fecha}:\n`;
                }

                for (const item of items) {
                    const horario = item.asistencia?.horario;
                    const materia = horario?.materia?.nombre || 'Clase';
                    const horaInicio = horario?.horaInicio || '--:--';
                    const horaFin = horario?.horaFin || '--:--';
                    const estado = item.asistencia?.estado || 'AUSENTE';
                    const emoji = getStatusEmoji(estado);
                    const estadoTexto = getStatusText(estado);

                    // Obtener nombre del día si está disponible
                    const diaSemana = horario?.diaSemana !== undefined
                        ? this.getDayName(horario.diaSemana)
                        : '';

                    message += `  ${emoji} *${materia}*\n`;
                    message += `     ⏰ ${horaInicio} - ${horaFin}${diaSemana ? ` (${diaSemana})` : ''}\n`;
                    message += `     Estado: ${estadoTexto}\n`;

                    // Agregar observación si existe
                    if (item.asistencia?.observacion) {
                        message += `     📝 ${item.asistencia.observacion}\n`;
                    }
                    message += `\n`;
                }
            }
        }

        message += `━━━━━━━━━━━━━━━━━━━━━━\n`;
        message += `💬 Si tiene dudas, comuníquese con ${institutionName}.\n`;
        message += `\n_Mensaje enviado automáticamente por AsistApp_`;

        return message;
    }

    /**
     * Construye resumen compacto para template de WhatsApp
     */
    private buildConsolidatedSummaryForTemplate(students: StudentNotificationInfo[]): string {
        const lines: string[] = [];

        for (const student of students) {
            lines.push(`📚 ${student.nombreCompleto}:`);

            for (const item of student.items) {
                const materia = item.asistencia?.horario?.materia?.nombre || 'Clase';
                const horaInicio = item.asistencia?.horario?.horaInicio || '--:--';
                const estado = item.asistencia?.estado || 'AUSENTE';
                const emoji = getStatusEmoji(estado);
                lines.push(`  ${emoji} ${materia} (${horaInicio})`);
            }
        }

        return lines.join('\n');
    }

    /**
     * Obtiene el nombre del día de la semana
     */
    private getDayName(dayNumber: number): string {
        const days = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];
        return days[dayNumber] || '';
    }

    /**
     * Procesa notificaciones de ausencia total diaria
     * Se envía si el estudiante faltó a TODAS las clases del día
     */
    public async processDailyTotalAbsenceNotifications() {
        logger.info('Processing daily total absence notifications...');

        try {
            // 1. Obtener instituciones con la configuración activada
            const institutions = await prisma.institucion.findMany({
                where: {
                    activa: true,
                    configuraciones: {
                        notificacionesActivas: true,
                        notificarAusenciaTotalDiaria: true
                    }
                },
                include: {
                    configuraciones: true
                }
            });

            logger.info(`Found ${institutions.length} institutions with daily total absence check enabled.`);

            const today = new Date();
            const startOfDay = new Date(today.setHours(0, 0, 0, 0));
            const endOfDay = new Date(today.setHours(23, 59, 59, 999));
            const dayOfWeek = today.getDay(); // 0-6

            for (const inst of institutions) {
                await this.processInstitutionTotalAbsences(inst, startOfDay, endOfDay, dayOfWeek);
            }

        } catch (error) {
            logger.error('Error processing daily total absence notifications:', error);
        }
    }

    private async processInstitutionTotalAbsences(institution: any, startOfDay: Date, endOfDay: Date, dayOfWeek: number) {
        logger.info(`Checking total absences for institution: ${institution.nombre}`);

        // 1. Obtener todas las asistencias de hoy para esta institución
        const asistenciasHoy = await prisma.asistencia.findMany({
            where: {
                institucionId: institution.id,
                fecha: {
                    gte: startOfDay,
                    lte: endOfDay
                }
            },
            include: {
                estudiante: {
                    include: {
                        usuario: true
                    }
                },
                horario: true
            }
        });

        // Agrupar por estudiante
        const asistenciasPorEstudiante = new Map<string, any[]>();
        for (const asis of asistenciasHoy) {
            if (!asistenciasPorEstudiante.has(asis.estudianteId)) {
                asistenciasPorEstudiante.set(asis.estudianteId, []);
            }
            asistenciasPorEstudiante.get(asis.estudianteId)?.push(asis);
        }

        // 2. Para cada estudiante con asistencias hoy, verificar si faltó a todas
        for (const [estudianteId, asistencias] of asistenciasPorEstudiante) {
            // Verificar si todas son AUSENTE
            const todasAusentes = asistencias.every(a => a.estado === 'AUSENTE');

            if (!todasAusentes) {
                continue; // Asistió al menos a una (o tiene tardanza/justificado)
            }

            const estudiante = asistencias[0].estudiante;

            // Obtener grupos del estudiante
            const gruposEstudiante = await prisma.estudianteGrupo.findMany({
                where: {
                    estudianteId: estudianteId
                },
                select: { grupoId: true }
            });

            const grupoIds = gruposEstudiante.map((g: { grupoId: string }) => g.grupoId);

            // Contar clases programadas para hoy
            const clasesHoy = await prisma.horario.count({
                where: {
                    grupoId: { in: grupoIds },
                    diaSemana: dayOfWeek,
                    institucionId: institution.id
                }
            });

            // Si el número de asistencias registradas (que son todas ausentes) es igual al número de clases programadas
            if (asistencias.length === clasesHoy && clasesHoy > 0) {
                logger.info(`Student ${estudiante.usuario.nombres} missed ALL ${clasesHoy} classes today. Sending notification.`);

                await this.sendTotalAbsenceNotification(estudiante, institution, asistencias);
            }
        }
    }

    private async sendTotalAbsenceNotification(estudiante: any, institution: any, asistencias: any[]) {
        const config = institution.configuraciones;
        const adapter = this.getAdapterForInstitution(config.canalNotificacion);

        if (adapter && estudiante.telefonoResponsable) {
            const nombreEstudiante = `${estudiante.usuario.nombres} ${estudiante.usuario.apellidos}`;
            const fecha = formatDateTime(new Date());

            const mensaje = `⚠️ *ALERTA DE AUSENCIA TOTAL* ⚠️\n\n` +
                `El estudiante *${nombreEstudiante}* ha faltado a TODAS sus clases el día de hoy (${fecha.split(',')[0]}).\n\n` +
                `Por favor contacte a la institución para justificar las inasistencias.`;

            await adapter.send({
                to: estudiante.telefonoResponsable,
                body: mensaje
            });

            await prisma.logNotificacion.create({
                data: {
                    estudianteId: estudiante.id,
                    telefonoDestino: estudiante.telefonoResponsable,
                    mensaje: mensaje,
                    proveedor: config.canalNotificacion,
                    exitoso: true
                }
            });
        }
    }
}

export const notificationService = new NotificationService();
