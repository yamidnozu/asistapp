
import { PrismaClient } from '@prisma/client';
import { AttendanceStatus, AttendanceType } from '../constants/attendance';
import { AuthorizationError, NotFoundError, UserRole, ValidationError } from '../types';
import { formatDateToISO, getDateRange, getStartOfDay, parseDateString } from '../utils/date.utils';
import logger from '../utils/logger';
import { notificationService } from './notification.service';

const prisma = new PrismaClient();

export interface RegistrarAsistenciaRequest {
  horarioId: string;
  codigoQr: string;
  profesorId: string;
}

export interface AsistenciaResponse {
  id: string;
  fecha: Date;
  estado: string;
  horarioId: string;
  estudianteId: string;
  profesorId: string;
  institucionId: string;
  estudiante: {
    id: string;
    nombres: string;
    apellidos: string;
    identificacion: string;
  };
  horario: {
    id: string;
    diaSemana: number;
    horaInicio: string;
    horaFin: string;
    grupo: {
      id: string;
      nombre: string;
      grado: string;
      seccion: string | null;
    };
    materia: {
      id: string;
      nombre: string;
      codigo: string | null;
    };
  };
}

export interface AsistenciaGrupoResponse {
  estudiante: {
    id: string;
    nombres: string;
    apellidos: string;
    identificacion: string;
  };
  estado: string | null; // null si no ha registrado asistencia
  fechaRegistro?: Date;
}

/**
 * Servicio para gestión de Asistencias
 * Maneja el registro y consulta de asistencias de estudiantes
 */
export class AsistenciaService {

  /**
   * Registra la asistencia de un estudiante mediante código QR
   * Método Principal: registrarAsistencia(datos)
   */
  public static async registrarAsistencia(datos: RegistrarAsistenciaRequest): Promise<AsistenciaResponse> {
    try {
      const { horarioId, codigoQr, profesorId } = datos;

      // 1. Verificar que la clase (horarioId) exista y esté activa
      const horario = await prisma.horario.findUnique({
        where: { id: horarioId },
        include: {
          grupo: true,
          periodoAcademico: true,
          profesor: true,
          institucion: true,
          materia: true, // Agregar materia
        },
      });

      if (!horario) {
        throw new NotFoundError('Horario/Clase');
      }

      if (!horario.periodoAcademico.activo) {
        throw new ValidationError('No se puede registrar asistencia en un periodo académico inactivo');
      }

      // 1.1. VALIDACIÓN CRÍTICA: Verificar que el profesor que registra es el asignado al horario
      if (horario.profesorId && horario.profesorId !== profesorId) {
        throw new AuthorizationError(
          'No tienes autorización para registrar asistencia en esta clase. Solo el profesor asignado puede hacerlo.'
        );
      }

      // 2. Buscar al estudiante por su codigoQr
      const estudiante = await prisma.estudiante.findUnique({
        where: { codigoQr },
        include: {
          usuario: true,
          estudiantesGrupos: {
            include: {
              grupo: true,
            },
          },
        },
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante con el código QR proporcionado');
      }

      // 3. Verificar que el estudiante pertenece al grupo asociado a esa clase
      const perteneceAlGrupo = estudiante.estudiantesGrupos.some(
        (eg: any) => eg.grupoId === horario.grupoId && eg.grupo.periodoId === horario.periodoId
      );

      if (!perteneceAlGrupo) {
        throw new AuthorizationError('El estudiante no pertenece al grupo de esta clase');
      }

      // 4. Verificar si ya existe un registro de asistencia para ese estudiante en esa clase en la fecha actual
      // Usamos getStartOfDay para manejar fechas en UTC consistentemente
      const hoy = getStartOfDay();

      const asistenciaExistente = await prisma.asistencia.findFirst({
        where: {
          horarioId,
          estudianteId: estudiante.id,
          fecha: hoy,
        },
      });

      if (asistenciaExistente) {
        throw new ValidationError('El estudiante ya tiene registrada su asistencia para esta clase hoy');
      }

      // 5. Crear nueva entrada en la tabla Asistencia
      const nuevaAsistencia = await prisma.asistencia.create({
        data: {
          horarioId,
          estudianteId: estudiante.id,
          profesorId,
          institucionId: horario.institucionId,
          estado: AttendanceStatus.PRESENTE,
          fecha: hoy,
          tipoRegistro: AttendanceType.QR,
        },
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
          horario: {
            include: {
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
            },
          },
        },
      }) as any;

      // Trigger Notification (Async)
      notificationService.notifyAttendanceCreated(nuevaAsistencia.id).catch(err => {
        logger.error('Error triggering notification:', err);
      });

      // Formatear respuesta
      return {
        id: nuevaAsistencia.id,
        fecha: nuevaAsistencia.fecha,
        estado: nuevaAsistencia.estado,
        horarioId: nuevaAsistencia.horarioId,
        estudianteId: nuevaAsistencia.estudianteId,
        profesorId: nuevaAsistencia.profesorId,
        institucionId: nuevaAsistencia.institucionId,
        estudiante: {
          id: nuevaAsistencia.estudiante.id,
          nombres: nuevaAsistencia.estudiante.usuario.nombres,
          apellidos: nuevaAsistencia.estudiante.usuario.apellidos,
          identificacion: nuevaAsistencia.estudiante.identificacion,
        },
        horario: {
          id: nuevaAsistencia.horario.id,
          diaSemana: nuevaAsistencia.horario.diaSemana,
          horaInicio: nuevaAsistencia.horario.horaInicio,
          horaFin: nuevaAsistencia.horario.horaFin,
          grupo: {
            id: nuevaAsistencia.horario.grupo.id,
            nombre: nuevaAsistencia.horario.grupo.nombre,
            grado: nuevaAsistencia.horario.grupo.grado,
            seccion: nuevaAsistencia.horario.grupo.seccion,
          },
          materia: {
            id: nuevaAsistencia.horario.materia.id,
            nombre: nuevaAsistencia.horario.materia.nombre,
            codigo: nuevaAsistencia.horario.materia.codigo,
          },
        },
      };
    } catch (error) {
      logger.error('Error al registrar asistencia:', error);
      if (error instanceof ValidationError || error instanceof NotFoundError || error instanceof AuthorizationError) {
        throw error;
      }
      throw new Error('Error al registrar la asistencia');
    }
  }

