/**
 * Templates predefinidos para notificaciones de WhatsApp
 * 
 * IMPORTANTE: Estos templates deben ser creados y aprobados en Meta Business Suite
 * antes de poder usarlos. Los nombres deben coincidir exactamente.
 * 
 * Crear templates en: https://business.facebook.com/wa/manage/message-templates/
 */

export interface WhatsAppTemplateConfig {
    name: string;
    language: {
        code: string;
    };
    components?: Array<{
        type: 'header' | 'body' | 'button';
        parameters?: Array<{
            type: 'text' | 'image' | 'document';
            text?: string;
            image?: { link: string };
            document?: { link: string; filename?: string };
        }>;
        sub_type?: 'quick_reply' | 'url';
        index?: number;
    }>;
}

/**
 * Genera un template de notificación de asistencia
 * 
 * Template en Meta debe tener estructura similar a:
 * "Hola {{1}}, le informamos que {{2}} registró {{3}} en la clase de {{4}} el día {{5}}."
 * 
 * @param guardianName - Nombre del acudiente
 * @param studentName - Nombre del estudiante
 * @param status - Estado de asistencia (Presente, Ausente, Tardanza)
 * @param subjectName - Nombre de la materia
 * @param date - Fecha formateada
 */
export function buildAttendanceTemplate(
    guardianName: string,
    studentName: string,
    status: string,
    subjectName: string,
    date: string
): WhatsAppTemplateConfig {
    return {
        name: 'asistencia_notificacion', // Debe coincidir con el template creado en Meta
        language: { code: 'es' },
        components: [
            {
                type: 'body',
                parameters: [
                    { type: 'text', text: guardianName },
                    { type: 'text', text: studentName },
                    { type: 'text', text: status },
                    { type: 'text', text: subjectName },
                    { type: 'text', text: date }
                ]
            }
        ]
    };
}

/**
 * Genera un template de resumen diario de asistencia
 * 
 * Template en Meta debe tener estructura similar a:
 * "Hola {{1}}, resumen de asistencia de {{2}} para hoy:\n{{3}}"
 * 
 * @param guardianName - Nombre del acudiente
 * @param studentName - Nombre del estudiante
 * @param summary - Resumen de clases y estados
 */
export function buildDailySummaryTemplate(
    guardianName: string,
    studentName: string,
    summary: string
): WhatsAppTemplateConfig {
    return {
        name: 'resumen_diario_asistencia',
        language: { code: 'es' },
        components: [
            {
                type: 'body',
                parameters: [
                    { type: 'text', text: guardianName },
                    { type: 'text', text: studentName },
                    { type: 'text', text: summary }
                ]
            }
        ]
    };
}

/**
 * Genera un template de alerta por inasistencias acumuladas
 * 
 * Template en Meta debe tener estructura similar a:
 * "⚠️ Alerta de Inasistencias\n\nHola {{1}}, {{2}} ha acumulado {{3}} inasistencias en el periodo actual. Por favor comuníquese con la institución."
 * 
 * @param guardianName - Nombre del acudiente
 * @param studentName - Nombre del estudiante
 * @param absenceCount - Número de inasistencias
 */
export function buildAbsenceAlertTemplate(
    guardianName: string,
    studentName: string,
    absenceCount: number
): WhatsAppTemplateConfig {
    return {
        name: 'alerta_inasistencias',
        language: { code: 'es' },
        components: [
            {
                type: 'body',
                parameters: [
                    { type: 'text', text: guardianName },
                    { type: 'text', text: studentName },
                    { type: 'text', text: absenceCount.toString() }
                ]
            }
        ]
    };
}

/**
 * Genera un template de bienvenida/verificación
 * 
 * Template en Meta (DEBE ser aprobado primero):
 * "Hola {{1}}, bienvenido al sistema de notificaciones de AsistApp. Recibirás alertas sobre la asistencia de {{2}}."
 * 
 * @param guardianName - Nombre del acudiente
 * @param studentName - Nombre del estudiante
 */
export function buildWelcomeTemplate(
    guardianName: string,
    studentName: string
): WhatsAppTemplateConfig {
    return {
        name: 'bienvenida_asistapp',
        language: { code: 'es' },
        components: [
            {
                type: 'body',
                parameters: [
                    { type: 'text', text: guardianName },
                    { type: 'text', text: studentName }
                ]
            }
        ]
    };
}

/**
 * Template simple de prueba (hello_world de Meta)
 * Este template viene preaprobado en todas las cuentas de WhatsApp Business
 */
export function buildTestTemplate(): WhatsAppTemplateConfig {
    return {
        name: 'hello_world',
        language: { code: 'en_US' }
    };
}

/**
 * Mapeo de estados de asistencia a texto amigable
 */
export const ATTENDANCE_STATUS_TEXT: Record<string, string> = {
    'PRESENTE': 'asistencia ✅',
    'AUSENTE': 'inasistencia ❌',
    'TARDANZA': 'tardanza ⏰',
    'JUSTIFICADO': 'falta justificada 📋',
    'PERMISO': 'permiso autorizado 📝'
};

/**
 * Obtiene el texto amigable para un estado de asistencia
 */
export function getStatusText(status: string): string {
    return ATTENDANCE_STATUS_TEXT[status] || status.toLowerCase();
}
