import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import PeriodoAcademicoService from '../services/periodo-academico.service';
import { NotFoundError, ValidationError } from '../types';

interface GetPeriodosQuery {
  page?: string;
  limit?: string;
}

interface GetPeriodoParams {
  id: string;
}

interface CreatePeriodoBody {
  nombre: string;
  fechaInicio: string;
  fechaFin: string;
}

interface UpdatePeriodoBody {
  nombre?: string;
  fechaInicio?: string;
  fechaFin?: string;
}

export class PeriodoAcademicoController {
  /**
   * Obtiene todos los períodos académicos de la institución del admin autenticado
   */
  public static async getAll(request: AuthenticatedRequest & FastifyRequest<{ Querystring: GetPeriodosQuery }>, reply: FastifyReply) {
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

      const institucionId = usuarioInstitucion.institucionId;

      const { page, limit } = request.query;

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

      const result = await PeriodoAcademicoService.getAllPeriodosAcademicos(institucionId, pagination);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      console.error('Error en getAll periodos académicos:', error);
      throw error;
    }
  }

  /**
   * Obtiene un período académico por ID
   */
  public static async getById(request: AuthenticatedRequest & FastifyRequest<{ Params: GetPeriodoParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const periodo = await PeriodoAcademicoService.getPeriodoAcademicoById(id);

      if (!periodo) {
        throw new NotFoundError('Período Académico');
      }

      // Verificar que el período pertenece a la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && periodo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a este período académico',
        });
      }

      return reply.code(200).send({
        success: true,
        data: periodo,
      });
    } catch (error) {
      console.error('Error en getById período académico:', error);
      throw error;
    }
  }

  /**
   * Crea un nuevo período académico
   */
  public static async create(request: AuthenticatedRequest & FastifyRequest<{ Body: CreatePeriodoBody }>, reply: FastifyReply) {
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

      const { nombre, fechaInicio, fechaFin } = request.body;

      const data = {
        nombre,
        fechaInicio: new Date(fechaInicio),
        fechaFin: new Date(fechaFin),
      };

      const periodo = await PeriodoAcademicoService.createPeriodoAcademico(data, usuarioInstitucion.institucionId);

      return reply.code(201).send({
        success: true,
        data: periodo,
        message: 'Período académico creado exitosamente',
      });
    } catch (error) {
      console.error('Error en create período académico:', error);
      throw error;
    }
  }

  /**
   * Actualiza un período académico
   */
  public static async update(request: AuthenticatedRequest & FastifyRequest<{ Params: GetPeriodoParams; Body: UpdatePeriodoBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const data = request.body;

      // Verificar que el período existe y pertenece a la institución del admin
      const existingPeriodo = await PeriodoAcademicoService.getPeriodoAcademicoById(id);
      if (!existingPeriodo) {
        throw new NotFoundError('Período Académico');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingPeriodo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este período académico',
        });
      }

      const updateData: any = {};
      if (data.nombre) updateData.nombre = data.nombre;
      if (data.fechaInicio) updateData.fechaInicio = new Date(data.fechaInicio);
      if (data.fechaFin) updateData.fechaFin = new Date(data.fechaFin);

      const periodo = await PeriodoAcademicoService.updatePeriodoAcademico(id, updateData);

      if (!periodo) {
        throw new NotFoundError('Período Académico');
      }

      return reply.code(200).send({
        success: true,
        data: periodo,
        message: 'Período académico actualizado exitosamente',
      });
    } catch (error) {
      console.error('Error en update período académico:', error);
      throw error;
    }
  }

  /**
   * Elimina un período académico
   */
  public static async delete(request: AuthenticatedRequest & FastifyRequest<{ Params: GetPeriodoParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      // Verificar que el período existe y pertenece a la institución del admin
      const existingPeriodo = await PeriodoAcademicoService.getPeriodoAcademicoById(id);
      if (!existingPeriodo) {
        throw new NotFoundError('Período Académico');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingPeriodo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para eliminar este período académico',
        });
      }

      const success = await PeriodoAcademicoService.deletePeriodoAcademico(id);

      return reply.code(200).send({
        success: true,
        message: 'Período académico eliminado exitosamente',
      });
    } catch (error) {
      console.error('Error en delete período académico:', error);
      throw error;
    }
  }

  /**
   * Activa/desactiva un período académico
   */
  public static async toggleStatus(request: AuthenticatedRequest & FastifyRequest<{ Params: GetPeriodoParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      // Verificar que el período existe y pertenece a la institución del admin
      const existingPeriodo = await PeriodoAcademicoService.getPeriodoAcademicoById(id);
      if (!existingPeriodo) {
        throw new NotFoundError('Período Académico');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingPeriodo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este período académico',
        });
      }

      const periodo = await PeriodoAcademicoService.toggleActivo(id);

      if (!periodo) {
        throw new NotFoundError('Período Académico');
      }

      return reply.code(200).send({
        success: true,
        data: periodo,
        message: `Período académico ${periodo.activo ? 'activado' : 'desactivado'} exitosamente`,
      });
    } catch (error) {
      console.error('Error en toggleStatus período académico:', error);
      throw error;
    }
  }

  /**
   * Obtiene los períodos académicos activos de la institución
   */
  public static async getActivos(request: AuthenticatedRequest, reply: FastifyReply) {
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

      const periodos = await PeriodoAcademicoService.getPeriodosActivos(usuarioInstitucion.institucionId);

      return reply.code(200).send({
        success: true,
        data: periodos,
      });
    } catch (error) {
      console.error('Error en getActivos períodos académicos:', error);
      throw error;
    }
  }
}

export default PeriodoAcademicoController;