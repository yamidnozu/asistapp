import { prisma } from '../config/database';
import { ConflictError, NotFoundError, PaginatedResponse, PaginationParams, ValidationError } from '../types';
import logger from '../utils/logger';

export interface CreatePeriodoAcademicoRequest {
  nombre: string;
  fechaInicio: Date;
  fechaFin: Date;
}

export interface UpdatePeriodoAcademicoRequest {
  nombre?: string;
  fechaInicio?: Date;
  fechaFin?: Date;
}

export interface PeriodoAcademicoResponse {
  id: string;
  nombre: string;
  fechaInicio: string;
  fechaFin: string;
  activo: boolean;
  institucionId: string;
  createdAt: string;
  _count?: {
    grupos: number;
  };
}

export class PeriodoAcademicoService {
  /**
   * Obtiene todos los períodos académicos de una institución con paginación
   */
  public static async getAllPeriodosAcademicos(
    institucionId: string,
    pagination?: PaginationParams,
    search?: string
  ): Promise<PaginatedResponse<PeriodoAcademicoResponse>> {
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

      // Construir where clause
      const whereClause: any = {
        institucionId: institucionId,
      };

      if (search) {
        whereClause.nombre = {
          contains: search,
          mode: 'insensitive',
        };
      }

      // Obtener total de registros
      const total = await prisma.periodoAcademico.count({
        where: whereClause,
      });

      // Obtener registros paginados
      const periodos = await prisma.periodoAcademico.findMany({
        where: whereClause,
        skip,
        take: limit,
        orderBy: [
          { activo: 'desc' },
          { fechaInicio: 'desc' },
        ],
        include: {
          _count: {
            select: {
              grupos: true,
            },
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: periodos.map((periodo: any) => ({
          id: periodo.id,
          nombre: periodo.nombre,
          fechaInicio: periodo.fechaInicio.toISOString(),
          fechaFin: periodo.fechaFin.toISOString(),
          activo: periodo.activo,
          institucionId: periodo.institucionId,
          createdAt: periodo.createdAt.toISOString(),
          _count: periodo._count,
        })),
        pagination: {
          page,
          limit,
          total,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      logger.error('Error al obtener períodos académicos:', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener los períodos académicos');
    }
  }

  /**
   * Obtiene un período académico por ID
   */
  public static async getPeriodoAcademicoById(id: string): Promise<PeriodoAcademicoResponse | null> {
    try {
      const periodo = await prisma.periodoAcademico.findUnique({
        where: { id },
        include: {
          _count: {
            select: {
              grupos: true,
            },
          },
        },
      });

      if (!periodo) {
        return null;
      }

      return {
        id: periodo.id,
        nombre: periodo.nombre,
        fechaInicio: periodo.fechaInicio.toISOString(),
        fechaFin: periodo.fechaFin.toISOString(),
        activo: periodo.activo,
        institucionId: periodo.institucionId,
        createdAt: periodo.createdAt.toISOString(),
        _count: periodo._count,
      };
    } catch (error) {
      logger.error('Error al obtener período académico:', error);
      throw new Error('Error al obtener el período académico');
    }
  }

  /**
   * Crea un nuevo período académico
   */
  public static async createPeriodoAcademico(
    data: CreatePeriodoAcademicoRequest,
    institucionId: string
  ): Promise<PeriodoAcademicoResponse> {
    try {
      // Validaciones de campos requeridos
      if (!data.nombre || data.nombre.trim() === '') {
        throw new ValidationError('El nombre del período académico es requerido');
      }
      if (!data.fechaInicio) {
        throw new ValidationError('La fecha de inicio es requerida');
      }
      if (!data.fechaFin) {
        throw new ValidationError('La fecha de fin es requerida');
      }

      // Validar que la fecha de inicio sea anterior a la fecha de fin
      if (data.fechaInicio >= data.fechaFin) {
        throw new ValidationError('La fecha de inicio debe ser anterior a la fecha de fin');
      }

      // Validar que no exista un período con el mismo nombre en la misma institución
      const existingPeriodo = await prisma.periodoAcademico.findFirst({
        where: {
          nombre: data.nombre.trim(),
          institucionId: institucionId,
        },
      });

      if (existingPeriodo) {
        throw new ConflictError('Ya existe un período académico con este nombre en la institución');
      }

      const periodo = await prisma.periodoAcademico.create({
        data: {
          nombre: data.nombre.trim(),
          fechaInicio: data.fechaInicio,
          fechaFin: data.fechaFin,
          institucionId: institucionId,
        },
        include: {
          _count: {
            select: {
              grupos: true,
            },
          },
        },
      });

      return {
        id: periodo.id,
        nombre: periodo.nombre,
        fechaInicio: periodo.fechaInicio.toISOString(),
        fechaFin: periodo.fechaFin.toISOString(),
        activo: periodo.activo,
        institucionId: periodo.institucionId,
        createdAt: periodo.createdAt.toISOString(),
        _count: periodo._count,
      };
    } catch (error) {
      logger.error('Error al crear período académico:', error);
      if (error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al crear el período académico');
    }
  }

  /**
   * Actualiza un período académico
   */
  public static async updatePeriodoAcademico(
    id: string,
    data: UpdatePeriodoAcademicoRequest
  ): Promise<PeriodoAcademicoResponse | null> {
    try {
      // Verificar que el período existe
      const existingPeriodo = await prisma.periodoAcademico.findUnique({
        where: { id },
      });

      if (!existingPeriodo) {
        throw new NotFoundError('Período Académico');
      }

      // Validar fechas si se están actualizando
      if (data.fechaInicio && data.fechaFin && data.fechaInicio >= data.fechaFin) {
        throw new ValidationError('La fecha de inicio debe ser anterior a la fecha de fin');
      }

      // Si se está cambiando el nombre, validar que no exista otro período con el mismo nombre
      if (data.nombre && data.nombre !== existingPeriodo.nombre) {
        const existingPeriodoWithName = await prisma.periodoAcademico.findFirst({
          where: {
            nombre: data.nombre,
            institucionId: existingPeriodo.institucionId,
            id: { not: id },
          },
        });

        if (existingPeriodoWithName) {
          throw new ConflictError('Ya existe un período académico con este nombre en la institución');
        }
      }

      const periodo = await prisma.periodoAcademico.update({
        where: { id },
        data: {
          nombre: data.nombre,
          fechaInicio: data.fechaInicio,
          fechaFin: data.fechaFin,
        },
        include: {
          _count: {
            select: {
              grupos: true,
            },
          },
        },
      });

      return {
        id: periodo.id,
        nombre: periodo.nombre,
        fechaInicio: periodo.fechaInicio.toISOString(),
        fechaFin: periodo.fechaFin.toISOString(),
        activo: periodo.activo,
        institucionId: periodo.institucionId,
        createdAt: periodo.createdAt.toISOString(),
        _count: periodo._count,
      };
    } catch (error) {
      logger.error('Error al actualizar período académico:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al actualizar el período académico');
    }
  }

  /**
   * Elimina un período académico
   */
  public static async deletePeriodoAcademico(id: string): Promise<boolean> {
    try {
      // Verificar que el período existe
      const existingPeriodo = await prisma.periodoAcademico.findUnique({
        where: { id },
        include: {
          grupos: {
            select: {
              id: true,
            },
            take: 1, // Solo necesitamos saber si existe al menos un grupo
          },
        },
      });

      if (!existingPeriodo) {
        throw new NotFoundError('Período Académico');
      }

      // Verificar que no tenga grupos asociados
      if (existingPeriodo.grupos.length > 0) {
        throw new ValidationError('No se puede eliminar el período académico porque tiene grupos asociados');
      }

      await prisma.periodoAcademico.delete({
        where: { id },
      });

      return true;
    } catch (error) {
      logger.error('Error al eliminar período académico:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al eliminar el período académico');
    }
  }

  /**
   * Activa/desactiva un período académico
   * Solo puede haber un período activo por institución
   */
  public static async toggleActivo(id: string): Promise<PeriodoAcademicoResponse | null> {
    try {
      // Obtener el período actual
      const periodo = await prisma.periodoAcademico.findUnique({
        where: { id },
        include: {
          _count: {
            select: {
              grupos: true,
            },
          },
        },
      });

      if (!periodo) {
        throw new NotFoundError('Período Académico');
      }

      // Si ya está activo, no hacer nada
      if (periodo.activo) {
        return {
          id: periodo.id,
          nombre: periodo.nombre,
          fechaInicio: periodo.fechaInicio.toISOString(),
          fechaFin: periodo.fechaFin.toISOString(),
          activo: periodo.activo,
          institucionId: periodo.institucionId,
          createdAt: periodo.createdAt.toISOString(),
          _count: periodo._count,
        };
      }

      // Desactivar todos los períodos activos de la institución
      await prisma.periodoAcademico.updateMany({
        where: {
          institucionId: periodo.institucionId,
          activo: true,
        },
        data: {
          activo: false,
        },
      });

      // Activar el período seleccionado
      const periodoActualizado = await prisma.periodoAcademico.update({
        where: { id },
        data: {
          activo: true,
        },
        include: {
          _count: {
            select: {
              grupos: true,
            },
          },
        },
      });

      return {
        id: periodoActualizado.id,
        nombre: periodoActualizado.nombre,
        fechaInicio: periodoActualizado.fechaInicio.toISOString(),
        fechaFin: periodoActualizado.fechaFin.toISOString(),
        activo: periodoActualizado.activo,
        institucionId: periodoActualizado.institucionId,
        createdAt: periodoActualizado.createdAt.toISOString(),
        _count: periodoActualizado._count,
      };
    } catch (error) {
      logger.error('Error al cambiar status del período académico:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al cambiar el status del período académico');
    }
  }

  /**
   * Obtiene los períodos académicos activos de una institución
   */
  public static async getPeriodosActivos(institucionId: string): Promise<PeriodoAcademicoResponse[]> {
    try {
      const periodos = await prisma.periodoAcademico.findMany({
        where: {
          institucionId: institucionId,
          activo: true,
        },
        orderBy: {
          fechaInicio: 'desc',
        },
        include: {
          _count: {
            select: {
              grupos: true,
            },
          },
        },
      });

      return periodos.map((periodo: any) => ({
        id: periodo.id,
        nombre: periodo.nombre,
        fechaInicio: periodo.fechaInicio.toISOString(),
        fechaFin: periodo.fechaFin.toISOString(),
        activo: periodo.activo,
        institucionId: periodo.institucionId,
        createdAt: periodo.createdAt.toISOString(),
        _count: periodo._count,
      }));
    } catch (error) {
      logger.error('Error al obtener períodos activos:', error);
      throw new Error('Error al obtener los períodos activos');
    }
  }
}

export default PeriodoAcademicoService;