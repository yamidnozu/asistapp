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
    console.log(`🔑 Iniciando autenticación - Header: ${authHeader ? 'presente' : 'ausente'}`);

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('❌ Header de autorización faltante o malformado');
      throw new AuthenticationError('Token de autenticación requerido');
    }

    const token = authHeader.substring(7); // Remover 'Bearer '
    console.log(`🔑 Token extraído: ${token.substring(0, 20)}...`);

    if (!token) {
      console.log('❌ Token vacío');
      throw new AuthenticationError('Token de autenticación requerido');
    }

    const decoded = await AuthService.verifyToken(token);
    request.user = decoded;
    console.log(`✅ Autenticación exitosa - Usuario: ${decoded.email}, Rol: ${decoded.rol}`);

  } catch (error) {
    console.log(`💥 Error en middleware de autenticación: ${(error as Error).message}`);
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
      console.log(`🔐 Verificando autorización - Usuario: ${request.user?.rol}, Roles permitidos: ${allowedRoles.join(', ')}`);

      if (!request.user) {
        console.log('❌ Usuario no autenticado en middleware de autorización');
        throw new AuthenticationError('Usuario no autenticado');
      }

      if (!allowedRoles.includes(request.user.rol)) {
        console.log(`❌ Acceso denegado: rol '${request.user.rol}' no está en ${allowedRoles.join(', ')}`);
        throw new AuthorizationError('Acceso denegado: rol insuficiente');
      }

      console.log(`✅ Autorización exitosa para rol '${request.user.rol}'`);
    } catch (error) {
      console.log(`💥 Error en middleware de autorización: ${(error as Error).message}`);
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