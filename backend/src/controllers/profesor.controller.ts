import { FastifyReply } from 'fastify';
import { ProfesorService } from '../services/profesor.service';
import { AuthenticatedRequest } from '../types';
import logger from '../utils/logger';

export class ProfesorController {
  /**
   * GET /profesores/dashboard/clases-hoy
   * Obtiene las clases que el profesor autenticado tiene hoy
   */
  public static async getClasesDelDia(
    request: AuthenticatedRequest,
    reply: FastifyReply
  ) {
    try {
      const profesorId = request.user.id;

      const clases = await ProfesorService.getClasesDelDia(profesorId);

      return reply.status(200).send({
        success: true,
        data: clases,
        message: 'Clases del día obtenidas exitosamente',
      });
    } catch (error) {
      logger.error('Error en getClasesDelDia:', error);
      return reply.status(500).send({
        success: false,
        message: 'Error interno del servidor',
      });
    }
  }

  /**
   * GET /profesores/dashboard/clases/:diaSemana
   * Obtiene las clases que el profesor tiene en un día específico de la semana
   */
  public static async getClasesPorDia(
    request: AuthenticatedRequest & { params: { diaSemana: string } },
    reply: FastifyReply
  ) {
    try {
      const profesorId = request.user.id;
      const diaSemana = parseInt(request.params.diaSemana);

      // Validar que diaSemana sea un número válido
      if (isNaN(diaSemana) || diaSemana < 1 || diaSemana > 7) {
        return reply.status(400).send({
          success: false,
          message: 'El día de la semana debe ser un número entre 1 (Lunes) y 7 (Domingo)',
        });
      }

      const clases = await ProfesorService.getClasesPorDia(profesorId, diaSemana);

      return reply.status(200).send({
        success: true,
        data: clases,
        message: `Clases del día ${diaSemana} obtenidas exitosamente`,
      });
    } catch (error) {
      logger.error('Error en getClasesPorDia:', error);
      return reply.status(500).send({
        success: false,
        message: 'Error interno del servidor',
      });
    }
  }

  /**
   * GET /profesores/dashboard/horario-semanal
   * Obtiene el horario semanal completo del profesor
   */
  public static async getHorarioSemanal(
    request: AuthenticatedRequest,
    reply: FastifyReply
  ) {
    try {
      const profesorId = request.user.id;

      const horarioSemanal = await ProfesorService.getHorarioSemanal(profesorId);

      return reply.status(200).send({
        success: true,
        data: horarioSemanal,
        message: 'Horario semanal obtenido exitosamente',
      });
    } catch (error) {
      logger.error('Error en getHorarioSemanal:', error);
      return reply.status(500).send({
        success: false,
        message: 'Error interno del servidor',
      });
    }
  }
}

export default ProfesorController;