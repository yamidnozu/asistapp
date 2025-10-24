import { Institucion, Usuario } from '@prisma/client';

// Tipos de roles
export type UserRole = 'super_admin' | 'admin_institucion' | 'profesor' | 'estudiante';

// Tipos de request/response para autenticación
export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  usuario: {
    id: string;
    nombres: string;
    apellidos: string;
    rol: UserRole;
    institucionId: string | null;
    institucion?: {
      id: string;
      nombre: string;
    } | null;
  };
  expiresIn: number; // segundos
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

export interface RefreshTokenResponse {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

export interface LogoutRequest {
  refreshToken?: string;
}

// Tipos extendidos de usuario
export interface UsuarioExtendido extends Usuario {
  institucion?: Institucion | null;
}

// Tipos para respuestas de API
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// Tipos para errores
export interface ApiError {
  code: string;
  message: string;
  statusCode: number;
}

// Tipos para JWT payload
export interface JWTPayload {
  id: string;
  rol: UserRole;
  institucionId: string | null;
  email: string;
  tokenVersion: number;
  jti?: string; // JWT ID único
  iat?: number;
  exp?: number;
}

// Tipos para configuración
export interface AppConfig {
  port: number;
  host: string;
  jwtSecret: string;
  jwtExpiresIn: string;
  nodeEnv: string;
  logLevel: string;
}