import { FastifyInstance } from 'fastify';

/**
 * Configura el manejo centralizado de errores
 */
export const setupErrorHandler = (fastify: FastifyInstance) => {
  fastify.setErrorHandler((error, request, reply) => {
    // Log del error
    fastify.log.error(error);

    // Errores de validación
    if (error.validation) {
      return reply.code(400).send({
        success: false,
        error: 'Datos de entrada inválidos',
        details: error.validation,
      });
    }

    // Errores personalizados
    if (error.message) {
      // Determinar código de estado basado en el mensaje
      let statusCode = 500;
      if (error.message.includes('Credenciales inválidas') || error.message.includes('Usuario inactivo')) {
        statusCode = 401;
      } else if (error.message.includes('Refresh token') || error.message.includes('Token inválido')) {
        statusCode = 401;
      } else if (error.message.includes('Acceso denegado')) {
        statusCode = 403;
      } else if (error.message.includes('no encontrado')) {
        statusCode = 404;
      }

      return reply.code(statusCode).send({
        success: false,
        error: error.message,
      });
    }

    // Error interno del servidor
    return reply.code(500).send({
      success: false,
      error: 'Error interno del servidor',
    });
  });

  // Manejo de rutas no encontradas
  fastify.setNotFoundHandler((request, reply) => {
    return reply.code(404).send({
      success: false,
      error: 'Ruta no encontrada',
    });
  });
};

export default setupErrorHandler;