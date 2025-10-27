import { FastifyReply, FastifyRequest } from 'fastify';
import AuthService from '../services/auth.service';
import { AuthenticationError, AuthorizationError, JWTPayload, UserRole } from '../types';

export interface AuthenticatedRequest extends FastifyRequest {
  user?: JWTPayload;
}

/**
 * Middleware de autenticación JWT
 */
export const authenticate = async (request: AuthenticatedRequest, reply: FastifyReply) => {
  try {
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new AuthenticationError('Token de autenticación requerido');
    }

    const token = authHeader.substring(7); // Remover 'Bearer '

    if (!token) {
      throw new AuthenticationError('Token de autenticación requerido');
    }
    const decoded = await AuthService.verifyToken(token);
    request.user = decoded;

  } catch (error) {
    if (error instanceof AuthenticationError) {
      return reply.code(error.statusCode).send({
        success: false,
        error: error.message,
        code: error.code,
      });
    }
    if (error instanceof Error && (error.message.includes('inválido') || error.message.includes('expirado'))) {
      return reply.code(401).send({
        success: false,
        error: 'Token de autenticación inválido',
        code: 'AUTHENTICATION_ERROR',
      });
    }
    throw error;
  }
};

/**
 * Middleware para verificar roles específicos
 */
export const authorize = (allowedRoles: UserRole[]) => {
  return async (request: AuthenticatedRequest, reply: FastifyReply) => {
    try {
      if (!request.user) {
        throw new AuthenticationError('Usuario no autenticado');
      }

      if (!allowedRoles.includes(request.user.rol)) {
        throw new AuthorizationError('Acceso denegado: rol insuficiente');
      }
    } catch (error) {
      if (error instanceof AuthenticationError || error instanceof AuthorizationError) {
        return reply.code(error.statusCode).send({
          success: false,
          error: error.message,
          code: error.code,
        });
      }
      throw error;
    }
  };
};

/**
 * Middleware opcional de autenticación (no falla si no hay token)
 */
export const optionalAuthenticate = async (request: AuthenticatedRequest, reply: FastifyReply) => {
  try {
    const authHeader = request.headers.authorization;

    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      if (token) {
        const decoded = await AuthService.verifyToken(token);
        request.user = decoded;
      }
    }
  } catch (error) {
    console.warn('Error en autenticación opcional:', error);
  }
};

export default {
  authenticate,
  authorize,
  optionalAuthenticate,
};