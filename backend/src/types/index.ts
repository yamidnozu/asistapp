import { Institucion, Usuario } from '@prisma/client';
import { PrismaClientKnownRequestError, PrismaClientValidationError } from '@prisma/client/runtime/library';
export type UserRole = 'super_admin' | 'admin_institucion' | 'profesor' | 'estudiante';
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
export interface UsuarioExtendido extends Omit<Usuario, 'institucionId'> {
  usuarioInstituciones?: {
    institucion: Institucion;
    rolEnInstitucion?: string | null;
    activo: boolean;
  }[];
}
export interface UsuarioConInstituciones extends Usuario {
  usuarioInstituciones: {
    institucion: Institucion;
    rolEnInstitucion?: string | null;
    activo: boolean;
  }[];
}
export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}
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
export type DatabaseError = PrismaClientKnownRequestError | PrismaClientValidationError;
export interface JWTPayload {
  id: string;
  rol: UserRole;
  email: string;
  tokenVersion: number;
  jti?: string; // JWT ID único
  iat?: number;
  exp?: number;
}
export interface AppConfig {
  port: number;
  host: string;
  jwtSecret: string;
  jwtExpiresIn: string;
  nodeEnv: string;
  logLevel: string;
}
export interface CreateInstitucionRequest {
  nombre: string;
  codigo: string;
  direccion?: string;
  telefono?: string;
  email?: string;
}

export interface UpdateInstitucionRequest {
  nombre?: string;
  codigo?: string;
  direccion?: string;
  telefono?: string;
  email?: string;
  activa?: boolean;
}

export interface InstitucionResponse {
  id: string;
  nombre: string;
  codigo: string;
  direccion?: string | null;
  telefono?: string | null;
  email?: string | null;
  activa: boolean;
  createdAt: string;
  updatedAt: string;
}