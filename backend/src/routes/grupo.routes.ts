import { FastifyInstance } from 'fastify';
import { UserRole } from '../constants/roles';
import GrupoController from '../controllers/grupo.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function grupoRoutes(fastify: FastifyInstance) {

  fastify.register(async function (grupoRoutes) {

    grupoRoutes.addHook('preHandler', authenticate);
    grupoRoutes.addHook('preHandler', authorize([UserRole.ADMIN_INSTITUCION]));

    /**
     * GET /grupos
     * Obtiene todos los grupos de la institución del admin autenticado
     */
    grupoRoutes.get('/', {
      handler: GrupoController.getAll as any,
      schema: {
        description: 'Obtener todos los grupos de la institución',
        tags: ['Grupos'],
        querystring: {
          type: 'object',
          properties: {
            page: { type: 'string', description: 'Número de página' },
            limit: { type: 'string', description: 'Elementos por página' },
            periodoId: { type: 'string', description: 'Filtrar por periodo académico' },
            grado: { type: 'string', description: 'Filtrar por grado' },
            seccion: { type: 'string', description: 'Filtrar por sección' },
            search: { type: 'string', description: 'Buscar por nombre' },
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
                    nombre: { type: 'string' },
                    grado: { type: 'string' },
                    seccion: { type: 'string', nullable: true },
                    periodoId: { type: 'string' },
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
                    _count: {
                      type: 'object',
                      properties: {
                        estudiantesGrupos: { type: 'number' },
                        horarios: { type: 'number' },
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
        },
      },
    });

    /**
     * GET /grupos/disponibles
     * Obtiene los grupos disponibles para asignar estudiantes (solo periodos activos)
     */
    grupoRoutes.get('/disponibles', {
      handler: GrupoController.getGruposDisponibles as any,
      schema: {
        description: 'Obtener grupos disponibles para asignar estudiantes',
        tags: ['Grupos'],
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
                    nombre: { type: 'string' },
                    grado: { type: 'string' },
                    seccion: { type: 'string', nullable: true },
                    periodoId: { type: 'string' },
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
                    _count: {
                      type: 'object',
                      properties: {
                        estudiantesGrupos: { type: 'number' },
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
     * GET /grupos/:id
     * Obtiene un grupo por ID
     */
    grupoRoutes.get('/:id', {
      handler: GrupoController.getById as any,
      schema: {
        description: 'Obtener un grupo por ID',
        tags: ['Grupos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del grupo' },
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
                  nombre: { type: 'string' },
                  grado: { type: 'string' },
                  seccion: { type: 'string', nullable: true },
                  periodoId: { type: 'string' },
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
                  _count: {
                    type: 'object',
                    properties: {
                      estudiantesGrupos: { type: 'number' },
                      horarios: { type: 'number' },
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
     * POST /grupos
     * Crea un nuevo grupo
     */
    grupoRoutes.post('/', {
      handler: GrupoController.create as any,
      schema: {
        description: 'Crear un nuevo grupo',
        tags: ['Grupos'],
        body: {
          type: 'object',
          properties: {
            nombre: { type: 'string', description: 'Nombre del grupo' },
            grado: { type: 'string', description: 'Grado del grupo' },
            seccion: { type: 'string', description: 'Sección del grupo (opcional)' },
            periodoId: { type: 'string', description: 'ID del periodo académico' },
          },
          required: ['nombre', 'grado', 'periodoId'],
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
                  nombre: { type: 'string' },
                  grado: { type: 'string' },
                  seccion: { type: 'string', nullable: true },
                  periodoId: { type: 'string' },
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
                  _count: {
                    type: 'object',
                    properties: {
                      estudiantesGrupos: { type: 'number' },
                      horarios: { type: 'number' },
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
     * PUT /grupos/:id
     * Actualiza un grupo
     */
    grupoRoutes.put('/:id', {
      handler: GrupoController.update as any,
      schema: {
        description: 'Actualizar un grupo',
        tags: ['Grupos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del grupo' },
          },
          required: ['id'],
        },
        body: {
          type: 'object',
          properties: {
            nombre: { type: 'string', description: 'Nombre del grupo' },
            grado: { type: 'string', description: 'Grado del grupo' },
            seccion: { type: 'string', description: 'Sección del grupo (opcional)' },
            periodoId: { type: 'string', description: 'ID del periodo académico' },
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
                  nombre: { type: 'string' },
                  grado: { type: 'string' },
                  seccion: { type: 'string', nullable: true },
                  periodoId: { type: 'string' },
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
                  _count: {
                    type: 'object',
                    properties: {
                      estudiantesGrupos: { type: 'number' },
                      horarios: { type: 'number' },
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
     * PATCH /grupos/:id/toggle-status
     * Activa/desactiva un grupo
     */
    grupoRoutes.patch('/:id/toggle-status', {
      handler: GrupoController.toggleStatus as any,
      schema: {
        description: 'Activar/desactivar un grupo',
        tags: ['Grupos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del grupo' },
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
     * DELETE /grupos/:id
     * Elimina un grupo
     */
    grupoRoutes.delete('/:id', {
      handler: GrupoController.delete as any,
      schema: {
        description: 'Eliminar un grupo',
        tags: ['Grupos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del grupo' },
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
     * GET /grupos/:id/estudiantes
     * Obtiene los estudiantes asignados a un grupo
     */
    grupoRoutes.get('/:id/estudiantes', {
      handler: GrupoController.getEstudiantesByGrupo as any,
      schema: {
        description: 'Obtener estudiantes asignados a un grupo',
        tags: ['Grupos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del grupo' },
          },
          required: ['id'],
        },
        querystring: {
          type: 'object',
          properties: {
            page: { type: 'string', description: 'Número de página' },
            limit: { type: 'string', description: 'Elementos por página' },
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
                    nombres: { type: 'string' },
                    apellidos: { type: 'string' },
                    usuario: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombres: { type: 'string' },
                        apellidos: { type: 'string' },
                        email: { type: 'string' },
                        activo: { type: 'boolean' },
                        createdAt: { type: 'string' },
                      }
                    },
                    identificacion: { type: 'string' },
                    telefonoResponsable: { type: 'string', nullable: true },
                    createdAt: { type: 'string' },
                    asignadoAt: { type: 'string' },
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
        },
      },
    });

    /**
     * GET /grupos/estudiantes-sin-asignar
     * Obtiene estudiantes sin asignar a ningún grupo en el período activo
     */
    grupoRoutes.get('/estudiantes-sin-asignar', {
      handler: GrupoController.getEstudiantesSinAsignar as any,
      schema: {
        description: 'Obtener estudiantes sin asignar a grupos',
        tags: ['Grupos'],
        querystring: {
          type: 'object',
          properties: {
            page: { type: 'string', description: 'Número de página' },
            limit: { type: 'string', description: 'Elementos por página' },
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
                    nombres: { type: 'string' },
                    apellidos: { type: 'string' },
                    usuario: {
                      type: 'object',
                      properties: {
                        id: { type: 'string' },
                        nombres: { type: 'string' },
                        apellidos: { type: 'string' },
                        email: { type: 'string' },
                        activo: { type: 'boolean' },
                        createdAt: { type: 'string' },
                      }
                    },
                    identificacion: { type: 'string' },
                    telefonoResponsable: { type: 'string', nullable: true },
                    createdAt: { type: 'string' },
                    asignadoAt: { type: 'string' },
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
        },
      },
    });

    /**
     * POST /grupos/:id/asignar-estudiante
     * Asigna un estudiante a un grupo
     */
    grupoRoutes.post('/:id/asignar-estudiante', {
      handler: GrupoController.asignarEstudiante as any,
      schema: {
        description: 'Asignar estudiante a un grupo',
        tags: ['Grupos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del grupo' },
          },
          required: ['id'],
        },
        body: {
          type: 'object',
          properties: {
            estudianteId: { type: 'string', description: 'ID del estudiante' },
          },
          required: ['estudianteId'],
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
     * POST /grupos/:id/desasignar-estudiante
     * Desasigna un estudiante de un grupo
     */
    grupoRoutes.post('/:id/desasignar-estudiante', {
      handler: GrupoController.desasignarEstudiante as any,
      schema: {
        description: 'Desasignar estudiante de un grupo',
        tags: ['Grupos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del grupo' },
          },
          required: ['id'],
        },
        body: {
          type: 'object',
          properties: {
            estudianteId: { type: 'string', description: 'ID del estudiante' },
          },
          required: ['estudianteId'],
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
  });
}