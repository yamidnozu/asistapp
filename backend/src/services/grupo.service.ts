import { prisma } from '../config/database';
import { ConflictError, NotFoundError, PaginatedResponse, PaginationParams, ValidationError } from '../types';

export interface GrupoFilters {
  periodoId?: string;
  grado?: string;
  seccion?: string;
  search?: string;
}

export interface CreateGrupoRequest {
  nombre: string;
  grado: string;
  seccion?: string;
  periodoId: string;
  institucionId: string;
}

export interface UpdateGrupoRequest {
  nombre?: string;
  grado?: string;
  seccion?: string;
  periodoId?: string;
}

export interface GrupoResponse {
  id: string;
  nombre: string;
  grado: string;
  seccion: string | null;
  periodoId: string;
  institucionId: string;
  createdAt: string;
  periodoAcademico: {
    id: string;
    nombre: string;
    fechaInicio: string;
    fechaFin: string;
    activo: boolean;
  };
  _count?: {
    estudiantesGrupos: number;
    horarios: number;
  };
}

export class GrupoService {
  /**
   * Obtiene todos los grupos de una institución con paginación y filtros
   */
  public static async getAllGruposByInstitucion(
    institucionId: string,
    pagination?: PaginationParams,
    filters?: GrupoFilters
  ): Promise<PaginatedResponse<GrupoResponse>> {
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

      // Construir cláusula where dinámicamente
      const where: any = {
        institucionId: institucionId,
      };

      if (filters?.periodoId) {
        where.periodoId = filters.periodoId;
      }
      if (filters?.grado) {
        where.grado = filters.grado;
      }
      if (filters?.seccion) {
        where.seccion = filters.seccion;
      }
      if (filters?.search) {
        where.nombre = {
          contains: filters.search,
          mode: 'insensitive',
        };
      }

      // Obtener total de registros
      const total = await prisma.grupo.count({ where });

      // Obtener registros paginados
      const grupos = await prisma.grupo.findMany({
        where,
        skip,
        take: limit,
        orderBy: [
          { grado: 'asc' },
          { seccion: 'asc' },
          { nombre: 'asc' },
        ],
        include: {
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              fechaInicio: true,
              fechaFin: true,
              activo: true,
            },
          },
          _count: {
            select: {
              estudiantesGrupos: true,
              horarios: true,
            },
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: grupos.map((grupo: any) => ({
          id: grupo.id,
          nombre: grupo.nombre,
          grado: grupo.grado,
          seccion: grupo.seccion,
          periodoId: grupo.periodoId,
          institucionId: grupo.institucionId,
          createdAt: grupo.createdAt.toISOString(),
          periodoAcademico: {
            id: grupo.periodoAcademico.id,
            nombre: grupo.periodoAcademico.nombre,
            fechaInicio: grupo.periodoAcademico.fechaInicio.toISOString(),
            fechaFin: grupo.periodoAcademico.fechaFin.toISOString(),
            activo: grupo.periodoAcademico.activo,
          },
          _count: grupo._count,
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
      console.error('Error al obtener grupos:', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener los grupos');
    }
  }

  /**
   * Obtiene un grupo por ID
   */
  public static async getGrupoById(id: string): Promise<GrupoResponse | null> {
    try {
      const grupo = await prisma.grupo.findUnique({
        where: { id },
        include: {
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              fechaInicio: true,
              fechaFin: true,
              activo: true,
            },
          },
          _count: {
            select: {
              estudiantesGrupos: true,
              horarios: true,
            },
          },
        },
      });

      if (!grupo) {
        return null;
      }

      return {
        id: grupo.id,
        nombre: grupo.nombre,
        grado: grupo.grado,
        seccion: grupo.seccion,
        periodoId: grupo.periodoId,
        institucionId: grupo.institucionId,
        createdAt: grupo.createdAt.toISOString(),
        periodoAcademico: {
          id: grupo.periodoAcademico.id,
          nombre: grupo.periodoAcademico.nombre,
          fechaInicio: grupo.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: grupo.periodoAcademico.fechaFin.toISOString(),
          activo: grupo.periodoAcademico.activo,
        },
        _count: grupo._count,
      };
    } catch (error) {
      console.error('Error al obtener grupo:', error);
      throw new Error('Error al obtener el grupo');
    }
  }

  /**
   * Crea un nuevo grupo
   */
  public static async createGrupo(data: CreateGrupoRequest): Promise<GrupoResponse> {
    try {
      // Validaciones de campos requeridos
      if (!data.nombre || data.nombre.trim() === '') {
        throw new ValidationError('El nombre del grupo es requerido');
      }
      if (!data.grado || data.grado.trim() === '') {
        throw new ValidationError('El grado del grupo es requerido');
      }

      // Validar que el periodo académico existe y pertenece a la institución
      const periodo = await prisma.periodoAcademico.findFirst({
        where: {
          id: data.periodoId,
          institucionId: data.institucionId,
        },
      });

      if (!periodo) {
        throw new ValidationError('El periodo académico no existe o no pertenece a esta institución');
      }

      // Validar que no exista un grupo con el mismo nombre en el mismo periodo
      const existingGrupo = await prisma.grupo.findFirst({
        where: {
          nombre: data.nombre.trim(),
          periodoId: data.periodoId,
          institucionId: data.institucionId,
        },
      });

      if (existingGrupo) {
        throw new ConflictError('Ya existe un grupo con este nombre en el periodo académico seleccionado');
      }

      const grupo = await prisma.grupo.create({
        data: {
          nombre: data.nombre.trim(),
          grado: data.grado.trim(),
          seccion: data.seccion?.trim() || null,
          periodoId: data.periodoId,
          institucionId: data.institucionId,
        },
        include: {
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              fechaInicio: true,
              fechaFin: true,
              activo: true,
            },
          },
          _count: {
            select: {
              estudiantesGrupos: true,
              horarios: true,
            },
          },
        },
      });

      return {
        id: grupo.id,
        nombre: grupo.nombre,
        grado: grupo.grado,
        seccion: grupo.seccion,
        periodoId: grupo.periodoId,
        institucionId: grupo.institucionId,
        createdAt: grupo.createdAt.toISOString(),
        periodoAcademico: {
          id: grupo.periodoAcademico.id,
          nombre: grupo.periodoAcademico.nombre,
          fechaInicio: grupo.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: grupo.periodoAcademico.fechaFin.toISOString(),
          activo: grupo.periodoAcademico.activo,
        },
        _count: grupo._count,
      };
    } catch (error) {
      console.error('Error al crear grupo:', error);
      if (error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al crear el grupo');
    }
  }

  /**
   * Actualiza un grupo
   */
  public static async updateGrupo(id: string, data: UpdateGrupoRequest): Promise<GrupoResponse | null> {
    try {
      // Verificar que el grupo existe
      const existingGrupo = await prisma.grupo.findUnique({
        where: { id },
      });

      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      // Si se está cambiando el periodo, validar que existe y pertenece a la institución
      if (data.periodoId && data.periodoId !== existingGrupo.periodoId) {
        const periodo = await prisma.periodoAcademico.findFirst({
          where: {
            id: data.periodoId,
            institucionId: existingGrupo.institucionId,
          },
        });

        if (!periodo) {
          throw new ValidationError('El periodo académico no existe o no pertenece a esta institución');
        }
      }

      // Si se está cambiando el nombre, validar que no exista otro grupo con el mismo nombre en el periodo
      if (data.nombre && data.nombre !== existingGrupo.nombre) {
        const periodoId = data.periodoId || existingGrupo.periodoId;
        const existingGrupoWithName = await prisma.grupo.findFirst({
          where: {
            nombre: data.nombre,
            periodoId: periodoId,
            institucionId: existingGrupo.institucionId,
            id: { not: id },
          },
        });

        if (existingGrupoWithName) {
          throw new ConflictError('Ya existe un grupo con este nombre en el periodo académico seleccionado');
        }
      }

      const grupo = await prisma.grupo.update({
        where: { id },
        data: {
          nombre: data.nombre,
          grado: data.grado,
          seccion: data.seccion,
          periodoId: data.periodoId,
        },
        include: {
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              fechaInicio: true,
              fechaFin: true,
              activo: true,
            },
          },
          _count: {
            select: {
              estudiantesGrupos: true,
              horarios: true,
            },
          },
        },
      });

      return {
        id: grupo.id,
        nombre: grupo.nombre,
        grado: grupo.grado,
        seccion: grupo.seccion,
        periodoId: grupo.periodoId,
        institucionId: grupo.institucionId,
        createdAt: grupo.createdAt.toISOString(),
        periodoAcademico: {
          id: grupo.periodoAcademico.id,
          nombre: grupo.periodoAcademico.nombre,
          fechaInicio: grupo.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: grupo.periodoAcademico.fechaFin.toISOString(),
          activo: grupo.periodoAcademico.activo,
        },
        _count: grupo._count,
      };
    } catch (error) {
      console.error('Error al actualizar grupo:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al actualizar el grupo');
    }
  }

