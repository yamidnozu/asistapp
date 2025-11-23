/**
 * Utilidades para manejo consistente de fechas en AsistApp
 * 
 * IMPORTANTE: Todas las fechas se guardan en UTC en la base de datos.
 * El frontend (Flutter) es responsable de convertir a la zona horaria local del usuario.
 * 
 * Esto garantiza:
 * - Consistencia global sin importar dónde esté el servidor
 * - Soporte multi-país sin hardcodear zona horaria
 * - El usuario ve las fechas en su hora local automáticamente
 */

export function getStartOfDay(date?: Date): Date {
    const d = date ? new Date(date) : new Date();
    return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 0, 0, 0, 0));
}

export function getEndOfDay(date?: Date): Date {
    const d = date ? new Date(date) : new Date();
    return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), 23, 59, 59, 999));
}

export function parseDateString(dateStr: string): Date {
    const [year, month, day] = dateStr.split('-').map(Number);
    if (!year || !month || !day || month < 1 || month > 12 || day < 1 || day > 31) {
        throw new Error(`Formato de fecha inválido: ${dateStr}. Use YYYY-MM-DD`);
    }
    return new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
}

export function formatDateForDB(date: Date): Date {
    return getStartOfDay(date);
}

export function isSameDay(date1: Date, date2: Date): boolean {
    return (
        date1.getUTCFullYear() === date2.getUTCFullYear() &&
        date1.getUTCMonth() === date2.getUTCMonth() &&
        date1.getUTCDate() === date2.getUTCDate()
    );
}

export function getDateRange(date: Date): { start: Date; end: Date } {
    const start = getStartOfDay(date);
    const end = new Date(start);
    end.setUTCDate(end.getUTCDate() + 1);
    return { start, end };
}

export function formatDateToISO(date: Date): string {
    const year = date.getUTCFullYear();
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    const day = String(date.getUTCDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

export function formatDateTimeToISO(date: Date): string {
    return date.toISOString();
}

export function getToday(): Date {
    return getStartOfDay(new Date());
}

export function daysDifference(date1: Date, date2: Date): number {
    const start = getStartOfDay(date1);
    const end = getStartOfDay(date2);
    const diffTime = end.getTime() - start.getTime();
    return Math.floor(diffTime / (1000 * 60 * 60 * 24));
}

export function isDateInRange(date: Date, startDate: Date, endDate: Date): boolean {
    const checkDate = getStartOfDay(date).getTime();
    const start = getStartOfDay(startDate).getTime();
    const end = getStartOfDay(endDate).getTime();
    return checkDate >= start && checkDate <= end;
}
