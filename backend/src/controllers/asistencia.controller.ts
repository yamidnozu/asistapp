import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import AsistenciaService, { RegistrarAsistenciaRequest } from '../services/asistencia.service';
import { formatDateToISO, getStartOfDay } from '../utils/date.utils';

export interface RegistrarAsistenciaBody {
  horarioId: string;
  codigoQr: string;
}

export interface GetAsistenciasParams {
  horarioId: string;
}

export interface GetAsistenciasQuery {
  page?: string;
  limit?: string;
  fecha?: string;
  horarioId?: string;
  estudianteId?: string;
  estado?: string;
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
   * Obtiene la lista de asistencias para un horario específico (fecha actual)
   * GET /horarios/:horarioId/asistencias
   */
  public static async getAsistenciasPorHorario(
    request: AuthenticatedRequest & FastifyRequest<{ Params: GetAsistenciasParams }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { horarioId } = request.params;

      // Obtener la institución del usuario autenticado
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        reply.code(400).send({ success: false, error: 'El usuario no tiene una institución asignada' });
        return;
      }

      const institucionId = usuarioInstitucion.institucionId;

      // Obtener asistencias del día actual para el horario
      const hoy = formatDateToISO(getStartOfDay());

      const resultado = await AsistenciaService.getAsistenciasPorHorario(horarioId);

      reply.code(200).send({ success: true, message: 'Asistencias obtenidas', data: resultado });
    } catch (error: any) {
      console.error('Error en getAsistenciasPorHorario:', error);
      reply.code(500).send({ success: false, message: 'Error interno del servidor', error: 'InternalServerError' });
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

  /**
   * Obtiene todas las asistencias con filtros opcionales
   * GET /asistencias
   */
  public static async getAllAsistencias(
    request: AuthenticatedRequest & FastifyRequest<{ Querystring: GetAsistenciasQuery }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { page, limit, fecha, horarioId, estudianteId, estado } = request.query;

      // Obtener la institución del usuario autenticado
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
        return;
      }

      const institucionId = usuarioInstitucion.institucionId;

      // Validar parámetros de paginación
      const pageNum = page ? parseInt(page, 10) : 1;
      const limitNum = limit ? parseInt(limit, 10) : 10;

      if (pageNum < 1 || limitNum < 1 || limitNum > 100) {
        reply.code(400).send({
          success: false,
          error: 'Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.',
        });
        return;
      }

      const pagination = {
        page: pageNum,
        limit: limitNum,
      };

      const filters = {
        institucionId,
        fecha: fecha || undefined,
        horarioId: horarioId || undefined,
        estudianteId: estudianteId || undefined,
        estado: estado || undefined,
      };

      const resultado = await AsistenciaService.getAllAsistencias(pagination, filters);

      reply.code(200).send({
        success: true,
        data: resultado.data,
        pagination: resultado.pagination,
      });
    } catch (error: any) {
      console.error('Error en getAllAsistencias:', error);
      reply.code(500).send({
        success: false,
        message: 'Error interno del servidor',
        error: 'InternalServerError',
      });
    }
  }

  /**
   * Obtiene las asistencias del estudiante autenticado
   * GET /asistencias/estudiante
   */
  public static async getAsistenciasEstudiante(
    request: AuthenticatedRequest & FastifyRequest<{ Querystring: { page?: string; limit?: string; fecha?: string } }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { page, limit, fecha } = request.query;

      // Verificar que el usuario es estudiante
      if (request.user!.rol !== 'estudiante') {
        reply.code(403).send({
          success: false,
          error: 'Acceso denegado: solo estudiantes pueden acceder a este endpoint',
        });
        return;
      }

      // Obtener el estudiante correspondiente al usuario
      const estudiante = await prisma.estudiante.findUnique({
        where: { usuarioId: request.user!.id },
      });

      if (!estudiante) {
        reply.code(404).send({
          success: false,
          error: 'Estudiante no encontrado',
        });
        return;
      }

      // Validar parámetros de paginación
      const pageNum = page ? parseInt(page, 10) : 1;
      const limitNum = limit ? parseInt(limit, 10) : 10;

      if (pageNum < 1 || limitNum < 1 || limitNum > 100) {
        reply.code(400).send({
          success: false,
          error: 'Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.',
        });
        return;
      }

      const pagination = {
        page: pageNum,
        limit: limitNum,
      };

      const filters = {
        estudianteId: estudiante.id,
        fecha: fecha || undefined,
      };

      const resultado = await AsistenciaService.getAsistenciasByEstudiante(estudiante.id, pagination, filters);

      reply.code(200).send({
        success: true,
        data: resultado.data,
        pagination: resultado.pagination,
      });
    } catch (error: any) {
      console.error('Error en getAsistenciasEstudiante:', error);
      reply.code(500).send({
        success: false,
        message: 'Error interno del servidor',
        error: 'InternalServerError',
      });
    }
  }

  /**
   * Actualiza una asistencia existente
   * PUT /asistencias/:id
   */
  public static async updateAsistencia(
    request: AuthenticatedRequest & FastifyRequest<{
      Params: { id: string },
      Body: { estado?: string; observacion?: string }
    }>,
    reply: FastifyReply
  ): Promise<void> {
    try {
      const { id } = request.params;
      const { estado, observacion } = request.body;
      const usuario = request.user!;

      // Validar estado si se proporciona
      if (estado && !['PRESENTE', 'AUSENTE', 'TARDANZA', 'JUSTIFICADO'].includes(estado)) {
        reply.code(400).send({
          success: false,
          error: 'Estado de asistencia inválido',
        });
        return;
      }

      const resultado = await AsistenciaService.updateAsistencia(
        id,
        {
          estado: estado as any,
          observacion,
        },
        usuario.id,
        usuario.rol
      );

      reply.code(200).send({
        success: true,
        message: 'Asistencia actualizada exitosamente',
        data: resultado,
      });
    } catch (error: any) {
      console.error('Error en updateAsistencia:', error);

      if (error instanceof Error && error.message.includes('NotFoundError')) {
        reply.code(404).send({
          success: false,
          message: error.message,
          error: 'NotFoundError',
        });
        return;
      }

      if (error instanceof Error && error.message.includes('AuthorizationError')) {
        reply.code(403).send({
          success: false,
          message: error.message,
          error: 'AuthorizationError',
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
}

export default AsistenciaController;