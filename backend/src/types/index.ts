// import type { Institucion, Usuario } from '@prisma/client';
import { PrismaClientKnownRequestError, PrismaClientValidationError } from '@prisma/client/runtime/library';
import { FastifyRequest } from 'fastify';

// Tipos temporales hasta que Prisma se genere correctamente
export type Institucion = any;
export type Usuario = any;

import { UserRole } from '../constants/roles';
export { UserRole };

import { AttendanceStatus, AttendanceType } from '../constants/attendance';
export { AttendanceStatus, AttendanceType };

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
  // Campos para profesores (opcionales)
  titulo?: string | null;
  especialidad?: string | null;
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

export interface ApiResponse<T = unknown> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
  meta?: any; // Datos adicionales relacionados con la respuesta
}

export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly reason?: string;
  public readonly meta?: any;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number = 500, code: string = 'INTERNAL_ERROR', reason?: string, meta?: any) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.reason = reason;
    this.meta = meta;
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
  constructor(message: string, reason?: string, meta?: any) {
    super(message, 409, 'CONFLICT_ERROR', reason, meta);
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

/**
 * Extiende FastifyRequest para incluir la información del usuario autenticado
 * que es añadida por el middleware de autenticación
 */
export interface AuthenticatedRequest extends FastifyRequest {
  user: JWTPayload;
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
  direccion?: string;
  telefono?: string;
  email?: string;
}

export interface UpdateInstitucionRequest {
  nombre?: string;
  direccion?: string;
  telefono?: string;
  email?: string;
  activa?: boolean;
}

export interface InstitucionResponse {
  id: string;
  nombre: string;
  direccion?: string | null;
  telefono?: string | null;
  email?: string | null;
  activa: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CreateUserRequest {
  email: string;
  password: string;
  nombres: string;
  apellidos: string;
  rol: UserRole;
  telefono?: string;
  identificacion?: string; // Documento de identidad (todos los usuarios)
  institucionId?: string; // Para asignar institución inicial
  rolEnInstitucion?: string; // Rol específico en la institución
  // Campos específicos para profesores
  titulo?: string;
  especialidad?: string;
  // Campos específicos para estudiantes
  nombreResponsable?: string; // Solo para estudiantes
  telefonoResponsable?: string; // Solo para estudiantes
}

export interface UpdateUserRequest {
  email?: string;
  nombres?: string;
  apellidos?: string;
  telefono?: string;
  activo?: boolean;
  // Para estudiantes
  identificacion?: string;
  nombreResponsable?: string;
  telefonoResponsable?: string;
  // Para profesores
  titulo?: string;
  especialidad?: string;
}

export interface CreateUserResponse extends UserResponse {
  estudiante?: {
    id: string;
    identificacion: string;
    codigoQr: string;
    nombreResponsable?: string | null;
    telefonoResponsable?: string | null;
  };
}

// Paginación
export interface PaginationParams {
  page?: number;
  limit?: number;
}

export interface PaginatedResponse<T> {
  data: T[];
  pagination: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
}

export interface UserFilters {
  activo?: boolean;
  rol?: UserRole;
  institucionId?: string;
  search?: string;
}