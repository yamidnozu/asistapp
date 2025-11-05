import { FastifyInstance } from 'fastify';
import GrupoController from '../controllers/grupo.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function grupoRoutes(fastify: FastifyInstance) {

  fastify.register(async function (grupoRoutes) {

    grupoRoutes.addHook('preHandler', authenticate);
    grupoRoutes.addHook('preHandler', authorize(['admin_institucion']));

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
  });
}