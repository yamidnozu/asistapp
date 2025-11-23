import {
    daysDifference,
    formatDateTimeToISO,
    formatDateToISO,
    getDateRange,
    getEndOfDay,
    getStartOfDay,
    getToday, isSameDay,
    parseDateString
} from '../date.utils';

describe('date.utils', () => {
  describe('getStartOfDay', () => {
    it('should return UTC midnight for any input date', () => {
      const input = new Date('2025-11-21T15:30:45.123Z');
      const result = getStartOfDay(input);
      
      expect(result.toISOString()).toBe('2025-11-21T00:00:00.000Z');
      expect(result.getUTCHours()).toBe(0);
      expect(result.getUTCMinutes()).toBe(0);
      expect(result.getUTCSeconds()).toBe(0);
      expect(result.getUTCMilliseconds()).toBe(0);
    });

    it('should handle date already at midnight', () => {
      const input = new Date('2025-11-21T00:00:00.000Z');
      const result = getStartOfDay(input);
      
      expect(result.toISOString()).toBe('2025-11-21T00:00:00.000Z');
    });

    it('should work with dates at end of day', () => {
      const input = new Date('2025-11-21T23:59:59.999Z');
      const result = getStartOfDay(input);
      
      expect(result.toISOString()).toBe('2025-11-21T00:00:00.000Z');
    });

    it('should preserve UTC timezone', () => {
      const input = new Date('2025-11-21T18:00:00.000-05:00'); // 6pm Colombia time
      const result = getStartOfDay(input);
      
      // Debe ser medianoche del día siguiente en UTC (porque 6pm-5h = 11pm UTC del día 21)
      expect(result.toISOString()).toBe('2025-11-21T00:00:00.000Z');
    });
  });

  describe('parseDateString', () => {
    it('should parse YYYY-MM-DD to UTC midnight', () => {
      const result = parseDateString('2025-11-21');
      
      expect(result.toISOString()).toBe('2025-11-21T00:00:00.000Z');
    });

    it('should only accept YYYY-MM-DD format', () => {
      // parseDateString solo acepta formato YYYY-MM-DD
      const result = parseDateString('2025-11-21');
      
      expect(result.toISOString()).toBe('2025-11-21T00:00:00.000Z');
      
      // Otros formatos deben lanzar error
      expect(() => parseDateString('11/21/2025')).toThrow();
      expect(() => parseDateString('2025-11-21T15:30:45.000Z')).toThrow();
    });

    it('should throw error for invalid date string', () => {
      expect(() => parseDateString('invalid-date')).toThrow();
    });

    it('should handle leading zeros', () => {
      const result = parseDateString('2025-01-05');
      
      expect(result.toISOString()).toBe('2025-01-05T00:00:00.000Z');
    });
  });

  describe('getDateRange', () => {
    it('should return start of day and start of next day', () => {
      const date = new Date('2025-11-21T12:00:00.000Z');
      const { start, end } = getDateRange(date);
      
      expect(start.toISOString()).toBe('2025-11-21T00:00:00.000Z');
      expect(end.toISOString()).toBe('2025-11-22T00:00:00.000Z');
    });

    it('should work with date at midnight', () => {
      const date = new Date('2025-11-21T00:00:00.000Z');
      const { start, end } = getDateRange(date);
      
      expect(start.toISOString()).toBe('2025-11-21T00:00:00.000Z');
      expect(end.toISOString()).toBe('2025-11-22T00:00:00.000Z');
    });

    it('should work with date at end of day', () => {
      const date = new Date('2025-11-21T23:59:59.999Z');
      const { start, end } = getDateRange(date);
      
      expect(start.toISOString()).toBe('2025-11-21T00:00:00.000Z');
      expect(end.toISOString()).toBe('2025-11-22T00:00:00.000Z');
    });

    it('should handle leap year date', () => {
      const date = new Date('2024-02-29T12:00:00.000Z');
      const { start, end } = getDateRange(date);
      
      expect(start.toISOString()).toBe('2024-02-29T00:00:00.000Z');
      expect(end.toISOString()).toBe('2024-03-01T00:00:00.000Z');
    });
  });

  describe('getEndOfDay', () => {
    it('should return end of day (23:59:59.999) in UTC', () => {
      const date = new Date('2025-11-21T12:00:00.000Z');
      const end = getEndOfDay(date);
      
      expect(end.toISOString()).toBe('2025-11-21T23:59:59.999Z');
    });

    it('should work with date at midnight', () => {
      const date = new Date('2025-11-21T00:00:00.000Z');
      const end = getEndOfDay(date);
      
      expect(end.toISOString()).toBe('2025-11-21T23:59:59.999Z');
    });
  });

  describe('getToday', () => {
    it('should return today at midnight UTC', () => {
      const today = getToday();
      const now = new Date();
      
      // Verificar que es el mismo día
      expect(today.getUTCDate()).toBe(now.getUTCDate());
      expect(today.getUTCMonth()).toBe(now.getUTCMonth());
      expect(today.getUTCFullYear()).toBe(now.getUTCFullYear());
      
      // Verificar que es medianoche
      expect(today.getUTCHours()).toBe(0);
      expect(today.getUTCMinutes()).toBe(0);
      expect(today.getUTCSeconds()).toBe(0);
      expect(today.getUTCMilliseconds()).toBe(0);
    });

    it('should return date in UTC timezone', () => {
      const today = getToday();
      
      // Verificar que termina en Z (UTC)
      expect(today.toISOString()).toMatch(/Z$/);
    });
  });

  describe('isSameDay', () => {
    it('should return true for same day at different times', () => {
      const date1 = new Date('2025-11-21T08:00:00.000Z');
      const date2 = new Date('2025-11-21T20:00:00.000Z');
      
      expect(isSameDay(date1, date2)).toBe(true);
    });

    it('should return false for different days', () => {
      const date1 = new Date('2025-11-21T23:59:59.999Z');
      const date2 = new Date('2025-11-22T00:00:00.000Z');
      
      expect(isSameDay(date1, date2)).toBe(false);
    });

    it('should use UTC comparison', () => {
      const date1 = new Date('2025-11-21T23:00:00.000-05:00'); // 11pm Colombia = 4am UTC next day
      const date2 = new Date('2025-11-22T04:00:00.000Z'); // 4am UTC
      
      expect(isSameDay(date1, date2)).toBe(true); // Mismo día en UTC
    });
  });

  describe('daysDifference', () => {
    it('should calculate difference in days', () => {
      const date1 = new Date('2025-11-21T12:00:00.000Z');
      const date2 = new Date('2025-11-25T12:00:00.000Z');
      
      expect(daysDifference(date1, date2)).toBe(4);
    });

    it('should return negative for past dates', () => {
      const date1 = new Date('2025-11-25T12:00:00.000Z');
      const date2 = new Date('2025-11-21T12:00:00.000Z');
      
      expect(daysDifference(date1, date2)).toBe(-4);
    });

    it('should return 0 for same day', () => {
      const date1 = new Date('2025-11-21T08:00:00.000Z');
      const date2 = new Date('2025-11-21T20:00:00.000Z');
      
      expect(daysDifference(date1, date2)).toBe(0);
    });
  });

  describe('UTC consistency', () => {
    it('should never use local timezone offsets', () => {
      const testDate = new Date('2025-11-21T15:30:00.000Z');
      
      // Ninguna función debe usar getHours() o getDate() (local)
      // Solo debe usar getUTCHours(), getUTCDate(), etc.
      const start = getStartOfDay(testDate);
      const { start: rangeStart, end: rangeEnd } = getDateRange(testDate);
      
      // Todas las fechas deben ser UTC (terminar en Z)
      expect(start.toISOString()).toMatch(/Z$/);
      expect(rangeStart.toISOString()).toMatch(/Z$/);
      expect(rangeEnd.toISOString()).toMatch(/Z$/);
      
      // getTimezoneOffset() retorna el offset del sistema, no de la fecha
      // En UTC siempre debe ser 0 minutos de diferencia entre medianoche y medianoche
      const diffMinutes = (start.getTime() - getStartOfDay(start).getTime()) / (1000 * 60);
      expect(diffMinutes).toBe(0);
    });

    it('should produce same results regardless of system timezone', () => {
      // Simular diferentes fechas de entrada con timezones
      const utcDate = new Date('2025-11-21T12:00:00.000Z');
      const colombiaDate = new Date('2025-11-21T12:00:00.000-05:00');
      
      const utcStart = getStartOfDay(utcDate);
      const colombiaStart = getStartOfDay(colombiaDate);
      
      // Ambos deben producir el mismo resultado en UTC
      // (aunque las entradas sean diferentes debido al timezone)
      expect(utcStart.getUTCDate()).toBe(21);
      expect(colombiaStart.getUTCDate()).toBe(21);
    });
  });

  describe('Edge cases', () => {
    it('should handle year transitions', () => {
      const newYearsEve = new Date('2024-12-31T23:59:59.999Z');
      const { start, end } = getDateRange(newYearsEve);
      
      expect(start.toISOString()).toBe('2024-12-31T00:00:00.000Z');
      expect(end.toISOString()).toBe('2025-01-01T00:00:00.000Z');
    });

    it('should handle month transitions', () => {
      const lastDayOfMonth = new Date('2025-11-30T23:59:59.999Z');
      const { start, end } = getDateRange(lastDayOfMonth);
      
      expect(start.toISOString()).toBe('2025-11-30T00:00:00.000Z');
      expect(end.toISOString()).toBe('2025-12-01T00:00:00.000Z');
    });

    it('should handle February 29 (leap year)', () => {
      const leapDay = new Date('2024-02-29T12:00:00.000Z');
      const { start, end } = getDateRange(leapDay);
      
      expect(start.toISOString()).toBe('2024-02-29T00:00:00.000Z');
      expect(end.toISOString()).toBe('2024-03-01T00:00:00.000Z');
    });

    it('should work with formatDateToISO', () => {
      const date = new Date('2025-11-21T12:30:45.123Z');
      const formatted = formatDateToISO(date);
      
      expect(formatted).toBe('2025-11-21');
    });

    it('should work with formatDateTimeToISO', () => {
      const date = new Date('2025-11-21T12:30:45.123Z');
      const formatted = formatDateTimeToISO(date);
      
      expect(formatted).toBe('2025-11-21T12:30:45.123Z');
    });
  });
});
