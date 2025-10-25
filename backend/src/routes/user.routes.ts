import { FastifyInstance } from 'fastify';
import UserController from '../controllers/user.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function userRoutes(fastify: FastifyInstance) {
  // Obtener todos los usuarios (solo admins)
  fastify.get('/', {
    preHandler: [authenticate, authorize(['super_admin', 'admin_institucion'])],
    handler: UserController.getAllUsers,
  });

  // Obtener usuario por ID
  fastify.get('/:id', {
    preHandler: authenticate,
    handler: UserController.getUserById,
  });

  // Obtener usuarios por rol
  fastify.get('/rol/:role', {
    preHandler: [authenticate, authorize(['super_admin', 'admin_institucion'])],
    handler: UserController.getUsersByRole,
  });

  // Obtener usuarios por institución
  fastify.get('/institucion/:institucionId', {
    preHandler: authenticate,
    handler: UserController.getUsersByInstitution,
  });

  // Endpoint para limpiar tokens expirados (solo super_admin)
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