import { FastifyInstance } from 'fastify';
import { UserRole } from '../constants/roles';
import { EstudianteController } from '../controllers/estudiante.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function estudianteRoutes(fastify: FastifyInstance) {

  fastify.register(async function (estudianteRoutes) {

    estudianteRoutes.addHook('preHandler', authenticate);
    estudianteRoutes.addHook('preHandler', authorize([UserRole.ESTUDIANTE]));

    estudianteRoutes.get('/dashboard/clases-hoy', {
      handler: EstudianteController.getClasesHoy as any,
      schema: {
        description: 'Obtiene las clases que el estudiante tiene hoy',
        tags: ['Estudiantes - Dashboard'],
        summary: 'Clases del día',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    diaSemana: { type: 'number' },
                    horaInicio: { type: 'string' },
                    horaFin: { type: 'string' },
                    materia: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        codigo: { type: 'string' }
                      }
                    },
                    profesor: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombres: { type: 'string' },
                        apellidos: { type: 'string' }
                      }
                    },
                    grupo: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        grado: { type: 'string' },
                        seccion: { type: 'string' }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    });

    estudianteRoutes.get('/dashboard/horario-semanal', {
      handler: EstudianteController.getHorarioSemanal as any,
      schema: {
        description: 'Obtiene el horario semanal completo del estudiante',
        tags: ['Estudiantes - Dashboard'],
        summary: 'Horario semanal',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: {
                type: 'object',
                patternProperties: {
                  '^[1-7]$': {
                    type: 'array',
                    items: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        diaSemana: { type: 'number' },
                        horaInicio: { type: 'string' },
                        horaFin: { type: 'string' },
                        materia: { type: 'object' },
                        profesor: { type: 'object' },
                        grupo: { type: 'object' }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    });

    estudianteRoutes.get('/dashboard/notificaciones', {
      handler: EstudianteController.getNotificaciones as any,
      schema: {
        description: 'Obtiene las notificaciones del estudiante',
        tags: ['Estudiantes - Dashboard'],
        summary: 'Notificaciones',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    titulo: { type: 'string' },
                    mensaje: { type: 'string' },
                    tipo: { type: 'string' },
                    fecha: { type: 'string' },
                    leida: { type: 'boolean' },
                    importante: { type: 'boolean' }
                  }
                }
              }
            }
          }
        }
      }
    });

    estudianteRoutes.get('/dashboard/clases/:diaSemana', {
      handler: EstudianteController.getClasesPorDia as any,
      schema: {
        description: 'Obtiene las clases de un día específico para el estudiante',
        tags: ['Estudiantes - Dashboard'],
        summary: 'Clases por día',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            diaSemana: {
              type: 'string',
              pattern: '^[1-7]$',
              description: 'Día de la semana (1=Lunes, 7=Domingo)'
            }
          },
          required: ['diaSemana']
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: { type: 'array' }
            }
          }
        }
      }
    });

    // Información del estudiante
    estudianteRoutes.get('/perfil', {
      handler: EstudianteController.getPerfil as any,
      schema: {
        description: 'Obtiene el perfil del estudiante',
        tags: ['Estudiantes'],
        summary: 'Perfil del estudiante',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: { type: 'object' }
            }
          }
        }
      }
    });

    estudianteRoutes.get('/grupos', {
      handler: EstudianteController.getGrupos as any,
      schema: {
        description: 'Obtiene los grupos del estudiante',
        tags: ['Estudiantes'],
        summary: 'Grupos del estudiante',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: { type: 'array' }
            }
          }
        }
      }
    });

    estudianteRoutes.get('/me', {
      handler: EstudianteController.getMyInfo as any,
      schema: {
        description: 'Obtiene la información del estudiante autenticado incluyendo código QR',
        tags: ['Estudiantes'],
        summary: 'Información del estudiante',
        security: [{ bearerAuth: [] }],
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
              data: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  usuarioId: { type: 'string' },
                  identificacion: { type: 'string' },
                  codigoQr: { type: 'string' },
                  nombreResponsable: { type: 'string', nullable: true },
                  telefonoResponsable: { type: 'string', nullable: true },
                  usuario: {
                    type: 'object',
                    properties: {
                      id: { type: 'string' },
                      nombres: { type: 'string' },
                      apellidos: { type: 'string' },
                      email: { type: 'string' },
                      rol: { type: 'string' }
                    }
                  },
                  createdAt: { type: 'string' },
                  updatedAt: { type: 'string' }
                }
              }
            }
          }
        }
      }
    });

  });

  console.log('✅ Rutas del estudiante registradas exitosamente');
}