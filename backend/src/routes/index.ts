import { FastifyInstance } from 'fastify';
import authRoutes from './auth.routes';
import userRoutes from './user.routes';

export default async function routes(fastify: FastifyInstance) {
  // Ruta de prueba (pública)
  fastify.get('/', async (request, reply) => {
    return {
      success: true,
      message: 'Hola Mundo desde AsistApp Backend v2.0!',
      timestamp: new Date().toISOString(),
    };
  });

  // Ruta de prueba para verificar estructura de respuesta
  fastify.get('/test', async (request, reply) => {
    return reply.code(200).send({
      success: true,
      data: {
        accessToken: 'test_token',
        refreshToken: 'test_refresh_token',
        expiresIn: 86400,
        usuario: {
          id: 'test_id',
          nombres: 'Test',
          apellidos: 'User',
          rol: 'estudiante',
          institucionId: null,
          institucion: null
        }
      }
    });
  });

  // Registrar rutas de módulos
  await fastify.register(authRoutes, { prefix: '/auth' });
  await fastify.register(userRoutes, { prefix: '/usuarios' });
}