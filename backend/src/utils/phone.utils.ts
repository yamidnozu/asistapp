/**
 * Utilidades para normalización y validación de números de teléfono
 * para uso con WhatsApp Cloud API (formato E.164 sin el signo +)
 */

/**
 * Normaliza un número de teléfono al formato E.164 sin el signo +
 * Requerido por WhatsApp Cloud API de Meta
 * 
 * @param phone - Número de teléfono en cualquier formato
 * @param defaultCountryCode - Código de país por defecto (sin +), default: '57' (Colombia)
 * @returns Número normalizado (ej: '573001234567')
 * 
 * @example
 * normalizePhoneNumber('300 123 4567')      // '573001234567'
 * normalizePhoneNumber('+57 300-123-4567')  // '573001234567'
 * normalizePhoneNumber('573001234567')      // '573001234567'
 * normalizePhoneNumber('3001234567', '57')  // '573001234567'
 */
export function normalizePhoneNumber(phone: string, defaultCountryCode: string = '57'): string {
    if (!phone) {
        throw new Error('Phone number is required');
    }

    // Eliminar todos los caracteres no numéricos (espacios, guiones, paréntesis, +)
    let cleaned = phone.replace(/\D/g, '');

    // Si está vacío después de limpiar, error
    if (!cleaned) {
        throw new Error('Invalid phone number: no digits found');
    }

    // Casos según longitud y formato:
    
    // Caso 1: Número colombiano de 10 dígitos que empieza con 3 (celular)
    // Ejemplo: 3001234567 → 573001234567
    if (cleaned.length === 10 && cleaned.startsWith('3')) {
        cleaned = defaultCountryCode + cleaned;
    }
    
    // Caso 2: Número colombiano de 7 dígitos (fijo sin indicativo)
    // No se procesa para WhatsApp ya que necesita celular
    
    // Caso 3: Número ya tiene código de país (11+ dígitos)
    // Ejemplo: 573001234567 → 573001234567 (sin cambios)
    
    // Caso 4: Número con código de país incluido pero formato incorrecto
    // Se asume que ya está correcto si tiene 11+ dígitos
    
    // Validación básica: WhatsApp requiere mínimo 10 dígitos
    if (cleaned.length < 10) {
        throw new Error(`Invalid phone number: too short (${cleaned.length} digits)`);
    }

    // Validación máxima: números de teléfono no suelen tener más de 15 dígitos
    if (cleaned.length > 15) {
        throw new Error(`Invalid phone number: too long (${cleaned.length} digits)`);
    }

    return cleaned;
}

/**
 * Valida si un número de teléfono tiene un formato válido para WhatsApp
 * 
 * @param phone - Número de teléfono a validar
 * @returns true si el número es válido
 */
export function isValidPhoneNumber(phone: string): boolean {
    try {
        normalizePhoneNumber(phone);
        return true;
    } catch {
        return false;
    }
}

/**
 * Formatea un número de teléfono para mostrar en UI
 * 
 * @param phone - Número de teléfono normalizado
 * @returns Número formateado para display (ej: '+57 300 123 4567')
 */
export function formatPhoneForDisplay(phone: string): string {
    const cleaned = phone.replace(/\D/g, '');
    
    // Formato colombiano: +57 3XX XXX XXXX
    if (cleaned.length === 12 && cleaned.startsWith('57')) {
        return `+${cleaned.slice(0, 2)} ${cleaned.slice(2, 5)} ${cleaned.slice(5, 8)} ${cleaned.slice(8)}`;
    }
    
    // Formato genérico con código de país
    if (cleaned.length >= 11) {
        const countryCode = cleaned.slice(0, 2);
        const rest = cleaned.slice(2);
        return `+${countryCode} ${rest}`;
    }
    
    return phone;
}
