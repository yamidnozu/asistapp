import { PrismaClient } from '@prisma/client';
import { AuthorizationError, NotFoundError, ValidationError } from '../types';

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
      const hoy = new Date();
      hoy.setHours(0, 0, 0, 0); // Inicio del día

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
          estado: 'PRESENTE',
          fecha: hoy,
          tipoRegistro: 'QR',
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
      console.error('Error al registrar asistencia:', error);
      if (error instanceof ValidationError || error instanceof NotFoundError || error instanceof AuthorizationError) {
        throw error;
      }
      throw new Error('Error al registrar la asistencia');
    }
  }

  /**
   * Obtiene la lista de asistencias para un horario específico en la fecha actual
   * Incluye todos los estudiantes del grupo con su estado de asistencia
   */
  public static async getAsistenciasPorHorario(horarioId: string, profesorId: string): Promise<AsistenciaGrupoResponse[]> {
    try {
      // 1. Obtener el horario con su grupo y profesor
      const horario = await prisma.horario.findUnique({
        where: { id: horarioId },
        include: {
          grupo: {
            include: {
              estudiantesGrupos: {
                include: {
                  estudiante: {
                    include: {
                      usuario: true,
                    },
                  },
                },
              },
            },
          },
          profesor: true,
        },
      });

      if (!horario) {
        throw new NotFoundError('Horario/Clase');
      }

      // 2. Verificar que el profesor que hace la petición sea el profesor asignado al horario
      if (horario.profesorId !== profesorId) {
        throw new AuthorizationError('No tienes permisos para acceder a las asistencias de esta clase');
      }

      // 3. Obtener todos los estudiantes del grupo
      const estudiantesDelGrupo = horario.grupo.estudiantesGrupos.map((eg: any) => eg.estudiante);

      // 3. Obtener todos los registros de asistencia para ese horarioId en la fecha de hoy
      const hoy = new Date();
      hoy.setHours(0, 0, 0, 0); // Inicio del día

      const asistenciasHoy = await prisma.asistencia.findMany({
        where: {
          horarioId,
          fecha: hoy,
        },
      });

      // 4. Crear mapa de asistencias por estudianteId para búsqueda rápida
      const asistenciasMap = new Map(
        asistenciasHoy.map((asistencia: any) => [asistencia.estudianteId, asistencia])
      );

      // 5. Combinar estudiantes con sus estados de asistencia
      return estudiantesDelGrupo.map((estudiante: any) => {
        const asistencia = asistenciasMap.get(estudiante.id);

        return {
          estudiante: {
            id: estudiante.id,
            nombres: estudiante.usuario.nombres,
            apellidos: estudiante.usuario.apellidos,
            identificacion: estudiante.identificacion,
          },
          estado: asistencia ? (asistencia as any).estado : null,
          fechaRegistro: asistencia ? (asistencia as any).fecha : undefined,
        };
      });
    } catch (error) {
      console.error('Error al obtener asistencias por horario:', error);
      if (error instanceof NotFoundError) {
        throw error;
      }
      throw new Error('Error al obtener las asistencias');
    }
  }

  /**
   * Obtiene las estadísticas de asistencia para un horario específico
   */
  public static async getEstadisticasAsistencia(horarioId: string) {
    try {
      const hoy = new Date();
      hoy.setHours(0, 0, 0, 0);

      const asistencias = await prisma.asistencia.findMany({
        where: {
          horarioId,
          fecha: hoy,
        },
      });

      const totalEstudiantes = await this.getTotalEstudiantesEnHorario(horarioId);

      const estadisticas = {
        totalEstudiantes,
        presentes: asistencias.filter((a: any) => a.estado === 'PRESENTE').length,
        ausentes: asistencias.filter((a: any) => a.estado === 'AUSENTE').length,
        tardanzas: asistencias.filter((a: any) => a.estado === 'TARDANZA').length,
        justificados: asistencias.filter((a: any) => a.estado === 'JUSTIFICADO').length,
        sinRegistrar: totalEstudiantes - asistencias.length,
      };

      return estadisticas;
    } catch (error) {
      console.error('Error al obtener estadísticas de asistencia:', error);
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
      const hoy = new Date();
      hoy.setHours(0, 0, 0, 0);

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
          estado: 'PRESENTE',
          tipoRegistro: 'MANUAL',
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
      console.error('❌ Error en registrarAsistenciaManual:', error);
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

      console.log('🔍 getAllAsistencias - Filtros recibidos:', { institucionId, fecha, horarioId, estudianteId, estado });

      if (fecha) {
        // Parsear la fecha en UTC para evitar problemas de zona horaria
        const [year, month, day] = fecha.split('-').map(Number);
        const fechaFiltro = new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
        where.fecha = {
          gte: fechaFiltro,
          lt: new Date(fechaFiltro.getTime() + 24 * 60 * 60 * 1000) // Siguiente día
        };
        console.log('📅 Filtro de fecha aplicado:', { gte: fechaFiltro, lt: new Date(fechaFiltro.getTime() + 24 * 60 * 60 * 1000) });
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

      console.log('🔍 WHERE final para consulta:', JSON.stringify(where, null, 2));

      // Obtener total de registros
      const total = await prisma.asistencia.count({ where });
      console.log('📊 Total de asistencias encontradas:', total);

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
                },
              },
              materia: {
                select: {
                  id: true,
                  nombre: true,
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
          fecha: asistencia.fecha.toISOString().split('T')[0],
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
      console.error('Error al obtener todas las asistencias:', error);
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
        const fechaFiltro = new Date(fecha);
        fechaFiltro.setHours(0, 0, 0, 0);
        where.fecha = fechaFiltro;
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
          fecha: asistencia.fecha.toISOString().split('T')[0],
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
      console.error('Error al obtener asistencias del estudiante:', error);
      throw new Error('Error al obtener las asistencias del estudiante');
    }
  }
}

export default AsistenciaService;