  /**
   * Elimina un grupo
   */
  public static async deleteGrupo(id: string): Promise<boolean> {
    try {
      // Verificar que el grupo existe
      const existingGrupo = await prisma.grupo.findUnique({
        where: { id },
        include: {
          _count: {
            select: {
              estudiantesGrupos: true,
              horarios: true,
              asistencias: true,
            },
          },
        },
      });

      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      // Verificar que no tenga estudiantes asignados
      if (existingGrupo._count.estudiantesGrupos > 0) {
        throw new ValidationError('No se puede eliminar el grupo porque tiene estudiantes asignados');
      }

      // Verificar que no tenga horarios asignados
      if (existingGrupo._count.horarios > 0) {
        throw new ValidationError('No se puede eliminar el grupo porque tiene horarios asignados');
      }

      // Verificar que no tenga asistencias registradas
      if (existingGrupo._count.asistencias > 0) {
        throw new ValidationError('No se puede eliminar el grupo porque tiene asistencias registradas');
      }

      await prisma.grupo.delete({
        where: { id },
      });

      return true;
    } catch (error) {
      console.error('Error al eliminar grupo:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al eliminar el grupo');
    }
  }

  /**
   * Obtiene los grupos disponibles para asignar estudiantes (solo periodos activos)
   */
  public static async getGruposDisponibles(institucionId: string): Promise<GrupoResponse[]> {
    try {
      const grupos = await prisma.grupo.findMany({
        where: {
          institucionId: institucionId,
          periodoAcademico: {
            activo: true,
          },
        },
        orderBy: [
          { grado: 'asc' },
          { seccion: 'asc' },
          { nombre: 'asc' },
        ],
        include: {
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              fechaInicio: true,
              fechaFin: true,
              activo: true,
            },
          },
          _count: {
            select: {
              estudiantesGrupos: true,
              horarios: true,
            },
          },
        },
      });

      return grupos.map((grupo: any) => ({
        id: grupo.id,
        nombre: grupo.nombre,
        grado: grupo.grado,
        seccion: grupo.seccion,
        periodoId: grupo.periodoId,
        institucionId: grupo.institucionId,
        createdAt: grupo.createdAt.toISOString(),
        periodoAcademico: {
          id: grupo.periodoAcademico.id,
          nombre: grupo.periodoAcademico.nombre,
          fechaInicio: grupo.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: grupo.periodoAcademico.fechaFin.toISOString(),
          activo: grupo.periodoAcademico.activo,
        },
        _count: grupo._count,
      }));
    } catch (error) {
      console.error('Error al obtener grupos disponibles:', error);
      throw new Error('Error al obtener los grupos disponibles');
    }
  }
}

export default GrupoService;