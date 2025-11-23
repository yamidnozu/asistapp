import { FastifyInstance } from 'fastify';
import { UserRole } from '../constants/roles';
import MateriaController from '../controllers/materia.controller';
import { authenticate, authorize } from '../middleware/auth';

export default async function materiaRoutes(fastify: FastifyInstance) {

  fastify.register(async function (materiaRoutes) {

    materiaRoutes.addHook('preHandler', authenticate);
    materiaRoutes.addHook('preHandler', authorize([UserRole.ADMIN_INSTITUCION]));

    /**
     * GET /materias
     * Obtiene todas las materias de la institución del admin autenticado
     */
    materiaRoutes.get('/', {
      handler: MateriaController.getAll as any,
      schema: {
        description: 'Obtener todas las materias de la institución',
        tags: ['Materias'],
        querystring: {
          type: 'object',
          properties: {
            page: { type: 'string', description: 'Número de página' },
            limit: { type: 'string', description: 'Elementos por página' },
            search: { type: 'string', description: 'Buscar por nombre o código' },
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
                    codigo: { type: 'string', nullable: true },
                    institucionId: { type: 'string' },
                    createdAt: { type: 'string' },
                    _count: {
                      type: 'object',
                      properties: {
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
     * GET /materias/disponibles
     * Obtiene las materias disponibles para crear horarios
     */
    materiaRoutes.get('/disponibles', {
      handler: MateriaController.getMateriasDisponibles as any,
      schema: {
        description: 'Obtener materias disponibles para crear horarios',
        tags: ['Materias'],
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
                    codigo: { type: 'string', nullable: true },
                    institucionId: { type: 'string' },
                    createdAt: { type: 'string' },
                    _count: {
                      type: 'object',
                      properties: {
                        horarios: { type: 'number' },
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
     * GET /materias/:id
     * Obtiene una materia por ID
     */
    materiaRoutes.get('/:id', {
      handler: MateriaController.getById as any,
      schema: {
        description: 'Obtener una materia por ID',
        tags: ['Materias'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID de la materia' },
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
                  codigo: { type: 'string', nullable: true },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  _count: {
                    type: 'object',
                    properties: {
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
     * POST /materias
     * Crea una nueva materia
     */
    materiaRoutes.post('/', {
      handler: MateriaController.create as any,
      schema: {
        description: 'Crear una nueva materia',
        tags: ['Materias'],
        body: {
          type: 'object',
          properties: {
            nombre: { type: 'string', description: 'Nombre de la materia' },
            codigo: { type: 'string', description: 'Código de la materia (opcional)' },
          },
          required: ['nombre'],
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
                  codigo: { type: 'string', nullable: true },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  _count: {
                    type: 'object',
                    properties: {
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
     * PUT /materias/:id
     * Actualiza una materia
     */
    materiaRoutes.put('/:id', {
      handler: MateriaController.update as any,
      schema: {
        description: 'Actualizar una materia',
        tags: ['Materias'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID de la materia' },
          },
          required: ['id'],
        },
        body: {
          type: 'object',
          properties: {
            nombre: { type: 'string', description: 'Nombre de la materia' },
            codigo: { type: 'string', description: 'Código de la materia (opcional)' },
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
                  codigo: { type: 'string', nullable: true },
                  institucionId: { type: 'string' },
                  createdAt: { type: 'string' },
                  _count: {
                    type: 'object',
                    properties: {
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
     * DELETE /materias/:id
     * Elimina una materia
     */
    materiaRoutes.delete('/:id', {
      handler: MateriaController.delete as any,
      schema: {
        description: 'Eliminar una materia',
        tags: ['Materias'],
        params: {
          type: 'object',
          properties: {
            id: { type: 'string', description: 'ID de la materia' },
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