import { FastifyInstance } from 'fastify';
import InstitutionAdminController from '../controllers/institution-admin.controller';
import { authenticate, authorize } from '../middleware/auth';

/**
 * Rutas para Admin de Institución
 * Gestiona profesores y estudiantes de su institución
 */
export default async function institutionAdminRoutes(fastify: FastifyInstance) {
  // Todas las rutas requieren autenticación y rol admin_institucion
  fastify.addHook('preHandler', authenticate);
  fastify.addHook('preHandler', authorize(['admin_institucion']));

  // ========== GESTIÓN DE PROFESORES ==========

  /**
   * GET /institution-admin/profesores
   * Obtiene todos los profesores de la institución del admin
   */
  fastify.get('/profesores', InstitutionAdminController.getAllProfesores);

  /**
   * GET /institution-admin/profesores/:id
   * Obtiene un profesor específico por ID
   */
  fastify.get('/profesores/:id', InstitutionAdminController.getProfesorById);

  /**
   * POST /institution-admin/profesores
   * Crea un nuevo profesor
   */
  fastify.post('/profesores', InstitutionAdminController.createProfesor);

  /**
   * PUT /institution-admin/profesores/:id
   * Actualiza un profesor
   */
  fastify.put('/profesores/:id', InstitutionAdminController.updateProfesor);

  /**
   * DELETE /institution-admin/profesores/:id
   * Elimina un profesor (desactivación lógica)
   */
  fastify.delete('/profesores/:id', InstitutionAdminController.deleteProfesor);

  /**
   * PATCH /institution-admin/profesores/:id/toggle-status
   * Activa/desactiva un profesor
   */
  fastify.patch('/profesores/:id/toggle-status', InstitutionAdminController.toggleProfesorStatus);

  // TODO: Agregar rutas para gestión de estudiantes
}