import { FastifyInstance } from 'fastify';
import AsistenciaController from '../controllers/asistencia.controller';
import { authenticate, authorize } from '../middleware/auth';

/**
 * Rutas para gestión de Asistencias
 * Define los endpoints de la API REST para asistencias
 */
export async function asistenciaRoutes(fastify: FastifyInstance): Promise<void> {

  // ============================================
  // REGISTRAR ASISTENCIA (QR Code)
  // ============================================
  fastify.post('/registrar', {
    preHandler: [
      authenticate,
      authorize(['profesor', 'admin_institucion']),
    ],
    schema: {
      description: 'Registra la asistencia de un estudiante mediante código QR',
      tags: ['Asistencias'],
      body: {
        type: 'object',
        required: ['horarioId', 'codigoQr'],
        properties: {
          horarioId: {
            type: 'string',
            description: 'ID del horario/clase',
          },
          codigoQr: {
            type: 'string',
            description: 'Código QR del estudiante',
          },
        },
      },
      response: {
        201: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                fecha: { type: 'string', format: 'date-time' },
                estado: { type: 'string', enum: ['PRESENTE', 'AUSENTE', 'TARDANZA', 'JUSTIFICADO'] },
                horarioId: { type: 'string' },
                estudianteId: { type: 'string' },
                profesorId: { type: 'string' },
                institucionId: { type: 'string' },
                estudiante: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    nombres: { type: 'string' },
                    apellidos: { type: 'string' },
                    identificacion: { type: 'string' },
                  },
                },
                horario: {
                  type: 'object',
                  properties: {
                    id: { type: 'string' },
                    diaSemana: { type: 'number' },
                    horaInicio: { type: 'string' },
                    horaFin: { type: 'string' },
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
                  },
                },
              },
            },
          },
        },
        400: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            error: { type: 'string' },
          },
        },
        403: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            error: { type: 'string' },
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
    handler: AsistenciaController.registrarAsistencia,
  });

  // ============================================
  // OBTENER ESTADÍSTICAS DE ASISTENCIA
  // ============================================
  fastify.get('/estadisticas/:horarioId', {
    preHandler: [
      authenticate,
      authorize(['profesor', 'admin_institucion']),
    ],
    schema: {
      description: 'Obtiene las estadísticas de asistencia para un horario específico',
      tags: ['Asistencias'],
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
              type: 'object',
              properties: {
                totalEstudiantes: { type: 'number' },
                presentes: { type: 'number' },
                ausentes: { type: 'number' },
                tardanzas: { type: 'number' },
                justificados: { type: 'number' },
                sinRegistrar: { type: 'number' },
              },
            },
          },
        },
      },
    },
    handler: AsistenciaController.getEstadisticasAsistencia,
  });

  // ============================================
  // REGISTRAR ASISTENCIA MANUAL (sin QR)
  // ============================================
  fastify.post('/registrar-manual', {
    preHandler: [
      authenticate,
      authorize(['profesor', 'admin_institucion']),
    ],
    schema: {
      description: 'Registra la asistencia de un estudiante manualmente (sin código QR)',
      tags: ['Asistencias'],
      summary: 'Registro manual de asistencia',
      body: {
        type: 'object',
        required: ['horarioId', 'estudianteId'],
        properties: {
          horarioId: {
            type: 'string',
            description: 'ID del horario/clase',
          },
          estudianteId: {
            type: 'string',
            description: 'ID del estudiante',
          },
        },
      },
      response: {
        201: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            data: {
              type: 'object',
              properties: {
                id: { type: 'string' },
                fecha: { type: 'string', format: 'date-time' },
                estado: { type: 'string' },
                horarioId: { type: 'string' },
                estudianteId: { type: 'string' },
                profesorId: { type: 'string' },
                institucionId: { type: 'string' },
                estudiante: { type: 'object' },
                horario: { type: 'object' },
              },
            },
          },
        },
        400: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            error: { type: 'string' },
          },
        },
        403: {
          type: 'object',
          properties: {
            success: { type: 'boolean' },
            message: { type: 'string' },
            error: { type: 'string' },
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
    handler: AsistenciaController.registrarAsistenciaManual,
  });
}

export default asistenciaRoutes;