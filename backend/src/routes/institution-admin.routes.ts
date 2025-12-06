import { FastifyInstance } from 'fastify';
import { UserRole } from '../constants/roles';
import InstitutionAdminController from '../controllers/institution-admin.controller';
import { authenticate, AuthenticatedRequest, authorize } from '../middleware/auth';

/**
 * Rutas para Admin de Institución
 * Gestiona profesores y estudiantes de su institución
 */
export default async function institutionAdminRoutes(fastify: FastifyInstance) {
  console.log('[INFO] institution-admin.routes.ts - FUNCIÓN EJECUTADA');
  
  fastify.register(async function (institutionAdminRoutes) {
    console.log('[INFO] institution-admin.routes.ts - REGISTER EJECUTADO');
    
    // Todas las rutas requieren autenticación y rol admin_institucion
    institutionAdminRoutes.addHook('preHandler', authenticate);
    institutionAdminRoutes.addHook('preHandler', authorize([UserRole.ADMIN_INSTITUCION]));

    // ========== ENDPOINT DE PRUEBA ==========

    /**
     * GET /institution-admin/test
     * Endpoint de prueba para verificar funcionamiento
     */
    institutionAdminRoutes.get('/test', async (request, reply) => {
      console.log('🧪 GET /institution-admin/test - Endpoint ejecutado');
      return reply.code(200).send({
        success: true,
        message: 'institution-admin routes funcionando correctamente',
        timestamp: new Date().toISOString(),
      });
    });

    // ========== GESTIÓN DE PROFESORES ==========

    /**
     * GET /institution-admin/profesores
     * Obtiene todos los profesores de la institución del admin
     */
    institutionAdminRoutes.get('/profesores', InstitutionAdminController.getAllProfesores);

    /**
     * GET /institution-admin/profesores/:id
     * Obtiene un profesor específico por ID
     */
    institutionAdminRoutes.get('/profesores/:id', InstitutionAdminController.getProfesorById);

    /**
     * POST /institution-admin/profesores
     * Crea un nuevo profesor
     */
    institutionAdminRoutes.post('/profesores', InstitutionAdminController.createProfesor);

    /**
     * PUT /institution-admin/profesores/:id
     * Actualiza un profesor
     */
    institutionAdminRoutes.put('/profesores/:id', InstitutionAdminController.updateProfesor);

    /**
     * DELETE /institution-admin/profesores/:id
     * Elimina un profesor (desactivación lógica)
     */
    institutionAdminRoutes.delete('/profesores/:id', InstitutionAdminController.deleteProfesor);

    /**
     * PATCH /institution-admin/profesores/:id/toggle-status
     * Activa/desactiva un profesor
     */
    institutionAdminRoutes.patch('/profesores/:id/toggle-status', InstitutionAdminController.toggleProfesorStatus);

    // ========== GESTIÓN DE ESTUDIANTES ==========

    /**
     * GET /institution-admin/estudiantes
     * Obtiene todos los estudiantes de la institución del admin
     */
    institutionAdminRoutes.get('/estudiantes', InstitutionAdminController.getAllEstudiantes);

    /**
     * GET /institution-admin/estudiantes/:id
     * Obtiene un estudiante específico por ID
     */
    institutionAdminRoutes.get('/estudiantes/:id', InstitutionAdminController.getEstudianteById);

    /**
     * POST /institution-admin/estudiantes
     * Crea un nuevo estudiante
     */
    institutionAdminRoutes.post('/estudiantes', async (request, reply) => {
      console.log('🔍 POST /estudiantes - Validando datos:', request.body);
      
      const authRequest = request as AuthenticatedRequest;
      const body = request.body as any;
      
      // Validaciones inline
      if (!body.nombres || body.nombres.trim() === '') {
        console.log('❌ Validación fallida: nombres vacío');
        return reply.code(400).send({
          success: false,
          error: 'El nombre es requerido',
          code: 'VALIDATION_ERROR',
        });
      }
      
      if (!body.apellidos || body.apellidos.trim() === '') {
        console.log('❌ Validación fallida: apellidos vacío');
        return reply.code(400).send({
          success: false,
          error: 'Los apellidos son requeridos',
          code: 'VALIDATION_ERROR',
        });
      }
      
      if (!body.email || body.email.trim() === '') {
        console.log('❌ Validación fallida: email vacío');
        return reply.code(400).send({
          success: false,
          error: 'El email es requerido',
          code: 'VALIDATION_ERROR',
        });
      }
      
      if (!body.password || body.password.trim() === '') {
        console.log('❌ Validación fallida: password vacío');
        return reply.code(400).send({
          success: false,
          error: 'La contraseña es requerida',
          code: 'VALIDATION_ERROR',
        });
      }
      
      if (!body.identificacion || body.identificacion.trim() === '') {
        console.log('❌ Validación fallida: identificacion vacío');
        return reply.code(400).send({
          success: false,
          error: 'La identificación es requerida',
          code: 'VALIDATION_ERROR',
        });
      }
      
      console.log('✅ Validaciones pasaron, llamando al controlador');
      return InstitutionAdminController.createEstudiante(request as any, reply);
    });

    /**
     * PUT /institution-admin/estudiantes/:id
     * Actualiza un estudiante
     */
    institutionAdminRoutes.put('/estudiantes/:id', InstitutionAdminController.updateEstudiante);

    /**
     * DELETE /institution-admin/estudiantes/:id
     * Elimina un estudiante (desactivación lógica)
     */
    institutionAdminRoutes.delete('/estudiantes/:id', InstitutionAdminController.deleteEstudiante);

    /**
     * PATCH /institution-admin/estudiantes/:id/toggle-status
     * Activa/desactiva un estudiante
     */
    institutionAdminRoutes.patch('/estudiantes/:id/toggle-status', InstitutionAdminController.toggleEstudianteStatus);
  });
}