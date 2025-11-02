import { FastifyInstance } from 'fastify';
import InstitucionController from '../controllers/institucion.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function institucionRoutes(fastify: FastifyInstance) {

  fastify.register(async function (institucionRoutes) {

    institucionRoutes.addHook('preHandler', authenticate);
    institucionRoutes.addHook('preHandler', authorize(['super_admin']));

    institucionRoutes.get('/', {
      handler: InstitucionController.getAll,
    });

    institucionRoutes.get('/:id', {
      handler: InstitucionController.getById as any,
    });

    // Gestionar administradores por institución (solo super_admin)
    institucionRoutes.get('/:id/admins', {
      handler: InstitucionController.getAdminsByInstitution as any,
    });

    institucionRoutes.post('/:id/admins', {
      handler: InstitucionController.assignAdminToInstitution as any,
    });

    institucionRoutes.delete('/:id/admins/:userId', {
      handler: InstitucionController.removeAdminFromInstitution as any,
    });

    institucionRoutes.post('/', {
      handler: InstitucionController.create as any,
    });

    institucionRoutes.put('/:id', {
      handler: InstitucionController.update as any,
    });

    institucionRoutes.delete('/:id', {
      handler: InstitucionController.delete as any,
    });
  });
}