import { FastifyReply } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import { NotFoundError, ValidationError } from '../types';

export class EstudianteController {
  /**
   * Obtiene las clases de hoy para el estudiante
   */
  public static async getClasesHoy(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const user = request.user;
      if (!user) {
        throw new ValidationError('Usuario no autenticado');
      }

      // Obtener estudiante
      const estudiante = await prisma.estudiante.findUnique({
        where: { usuarioId: user.id },
        include: {
          usuario: {
            include: {
              usuarioInstituciones: {
                include: { institucion: true }
              }
            }
          }
        }
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante');
      }

      // Obtener día actual (1=Lunes, 7=Domingo)
      const today = new Date().getDay() || 7;

      // Obtener clases de hoy
      const clasesHoy = await prisma.horario.findMany({
        where: {
          diaSemana: today,
          institucionId: estudiante.usuario.usuarioInstituciones[0]?.institucionId,
          grupo: {
            estudiantesGrupos: {
              some: {
                estudianteId: estudiante.id
              }
            }
          }
        },
        include: {
          materia: true,
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true
            }
          },
          grupo: true
        },
        orderBy: {
          horaInicio: 'asc'
        }
      });

      return reply.code(200).send({
        success: true,
        data: clasesHoy,
        message: `Clases del día ${today}`
      });

    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene el horario semanal completo del estudiante
   */
  public static async getHorarioSemanal(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const user = request.user;
      if (!user) {
        throw new ValidationError('Usuario no autenticado');
      }

      // Obtener estudiante
      const estudiante = await prisma.estudiante.findUnique({
        where: { usuarioId: user.id },
        include: {
          usuario: {
            include: {
              usuarioInstituciones: {
                include: { institucion: true }
              }
            }
          }
        }
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante');
      }

      // Obtener todas las clases de la semana
      const horarioSemanal = await prisma.horario.findMany({
        where: {
          institucionId: estudiante.usuario.usuarioInstituciones[0]?.institucionId,
          grupo: {
            estudiantesGrupos: {
              some: {
                estudianteId: estudiante.id
              }
            }
          }
        },
        include: {
          materia: true,
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true
            }
          },
          grupo: true
        },
        orderBy: [
          { diaSemana: 'asc' },
          { horaInicio: 'asc' }
        ]
      });

      // Organizar por día de la semana
      const horarioPorDia: { [key: number]: any[] } = {};
      for (let dia = 1; dia <= 7; dia++) {
        horarioPorDia[dia] = horarioSemanal.filter((h: any) => h.diaSemana === dia);
      }

      return reply.code(200).send({
        success: true,
        data: horarioPorDia
      });

    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene las clases de un día específico para el estudiante
   */
  public static async getClasesPorDia(request: AuthenticatedRequest & { params: { diaSemana: string } }, reply: FastifyReply) {
    try {
      const user = request.user;
      const { diaSemana } = request.params;

      if (!user) {
        throw new ValidationError('Usuario no autenticado');
      }

      const dia = parseInt(diaSemana);
      if (dia < 1 || dia > 7) {
        throw new ValidationError('Día de semana inválido (1-7)');
      }

      // Obtener estudiante
      const estudiante = await prisma.estudiante.findUnique({
        where: { usuarioId: user.id },
        include: {
          usuario: {
            include: {
              usuarioInstituciones: {
                include: { institucion: true }
              }
            }
          }
        }
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante');
      }

      // Obtener clases del día
      const clasesDia = await prisma.horario.findMany({
        where: {
          diaSemana: dia,
          institucionId: estudiante.usuario.usuarioInstituciones[0]?.institucionId,
          grupo: {
            estudiantesGrupos: {
              some: {
                estudianteId: estudiante.id
              }
            }
          }
        },
        include: {
          materia: true,
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true
            }
          },
          grupo: true
        },
        orderBy: {
          horaInicio: 'asc'
        }
      });

      return reply.code(200).send({
        success: true,
        data: clasesDia,
        message: `Clases del día ${dia}`
      });

    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene el perfil del estudiante
   */
  public static async getPerfil(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const user = request.user;
      if (!user) {
        throw new ValidationError('Usuario no autenticado');
      }

      const estudiante = await prisma.estudiante.findUnique({
        where: { usuarioId: user.id },
        include: {
          usuario: {
            include: {
              usuarioInstituciones: {
                include: {
                  institucion: true
                }
              }
            }
          }
        }
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante');
      }

      return reply.code(200).send({
        success: true,
        data: estudiante
      });

    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene los grupos del estudiante
   */
  public static async getGrupos(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const user = request.user;
      if (!user) {
        throw new ValidationError('Usuario no autenticado');
      }

      const estudiante = await prisma.estudiante.findUnique({
        where: { usuarioId: user.id }
      });

      if (!estudiante) {
        throw new NotFoundError('Estudiante');
      }

      const grupos = await prisma.estudianteGrupo.findMany({
        where: {
          estudianteId: estudiante.id
        },
        include: {
          grupo: {
            include: {
              periodoAcademico: true,
              _count: {
                select: {
                  estudiantesGrupos: true,
                  horarios: true
                }
              }
            }
          }
        }
      });

      return reply.code(200).send({
        success: true,
        data: grupos.map((eg: any) => eg.grupo)
      });

    } catch (error) {
      throw error;
    }
  }
}