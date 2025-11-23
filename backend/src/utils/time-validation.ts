import { ValidationError } from '../types';

/**
 * Regex para validar formato de hora HH:MM con padding de ceros
 * Acepta horas de 00:00 a 23:59
 * Ejemplos válidos: "08:00", "14:30", "23:59"
 * Ejemplos inválidos: "8:00", "24:00", "14:60"
 */
export const TIME_FORMAT_REGEX = /^([0-1][0-9]|2[0-3]):([0-5][0-9])$/;

/**
 * Valida que las horas tengan el formato correcto "HH:MM" con padding de ceros
 * y que la hora de inicio sea anterior a la hora de fin
 * 
 * @param horaInicio - Hora de inicio en formato "HH:MM"
 * @param horaFin - Hora de fin en formato "HH:MM"
 * @throws {ValidationError} si el formato es inválido o las horas son inconsistentes
 * 
 * @example
 * validateTimeFormat("08:00", "09:30"); // OK
 * validateTimeFormat("8:00", "09:30");  // Error: formato inválido
 * validateTimeFormat("09:00", "08:00"); // Error: inicio >= fin
 */
export function validateTimeFormat(horaInicio: string, horaFin: string): void {
    if (!TIME_FORMAT_REGEX.test(horaInicio)) {
        throw new ValidationError(
            `Formato de hora inválido en horaInicio: "${horaInicio}". Use formato HH:MM con padding de ceros (ej: 08:00, 14:30)`
        );
    }

    if (!TIME_FORMAT_REGEX.test(horaFin)) {
        throw new ValidationError(
            `Formato de hora inválido en horaFin: "${horaFin}". Use formato HH:MM con padding de ceros (ej: 08:00, 14:30)`
        );
    }

    // Comparación lexicográfica funciona porque el formato es consistente HH:MM
    if (horaInicio >= horaFin) {
        throw new ValidationError(
            `La hora de inicio (${horaInicio}) debe ser anterior a la hora de fin (${horaFin})`
        );
    }
}

/**
 * Valida que una hora individual tenga el formato correcto
 * 
 * @param hora - Hora en formato "HH:MM"
 * @returns true si el formato es válido
 * 
 * @example
 * isValidTimeFormat("08:00"); // true
 * isValidTimeFormat("8:00");  // false
 * isValidTimeFormat("24:00"); // false
 */
export function isValidTimeFormat(hora: string): boolean {
    return TIME_FORMAT_REGEX.test(hora);
}
