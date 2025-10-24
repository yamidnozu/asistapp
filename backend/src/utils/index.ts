import { ApiResponse } from '../types';

/**
 * Utilidades para respuestas HTTP estandarizadas
 */
export class ResponseUtil {
  /**
   * Respuesta de éxito
   */
  public static success<T>(data: T, message?: string): ApiResponse<T> {
    return {
      success: true,
      data,
      message,
    };
  }

  /**
   * Respuesta de error
   */
  public static error(message: string, code?: string): ApiResponse {
    return {
      success: false,
      error: message,
      message: code,
    };
  }

  /**
   * Respuesta de éxito con paginación
   */
  public static paginated<T>(
    data: T[],
    total: number,
    page: number,
    limit: number,
    message?: string
  ): ApiResponse<{
    items: T[];
    pagination: {
      total: number;
      page: number;
      limit: number;
      totalPages: number;
    };
  }> {
    return {
      success: true,
      data: {
        items: data,
        pagination: {
          total,
          page,
          limit,
          totalPages: Math.ceil(total / limit),
        },
      },
      message,
    };
  }
}

/**
 * Utilidades de validación
 */
export class ValidationUtil {
  /**
   * Valida formato de email
   */
  public static isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Valida que una cadena no esté vacía
   */
  public static isNotEmpty(value: string | undefined | null): boolean {
    return Boolean(value && value.trim().length > 0);
  }

  /**
   * Valida longitud mínima de cadena
   */
  public static hasMinLength(value: string | undefined | null, minLength: number): boolean {
    return Boolean(value && value.length >= minLength);
  }
}

/**
 * Utilidades de formato
 */
export class FormatUtil {
  /**
   * Capitaliza primera letra
   */
  public static capitalize(str: string): string {
    return str.charAt(0).toUpperCase() + str.slice(1).toLowerCase();
  }

  /**
   * Convierte snake_case a camelCase
   */
  public static snakeToCamel(str: string): string {
    return str.replace(/_([a-z])/g, (_, letter) => letter.toUpperCase());
  }

  /**
   * Convierte camelCase a snake_case
   */
  public static camelToSnake(str: string): string {
    return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
  }
}

export default {
  ResponseUtil,
  ValidationUtil,
  FormatUtil,
};