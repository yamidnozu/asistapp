import { config } from '../config/app';
import { prisma } from '../config/database';
import { ConflictError, NotFoundError, PaginatedResponse, PaginationParams, ValidationError } from '../types';
import logger from '../utils/logger';
import { validateTimeFormat } from '../utils/time-validation';

export interface HorarioFilters {
  grupoId?: string;
  materiaId?: string;
  profesorId?: string;
  diaSemana?: number;
}

export interface CreateHorarioRequest {
  periodoId: string;
  grupoId: string;
  materiaId: string;
  profesorId?: string;
  diaSemana: number;
  horaInicio: string;
  horaFin: string;
  institucionId: string;
}

export interface UpdateHorarioRequest {
  grupoId?: string;
  materiaId?: string;
  profesorId?: string;
  diaSemana?: number;
  horaInicio?: string;
  horaFin?: string;
}

export interface HorarioResponse {
  id: string;
  periodoId: string;
  grupoId: string;
  materiaId: string;
  profesorId: string | null;
  diaSemana: number;
  horaInicio: string;
  horaFin: string;
  institucionId: string;
  createdAt: string;
  periodoAcademico: {
    id: string;
    nombre: string;
    fechaInicio: string;
    fechaFin: string;
    activo: boolean;
  };
  grupo: {
    id: string;
    nombre: string;
    grado: string;
    seccion: string | null;
    institucionId?: string;
    periodoId?: string;
    createdAt?: string;
    periodoAcademico?: {
      id: string;
      nombre: string;
      fechaInicio: string;
      fechaFin: string;
      activo: boolean;
    } | null;
  };
  materia: {
    id: string;
    nombre: string;
    codigo: string | null;
  };
  profesor?: {
    id: string;
    nombres: string;
    apellidos: string;
  } | null;
  _count?: {
    asistencias: number;
  };
}

