import { FastifyInstance } from 'fastify';
import { AppError, DatabaseError } from '../types';

/**
 * Configura el manejo centralizado de errores
 */
export const setupErrorHandler = (fastify: FastifyInstance) => {
  fastify.setErrorHandler((error: Error | AppError | DatabaseError, request, reply) => {
    // Log del error
    fastify.log.error(error);

    // Errores de aplicación personalizados
    if (error instanceof AppError) {
      return reply.code(error.statusCode).send({
        success: false,
        error: error.message,
        code: error.code,
      });
    }

    // Errores de validación de Fastify
    if ('validation' in error && error.validation) {
      return reply.code(400).send({
        success: false,
        error: 'Datos de entrada inválidos',
        code: 'VALIDATION_ERROR',
        details: error.validation,
      });
    }

    // Errores de Prisma
    if (error instanceof Error && 'code' in error && typeof (error as any).code === 'string') {
      const prismaError = error as DatabaseError;

      // Solo PrismaClientKnownRequestError tiene la propiedad code
      if ('code' in prismaError) {
        // Foreign key constraint violations
        if (prismaError.code === 'P2003') {
          return reply.code(400).send({
            success: false,
            error: 'Datos de referencia inválidos',
            code: 'FOREIGN_KEY_ERROR',
          });
        }

        // Unique constraint violations
        if (prismaError.code === 'P2002') {
          return reply.code(409).send({
            success: false,
            error: 'El registro ya existe',
            code: 'UNIQUE_CONSTRAINT_ERROR',
          });
        }

        // Record not found
        if (prismaError.code === 'P2025') {
          return reply.code(404).send({
            success: false,
            error: 'Registro no encontrado',
            code: 'NOT_FOUND_ERROR',
          });
        }

        // Validation errors
        if (prismaError.code === 'P2000' || prismaError.code === 'P2001') {
          return reply.code(400).send({
            success: false,
            error: 'Datos inválidos',
            code: 'VALIDATION_ERROR',
          });
        }
      }
    }

    // Errores genéricos basados en mensaje (para compatibilidad)
    if (error.message) {
      let statusCode = 500;
      let code = 'INTERNAL_ERROR';

      if (error.message.includes('Credenciales inválidas') || error.message.includes('Usuario inactivo')) {
        statusCode = 401;
        code = 'AUTHENTICATION_ERROR';
      } else if (error.message.includes('Refresh token') || error.message.includes('Token inválido')) {
        statusCode = 401;
        code = 'AUTHENTICATION_ERROR';
      } else if (error.message.includes('Acceso denegado')) {
        statusCode = 403;
        code = 'AUTHORIZATION_ERROR';
      } else if (error.message.includes('no encontrado')) {
        statusCode = 404;
        code = 'NOT_FOUND_ERROR';
      }

      return reply.code(statusCode).send({
        success: false,
        error: error.message,
        code,
      });
    }

    // Error interno del servidor
    return reply.code(500).send({
      success: false,
      error: 'Error interno del servidor',
      code: 'INTERNAL_ERROR',
    });
  });

  // Manejo de rutas no encontradas
  fastify.setNotFoundHandler((request, reply) => {
    return reply.code(404).send({
      success: false,
      error: 'Ruta no encontrada',
      code: 'NOT_FOUND_ERROR',
    });
  });
};

export default setupErrorHandler;