  /**
   * Devuelve el listado de estudiantes del grupo asociado al horario y su estado de asistencia para el día actual
   */
  public static async getAsistenciasPorHorario(horarioId: string): Promise<AsistenciaGrupoResponse[]> {
    try {
      const hoy = getStartOfDay();

      // Obtener el horario con su grupo
      const horario = await prisma.horario.findUnique({
        where: { id: horarioId },
        include: {
          grupo: {
            include: {
              estudiantesGrupos: {
                include: {
                  estudiante: {
                    include: {
                      usuario: {
                        select: { nombres: true, apellidos: true, identificacion: true },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      });

      if (!horario) {
        throw new NotFoundError('Horario/Clase');
      }

      const estudiantes = horario.grupo.estudiantesGrupos.map((eg: any) => eg.estudiante);

      // Obtener asistencias del día para ese horario
      const asistenciasHoy = await prisma.asistencia.findMany({
        where: { horarioId, fecha: hoy },
      });

      // Mapear estudiantes al formato de respuesta, incluyendo estado si existe
      const resultado: AsistenciaGrupoResponse[] = estudiantes.map((est: any) => {
        const asistencia = asistenciasHoy.find((a: any) => a.estudianteId === est.id);
        return {
          estudiante: {
            id: est.id,
            nombres: est.usuario.nombres,
            apellidos: est.usuario.apellidos,
            identificacion: est.identificacion,
          },
          estado: asistencia ? asistencia.estado : null,
          fechaRegistro: asistencia ? asistencia.fecha : undefined,
        } as AsistenciaGrupoResponse;
      });

      return resultado;
    } catch (error) {
      logger.error('Error en getAsistenciasPorHorario:', error);
      throw new Error('Error al obtener asistencias por horario');
    }
  }

  /**
   * Obtiene las estadísticas de asistencia para un horario específico
   */
  public static async getEstadisticasAsistencia(horarioId: string) {
    try {
      const hoy = getStartOfDay();

      const asistencias = await prisma.asistencia.findMany({
        where: {
          horarioId,
          fecha: hoy,
        },
      });

      const totalEstudiantes = await this.getTotalEstudiantesEnHorario(horarioId);

      const estadisticas = {
        totalEstudiantes,
        presentes: asistencias.filter((a: any) => a.estado === AttendanceStatus.PRESENTE).length,
        ausentes: asistencias.filter((a: any) => a.estado === AttendanceStatus.AUSENTE).length,
        tardanzas: asistencias.filter((a: any) => a.estado === AttendanceStatus.TARDANZA).length,
        justificados: asistencias.filter((a: any) => a.estado === AttendanceStatus.JUSTIFICADO).length,
        sinRegistrar: totalEstudiantes - asistencias.length,
      };

      return estadisticas;
    } catch (error) {
      logger.error('Error al obtener estadísticas de asistencia:', error);
      throw new Error('Error al obtener las estadísticas');
    }
  }

  /**
   * Método auxiliar para obtener el total de estudiantes en un horario
   */
  private static async getTotalEstudiantesEnHorario(horarioId: string): Promise<number> {
    const horario = await prisma.horario.findUnique({
      where: { id: horarioId },
      include: {
        grupo: {
          include: {
            estudiantesGrupos: true,
          },
        },
      },
    });

    return horario?.grupo.estudiantesGrupos.length || 0;
  }

  /**
   * Registra la asistencia de un estudiante manualmente (sin QR)
   * Usado por profesores para marcar presente a un estudiante ausente
   */
  public static async registrarAsistenciaManual(
    horarioId: string,
    estudianteId: string,
    profesorId: string
  ): Promise<AsistenciaResponse> {
    try {
      // 1. Verificar que la clase (horarioId) exista y esté activa
      const horario = await prisma.horario.findUnique({
        where: { id: horarioId },
        include: {
          grupo: true,
          periodoAcademico: true,
          profesor: true,
          institucion: true,
          materia: true,
        },
      });

      if (!horario) {
        throw new NotFoundError('Horario/Clase');
      }

      if (!horario.periodoAcademico.activo) {
        throw new ValidationError('No se puede registrar asistencia en un periodo académico inactivo');
      }

      // 2. Verificar que el estudiante existe
      const estudiante = await prisma.estudiante.findUnique({
        where: { id: estudianteId },
        include: {
          usuario: true,
          estudiantesGrupos: {
            include: {
              grupo: true,
            },
          },
        },
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante');
      }

      // 3. Verificar que el estudiante pertenece al grupo asociado a esa clase
      const perteneceAlGrupo = estudiante.estudiantesGrupos.some(
        (eg: any) => eg.grupoId === horario.grupoId && eg.grupo.periodoId === horario.periodoId
      );

      if (!perteneceAlGrupo) {
        throw new AuthorizationError('El estudiante no pertenece al grupo de esta clase');
      }

      // 4. Verificar si ya existe un registro de asistencia para hoy
      const hoy = getStartOfDay();

      const asistenciaExistente = await prisma.asistencia.findFirst({
        where: {
          horarioId,
          estudianteId: estudiante.id,
          fecha: hoy,
        },
      });

      if (asistenciaExistente) {
        throw new ValidationError('El estudiante ya tiene registrada su asistencia para esta clase hoy');
      }

      // 5. Crear nueva entrada de asistencia
      const nuevaAsistencia = await prisma.asistencia.create({
        data: {
          horarioId,
          estudianteId: estudiante.id,
          profesorId,
          fecha: hoy,
          estado: AttendanceStatus.PRESENTE,
          tipoRegistro: AttendanceType.MANUAL,
          institucionId: horario.institucionId,
        },
      });

      // 6. Cargar datos completos para la respuesta
      const asistenciaCompleta = await prisma.asistencia.findUnique({
        where: { id: nuevaAsistencia.id },
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
          horario: {
            include: {
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
            },
          },
        },
      });

      if (!asistenciaCompleta) {
        throw new Error('Error al recuperar la asistencia creada');
      }

      // Trigger Notification (Async)
      notificationService.notifyAttendanceCreated(asistenciaCompleta.id).catch(err => {
        logger.error('Error triggering notification:', err);
      });

      // 7. Formatear respuesta
      const response: AsistenciaResponse = {
        id: asistenciaCompleta.id,
        fecha: asistenciaCompleta.fecha,
        estado: asistenciaCompleta.estado,
        horarioId: asistenciaCompleta.horarioId,
        estudianteId: asistenciaCompleta.estudianteId,
        profesorId: asistenciaCompleta.profesorId!,
        institucionId: asistenciaCompleta.institucionId,
        estudiante: {
          id: asistenciaCompleta.estudiante.id,
          nombres: asistenciaCompleta.estudiante.usuario.nombres,
          apellidos: asistenciaCompleta.estudiante.usuario.apellidos,
          identificacion: asistenciaCompleta.estudiante.identificacion,
        },
        horario: {
          id: asistenciaCompleta.horario.id,
          diaSemana: asistenciaCompleta.horario.diaSemana,
          horaInicio: asistenciaCompleta.horario.horaInicio,
          horaFin: asistenciaCompleta.horario.horaFin,
          grupo: asistenciaCompleta.horario.grupo,
          materia: asistenciaCompleta.horario.materia,
        },
      };

      return response;
    } catch (error) {
      logger.error('❌ Error en registrarAsistenciaManual:', error);
      throw error;
    }
  }

  /**
   * Obtiene todas las asistencias con filtros opcionales y paginación
   */
  public static async getAllAsistencias(pagination: { page: number; limit: number }, filters: any) {
    try {
      const { page, limit } = pagination;
      const { institucionId, fecha, horarioId, estudianteId, estado } = filters;

      const skip = (page - 1) * limit;

      // Construir where clause
      const where: any = {
        institucionId,
      };

      logger.debug('🔍 getAllAsistencias - Filtros recibidos:', { institucionId, fecha, horarioId, estudianteId, estado });

      if (fecha) {
        // Parsear la fecha en UTC para evitar problemas de zona horaria
        const fechaFiltro = parseDateString(fecha);
        const { start, end } = getDateRange(fechaFiltro);
        where.fecha = {
          gte: start,
          lt: end
        };
        logger.debug('📅 Filtro de fecha aplicado:', { gte: start, lt: end });
      }

      if (horarioId) {
        where.horarioId = horarioId;
      }

      if (estudianteId) {
        where.estudianteId = estudianteId;
      }

      if (estado) {
        where.estado = estado;
      }

      logger.debug('🔍 WHERE final para consulta:', JSON.stringify(where, null, 2));

      // Obtener total de registros
      const total = await prisma.asistencia.count({ where });
      logger.debug('📊 Total de asistencias encontradas:', total);

      // Obtener registros con paginación
      const asistencias = await prisma.asistencia.findMany({
        where,
        skip,
        take: limit,
        orderBy: {
          fecha: 'desc',
        },
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
          horario: {
            include: {
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
            },
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: asistencias.map((asistencia: any) => ({
          id: asistencia.id,
          fecha: formatDateToISO(asistencia.fecha),
          estado: asistencia.estado,
          horarioId: asistencia.horarioId,
          estudianteId: asistencia.estudianteId,
          profesorId: asistencia.profesorId,
          institucionId: asistencia.institucionId,
          estudiante: {
            id: asistencia.estudiante.id,
            nombres: asistencia.estudiante.usuario.nombres,
            apellidos: asistencia.estudiante.usuario.apellidos,
          },
          horario: {
            id: asistencia.horario.id,
            diaSemana: asistencia.horario.diaSemana,
            horaInicio: asistencia.horario.horaInicio,
            horaFin: asistencia.horario.horaFin,
            materia: {
              id: asistencia.horario.materia.id,
              nombre: asistencia.horario.materia.nombre,
            },
            grupo: {
              id: asistencia.horario.grupo.id,
              nombre: asistencia.horario.grupo.nombre,
            },
          },
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
      logger.error('Error al obtener todas las asistencias:', error);
      throw new Error('Error al obtener las asistencias');
    }
  }

  /**
   * Obtiene las asistencias de un estudiante específico con paginación y filtros opcionales
   */
  public static async getAsistenciasByEstudiante(
    estudianteId: string,
    pagination: { page: number; limit: number },
    filters: { fecha?: string }
  ) {
    try {
      const { page, limit } = pagination;
      const { fecha } = filters;

      const skip = (page - 1) * limit;

      // Construir where clause
      const where: any = {
        estudianteId,
      };

      if (fecha) {
        const fechaFiltro = parseDateString(fecha);
        where.fecha = getStartOfDay(fechaFiltro);
      }

      // Obtener total de registros
      const total = await prisma.asistencia.count({ where });

      // Obtener registros con paginación
      const asistencias = await prisma.asistencia.findMany({
        where,
        skip,
        take: limit,
        orderBy: {
          fecha: 'desc',
        },
        include: {
          horario: {
            include: {
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
            },
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: asistencias.map((asistencia: any) => ({
          id: asistencia.id,
          fecha: formatDateToISO(asistencia.fecha),
          estado: asistencia.estado,
          horarioId: asistencia.horarioId,
          estudianteId: asistencia.estudianteId,
          profesorId: asistencia.profesorId,
          institucionId: asistencia.institucionId,
          horario: {
            id: asistencia.horario.id,
            diaSemana: asistencia.horario.diaSemana,
            horaInicio: asistencia.horario.horaInicio,
            horaFin: asistencia.horario.horaFin,
            materia: {
              id: asistencia.horario.materia.id,
              nombre: asistencia.horario.materia.nombre,
              codigo: asistencia.horario.materia.codigo,
            },
            grupo: {
              id: asistencia.horario.grupo.id,
              nombre: asistencia.horario.grupo.nombre,
              grado: asistencia.horario.grupo.grado,
              seccion: asistencia.horario.grupo.seccion,
            },
            profesor: asistencia.horario.profesor ? {
              id: asistencia.horario.profesor.id,
              nombres: asistencia.horario.profesor.nombres,
              apellidos: asistencia.horario.profesor.apellidos,
            } : null,
          },
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
      logger.error('Error al obtener asistencias del estudiante:', error);
      throw new Error('Error al obtener las asistencias del estudiante');
    }
  }

  /**
   * Actualiza una asistencia existente (estado, justificación, observación)
   */
  public static async updateAsistencia(
    id: string,
    data: { estado?: AttendanceStatus; observacion?: string; justificada?: boolean },
    profesorId: string,
    rol: string
  ): Promise<AsistenciaResponse> {
    try {
      // 1. Buscar la asistencia
      const asistencia = await prisma.asistencia.findUnique({
        where: { id },
        include: {
          horario: true,
        },
      });

      if (!asistencia) {
        throw new NotFoundError('Asistencia');
      }

      // 2. Verificar permisos
      // Si es profesor, debe ser el profesor de la clase
      if (rol === UserRole.PROFESOR) {
        if (asistencia.horario.profesorId !== profesorId && asistencia.profesorId !== profesorId) {
          throw new AuthorizationError('No tienes permiso para editar esta asistencia');
        }
      }

      // 3. Actualizar asistencia
      const asistenciaActualizada = await prisma.asistencia.update({
        where: { id },
        data: {
          estado: data.estado,
          observaciones: data.observacion, // Map observacion to observaciones
          // justificada: data.justificada, // 'justificada' is not in schema
        },
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
          horario: {
            include: {
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
            },
          },
        },
      });

      // 4. Formatear respuesta
      // Use 'any' cast to avoid strict type checking issues with included relations if inference fails
      const result: any = asistenciaActualizada;

      return {
        id: result.id,
        fecha: result.fecha,
        estado: result.estado,
        horarioId: result.horarioId,
        estudianteId: result.estudianteId,
        profesorId: result.profesorId!,
        institucionId: result.institucionId,
        estudiante: {
          id: result.estudiante.id,
          nombres: result.estudiante.usuario.nombres,
          apellidos: result.estudiante.usuario.apellidos,
          identificacion: result.estudiante.identificacion,
        },
        horario: {
          id: result.horario.id,
          diaSemana: result.horario.diaSemana,
          horaInicio: result.horario.horaInicio,
          horaFin: result.horario.horaFin,
          grupo: result.horario.grupo,
          materia: result.horario.materia,
        },
      };
    } catch (error) {
      logger.error('Error al actualizar asistencia:', error);
      if (error instanceof NotFoundError || error instanceof AuthorizationError) {
        throw error;
      }
      throw new Error('Error al actualizar la asistencia');
    }
  }
}

export default AsistenciaService;