import { FastifyInstance } from 'fastify';
import UserController from '../controllers/user.controller';
import { authenticate, authorize } from '../middleware/auth';

/**
 * Rutas para gestión de usuarios
 */
export default async function userRoutes(fastify: FastifyInstance) {
  // Todas las rutas requieren autenticación
  fastify.addHook('preHandler', authenticate);

  /**
   * GET /usuarios
   * Obtiene todos los usuarios con paginación y filtros
   * Solo para super_admin
   */
  fastify.get('/', {
    preHandler: authorize(['super_admin']),
    handler: UserController.getAllUsers,
  });

  /**
   * GET /usuarios/:id
   * Obtiene un usuario específico por ID
   */
  fastify.get('/:id', UserController.getUserById);

  /**
   * GET /usuarios/rol/:role
   * Obtiene usuarios por rol con paginación y filtros adicionales
   */
  fastify.get('/rol/:role', UserController.getUsersByRole);

  /**
   * GET /usuarios/institucion/:institucionId
   * Obtiene usuarios por institución con paginación y filtros adicionales
   */
  fastify.get('/institucion/:institucionId', UserController.getUsersByInstitution);

  /**
   * POST /usuarios
   * Crea un nuevo usuario
   * Solo para super_admin y admin_institucion
   */
  fastify.post('/', {
    preHandler: authorize(['super_admin', 'admin_institucion']),
    handler: UserController.createUser,
  });

  /**
   * PUT /usuarios/:id
   * Actualiza un usuario existente
   * Solo para super_admin y admin_institucion
   */
  fastify.put('/:id', {
    preHandler: authorize(['super_admin', 'admin_institucion']),
    handler: UserController.updateUser,
  });

  /**
   * DELETE /usuarios/:id
   * Elimina un usuario (desactivación lógica)
   * Solo para super_admin y admin_institucion
   */
  fastify.delete('/:id', {
    preHandler: authorize(['super_admin', 'admin_institucion']),
    handler: UserController.deleteUser,
  });

  // TODO: Agregar rutas para crear, actualizar, eliminar usuarios si es necesario
}