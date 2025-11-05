import { FastifyInstance } from 'fastify';
import { ProfesorController } from '../controllers/profesor.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function profesorRoutes(fastify: FastifyInstance) {

  fastify.register(async function (profesorRoutes) {

    profesorRoutes.addHook('preHandler', authenticate);
    profesorRoutes.addHook('preHandler', authorize(['profesor']));

    profesorRoutes.get('/dashboard/clases-hoy', {
      handler: ProfesorController.getClasesDelDia as any,
      schema: {
        description: 'Obtiene las clases que el profesor tiene hoy',
        tags: ['Profesores - Dashboard'],
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
                    diaSemana: { type: 'number', minimum: 1, maximum: 7 },
                    horaInicio: { type: 'string', format: 'time' },
                    horaFin: { type: 'string', format: 'time' },
                    grupo: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        grado: { type: 'string' },
                        seccion: { type: 'string', nullable: true },
                      },
                    },
                    materia: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        codigo: { type: 'string', nullable: true },
                      },
                    },
                    periodoAcademico: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        activo: { type: 'boolean' },
                      },
                    },
                    institucion: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                      },
                    },
                  },
                },
              },
              message: { type: 'string' },
            },
          },
          401: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
          403: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
          500: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
        },
      },
    });

    profesorRoutes.get('/dashboard/clases/:diaSemana', {
      handler: ProfesorController.getClasesPorDia as any,
      schema: {
        description: 'Obtiene las clases que el profesor tiene en un día específico de la semana',
        tags: ['Profesores - Dashboard'],
        summary: 'Clases por día de la semana',
        security: [{ bearerAuth: [] }],
        params: {
          type: 'object',
          properties: {
            diaSemana: {
              type: 'string',
              pattern: '^[1-7]$',
              description: 'Día de la semana (1=Lunes, 2=Martes, ..., 7=Domingo)',
            },
          },
          required: ['diaSemana'],
        },
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
                    diaSemana: { type: 'number', minimum: 1, maximum: 7 },
                    horaInicio: { type: 'string', format: 'time' },
                    horaFin: { type: 'string', format: 'time' },
                    grupo: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        grado: { type: 'string' },
                        seccion: { type: 'string', nullable: true },
                      },
                    },
                    materia: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        codigo: { type: 'string', nullable: true },
                      },
                    },
                    periodoAcademico: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        activo: { type: 'boolean' },
                      },
                    },
                    institucion: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                      },
                    },
                  },
                },
              },
              message: { type: 'string' },
            },
          },
          400: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
          401: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
          403: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
          500: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
        },
      },
    });

    profesorRoutes.get('/dashboard/horario-semanal', {
      handler: ProfesorController.getHorarioSemanal as any,
      schema: {
        description: 'Obtiene el horario semanal completo del profesor',
        tags: ['Profesores - Dashboard'],
        summary: 'Horario semanal completo',
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
                        diaSemana: { type: 'number', minimum: 1, maximum: 7 },
                        horaInicio: { type: 'string', format: 'time' },
                        horaFin: { type: 'string', format: 'time' },
                        grupo: {
                          type: 'object',
                          properties: {
                            id: { type: 'string' },
                            nombre: { type: 'string' },
                            grado: { type: 'string' },
                            seccion: { type: 'string', nullable: true },
                          },
                        },
                        materia: {
                          type: 'object',
                          properties: {
                            id: { type: 'string' },
                            nombre: { type: 'string' },
                            codigo: { type: 'string', nullable: true },
                          },
                        },
                        periodoAcademico: {
                          type: 'object',
                          properties: {
                            id: { type: 'string' },
                            nombre: { type: 'string' },
                            activo: { type: 'boolean' },
                          },
                        },
                        institucion: {
                          type: 'object',
                          properties: {
                            id: { type: 'string' },
                            nombre: { type: 'string' },
                          },
                        },
                      },
                    },
                  },
                },
              },
              message: { type: 'string' },
            },
          },
          401: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
          403: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
          500: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
        },
      },
    });
  });
}