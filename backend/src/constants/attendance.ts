/**
 * Constantes para estados y tipos de asistencia en AsistApp
 * Centraliza todos los estados y tipos para evitar strings mágicos
 */

export enum AttendanceStatus {
    PRESENTE = 'PRESENTE',
    AUSENTE = 'AUSENTE',
    TARDANZA = 'TARDANZA',
    JUSTIFICADO = 'JUSTIFICADO',
}

export enum AttendanceType {
    MANUAL = 'MANUAL',
    QR = 'QR',
    AUTOMATICO = 'AUTOMATICO',
}

/**
 * Verifica si un string es un estado de asistencia válido
 */
export function isValidAttendanceStatus(status: string): status is AttendanceStatus {
    return Object.values(AttendanceStatus).includes(status as AttendanceStatus);
}

/**
 * Verifica si un string es un tipo de registro válido
 */
export function isValidAttendanceType(type: string): type is AttendanceType {
    return Object.values(AttendanceType).includes(type as AttendanceType);
}

/**
 * Obtiene el nombre legible de un estado de asistencia
 */
export function getAttendanceStatusName(status: AttendanceStatus): string {
    const statusNames: Record<AttendanceStatus, string> = {
        [AttendanceStatus.PRESENTE]: 'Presente',
        [AttendanceStatus.AUSENTE]: 'Ausente',
        [AttendanceStatus.TARDANZA]: 'Tardanza',
        [AttendanceStatus.JUSTIFICADO]: 'Justificado',
    };
    return statusNames[status];
}

/**
 * Obtiene el color asociado a un estado de asistencia
 */
export function getAttendanceStatusColor(status: AttendanceStatus): string {
    const statusColors: Record<AttendanceStatus, string> = {
        [AttendanceStatus.PRESENTE]: '#4CAF50', // Verde
        [AttendanceStatus.AUSENTE]: '#F44336', // Rojo
        [AttendanceStatus.TARDANZA]: '#FF9800', // Naranja
        [AttendanceStatus.JUSTIFICADO]: '#2196F3', // Azul
    };
    return statusColors[status];
}
