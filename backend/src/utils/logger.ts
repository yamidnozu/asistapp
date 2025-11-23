/**
 * Sistema de logging centralizado para AsistApp Backend
 * 
 * Características:
 * - Respeta NODE_ENV para evitar logs sensibles en producción
 * - Oculta automáticamente datos sensibles (tokens, passwords, etc.)
 * - Niveles de log configurables
 * - Salida formateada con timestamps y colores
 */

import { config } from '../config/app';

export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
  NONE = 4,
}

class Logger {
  private level: LogLevel;
  private sensitiveFields = [
    'password',
    'passwordHash',
    'token',
    'accessToken',
    'refreshToken',
    'authorization',
    'cookie',
    'secret',
  ];

  constructor() {
    // En producción, solo mostrar WARN y ERROR
    // En desarrollo, mostrar todo
    this.level = config.nodeEnv === 'production' ? LogLevel.WARN : LogLevel.DEBUG;
  }

  /**
   * Sanitiza objetos para ocultar datos sensibles
   */
  private sanitize(data: any): any {
    if (typeof data !== 'object' || data === null) {
      return data;
    }

    if (Array.isArray(data)) {
      return data.map((item) => this.sanitize(item));
    }

    const sanitized: any = {};
    for (const key in data) {
      const lowerKey = key.toLowerCase();
      const isSensitive = this.sensitiveFields.some((field) => lowerKey.includes(field));

      if (isSensitive) {
        sanitized[key] = '***REDACTED***';
      } else if (typeof data[key] === 'object') {
        sanitized[key] = this.sanitize(data[key]);
      } else {
        sanitized[key] = data[key];
      }
    }
    return sanitized;
  }

  /**
   * Formatea el mensaje de log
   */
  private format(level: string, message: string, data?: any): string {
    const timestamp = new Date().toISOString();
    const dataStr = data ? ` | ${JSON.stringify(this.sanitize(data))}` : '';
    return `[${timestamp}] [${level}] ${message}${dataStr}`;
  }

  /**
   * Log nivel DEBUG - Solo en desarrollo
   */
  public debug(message: string, data?: any): void {
    if (this.level <= LogLevel.DEBUG) {
      console.log(this.format('DEBUG', message, data));
    }
  }

  /**
   * Log nivel INFO
   */
  public info(message: string, data?: any): void {
    if (this.level <= LogLevel.INFO) {
      console.log(this.format('INFO', message, data));
    }
  }

  /**
   * Log nivel WARN
   */
  public warn(message: string, data?: any): void {
    if (this.level <= LogLevel.WARN) {
      console.warn(this.format('WARN', message, data));
    }
  }

  /**
   * Log nivel ERROR
   */
  public error(message: string, error?: Error | any, data?: any): void {
    if (this.level <= LogLevel.ERROR) {
      const errorData = error instanceof Error 
        ? { message: error.message, stack: error.stack, ...data }
        : { error, ...data };
      console.error(this.format('ERROR', message, errorData));
    }
  }

  /**
   * Cambia el nivel de log dinámicamente
   */
  public setLevel(level: LogLevel): void {
    this.level = level;
  }

  /**
   * Logs condicionales para debugging
   */
  public debugIf(condition: boolean, message: string, data?: any): void {
    if (condition) {
      this.debug(message, data);
    }
  }
}

// Exportar instancia singleton
export const logger = new Logger();

export default logger;
