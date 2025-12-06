import { prisma } from '../config/database';
import { ConflictError, NotFoundError, PaginatedResponse, PaginationParams, ValidationError } from '../types';
import logger from '../utils/logger';

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

export interface EstudianteGrupoResponse {
  id: string;
  nombres: string;
  apellidos: string;
  usuario?: {
    id: string;
    nombres: string;
    apellidos: string;
    email?: string;
    activo?: boolean;
    createdAt?: string;
  } | null;
  identificacion: string;
  telefonoResponsable: string | null;
  createdAt: string;
  asignadoAt: string; // Fecha de asignación al grupo
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
        where.OR = [
          { nombre: { contains: filters.search, mode: 'insensitive' } },
          { grado: { contains: filters.search, mode: 'insensitive' } },
          { seccion: { contains: filters.search, mode: 'insensitive' } },
        ];
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
      logger.error('Error al obtener grupos:', error);
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
      logger.error('Error al obtener grupo:', error);
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
      logger.error('Error al crear grupo:', error);
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
      logger.error('Error al actualizar grupo:', error);
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
          estudiantesGrupos: true,
          horarios: {
            include: {
              asistencias: {
                select: {
                  id: true,
                },
                take: 1, // Solo necesitamos saber si existe al menos una
              },
            },
          },
        },
      });

      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      // Verificar que no tenga estudiantes asignados
      if (existingGrupo.estudiantesGrupos.length > 0) {
        throw new ValidationError('No se puede eliminar el grupo porque tiene estudiantes asignados');
      }

      // Verificar que no tenga horarios asignados
      if (existingGrupo.horarios.length > 0) {
        throw new ValidationError('No se puede eliminar el grupo porque tiene horarios asignados');
      }

      // Verificar que no tenga asistencias registradas (a través de horarios)
      const tieneAsistencias = existingGrupo.horarios.some((horario: any) => horario.asistencias.length > 0);
      if (tieneAsistencias) {
        throw new ValidationError('No se puede eliminar el grupo porque tiene asistencias registradas');
      }

      await prisma.grupo.delete({
        where: { id },
      });

      return true;
    } catch (error) {
      logger.error('Error al eliminar grupo:', error);
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
      logger.error('Error al obtener grupos disponibles:', error);
      throw new Error('Error al obtener los grupos disponibles');
    }
  }

  /**
   * Activa/desactiva un grupo cambiando su periodo académico
   */
  public static async toggleGrupoStatus(id: string): Promise<GrupoResponse | null> {
    try {
      // Obtener el grupo actual
      const grupo = await prisma.grupo.findUnique({
        where: { id },
        include: {
          periodoAcademico: true,
          _count: {
            select: {
              estudiantesGrupos: true,
              horarios: true,
            },
          },
        },
      });

      if (!grupo) {
        throw new NotFoundError('Grupo');
      }

      // Cambiar el periodo académico activo por uno inactivo o viceversa
      const nuevoPeriodo = await prisma.periodoAcademico.findFirst({
        where: {
          institucionId: grupo.institucionId,
          activo: !grupo.periodoAcademico.activo,
        },
        orderBy: {
          fechaInicio: 'desc',
        },
      });

      // Si no hay periodo alternativo, el grupo ya está en el estado correcto
      if (!nuevoPeriodo) {
        // En lugar de devolver el grupo, devolver null para indicar que no se cambió nada
        // El controlador debe manejar este caso como éxito
        return null;
      }

      // Actualizar el grupo con el nuevo periodo
      const grupoActualizado = await prisma.grupo.update({
        where: { id },
        data: {
          periodoId: nuevoPeriodo.id,
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
        id: grupoActualizado.id,
        nombre: grupoActualizado.nombre,
        grado: grupoActualizado.grado,
        seccion: grupoActualizado.seccion,
        periodoId: grupoActualizado.periodoId,
        institucionId: grupoActualizado.institucionId,
        createdAt: grupoActualizado.createdAt.toISOString(),
        periodoAcademico: {
          id: grupoActualizado.periodoAcademico.id,
          nombre: grupoActualizado.periodoAcademico.nombre,
          fechaInicio: grupoActualizado.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: grupoActualizado.periodoAcademico.fechaFin.toISOString(),
          activo: grupoActualizado.periodoAcademico.activo,
        },
        _count: grupoActualizado._count,
      };
    } catch (error) {
      logger.error('Error al cambiar status del grupo:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al cambiar el status del grupo');
    }
  }

  /**
   * Obtiene los estudiantes asignados a un grupo específico
   */
  public static async getEstudiantesByGrupo(grupoId: string, pagination?: PaginationParams): Promise<PaginatedResponse<EstudianteGrupoResponse>> {
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

      // Verificar que el grupo existe
      const grupo = await prisma.grupo.findUnique({
        where: { id: grupoId },
        select: { id: true, institucionId: true },
      });

      if (!grupo) {
        throw new NotFoundError('Grupo');
      }

      // Obtener total de estudiantes asignados
      const total = await prisma.estudianteGrupo.count({
        where: { grupoId: grupoId },
      });

      // Obtener estudiantes asignados con paginación
      const estudiantesGrupos = await prisma.estudianteGrupo.findMany({
        where: { grupoId: grupoId },
        skip,
        take: limit,
        orderBy: [
          { createdAt: 'asc' }, // Ordenar por fecha de asignación
        ],
        include: {
          estudiante: {
            include: {
              usuario: {
                select: {
                  nombres: true,
                  apellidos: true,
                },
              },
            },
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: estudiantesGrupos.map((eg: any) => ({
          id: eg.estudiante.id,
          nombres: eg.estudiante.usuario.nombres,
          apellidos: eg.estudiante.usuario.apellidos,
          usuario: {
            id: eg.estudiante.usuario.id,
            nombres: eg.estudiante.usuario.nombres,
            apellidos: eg.estudiante.usuario.apellidos,
            email: eg.estudiante.usuario.email,
            activo: eg.estudiante.usuario.activo,
            createdAt: eg.estudiante.usuario.createdAt?.toISOString?.(),
          },
          identificacion: eg.estudiante.identificacion,
          telefonoResponsable: eg.estudiante.telefonoResponsable,
          createdAt: eg.estudiante.createdAt.toISOString(),
          asignadoAt: eg.createdAt.toISOString(),
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
      logger.error('Error al obtener estudiantes del grupo:', error);
      if (error instanceof ValidationError || error instanceof NotFoundError) {
        throw error;
      }
      throw new Error('Error al obtener los estudiantes del grupo');
    }
  }

  /**
   * Obtiene estudiantes sin asignar a ningún grupo en el período académico activo
   */
  public static async getEstudiantesSinAsignar(institucionId: string, pagination?: PaginationParams, search?: string): Promise<PaginatedResponse<EstudianteGrupoResponse>> {
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

      // Obtener el período académico activo de la institución
      const periodoActivo = await prisma.periodoAcademico.findFirst({
        where: {
          institucionId: institucionId,
          activo: true,
        },
      });

      if (!periodoActivo) {
        // Si no hay período activo, devolver lista vacía
        return {
          data: [],
          pagination: {
            page,
            limit,
            total: 0,
            totalPages: 0,
            hasNext: false,
            hasPrev: false,
          },
        };
      }

      // Construir filtro de búsqueda
      const searchFilter: any = {};
      if (search) {
        searchFilter.OR = [
          { usuario: { nombres: { contains: search, mode: 'insensitive' } } },
          { usuario: { apellidos: { contains: search, mode: 'insensitive' } } },
          { identificacion: { contains: search, mode: 'insensitive' } },
        ];
      }

      const whereClause = {
        usuario: {
          usuarioInstituciones: {
            some: {
              institucionId: institucionId,
              activo: true,
            },
          },
        },
        estudiantesGrupos: {
          none: {
            grupo: {
              periodoId: periodoActivo.id,
            },
          },
        },
        ...searchFilter,
      };

      // Obtener estudiantes de la institución que no están asignados a ningún grupo del período activo
      const estudiantesQuery = await prisma.estudiante.findMany({
        where: whereClause,
        include: {
          usuario: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
              email: true,
              activo: true,
              createdAt: true,
            },
          },
        },
        skip,
        take: limit,
        orderBy: [
          { usuario: { apellidos: 'asc' } },
          { usuario: { nombres: 'asc' } },
        ],
      });

      // Obtener el total de estudiantes sin asignar
      const total = await prisma.estudiante.count({
        where: whereClause,
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: estudiantesQuery.map((estudiante: any) => ({
          id: estudiante.id,
          nombres: estudiante.usuario.nombres,
          apellidos: estudiante.usuario.apellidos,
          usuario: {
            id: estudiante.usuario.id,
            nombres: estudiante.usuario.nombres,
            apellidos: estudiante.usuario.apellidos,
            email: estudiante.usuario.email,
            activo: estudiante.usuario.activo,
            createdAt: estudiante.usuario.createdAt?.toISOString?.(),
          },
          identificacion: estudiante.identificacion,
          telefonoResponsable: estudiante.telefonoResponsable,
          createdAt: estudiante.createdAt.toISOString(),
          asignadoAt: new Date().toISOString(), // No aplica para estudiantes sin asignar
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
      logger.error('Error al obtener estudiantes sin grupo:', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener los estudiantes sin grupo');
    }
  }

  /**
   * Asigna un estudiante a un grupo
   */
  public static async asignarEstudiante(grupoId: string, estudianteId: string): Promise<boolean> {
    try {
      // Verificar que el grupo existe
      const grupo = await prisma.grupo.findUnique({
        where: { id: grupoId },
        select: { id: true, institucionId: true, periodoId: true },
      });

      if (!grupo) {
        throw new NotFoundError('Grupo');
      }

      // Verificar que el estudiante existe y pertenece a la misma institución
      const estudiante = await prisma.estudiante.findFirst({
        where: { id: estudianteId },
        include: {
          usuario: {
            include: {
              usuarioInstituciones: {
                where: { activo: true },
                select: { institucionId: true },
              },
            },
          },
        },
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante');
      }

      // Obtener la institución del estudiante
      const estudianteInstitucionId = estudiante.usuario.usuarioInstituciones[0]?.institucionId;
      if (!estudianteInstitucionId) {
        throw new ValidationError('El estudiante no tiene una institución asignada');
      }

      if (estudianteInstitucionId !== grupo.institucionId) {
        throw new ValidationError('El estudiante y el grupo deben pertenecer a la misma institución');
      }

      // Verificar que el estudiante no esté ya asignado a este grupo
      const asignacionExistente = await prisma.estudianteGrupo.findFirst({
        where: {
          estudianteId: estudianteId,
          grupoId: grupoId,
        },
      });

      if (asignacionExistente) {
        throw new ConflictError('El estudiante ya está asignado a este grupo');
      }

      // Verificar que el estudiante no esté asignado a otro grupo del mismo período
      const asignacionPeriodo = await prisma.estudianteGrupo.findFirst({
        where: {
          estudianteId: estudianteId,
          grupo: {
            periodoId: grupo.periodoId,
          },
        },
      });

      if (asignacionPeriodo) {
        throw new ConflictError('El estudiante ya está asignado a otro grupo en este período académico');
      }

      // Crear la asignación
      await prisma.estudianteGrupo.create({
        data: {
          estudianteId: estudianteId,
          grupoId: grupoId,
        },
      });

      return true;
    } catch (error) {
      logger.error('Error al asignar estudiante al grupo:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al asignar el estudiante al grupo');
    }
  }

  /**
   * Desasigna un estudiante de un grupo
   */
  public static async desasignarEstudiante(grupoId: string, estudianteId: string): Promise<boolean> {
    try {
      // Verificar que la asignación existe
      const asignacion = await prisma.estudianteGrupo.findFirst({
        where: {
          estudianteId: estudianteId,
          grupoId: grupoId,
        },
      });

      if (!asignacion) {
        throw new NotFoundError('Asignación de estudiante a grupo');
      }

      // Eliminar la asignación
      await prisma.estudianteGrupo.deleteMany({
        where: {
          estudianteId: estudianteId,
          grupoId: grupoId,
        },
      });

      return true;
    } catch (error) {
      logger.error('Error al desasignar estudiante del grupo:', error);
      if (error instanceof NotFoundError) {
        throw error;
      }
      throw new Error('Error al desasignar el estudiante del grupo');
    }
  }
}

export default GrupoService;