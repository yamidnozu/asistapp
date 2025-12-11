import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import AuthService from '../services/auth.service';
import { AuthenticationError, AuthorizationError, JWTPayload, UserRole } from '../types';

export interface AuthenticatedRequest extends FastifyRequest {
  user?: JWTPayload;
}

/**
 * Middleware de autenticación
 * Verifica que el token JWT sea válido
 */
export const authenticate = async (request: AuthenticatedRequest, reply: FastifyReply) => {
  request.log.info(`<<<< AUTHENTICATE: Iniciando autenticación para ruta: ${request.raw.url}`);
  try {
    const authHeader = request.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      request.log.warn(`<<<< AUTHENTICATE: Fallo - No hay header 'Bearer '`);
      throw new AuthenticationError('Token no proporcionado');
    }

    const token = authHeader.substring(7);
    const decoded = await AuthService.verifyToken(token);
    request.log.info({ user: decoded }, `<<<< AUTHENTICATE: Token decodificado exitosamente.`);

    // Verificar si el usuario sigue activo en la DB
    const userStatus = await prisma.usuario.findUnique({
      where: { id: decoded.id },
      select: { activo: true }
    });

    if (!userStatus || !userStatus.activo) {
      request.log.warn({ userId: decoded.id }, `<<<< AUTHENTICATE: Fallo - Usuario inactivo en DB.`);
      throw new AuthenticationError('Su usuario ha sido desactivado. Contacte al administrador.');
    }

    // Si es Admin de Institución, verificar que su institución siga activa
    if (decoded.rol === 'admin_institucion') {
      const institucionActiva = await prisma.usuarioInstitucion.findFirst({
        where: { 
          usuarioId: decoded.id, 
          activo: true,
          institucion: { activa: true } // La institución debe estar activa
        }
      });
      
      if (!institucionActiva) {
        request.log.warn({ userId: decoded.id }, `<<<< AUTHENTICATE: Fallo - Institución inactiva o sin acceso para admin.`);
        throw new AuthenticationError('Su institución ha sido inhabilitada o su acceso revocado.');
      }
    }

    request.log.info({ userId: decoded.id }, `<<<< AUTHENTICATE: Autenticación completada exitosamente.`);
    request.user = decoded;
  } catch (error) {
    request.log.error(error, `<<<< AUTHENTICATE: Excepción atrapada en middleware de autenticación.`);
    if (error instanceof AuthenticationError) {
      return reply.code(401).send({
        success: false,
        error: error.message,
        code: 'UNAUTHORIZED',
      });
    }
    return reply.code(401).send({
      success: false,
      error: 'Token inválido o expirado',
      code: 'UNAUTHORIZED',
    });
  }
};

/**
 * Middleware de autorización
 * Verifica que el usuario tenga uno de los roles permitidos
 */
export const authorize = (allowedRoles: UserRole[]) => {
  return async (request: AuthenticatedRequest, reply: FastifyReply) => {
    request.log.info({ user: request.user, allowedRoles }, `<<<< AUTHORIZE: Verificando autorización para ruta: ${request.raw.url}`);
    try {
      if (!request.user) {
        request.log.warn('<<<< AUTHORIZE: Fallo - No hay objeto user en la petición (debe correr después de authenticate).');
        throw new AuthenticationError('Usuario no autenticado');
      }

      if (!allowedRoles.includes(request.user.rol)) {
        request.log.warn(`<<<< AUTHORIZE: Acceso denegado. Rol del usuario '${request.user.rol}' no está en la lista de permitidos: [${allowedRoles.join(', ')}]`);
        throw new AuthorizationError('Acceso denegado: rol insuficiente');
      }

      request.log.info(`<<<< AUTHORIZE: Autorización exitosa para rol '${request.user.rol}'`);
    } catch (error) {
      request.log.error(error, `<<<< AUTHORIZE: Excepción atrapada en middleware de autorización.`);
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

        // Verificar si el usuario sigue activo en la DB
        const userStatus = await prisma.usuario.findUnique({
          where: { id: decoded.id },
          select: { activo: true }
        });

        if (userStatus && userStatus.activo) {
          // Si es Admin de Institución, verificar que su institución siga activa
          if (decoded.rol === 'admin_institucion') {
            const institucionActiva = await prisma.usuarioInstitucion.findFirst({
              where: { 
                usuarioId: decoded.id, 
                activo: true,
                institucion: { activa: true }
              }
            });
            
            if (institucionActiva) {
              request.user = decoded;
            }
          } else {
            request.user = decoded;
          }
        }
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
