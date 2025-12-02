import { FastifyInstance } from 'fastify';
import { UserRole } from '../constants/roles';
import AsistenciaController from '../controllers/asistencia.controller';
import HorarioController from '../controllers/horario.controller';
import { authenticate, AuthenticatedRequest, authorize } from '../middleware/auth';

console.log('🔄 Cargando rutas de horario...');

export default async function horarioRoutes(fastify: FastifyInstance) {

  fastify.register(async function (horarioRoutes) {
    console.log('📅 horario.routes.ts - REGISTER EJECUTADO');

    /**
     * GET /horarios
     * Obtiene todos los horarios de la institución del admin autenticado
     */
    horarioRoutes.get('/', {
      preHandler: authenticate,
      handler: async (request: AuthenticatedRequest, reply) => {
        console.log('🔍 GET /horarios - Verificando usuario:', request.user?.rol);

        if (!request.user) {
          console.log('❌ No hay usuario autenticado');
          return reply.code(401).send({
            success: false,
            error: 'Usuario no autenticado',
            code: 'AUTHENTICATION_ERROR',
          });
        }

        if (request.user.rol !== 'admin_institucion') {
          console.log(`❌ Usuario con rol '${request.user.rol}' intentando acceder a horarios`);
          return reply.code(403).send({
            success: false,
            error: 'Acceso denegado: se requiere rol de administrador de institución',
            code: 'AUTHORIZATION_ERROR',
          });
        }

        console.log('✅ Autorización exitosa, llamando al controlador');
        return HorarioController.getAll(request as any, reply);
      },
      schema: {
        description: 'Obtener todos los horarios de la institución',
        tags: ['Horarios'],
        querystring: {
          type: 'object',
          properties: {
            page: { type: 'string', description: 'Número de página' },
            limit: { type: 'string', description: 'Elementos por página' },
            grupoId: { type: 'string', description: 'Filtrar por grupo' },
            materiaId: { type: 'string', description: 'Filtrar por materia' },
            profesorId: { type: 'string', description: 'Filtrar por profesor' },
            diaSemana: { type: 'string', description: 'Filtrar por día de la semana (1-7)' },
          },
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
                    periodoId: { type: 'string' },
                    grupoId: { type: 'string' },
                    materiaId: { type: 'string' },
                    profesorId: { type: 'string', nullable: true },
                    diaSemana: { type: 'number' },
                    horaInicio: { type: 'string' },
                    horaFin: { type: 'string' },
                    institucionId: { type: 'string' },
                    createdAt: { type: 'string' },
                    periodoAcademico: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        fechaInicio: { type: 'string' },
                        fechaFin: { type: 'string' },
                        activo: { type: 'boolean' },
                      },
                    },
                    grupo: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        grado: { type: 'string' },
                        seccion: { type: 'string', nullable: true },
                        periodoAcademico: {
                          type: 'object',
                          properties: {
                            id: { type: 'string' },
                            nombre: { type: 'string' },
                            fechaInicio: { type: 'string' },
                            fechaFin: { type: 'string' },
                            activo: { type: 'boolean' },
                          },
                        },
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
                    profesor: {
                      type: 'object',
                      nullable: true,
                      properties: {
                        id: { type: 'string' },
                        nombres: { type: 'string' },
                        apellidos: { type: 'string' },
                      },
                    },
                    _count: {
                      type: 'object',
                      properties: {
                        asistencias: { type: 'number' },
                      },
                    },
                  },
                },
              },
              pagination: {
                type: 'object',
                properties: {
                  page: { type: 'number' },
                  limit: { type: 'number' },
                  total: { type: 'number' },
                  totalPages: { type: 'number' },
                  hasNext: { type: 'boolean' },
                  hasPrev: { type: 'boolean' },
                },
              },
            },
          },
          401: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              error: { type: 'string' },
              code: { type: 'string' },
            },
          },
          403: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              error: { type: 'string' },
              code: { type: 'string' },
            },
          },
        },
      },
    });

      /**
       * GET /horarios/:horarioId/asistencias
       * Obtiene la lista de asistencias para un horario específico
       */
      horarioRoutes.get('/:horarioId/asistencias', {
        preHandler: [
          authenticate,
          authorize([UserRole.PROFESOR, UserRole.ADMIN_INSTITUCION]),
        ],
        handler: AsistenciaController.getAsistenciasPorHorario as any,
        schema: {
          description: 'Obtiene la lista de asistencias para un horario específico en la fecha actual',
          tags: ['Horarios', 'Asistencias'],
          params: {
            type: 'object',
            required: ['horarioId'],
            properties: {
              horarioId: {
                type: 'string',
                description: 'ID del horario/clase',
              },
            },
          },
          response: {
            200: {
              type: 'object',
              properties: {
                success: { type: 'boolean' },
                message: { type: 'string' },
                data: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      estudiante: {
                        type: 'object',
                        properties: {
                          id: { type: 'string' },
                          nombres: { type: 'string' },
                          apellidos: { type: 'string' },
                          identificacion: { type: 'string' },
                        },
                      },
                      estado: { type: 'string', enum: ['PRESENTE', 'AUSENTE', 'TARDANZA', 'JUSTIFICADO'], nullable: true },
                      fechaRegistro: { type: 'string', format: 'date-time', nullable: true },
                    },
                  },
                },
              },
            },
            404: {
              type: 'object',
              properties: {
                success: { type: 'boolean' },
                message: { type: 'string' },
                error: { type: 'string' },
              },
            },
          },
        },
      });

    /**
     * GET /horarios/grupo/:grupoId
     * Obtiene todos los horarios de un grupo específico
     */
    horarioRoutes.get('/grupo/:grupoId', {
      preHandler: [authenticate, authorize([UserRole.ADMIN_INSTITUCION])],
      handler: HorarioController.getByGrupo as any,
      schema: {
        description: 'Obtener todos los horarios de un grupo específico',
        tags: ['Horarios'],
        params: {
          type: 'object',
          properties: {
            grupoId: { type: 'string', description: 'ID del grupo' },
          },
          required: ['grupoId'],
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
                    periodoId: { type: 'string' },
                    grupoId: { type: 'string' },
                    materiaId: { type: 'string' },
                    profesorId: { type: 'string', nullable: true },
                    diaSemana: { type: 'number' },
                    horaInicio: { type: 'string' },
                    horaFin: { type: 'string' },
                    institucionId: { type: 'string' },
                    createdAt: { type: 'string' },
                    periodoAcademico: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        fechaInicio: { type: 'string' },
                        fechaFin: { type: 'string' },
                        activo: { type: 'boolean' },
                      },
                    },
                    grupo: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombre: { type: 'string' },
                        grado: { type: 'string' },
                        seccion: { type: 'string', nullable: true },
                        periodoAcademico: {
                          type: 'object',
                          properties: {
                            id: { type: 'string' },
                            nombre: { type: 'string' },
                            fechaInicio: { type: 'string' },
                            fechaFin: { type: 'string' },
                            activo: { type: 'boolean' },
                          },
                        },
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
                    profesor: {
                      type: 'object',
                      nullable: true,
                      properties: {
                        id: { type: 'string' },
                        nombres: { type: 'string' },
                        apellidos: { type: 'string' },
                      },
                    },
                    _count: {
                      type: 'object',
                      properties: {
                        asistencias: { type: 'number' },
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    /**
     * GET /horarios/:id
     * Obtiene un horario por ID
     */
    horarioRoutes.get('/:id', {
      preHandler: [authenticate, authorize([UserRole.ADMIN_INSTITUCION])],
      handler: HorarioController.getById as any,
      schema: {
        description: 'Obtener un horario por ID',
        tags: ['Horarios'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del horario' },
          },
          required: ['id'],
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  periodoId: { type: 'string' },
                  grupoId: { type: 'string' },
                  materiaId: { type: 'string' },
                  profesorId: { type: 'string', nullable: true },
                  diaSemana: { type: 'number' },
                  horaInicio: { type: 'string' },
                  horaFin: { type: 'string' },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  periodoAcademico: {
                    type: 'object',
                    properties: {
                      id: { type: 'string' },
                      nombre: { type: 'string' },
                      fechaInicio: { type: 'string' },
                      fechaFin: { type: 'string' },
                      activo: { type: 'boolean' },
                    },
                  },
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
                  profesor: {
                    type: 'object',
                    nullable: true,
                    properties: {
                      id: { type: 'string' },
                      nombres: { type: 'string' },
                      apellidos: { type: 'string' },
                    },
                  },
                  _count: {
                    type: 'object',
                    properties: {
                      asistencias: { type: 'number' },
                    },
                  },
                },
              },
            },
          },
        },
      },
    });

    /**
     * POST /horarios
     * Crea un nuevo horario
     */
    horarioRoutes.post('/', {
      preHandler: [authenticate, authorize([UserRole.ADMIN_INSTITUCION])],
      handler: HorarioController.create as any,
      schema: {
        description: 'Crear un nuevo horario',
        tags: ['Horarios'],
        body: {
          type: 'object',
          properties: {
            periodoId: { type: 'string', description: 'ID del periodo académico' },
            grupoId: { type: 'string', description: 'ID del grupo' },
            materiaId: { type: 'string', description: 'ID de la materia' },
            profesorId: { type: 'string', description: 'ID del profesor (opcional)' },
            diaSemana: { type: 'number', description: 'Día de la semana (1=Lunes, 7=Domingo)' },
            horaInicio: { type: 'string', description: 'Hora de inicio (HH:MM)' },
            horaFin: { type: 'string', description: 'Hora de fin (HH:MM)' },
          },
          required: ['periodoId', 'grupoId', 'materiaId', 'diaSemana', 'horaInicio', 'horaFin'],
        },
        response: {
          201: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  periodoId: { type: 'string' },
                  grupoId: { type: 'string' },
                  materiaId: { type: 'string' },
                  profesorId: { type: 'string', nullable: true },
                  diaSemana: { type: 'number' },
                  horaInicio: { type: 'string' },
                  horaFin: { type: 'string' },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  periodoAcademico: {
                    type: 'object',
                    properties: {
                      id: { type: 'string' },
                      nombre: { type: 'string' },
                      fechaInicio: { type: 'string' },
                      fechaFin: { type: 'string' },
                      activo: { type: 'boolean' },
                    },
                  },
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
                  profesor: {
                    type: 'object',
                    nullable: true,
                    properties: {
                      id: { type: 'string' },
                      nombres: { type: 'string' },
                      apellidos: { type: 'string' },
                    },
                  },
                  _count: {
                    type: 'object',
                    properties: {
                      asistencias: { type: 'number' },
                    },
                  },
                },
              },
              message: { type: 'string' },
            },
          },
        },
      },
    });

    /**
     * PUT /horarios/:id
     * Actualiza un horario
     */
    horarioRoutes.put('/:id', {
      preHandler: [authenticate, authorize([UserRole.ADMIN_INSTITUCION])],
      handler: HorarioController.update as any,
      schema: {
        description: 'Actualizar un horario',
        tags: ['Horarios'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del horario' },
          },
          required: ['id'],
        },
        body: {
          type: 'object',
          properties: {
            grupoId: { type: 'string', description: 'ID del grupo' },
            materiaId: { type: 'string', description: 'ID de la materia' },
            profesorId: { type: 'string', description: 'ID del profesor (opcional)' },
            diaSemana: { type: 'number', description: 'Día de la semana (1=Lunes, 7=Domingo)' },
            horaInicio: { type: 'string', description: 'Hora de inicio (HH:MM)' },
            horaFin: { type: 'string', description: 'Hora de fin (HH:MM)' },
          },
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              data: {
                type: 'object',
                properties: {
                  id: { type: 'string' },
                  periodoId: { type: 'string' },
                  grupoId: { type: 'string' },
                  materiaId: { type: 'string' },
                  profesorId: { type: 'string', nullable: true },
                  diaSemana: { type: 'number' },
                  horaInicio: { type: 'string' },
                  horaFin: { type: 'string' },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  periodoAcademico: {
                    type: 'object',
                    properties: {
                      id: { type: 'string' },
                      nombre: { type: 'string' },
                      fechaInicio: { type: 'string' },
                      fechaFin: { type: 'string' },
                      activo: { type: 'boolean' },
                    },
                  },
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
                  profesor: {
                    type: 'object',
                    nullable: true,
                    properties: {
                      id: { type: 'string' },
                      nombres: { type: 'string' },
                      apellidos: { type: 'string' },
                    },
                  },
                  _count: {
                    type: 'object',
                    properties: {
                      asistencias: { type: 'number' },
                    },
                  },
                },
              },
              message: { type: 'string' },
            },
          },
        },
      },
    });

    /**
     * DELETE /horarios/:id
     * Elimina un horario
     */
    horarioRoutes.delete('/:id', {
      preHandler: [authenticate, authorize([UserRole.ADMIN_INSTITUCION])],
      handler: HorarioController.delete as any,
      schema: {
        description: 'Eliminar un horario',
        tags: ['Horarios'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del horario' },
          },
          required: ['id'],
        },
        response: {
          200: {
            type: 'object',
            properties: {
              success: { type: 'boolean' },
              message: { type: 'string' },
            },
          },
        },
      },
    });

    /**
     * Endpoint de prueba para verificar funcionamiento
     */
    horarioRoutes.get('/test', async (request, reply) => {
      console.log('🧪 GET /horarios/test - Endpoint ejecutado');
      return reply.code(200).send({
        success: true,
        message: 'horario routes funcionando correctamente',
        timestamp: new Date().toISOString(),
      });
    });
  });
}