import { FastifyInstance } from 'fastify';
import { UserRole } from '../constants/roles';
import PeriodoAcademicoController from '../controllers/periodo-academico.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function periodoAcademicoRoutes(fastify: FastifyInstance) {

  fastify.register(async function (periodoAcademicoRoutes) {

    periodoAcademicoRoutes.addHook('preHandler', authenticate);
    periodoAcademicoRoutes.addHook('preHandler', authorize([UserRole.ADMIN_INSTITUCION]));

    /**
     * GET /periodos-academicos
     * Obtiene todos los períodos académicos de la institución del admin autenticado
     */
    periodoAcademicoRoutes.get('/', {
      handler: PeriodoAcademicoController.getAll as any,
      schema: {
        description: 'Obtener todos los períodos académicos de la institución',
        tags: ['Períodos Académicos'],
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
                    nombre: { type: 'string' },
                    fechaInicio: { type: 'string' },
                    fechaFin: { type: 'string' },
                    activo: { type: 'boolean' },
                    institucionId: { type: 'string' },
                    createdAt: { type: 'string' },
                    _count: {
                      type: 'object',
                      properties: {
                        grupos: { type: 'number' },
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
     * GET /periodos-academicos/activos
     * Obtiene los períodos académicos activos de la institución
     */
    periodoAcademicoRoutes.get('/activos', {
      handler: PeriodoAcademicoController.getActivos as any,
      schema: {
        description: 'Obtener períodos académicos activos',
        tags: ['Períodos Académicos'],
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
                    fechaInicio: { type: 'string' },
                    fechaFin: { type: 'string' },
                    activo: { type: 'boolean' },
                    institucionId: { type: 'string' },
                    createdAt: { type: 'string' },
                    _count: {
                      type: 'object',
                      properties: {
                        grupos: { type: 'number' },
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
     * GET /periodos-academicos/:id
     * Obtiene un período académico por ID
     */
    periodoAcademicoRoutes.get('/:id', {
      handler: PeriodoAcademicoController.getById as any,
      schema: {
        description: 'Obtener un período académico por ID',
        tags: ['Períodos Académicos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del período académico' },
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
                  fechaInicio: { type: 'string' },
                  fechaFin: { type: 'string' },
                  activo: { type: 'boolean' },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  _count: {
                    type: 'object',
                    properties: {
                      grupos: { type: 'number' },
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
     * POST /periodos-academicos
     * Crea un nuevo período académico
     */
    periodoAcademicoRoutes.post('/', {
      handler: PeriodoAcademicoController.create as any,
      schema: {
        description: 'Crear un nuevo período académico',
        tags: ['Períodos Académicos'],
        body: {
          type: 'object',
          properties: {
            nombre: { type: 'string', description: 'Nombre del período académico' },
            fechaInicio: { type: 'string', description: 'Fecha de inicio (ISO 8601)' },
            fechaFin: { type: 'string', description: 'Fecha de fin (ISO 8601)' },
          },
          required: ['nombre', 'fechaInicio', 'fechaFin'],
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
                  fechaInicio: { type: 'string' },
                  fechaFin: { type: 'string' },
                  activo: { type: 'boolean' },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  _count: {
                    type: 'object',
                    properties: {
                      grupos: { type: 'number' },
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
     * PUT /periodos-academicos/:id
     * Actualiza un período académico
     */
    periodoAcademicoRoutes.put('/:id', {
      handler: PeriodoAcademicoController.update as any,
      schema: {
        description: 'Actualizar un período académico',
        tags: ['Períodos Académicos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del período académico' },
          },
          required: ['id'],
        },
        body: {
          type: 'object',
          properties: {
            nombre: { type: 'string', description: 'Nombre del período académico' },
            fechaInicio: { type: 'string', description: 'Fecha de inicio (ISO 8601)' },
            fechaFin: { type: 'string', description: 'Fecha de fin (ISO 8601)' },
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
                  fechaInicio: { type: 'string' },
                  fechaFin: { type: 'string' },
                  activo: { type: 'boolean' },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  _count: {
                    type: 'object',
                    properties: {
                      grupos: { type: 'number' },
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
     * PATCH /periodos-academicos/:id/toggle-status
     * Activa/desactiva un período académico
     */
    periodoAcademicoRoutes.patch('/:id/toggle-status', {
      handler: PeriodoAcademicoController.toggleStatus as any,
      schema: {
        description: 'Activar/desactivar un período académico',
        tags: ['Períodos Académicos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del período académico' },
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
                  fechaInicio: { type: 'string' },
                  fechaFin: { type: 'string' },
                  activo: { type: 'boolean' },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  _count: {
                    type: 'object',
                    properties: {
                      grupos: { type: 'number' },
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
     * DELETE /periodos-academicos/:id
     * Elimina un período académico
     */
    periodoAcademicoRoutes.delete('/:id', {
      handler: PeriodoAcademicoController.delete as any,
      schema: {
        description: 'Eliminar un período académico',
        tags: ['Períodos Académicos'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID del período académico' },
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