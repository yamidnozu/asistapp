import { FastifyReply, FastifyRequest } from 'fastify';
import { AuthenticatedRequest } from '../middleware/auth';
import AsistenciaService, { RegistrarAsistenciaRequest } from '../services/asistencia.service';

export interface RegistrarAsistenciaBody {
  horarioId: string;
  codigoQr: string;
}

export interface GetAsistenciasParams {
  horarioId: string;
}

/**
 * Controlador para gestión de Asistencias
 * Maneja las solicitudes HTTP relacionadas con asistencias
 */
export class AsistenciaController {

  /**
   * Registra la asistencia de un estudiante mediante código QR
   * POST /asistencias/registrar
   */
  public static async registrarAsistencia(
    request: FastifyRequest<{ Body: RegistrarAsistenciaBody }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { horarioId, codigoQr } = request.body;

      // Obtener el profesor del token JWT
      const profesorId = (request as any).user.id;

      const datos: RegistrarAsistenciaRequest = {
        horarioId,
        codigoQr,
        profesorId,
      };

      const resultado = await AsistenciaService.registrarAsistencia(datos);

      reply.code(201).send({
        success: true,
        message: 'Asistencia registrada exitosamente',
        data: resultado,
      });
    } catch (error: any) {
      console.error('Error en registrarAsistencia:', error);

      // Manejar errores conocidos por nombre de clase
      const errorName = error.constructor?.name || '';
      
      if (errorName === 'NotFoundError') {
        reply.code(404).send({
          success: false,
          message: error.message || 'Recurso no encontrado',
          error: 'NotFoundError',
        });
        return;
      }
      
      if (errorName === 'ValidationError') {
        reply.code(400).send({
          success: false,
          message: error.message || 'Datos inválidos',
          error: 'ValidationError',
        });
        return;
      }
      
      if (errorName === 'AuthorizationError') {
        reply.code(403).send({
          success: false,
          message: error.message || 'No autorizado',
          error: 'AuthorizationError',
        });
        return;
      }

      // Error genérico
      reply.code(500).send({
        success: false,
        message: error.message || 'Error interno del servidor',
        error: 'InternalServerError',
      });
    }
  }

  /**
   * Obtiene la lista de asistencias para un horario específico
   * GET /horarios/:horarioId/asistencias
   */
  public static async getAsistenciasPorHorario(
    request: AuthenticatedRequest & FastifyRequest<{ Params: GetAsistenciasParams }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { horarioId } = request.params;
      const profesorId = request.user!.id;

      const resultado = await AsistenciaService.getAsistenciasPorHorario(horarioId, profesorId);

      reply.code(200).send({
        success: true,
        message: 'Asistencias obtenidas exitosamente',
        data: resultado,
      });
    } catch (error: any) {
      console.error('Error en getAsistenciasPorHorario:', error);

      if (error.message?.includes('NotFoundError')) {
        reply.code(404).send({
          success: false,
          message: error.message,
          error: error.constructor.name,
        });
        return;
      }

      if (error.message?.includes('ForbiddenError') || error.message?.includes('no tiene permisos')) {
        reply.code(403).send({
          success: false,
          message: error.message,
          error: 'ForbiddenError',
        });
        return;
      }

      reply.code(500).send({
        success: false,
        message: 'Error interno del servidor',
        error: 'InternalServerError',
      });
    }
  }

  /**
   * Obtiene las estadísticas de asistencia para un horario específico
   * GET /asistencias/estadisticas/:horarioId
   */
  public static async getEstadisticasAsistencia(
    request: FastifyRequest<{ Params: GetAsistenciasParams }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { horarioId } = request.params;

      const resultado = await AsistenciaService.getEstadisticasAsistencia(horarioId);

      reply.code(200).send({
        success: true,
        message: 'Estadísticas de asistencia obtenidas exitosamente',
        data: resultado,
      });
    } catch (error: any) {
      console.error('Error en getEstadisticasAsistencia:', error);

      reply.code(500).send({
        success: false,
        message: 'Error interno del servidor',
        error: 'InternalServerError',
      });
    }
  }

  /**
   * Registra la asistencia de un estudiante manualmente (sin QR)
   * POST /asistencias/registrar-manual
   */
  public static async registrarAsistenciaManual(
    request: FastifyRequest<{ Body: { horarioId: string; estudianteId: string } }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { horarioId, estudianteId } = request.body;
      const profesorId = (request as any).user.id;

      const resultado = await AsistenciaService.registrarAsistenciaManual(
        horarioId,
        estudianteId,
        profesorId
      );

      reply.code(201).send({
        success: true,
        message: 'Asistencia registrada manualmente',
        data: resultado,
      });
    } catch (error: any) {
      console.error('Error en registrarAsistenciaManual:', error);

      // Manejar errores conocidos por nombre de clase
      const errorName = error.constructor?.name || '';
      
      if (errorName === 'NotFoundError') {
        reply.code(404).send({
          success: false,
          message: error.message || 'Recurso no encontrado',
          error: 'NotFoundError',
        });
        return;
      }
      
      if (errorName === 'ValidationError') {
        reply.code(400).send({
          success: false,
          message: error.message || 'Datos inválidos',
          error: 'ValidationError',
        });
        return;
      }
      
      if (errorName === 'AuthorizationError') {
        reply.code(403).send({
          success: false,
          message: error.message || 'No autorizado',
          error: 'AuthorizationError',
        });
        return;
      }

      // Error genérico
      reply.code(500).send({
        success: false,
        message: error.message || 'Error interno del servidor',
        error: 'InternalServerError',
      });
    }
  }
}

export default AsistenciaController;