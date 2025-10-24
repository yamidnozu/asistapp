import { FastifyReply, FastifyRequest } from 'fastify';
import AuthService from '../services/auth.service';
import { JWTPayload } from '../types';

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
      return reply.code(401).send({ error: 'Token de autenticación requerido' });
    }

    const token = authHeader.substring(7); // Remover 'Bearer '

    if (!token) {
      return reply.code(401).send({ error: 'Token de autenticación requerido' });
    }

    // Verificar token
    const decoded = await AuthService.verifyToken(token);
    request.user = decoded;

  } catch (error) {
    return reply.code(401).send({ error: 'Token inválido o expirado' });
  }
};

/**
 * Middleware para verificar roles específicos
 */
export const authorize = (allowedRoles: string[]) => {
  return async (request: AuthenticatedRequest, reply: FastifyReply) => {
    if (!request.user) {
      return reply.code(401).send({ error: 'Usuario no autenticado' });
    }

    if (!allowedRoles.includes(request.user.rol)) {
      return reply.code(403).send({ error: 'Acceso denegado: rol insuficiente' });
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
    // Silenciar errores en autenticación opcional
    console.warn('Error en autenticación opcional:', error);
  }
};

export default {
  authenticate,
  authorize,
  optionalAuthenticate,
};