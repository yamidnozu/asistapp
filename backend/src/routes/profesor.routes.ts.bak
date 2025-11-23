import { FastifyInstance } from 'fastify';
import { ProfesorController } from '../controllers/profesor.controller';
import { authenticate, AuthenticatedRequest } from '../middleware/auth';

export default async function profesorRoutes(fastify: FastifyInstance) {

  fastify.register(async function (profesorRoutes) {

    profesorRoutes.addHook('preHandler', authenticate);
    // Removido: profesorRoutes.addHook('preHandler', authorize(['profesor']));

    profesorRoutes.get('/dashboard/clases-hoy', {
      handler: async (request: AuthenticatedRequest, reply) => {
        console.log('🔍 GET /profesores/dashboard/clases-hoy - Verificando usuario:', request.user?.rol);
        
        if (!request.user) {
          console.log('❌ No hay usuario autenticado');
          return reply.code(401).send({
            success: false,
            error: 'Usuario no autenticado',
            code: 'AUTHENTICATION_ERROR',
          });
        }

        if (request.user.rol !== 'profesor') {
          console.log(`❌ Usuario con rol '${request.user.rol}' intentando acceder a dashboard profesor`);
          return reply.code(403).send({
            success: false,
            error: 'Acceso denegado: se requiere rol de profesor',
            code: 'AUTHORIZATION_ERROR',
          });
        }

        console.log('✅ Autorización exitosa, llamando al controlador');
        return ProfesorController.getClasesDelDia(request as any, reply);
      },
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
      handler: async (request: AuthenticatedRequest, reply) => {
        console.log('🔍 GET /profesores/dashboard/clases/:diaSemana - Verificando usuario:', request.user?.rol);
        
        if (!request.user) {
          console.log('❌ No hay usuario autenticado');
          return reply.code(401).send({
            success: false,
            error: 'Usuario no autenticado',
            code: 'AUTHENTICATION_ERROR',
          });
        }

        if (request.user.rol !== 'profesor') {
          console.log(`❌ Usuario con rol '${request.user.rol}' intentando acceder a dashboard profesor`);
          return reply.code(403).send({
            success: false,
            error: 'Acceso denegado: se requiere rol de profesor',
            code: 'AUTHORIZATION_ERROR',
          });
        }

        console.log('✅ Autorización exitosa, llamando al controlador');
        return ProfesorController.getClasesPorDia(request as any, reply);
      },
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
      handler: async (request: AuthenticatedRequest, reply) => {
        console.log('🔍 GET /profesores/dashboard/horario-semanal - Verificando usuario:', request.user?.rol);
        
        if (!request.user) {
          console.log('❌ No hay usuario autenticado');
          return reply.code(401).send({
            success: false,
            error: 'Usuario no autenticado',
            code: 'AUTHENTICATION_ERROR',
          });
        }

        if (request.user.rol !== 'profesor') {
          console.log(`❌ Usuario con rol '${request.user.rol}' intentando acceder a dashboard profesor`);
          return reply.code(403).send({
            success: false,
            error: 'Acceso denegado: se requiere rol de profesor',
            code: 'AUTHORIZATION_ERROR',
          });
        }

        console.log('✅ Autorización exitosa, llamando al controlador');
        return ProfesorController.getHorarioSemanal(request as any, reply);
      },
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