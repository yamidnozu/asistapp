import { FastifyReply, FastifyRequest } from 'fastify';
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

      if (error.message?.includes('NotFoundError') ||
          error.message?.includes('ValidationError') ||
          error.message?.includes('AuthorizationError')) {
        const statusCode = error.message.includes('NotFoundError') ? 404 :
                          error.message.includes('ValidationError') ? 400 : 403;

        reply.code(statusCode).send({
          success: false,
          message: error.message,
          error: error.constructor.name,
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
   * Obtiene la lista de asistencias para un horario específico
   * GET /horarios/:horarioId/asistencias
   */
  public static async getAsistenciasPorHorario(
    request: FastifyRequest<{ Params: GetAsistenciasParams }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { horarioId } = request.params;

      const resultado = await AsistenciaService.getAsistenciasPorHorario(horarioId);

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
}

export default AsistenciaController;