export class HorarioService {
  /**
   * Obtiene todos los horarios de una institución con paginación y filtros
   */
  public static async getAllHorariosByInstitucion(
    institucionId: string,
    pagination?: PaginationParams,
    filters?: HorarioFilters
  ): Promise<PaginatedResponse<HorarioResponse>> {
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

      if (filters?.grupoId) {
        where.grupoId = filters.grupoId;
      }
      if (filters?.materiaId) {
        where.materiaId = filters.materiaId;
      }
      if (filters?.profesorId) {
        where.profesorId = filters.profesorId;
      }
      if (filters?.diaSemana !== undefined) {
        where.diaSemana = filters.diaSemana;
      }

      // Obtener total de registros
      const total = await prisma.horario.count({ where });

      // Obtener registros paginados
      const horarios = await prisma.horario.findMany({
        where,
        skip,
        take: limit,
        orderBy: [
          { diaSemana: 'asc' },
          { horaInicio: 'asc' },
          { grupo: { nombre: 'asc' } },
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
          grupo: {
            select: {
              id: true,
              nombre: true,
              grado: true,
              seccion: true,
              periodoAcademico: {
                select: {
                  id: true,
                  nombre: true,
                  fechaInicio: true,
                  fechaFin: true,
                  activo: true,
                },
              },
              institucionId: true,
              periodoId: true,
              createdAt: true,
            },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
            },
          },
          _count: {
            select: {
              asistencias: true,
            },
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: horarios.map((horario: any) => ({
          id: horario.id,
          periodoId: horario.periodoId,
          grupoId: horario.grupoId,
          materiaId: horario.materiaId,
          profesorId: horario.profesorId,
          diaSemana: horario.diaSemana,
          horaInicio: horario.horaInicio,
          horaFin: horario.horaFin,
          institucionId: horario.institucionId,
          createdAt: horario.createdAt.toISOString(),
          periodoAcademico: {
            id: horario.periodoAcademico.id,
            nombre: horario.periodoAcademico.nombre,
            fechaInicio: horario.periodoAcademico.fechaInicio.toISOString(),
            fechaFin: horario.periodoAcademico.fechaFin.toISOString(),
            activo: horario.periodoAcademico.activo,
          },
          grupo: {
            id: horario.grupo.id,
            nombre: horario.grupo.nombre,
            grado: horario.grupo.grado,
            seccion: horario.grupo.seccion,
            institucionId: horario.grupo.institucionId,
            periodoId: horario.grupo.periodoId,
            createdAt: horario.grupo.createdAt?.toISOString(),
            periodoAcademico: horario.grupo.periodoAcademico ? {
              id: horario.grupo.periodoAcademico.id,
              nombre: horario.grupo.periodoAcademico.nombre,
              fechaInicio: horario.grupo.periodoAcademico.fechaInicio.toISOString(),
              fechaFin: horario.grupo.periodoAcademico.fechaFin.toISOString(),
              activo: horario.grupo.periodoAcademico.activo,
            } : null,
          },
          materia: {
            id: horario.materia.id,
            nombre: horario.materia.nombre,
            codigo: horario.materia.codigo,
          },
          profesor: horario.profesor ? {
            id: horario.profesor.id,
            nombres: horario.profesor.nombres,
            apellidos: horario.profesor.apellidos,
          } : null,
          _count: horario._count,
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
      logger.error('Error al obtener horarios', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener los horarios');
    }
  }

  /**
   * Obtiene los horarios de un grupo específico
   */
  public static async getHorariosByGrupo(grupoId: string): Promise<HorarioResponse[]> {
    try {
      const horarios = await prisma.horario.findMany({
        where: { grupoId },
        orderBy: [
          { diaSemana: 'asc' },
          { horaInicio: 'asc' },
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
          grupo: {
              select: {
                id: true,
                nombre: true,
                grado: true,
                seccion: true,
                periodoAcademico: {
                  select: {
                    id: true,
                    nombre: true,
                    fechaInicio: true,
                    fechaFin: true,
                    activo: true,
                  },
                },
                institucionId: true,
                periodoId: true,
                createdAt: true,
              },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
            },
          },
          _count: {
            select: {
              asistencias: true,
            },
          },
        },
      });

      return horarios.map((horario: any) => ({
        id: horario.id,
        periodoId: horario.periodoId,
        grupoId: horario.grupoId,
        materiaId: horario.materiaId,
        profesorId: horario.profesorId,
        diaSemana: horario.diaSemana,
        horaInicio: horario.horaInicio,
        horaFin: horario.horaFin,
        institucionId: horario.institucionId,
        createdAt: horario.createdAt.toISOString(),
        periodoAcademico: {
          id: horario.periodoAcademico.id,
          nombre: horario.periodoAcademico.nombre,
          fechaInicio: horario.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: horario.periodoAcademico.fechaFin.toISOString(),
          activo: horario.periodoAcademico.activo,
        },
        grupo: {
          id: horario.grupo.id,
          nombre: horario.grupo.nombre,
          grado: horario.grupo.grado,
          seccion: horario.grupo.seccion,
          institucionId: horario.grupo.institucionId,
          periodoId: horario.grupo.periodoId,
          createdAt: horario.grupo.createdAt?.toISOString(),
          periodoAcademico: horario.grupo.periodoAcademico ? {
            id: horario.grupo.periodoAcademico.id,
            nombre: horario.grupo.periodoAcademico.nombre,
            fechaInicio: horario.grupo.periodoAcademico.fechaInicio.toISOString(),
            fechaFin: horario.grupo.periodoAcademico.fechaFin.toISOString(),
            activo: horario.grupo.periodoAcademico.activo,
          } : null,
        },
        materia: {
          id: horario.materia.id,
          nombre: horario.materia.nombre,
          codigo: horario.materia.codigo,
        },
        profesor: horario.profesor ? {
          id: horario.profesor.id,
          nombres: horario.profesor.nombres,
          apellidos: horario.profesor.apellidos,
        } : null,
        _count: horario._count,
      }));
    } catch (error) {
      logger.error('Error al obtener horarios del grupo:', error);
      throw new Error('Error al obtener los horarios del grupo');
    }
  }

  /**
   * Obtiene un horario por ID
   */
  public static async getHorarioById(id: string): Promise<HorarioResponse | null> {
    try {
      const horario = await prisma.horario.findUnique({
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
          grupo: {
              select: {
                id: true,
                nombre: true,
                grado: true,
                seccion: true,
                periodoAcademico: {
                  select: {
                    id: true,
                    nombre: true,
                    fechaInicio: true,
                    fechaFin: true,
                    activo: true,
                  },
                },
                institucionId: true,
                periodoId: true,
                createdAt: true,
              },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
            },
          },
          _count: {
            select: {
              asistencias: true,
            },
          },
        },
      });

      if (!horario) {
        return null;
      }

      return {
        id: horario.id,
        periodoId: horario.periodoId,
        grupoId: horario.grupoId,
        materiaId: horario.materiaId,
        profesorId: horario.profesorId,
        diaSemana: horario.diaSemana,
        horaInicio: horario.horaInicio,
        horaFin: horario.horaFin,
        institucionId: horario.institucionId,
        createdAt: horario.createdAt.toISOString(),
        periodoAcademico: {
          id: horario.periodoAcademico.id,
          nombre: horario.periodoAcademico.nombre,
          fechaInicio: horario.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: horario.periodoAcademico.fechaFin.toISOString(),
          activo: horario.periodoAcademico.activo,
        },
        grupo: {
          id: horario.grupo.id,
          nombre: horario.grupo.nombre,
          grado: horario.grupo.grado,
          seccion: horario.grupo.seccion,
        },
        materia: {
          id: horario.materia.id,
          nombre: horario.materia.nombre,
          codigo: horario.materia.codigo,
        },
        profesor: horario.profesor ? {
          id: horario.profesor.id,
          nombres: horario.profesor.nombres,
          apellidos: horario.profesor.apellidos,
        } : null,
        _count: horario._count,
      };
    } catch (error) {
      logger.error('Error al obtener horario:', error);
      throw new Error('Error al obtener el horario');
    }
  }

  /**
   * ✅ OPTIMIZADO: Valida conflictos de horario DIRECTAMENTE en la base de datos
   * Usa $queryRaw con comparación de TIME en PostgreSQL para máxima eficiencia
   * 
   * Lógica de solapamiento:
   * Dos horarios se solapan si:
   * - El nuevo empieza ANTES de que termine el existente Y
   * - El nuevo termina DESPUÉS de que empiece el existente
   * 
   * En SQL: horaInicio < existente.horaFin AND horaFin > existente.horaInicio
   */
  private static async validateHorarioConflict(
    grupoId: string,
    profesorId: string | null,
    diaSemana: number,
    horaInicio: string,
    horaFin: string,
    excludeId?: string
  ): Promise<void> {
    // Validar formato de hora (HH:MM)
    const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
    if (!timeRegex.test(horaInicio) || !timeRegex.test(horaFin)) {
      throw new ValidationError('El formato de hora debe ser HH:MM');
    }

    // Validar que horaInicio < horaFin (conversión simple a minutos)
    const [inicioHoras, inicioMinutos] = horaInicio.split(':').map(Number);
    const [finHoras, finMinutos] = horaFin.split(':').map(Number);
    const inicioTotalMinutos = inicioHoras * 60 + inicioMinutos;
    const finTotalMinutos = finHoras * 60 + finMinutos;
    
    if (inicioTotalMinutos >= finTotalMinutos) {
      throw new ValidationError('La hora de inicio debe ser anterior a la hora de fin');
    }

    // Validar que diaSemana esté en rango 1-7
    if (diaSemana < 1 || diaSemana > 7) {
      throw new ValidationError('El día de la semana debe estar entre 1 (Lunes) y 7 (Domingo)');
    }

    // ✅ OPTIMIZACIÓN: Query única con comparación de TIME en PostgreSQL
    // La base de datos hace toda la lógica de solapamiento
    interface ConflictoHorario {
      id: string;
      horaInicio: string;
      horaFin: string;
      grupoId: string;
      profesorId: string | null;
      tipo: 'grupo' | 'profesor';
    }

    // Construir query SQL con UNION para grupo y profesor
    const grupoQuery = excludeId
      ? `SELECT id, "horaInicio", "horaFin", "grupoId", "profesorId", 'grupo' as tipo
         FROM "Horario"
         WHERE "grupoId" = $1
           AND "diaSemana" = $2
           AND id != $3
           AND "horaInicio"::TIME < $5::TIME
           AND "horaFin"::TIME > $4::TIME`
      : `SELECT id, "horaInicio", "horaFin", "grupoId", "profesorId", 'grupo' as tipo
         FROM "Horario"
         WHERE "grupoId" = $1
           AND "diaSemana" = $2
           AND "horaInicio"::TIME < $4::TIME
           AND "horaFin"::TIME > $3::TIME`;

    const profesorQuery = profesorId
      ? excludeId
        ? `SELECT id, "horaInicio", "horaFin", "grupoId", "profesorId", 'profesor' as tipo
           FROM "Horario"
           WHERE "profesorId" = $6
             AND "diaSemana" = $2
             AND id != $3
             AND "horaInicio"::TIME < $5::TIME
             AND "horaFin"::TIME > $4::TIME`
        : `SELECT id, "horaInicio", "horaFin", "grupoId", "profesorId", 'profesor' as tipo
           FROM "Horario"
           WHERE "profesorId" = $5
             AND "diaSemana" = $2
             AND "horaInicio"::TIME < $4::TIME
             AND "horaFin"::TIME > $3::TIME`
      : '';

    const fullQuery = profesorQuery
      ? `${grupoQuery} UNION ${profesorQuery}`
      : grupoQuery;

    // Preparar parámetros según el caso
    let params: any[];
    if (excludeId) {
      params = profesorId
        ? [grupoId, diaSemana, excludeId, horaInicio, horaFin, profesorId]
        : [grupoId, diaSemana, excludeId, horaInicio, horaFin];
    } else {
      params = profesorId
        ? [grupoId, diaSemana, horaInicio, horaFin, profesorId]
        : [grupoId, diaSemana, horaInicio, horaFin];
    }

    // Ejecutar query optimizada
    const conflictos = await prisma.$queryRawUnsafe(
      fullQuery,
      ...params
    ) as ConflictoHorario[];

    // Clasificar conflictos por tipo
    const grupoConflicts = conflictos.filter((c: ConflictoHorario) => c.tipo === 'grupo');
    const profesorConflicts = conflictos.filter((c: ConflictoHorario) => c.tipo === 'profesor');

    // Lanzar error si hay conflictos (priorizar grupo sobre profesor)
    if (grupoConflicts.length > 0) {
      throw new ConflictError(
        'El grupo ya tiene una clase programada en este horario',
        'grupo_conflict',
        {
          conflictingHorarioIds: grupoConflicts.map((c: ConflictoHorario) => c.id),
          detalles: grupoConflicts.map((c: ConflictoHorario) => ({
            id: c.id,
            horario: `${c.horaInicio} - ${c.horaFin}`,
          })),
        }
      );
    }

    if (profesorConflicts.length > 0) {
      throw new ConflictError(
        'El profesor ya tiene una clase programada en este horario',
        'profesor_conflict',
        {
          conflictingHorarioIds: profesorConflicts.map((c: ConflictoHorario) => c.id),
          detalles: profesorConflicts.map((c: ConflictoHorario) => ({
            id: c.id,
            horario: `${c.horaInicio} - ${c.horaFin}`,
          })),
        }
      );
    }
  }

  /**
   * Crea un nuevo horario
   */
  public static async createHorario(data: CreateHorarioRequest): Promise<HorarioResponse> {
    try {
      if (config.nodeEnv === 'development') {
        logger.debug('🔍 DEBUG: Iniciando createHorario con data:', JSON.stringify(data, null, 2));
      }

      validateTimeFormat(data.horaInicio, data.horaFin);

      // Validar que el periodo académico existe y pertenece a la institución
      if (config.nodeEnv === 'development') {
        logger.debug('🔍 DEBUG: Validando periodo académico...');
      }
      const periodo = await prisma.periodoAcademico.findFirst({
        where: {
          id: data.periodoId,
          institucionId: data.institucionId,
        },
      });

      if (!periodo) {
        if (config.nodeEnv === 'development') {
          logger.debug('❌ DEBUG: Periodo no encontrado o no pertenece a institución');
        }
        throw new ValidationError('El periodo académico no existe o no pertenece a esta institución');
      }
      if (config.nodeEnv === 'development') {
        logger.debug('✅ DEBUG: Periodo válido:', periodo.nombre);
      }

      // Validar que el grupo existe y pertenece a la institución y periodo
      if (config.nodeEnv === 'development') {
        logger.debug('🔍 DEBUG: Validando grupo...');
      }
      const grupo = await prisma.grupo.findFirst({
        where: {
          id: data.grupoId,
          institucionId: data.institucionId,
        },
      });

      if (!grupo) {
        if (config.nodeEnv === 'development') {
          logger.debug('❌ DEBUG: Grupo no encontrado o no pertenece a institución');
        }
        throw new ValidationError('El grupo seleccionado no existe o no pertenece a esta institución');
      }
      if (grupo.periodoId !== data.periodoId) { // <-- Validación clave
        throw new ValidationError('El grupo no pertenece al período académico seleccionado.');
      }
      if (config.nodeEnv === 'development') {
        logger.debug('✅ DEBUG: Grupo válido:', grupo.nombre);
      }

      // Validar que la materia existe y pertenece a la institución
      if (config.nodeEnv === 'development') {
        logger.debug('🔍 DEBUG: Validando materia...');
      }
      const materia = await prisma.materia.findFirst({
        where: {
          id: data.materiaId,
          institucionId: data.institucionId,
        },
      });

      if (!materia) {
        if (config.nodeEnv === 'development') {
          logger.debug('❌ DEBUG: Materia no encontrada o no pertenece a institución');
        }
        throw new ValidationError('La materia no existe o no pertenece a esta institución');
      }
      if (config.nodeEnv === 'development') {
        logger.debug('✅ DEBUG: Materia válida:', materia.nombre);
      }

      // Si hay profesor asignado, validar que existe y es profesor
      if (data.profesorId) {
        if (config.nodeEnv === 'development') {
          logger.debug('🔍 DEBUG: Validando profesor...');
        }
        const profesor = await prisma.usuario.findFirst({
          where: {
            id: data.profesorId,
            rol: 'profesor',
            usuarioInstituciones: {
              some: {
                institucionId: data.institucionId,
                activo: true,
              },
            },
          },
        });

        if (!profesor) {
          if (config.nodeEnv === 'development') {
            logger.debug('❌ DEBUG: Profesor no encontrado o no pertenece a institución');
          }
          throw new ValidationError('El profesor no existe o no pertenece a esta institución');
        }
        if (config.nodeEnv === 'development') {
          logger.debug('✅ DEBUG: Profesor válido:', { nombres: profesor.nombres, apellidos: profesor.apellidos });
        }
      } else {
        if (config.nodeEnv === 'development') {
          logger.debug('ℹ️ DEBUG: No hay profesor asignado (permitido)');
        }
      }

      // Validar conflictos de horario
      if (config.nodeEnv === 'development') {
        logger.debug('🔍 DEBUG: Validando conflictos de horario...');
      }
      await this.validateHorarioConflict(
        data.grupoId,
        data.profesorId || null,
        data.diaSemana,
        data.horaInicio,
        data.horaFin
      );
      if (config.nodeEnv === 'development') {
        logger.debug('✅ DEBUG: No hay conflictos de horario');
        logger.debug('🔍 DEBUG: Creando horario en base de datos...');
      }
      const horario = await prisma.horario.create({
        data: {
          periodoId: data.periodoId,
          grupoId: data.grupoId,
          materiaId: data.materiaId,
          profesorId: data.profesorId,
          diaSemana: data.diaSemana,
          horaInicio: data.horaInicio,
          horaFin: data.horaFin,
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
          grupo: {
            select: {
              id: true,
              nombre: true,
              grado: true,
              seccion: true,
            },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
            },
          },
          _count: {
            select: {
              asistencias: true,
            },
          },
        },
      });
      if (config.nodeEnv === 'development') {
        logger.debug('✅ DEBUG: Horario creado exitosamente en BD');
      }

      return {
        id: horario.id,
        periodoId: horario.periodoId,
        grupoId: horario.grupoId,
        materiaId: horario.materiaId,
        profesorId: horario.profesorId,
        diaSemana: horario.diaSemana,
        horaInicio: horario.horaInicio,
        horaFin: horario.horaFin,
        institucionId: horario.institucionId,
        createdAt: horario.createdAt.toISOString(),
        periodoAcademico: {
          id: horario.periodoAcademico.id,
          nombre: horario.periodoAcademico.nombre,
          fechaInicio: horario.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: horario.periodoAcademico.fechaFin.toISOString(),
          activo: horario.periodoAcademico.activo,
        },
        grupo: {
          id: horario.grupo.id,
          nombre: horario.grupo.nombre,
          grado: horario.grupo.grado,
          seccion: horario.grupo.seccion,
        },
        materia: {
          id: horario.materia.id,
          nombre: horario.materia.nombre,
          codigo: horario.materia.codigo,
        },
        profesor: horario.profesor ? {
          id: horario.profesor.id,
          nombres: horario.profesor.nombres,
          apellidos: horario.profesor.apellidos,
        } : null,
        _count: horario._count,
      };
    } catch (error) {
      logger.error('❌ Error al crear horario:', error);
      logger.error('❌ Stack trace:', (error as Error).stack);
      if (error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al crear el horario');
    }
  }

  /**
   * Actualiza un horario
   */
  public static async updateHorario(id: string, data: UpdateHorarioRequest): Promise<HorarioResponse | null> {
    try {
      // Verificar que el horario existe
      const existingHorario = await prisma.horario.findUnique({
        where: { id },
      });

      if (!existingHorario) {
        throw new NotFoundError('Horario');
      }

      // Preparar datos para validación
      const grupoId = data.grupoId || existingHorario.grupoId;
      const profesorId = data.profesorId !== undefined ? data.profesorId : existingHorario.profesorId;
      const diaSemana = data.diaSemana !== undefined ? data.diaSemana : existingHorario.diaSemana;
      const horaInicio = data.horaInicio || existingHorario.horaInicio;
      const horaFin = data.horaFin || existingHorario.horaFin;

      // Si se está cambiando el grupo, validar que existe
      if (data.grupoId && data.grupoId !== existingHorario.grupoId) {
        const grupo = await prisma.grupo.findFirst({
          where: {
            id: data.grupoId,
            institucionId: existingHorario.institucionId,
            periodoId: existingHorario.periodoId,
          },
        });

        if (!grupo) {
          throw new ValidationError('El grupo no existe o no pertenece a esta institución y periodo');
        }
      }

      // Si se está cambiando la materia, validar que existe
      if (data.materiaId && data.materiaId !== existingHorario.materiaId) {
        const materia = await prisma.materia.findFirst({
          where: {
            id: data.materiaId,
            institucionId: existingHorario.institucionId,
          },
        });

        if (!materia) {
          throw new ValidationError('La materia no existe o no pertenece a esta institución');
        }
      }

      // Si se está cambiando el profesor, validar que existe
      if (data.profesorId !== undefined && data.profesorId !== existingHorario.profesorId) {
        if (data.profesorId) {
          const profesor = await prisma.usuario.findFirst({
            where: {
              id: data.profesorId,
              rol: 'profesor',
              usuarioInstituciones: {
                some: {
                  institucionId: existingHorario.institucionId,
                  activo: true,
                },
              },
            },
          });

          if (!profesor) {
            throw new ValidationError('El profesor no existe o no pertenece a esta institución');
          }
        }
      }

      // Validar conflictos de horario
      validateTimeFormat(horaInicio, horaFin);
      await this.validateHorarioConflict(
        grupoId,
        profesorId,
        diaSemana,
        horaInicio,
        horaFin,
        id
      );

      const horario = await prisma.horario.update({
        where: { id },
        data: {
          grupoId: data.grupoId,
          materiaId: data.materiaId,
          profesorId: data.profesorId,
          diaSemana: data.diaSemana,
          horaInicio: data.horaInicio,
          horaFin: data.horaFin,
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
          grupo: {
            select: {
              id: true,
              nombre: true,
              grado: true,
              seccion: true,
            },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
            },
          },
          _count: {
            select: {
              asistencias: true,
            },
          },
        },
      });

      return {
        id: horario.id,
        periodoId: horario.periodoId,
        grupoId: horario.grupoId,
        materiaId: horario.materiaId,
        profesorId: horario.profesorId,
        diaSemana: horario.diaSemana,
        horaInicio: horario.horaInicio,
        horaFin: horario.horaFin,
        institucionId: horario.institucionId,
        createdAt: horario.createdAt.toISOString(),
        periodoAcademico: {
          id: horario.periodoAcademico.id,
          nombre: horario.periodoAcademico.nombre,
          fechaInicio: horario.periodoAcademico.fechaInicio.toISOString(),
          fechaFin: horario.periodoAcademico.fechaFin.toISOString(),
          activo: horario.periodoAcademico.activo,
        },
        grupo: {
          id: horario.grupo.id,
          nombre: horario.grupo.nombre,
          grado: horario.grupo.grado,
          seccion: horario.grupo.seccion,
        },
        materia: {
          id: horario.materia.id,
          nombre: horario.materia.nombre,
          codigo: horario.materia.codigo,
        },
        profesor: horario.profesor ? {
          id: horario.profesor.id,
          nombres: horario.profesor.nombres,
          apellidos: horario.profesor.apellidos,
        } : null,
        _count: horario._count,
      };
    } catch (error) {
      logger.error('Error al actualizar horario:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al actualizar el horario');
    }
  }

  /**
   * Elimina un horario
   */
  public static async deleteHorario(id: string): Promise<boolean> {
    try {
      // Verificar que el horario existe
      const existingHorario = await prisma.horario.findUnique({
        where: { id },
        include: {
          _count: {
            select: {
              asistencias: true,
            },
          },
        },
      });

      if (!existingHorario) {
        throw new NotFoundError('Horario');
      }

      // Verificar que no tenga asistencias registradas
      if (existingHorario._count.asistencias > 0) {
        throw new ValidationError('No se puede eliminar el horario porque tiene asistencias registradas');
      }

      await prisma.horario.delete({
        where: { id },
      });

      return true;
    } catch (error) {
      logger.error('Error al eliminar horario:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al eliminar el horario');
    }
  }
}

export default HorarioService;


