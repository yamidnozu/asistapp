import { FastifyInstance } from 'fastify';
import AdminInstitucionController from '../controllers/admin-institucion.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function adminInstitucionRoutes(fastify: FastifyInstance) {

  fastify.register(async function (adminInstitucionRoutes) {

    adminInstitucionRoutes.addHook('preHandler', authenticate);
    adminInstitucionRoutes.addHook('preHandler', authorize(['super_admin']));

    adminInstitucionRoutes.get('/', {
      handler: AdminInstitucionController.getAll,
    });

    adminInstitucionRoutes.get('/:id', {
      handler: AdminInstitucionController.getById,
    });

    adminInstitucionRoutes.post('/', {
      handler: AdminInstitucionController.create,
    });

    adminInstitucionRoutes.put('/:id', {
      handler: AdminInstitucionController.update,
    });

    adminInstitucionRoutes.delete('/:id', {
      handler: AdminInstitucionController.delete,
    });
  });
}