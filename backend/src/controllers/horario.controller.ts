import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import HorarioService from '../services/horario.service';
import { NotFoundError, ValidationError } from '../types';

interface GetHorariosQuery {
  page?: string;
  limit?: string;
  grupoId?: string;
  materiaId?: string;
  profesorId?: string;
  diaSemana?: string;
}

interface GetHorarioParams {
  id: string;
}

interface GetHorariosByGrupoParams {
  grupoId: string;
}

interface CreateHorarioBody {
  periodoId: string;
  grupoId: string;
  materiaId: string;
  profesorId?: string;
  diaSemana: number;
  horaInicio: string;
  horaFin: string;
}

interface UpdateHorarioBody {
  grupoId?: string;
  materiaId?: string;
  profesorId?: string;
  diaSemana?: number;
  horaInicio?: string;
  horaFin?: string;
}

export class HorarioController {
  /**
   * Obtiene todos los horarios de la institución del admin autenticado
   */
  public static async getAll(request: AuthenticatedRequest & FastifyRequest<{ Querystring: GetHorariosQuery }>, reply: FastifyReply) {
    try {
      // Obtener la institución del admin autenticado
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const { page, limit, grupoId, materiaId, profesorId, diaSemana } = request.query;

      // Validar parámetros de paginación
      const pageNum = page ? parseInt(page, 10) : 1;
      const limitNum = limit ? parseInt(limit, 10) : 10;

      if (pageNum < 1 || limitNum < 1 || limitNum > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const pagination = {
        page: pageNum,
        limit: limitNum,
      };

      const filters = {
        grupoId: grupoId || undefined,
        materiaId: materiaId || undefined,
        profesorId: profesorId || undefined,
        diaSemana: diaSemana ? parseInt(diaSemana, 10) : undefined,
      };

      const result = await HorarioService.getAllHorariosByInstitucion(usuarioInstitucion.institucionId, pagination, filters);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      console.error('Error en getAll horarios:', error);
      throw error;
    }
  }

  /**
   * Obtiene los horarios de un grupo específico
   */
  public static async getByGrupo(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorariosByGrupoParams }>, reply: FastifyReply) {
    try {
      const { grupoId } = request.params;

      // Verificar que el grupo pertenece a la institución del admin
      const grupo = await prisma.grupo.findUnique({
        where: { id: grupoId },
      });

      if (!grupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && grupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a los horarios de este grupo',
        });
      }

      const horarios = await HorarioService.getHorariosByGrupo(grupoId);

      return reply.code(200).send({
        success: true,
        data: horarios,
      });
    } catch (error) {
      console.error('Error en getByGrupo horarios:', error);
      throw error;
    }
  }

  /**
   * Obtiene un horario por ID
   */
  public static async getById(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorarioParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const horario = await HorarioService.getHorarioById(id);

      if (!horario) {
        throw new NotFoundError('Horario');
      }

      // Verificar que el horario pertenece a la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && horario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a este horario',
        });
      }

      return reply.code(200).send({
        success: true,
        data: horario,
      });
    } catch (error) {
      console.error('Error en getById horario:', error);
      throw error;
    }
  }

  /**
   * Crea un nuevo horario
   */
  public static async create(request: AuthenticatedRequest & FastifyRequest<{ Body: CreateHorarioBody }>, reply: FastifyReply) {
    try {
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      // Validar formato de UUIDs antes de consultar la base de datos
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      const { periodoId, grupoId, materiaId, profesorId } = request.body;
      
      if (!uuidRegex.test(periodoId) || !uuidRegex.test(grupoId) || !uuidRegex.test(materiaId)) {
        return reply.code(400).send({
          success: false,
          error: 'Formato de ID inválido',
          code: 'VALIDATION_ERROR'
        });
      }
      
      if (profesorId && !uuidRegex.test(profesorId)) {
        return reply.code(400).send({
          success: false,
          error: 'Formato de ID del profesor inválido',
          code: 'VALIDATION_ERROR'
        });
      }

      const data = {
        ...request.body,
        institucionId: usuarioInstitucion.institucionId,
      };

      const horario = await HorarioService.createHorario(data);

      return reply.code(201).send({
        success: true,
        data: horario,
        message: 'Horario creado exitosamente',
      });
    } catch (error) {
      console.error('Error en create horario:', error);
      
      // Si es un error de validación de Prisma (IDs inválidos), devolver 400
      if ((error as any).code === 'P2025' || (error as any).code === 'P2003') {
        return reply.code(400).send({
          success: false,
          error: 'IDs inválidos en la solicitud',
          code: 'VALIDATION_ERROR'
        });
      }
      
      throw error;
    }
  }

  /**
   * Actualiza un horario
   */
  public static async update(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorarioParams; Body: UpdateHorarioBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const data = request.body;

      // Verificar que el horario existe y pertenece a la institución del admin
      const existingHorario = await HorarioService.getHorarioById(id);
      if (!existingHorario) {
        throw new NotFoundError('Horario');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingHorario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este horario',
        });
      }

      const horario = await HorarioService.updateHorario(id, data);

      if (!horario) {
        throw new NotFoundError('Horario');
      }

      return reply.code(200).send({
        success: true,
        data: horario,
        message: 'Horario actualizado exitosamente',
      });
    } catch (error) {
      console.error('Error en update horario:', error);
      throw error;
    }
  }

  /**
   * Elimina un horario
   */
  public static async delete(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorarioParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      // Verificar que el horario existe y pertenece a la institución del admin
      const existingHorario = await HorarioService.getHorarioById(id);
      if (!existingHorario) {
        throw new NotFoundError('Horario');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingHorario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para eliminar este horario',
        });
      }

      const success = await HorarioService.deleteHorario(id);

      return reply.code(200).send({
        success: true,
        message: 'Horario eliminado exitosamente',
      });
    } catch (error) {
      console.error('Error en delete horario:', error);
      throw error;
    }
  }
}

export default HorarioController;