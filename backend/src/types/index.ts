import { Institucion, Usuario } from '@prisma/client';
import { PrismaClientKnownRequestError, PrismaClientValidationError } from '@prisma/client/runtime/library';

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
    instituciones: {
      id: string;
      nombre: string;
      rolEnInstitucion?: string | null;
    }[];
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

export interface VerifyTokenResponse {
  usuario: JWTPayload;
  valid: boolean;
}

// Tipos de request/response para usuarios
export interface GetUserByIdRequest {
  id: string;
}

export interface GetUsersByRoleRequest {
  role: UserRole;
}

export interface GetUsersByInstitutionRequest {
  institucionId: string;
}

export interface UserResponse {
  id: string;
  email: string;
  nombres: string;
  apellidos: string;
  rol: UserRole;
  telefono?: string | null;
  activo: boolean;
  instituciones: {
    id: string;
    nombre: string;
    rolEnInstitucion?: string | null;
    activo: boolean;
  }[];
}

// Tipos extendidos de usuario
export interface UsuarioExtendido extends Omit<Usuario, 'institucionId'> {
  usuarioInstituciones?: {
    institucion: Institucion;
    rolEnInstitucion?: string | null;
    activo: boolean;
  }[];
}

// Tipo para usuario con instituciones incluidas
export interface UsuarioConInstituciones extends Usuario {
  usuarioInstituciones: {
    institucion: Institucion;
    rolEnInstitucion?: string | null;
    activo: boolean;
  }[];
}

// Tipos para respuestas de API
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}

// Tipos para errores específicos
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number = 500, code: string = 'INTERNAL_ERROR') {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends AppError {
  constructor(message: string) {
    super(message, 400, 'VALIDATION_ERROR');
  }
}

export class AuthenticationError extends AppError {
  constructor(message: string = 'No autorizado') {
    super(message, 401, 'AUTHENTICATION_ERROR');
  }
}

export class AuthorizationError extends AppError {
  constructor(message: string = 'Acceso denegado') {
    super(message, 403, 'AUTHORIZATION_ERROR');
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string = 'Recurso') {
    super(`${resource} no encontrado`, 404, 'NOT_FOUND_ERROR');
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(message, 409, 'CONFLICT_ERROR');
  }
}

// Tipos para errores de Prisma
export type DatabaseError = PrismaClientKnownRequestError | PrismaClientValidationError;

// Tipos para JWT payload
export interface JWTPayload {
  id: string;
  rol: UserRole;
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