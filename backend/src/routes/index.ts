import { FastifyInstance } from 'fastify';
import adminInstitucionRoutes from './admin-institucion.routes';
import authRoutes from './auth.routes';
import institucionRoutes from './institucion.routes';
import institutionAdminRoutes from './institution-admin.routes';
import userRoutes from './user.routes';

export default async function routes(fastify: FastifyInstance) {

  fastify.get('/', async (request, reply) => {
    return {
      success: true,
      message: 'Hola Mundo desde AsistApp Backend v2.0!',
      timestamp: new Date().toISOString(),
    };
  });

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

  await fastify.register(authRoutes, { prefix: '/auth' });
  await fastify.register(userRoutes, { prefix: '/usuarios' });
  await fastify.register(adminInstitucionRoutes, { prefix: '/admin-institucion' });
  await fastify.register(institutionAdminRoutes, { prefix: '/institution-admin' });
  await fastify.register(institucionRoutes, { prefix: '/instituciones' });
}