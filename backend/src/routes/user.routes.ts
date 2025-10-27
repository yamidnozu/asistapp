import { FastifyInstance } from 'fastify';
import UserController from '../controllers/user.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function userRoutes(fastify: FastifyInstance) {
  fastify.get('/', {
    preHandler: [authenticate, authorize(['super_admin', 'admin_institucion'])],
    handler: UserController.getAllUsers,
  });
  fastify.get('/:id', {
    preHandler: authenticate,
    handler: UserController.getUserById,
  });
  fastify.get('/rol/:role', {
    preHandler: [authenticate, authorize(['super_admin', 'admin_institucion'])],
    handler: UserController.getUsersByRole,
  });
  fastify.get('/institucion/:institucionId', {
    preHandler: authenticate,
    handler: UserController.getUsersByInstitution,
  });
  fastify.post('/admin/cleanup-tokens', {
    preHandler: [authenticate, authorize(['super_admin'])],
    handler: async (request, reply) => {
      try {
        const cleanupTokens = (await import('../scripts/cleanup-tokens')).default;
        await cleanupTokens();
        return reply.code(200).send({
          success: true,
          data: {
            message: 'Limpieza de tokens completada',
          }
        });
      } catch (error) {
        throw error;
      }
    },
  });
}