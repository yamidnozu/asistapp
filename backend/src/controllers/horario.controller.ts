import { FastifyReply, FastifyRequest } from 'fastify';
import { config } from '../config/app';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import HorarioService from '../services/horario.service';
import { NotFoundError, ValidationError } from '../types';
import logger from '../utils/logger';
import { validateTimeFormat } from '../utils/time-validation';

interface GetHorariosQuery {
  page?: string;
  limit?: string;
  grupoId?: string;
  materiaId?: string;
  profesorId?: string;
  diaSemana?: string;
}

interface GetHorarioParams {
  id: string;
}

interface GetHorariosByGrupoParams {
  grupoId: string;
}

interface CreateHorarioBody {
  periodoId: string;
  grupoId: string;
  materiaId: string;
  profesorId?: string;
  diaSemana: number;
  horaInicio: string;
  horaFin: string;
}

interface UpdateHorarioBody {
  grupoId?: string;
  materiaId?: string;
  profesorId?: string;
  diaSemana?: number;
  horaInicio?: string;
  horaFin?: string;
}

export class HorarioController {
  /**
   * Obtiene los horarios del estudiante autenticado basado en sus grupos
   */
  public static async getMisHorarios(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      if (!request.user) {
        return reply.code(401).send({
          success: false,
          error: 'Usuario no autenticado',
          code: 'AUTHENTICATION_ERROR',
        });
      }

      // Buscar el estudiante asociado al usuario
      const estudiante = await prisma.estudiante.findUnique({
        where: { usuarioId: request.user.id },
        include: {
          estudiantesGrupos: {
            include: {
              grupo: {
                include: {
                  periodoAcademico: true,
                },
              },
            },
          },
        },
      });

      if (!estudiante) {
        return reply.code(404).send({
          success: false,
          error: 'Estudiante no encontrado',
          code: 'NOT_FOUND_ERROR',
        });
      }

      // Obtener solo los grupos con periodo activo
      const gruposActivos = estudiante.estudiantesGrupos
        .filter((eg: any) => eg.grupo.periodoAcademico?.activo)
        .map((eg: any) => eg.grupoId);

      if (gruposActivos.length === 0) {
        return reply.code(200).send({
          success: true,
          data: [],
          message: 'No tienes grupos asignados en un periodo activo',
        });
      }

      // Obtener todos los horarios de los grupos del estudiante
      const horarios = await prisma.horario.findMany({
        where: {
          grupoId: { in: gruposActivos },
        },
        orderBy: [
          { diaSemana: 'asc' },
          { horaInicio: 'asc' },
        ],
        include: {
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              fechaInicio: true,
              fechaFin: true,
              activo: true,
            },
          },
          grupo: {
            select: {
              id: true,
              nombre: true,
              grado: true,
              seccion: true,
            },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
            },
          },
        },
      });

      const formattedHorarios = horarios.map((horario: any) => ({
        id: horario.id,
        diaSemana: horario.diaSemana,
        horaInicio: horario.horaInicio,
        horaFin: horario.horaFin,
        periodoAcademico: {
          id: horario.periodoAcademico.id,
          nombre: horario.periodoAcademico.nombre,
          activo: horario.periodoAcademico.activo,
        },
        grupo: {
          id: horario.grupo.id,
          nombre: horario.grupo.nombre,
          grado: horario.grupo.grado,
          seccion: horario.grupo.seccion,
        },
        materia: {
          id: horario.materia.id,
          nombre: horario.materia.nombre,
          codigo: horario.materia.codigo,
        },
        profesor: horario.profesor ? {
          id: horario.profesor.id,
          nombres: horario.profesor.nombres,
          apellidos: horario.profesor.apellidos,
        } : null,
      }));

      return reply.code(200).send({
        success: true,
        data: formattedHorarios,
      });
    } catch (error) {
      logger.error('Error en getMisHorarios:', error);
      throw error;
    }
  }

  /**
   * Obtiene todos los horarios de la institución del admin autenticado
   */
  public static async getAll(request: AuthenticatedRequest & FastifyRequest<{ Querystring: GetHorariosQuery }>, reply: FastifyReply) {
    try {
      if (config.nodeEnv === 'development') {
        console.log('🔍 Verificando usuario en getAll horarios:', request.user);
      }

      // Verificar autorización manualmente
      if (!request.user) {
        if (config.nodeEnv === 'development') {
          console.log('❌ No hay usuario autenticado');
        }
        return reply.code(401).send({
          success: false,
          error: 'Usuario no autenticado',
          code: 'AUTHENTICATION_ERROR',
        });
      }

      if (request.user.rol !== 'admin_institucion') {
        if (config.nodeEnv === 'development') {
          console.log(`❌ Usuario con rol '${request.user.rol}' intentando acceder a horarios`);
        }
        return reply.code(403).send({
          success: false,
          error: 'Acceso denegado: se requiere rol de administrador de institución',
          code: 'AUTHORIZATION_ERROR',
        });
      }

      if (config.nodeEnv === 'development') {
        console.log('✅ Autorización exitosa para admin_institucion');
      }

      // Obtener la institución del admin autenticado
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const { page, limit, grupoId, materiaId, profesorId, diaSemana } = request.query;

      // Validar parámetros de paginación
      const pageNum = page ? parseInt(page, 10) : 1;
      const limitNum = limit ? parseInt(limit, 10) : 10;

      if (pageNum < 1 || limitNum < 1 || limitNum > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const pagination = {
        page: pageNum,
        limit: limitNum,
      };

      const filters = {
        grupoId: grupoId || undefined,
        materiaId: materiaId || undefined,
        profesorId: profesorId || undefined,
        diaSemana: diaSemana ? parseInt(diaSemana, 10) : undefined,
      };

      // Validar día de semana si se proporciona
      if (diaSemana && (filters.diaSemana! < 1 || filters.diaSemana! > 7)) {
        throw new ValidationError('El día de semana debe estar entre 1 (Lunes) y 7 (Domingo)');
      }

      const result = await HorarioService.getAllHorariosByInstitucion(usuarioInstitucion.institucionId, pagination, filters);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      logger.error('Error en getAll horarios:', error);
      throw error;
    }
  }

  /**
   * Obtiene los horarios de un grupo específico
   */
  public static async getByGrupo(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorariosByGrupoParams }>, reply: FastifyReply) {
    try {
      const { grupoId } = request.params;

      // Verificar que el grupo pertenece a la institución del admin
      const grupo = await prisma.grupo.findUnique({
        where: { id: grupoId },
      });

      if (!grupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && grupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a los horarios de este grupo',
        });
      }

      const horarios = await HorarioService.getHorariosByGrupo(grupoId);

      return reply.code(200).send({
        success: true,
        data: horarios,
      });
    } catch (error) {
      logger.error('Error en getByGrupo horarios:', error);
      throw error;
    }
  }

  /**
   * Obtiene un horario por ID
   */
  public static async getById(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorarioParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const horario = await HorarioService.getHorarioById(id);

      if (!horario) {
        throw new NotFoundError('Horario');
      }

      // Verificar que el horario pertenece a la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && horario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a este horario',
        });
      }

      return reply.code(200).send({
        success: true,
        data: horario,
      });
    } catch (error) {
      logger.error('Error en getById horario:', error);
      throw error;
    }
  }

  /**
   * Crea un nuevo horario
   */
  public static async create(request: AuthenticatedRequest & FastifyRequest<{ Body: CreateHorarioBody }>, reply: FastifyReply) {
    try {
      if (config.nodeEnv === 'development') {
        console.log('🔍 CONTROLLER: Iniciando create horario');
        console.log('🔍 CONTROLLER: Body recibido:', JSON.stringify(request.body, null, 2));
        console.log('🔍 CONTROLLER: Usuario:', request.user?.id);
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      if (config.nodeEnv === 'development') {
        console.log('🔍 CONTROLLER: Institución del usuario:', usuarioInstitucion.institucionId);
      }

      // Validar formato de UUIDs antes de consultar la base de datos
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      const { periodoId, grupoId, materiaId, profesorId } = request.body;

      if (!uuidRegex.test(periodoId) || !uuidRegex.test(grupoId) || !uuidRegex.test(materiaId)) {
        return reply.code(400).send({
          success: false,
          error: 'Formato de ID inválido',
          code: 'VALIDATION_ERROR'
        });
      }

      if (profesorId && !uuidRegex.test(profesorId)) {
        return reply.code(400).send({
          success: false,
          error: 'Formato de ID del profesor inválido',
          code: 'VALIDATION_ERROR'
        });
      }

      // Validar formato de horas
      try {
        validateTimeFormat(request.body.horaInicio, request.body.horaFin);
      } catch (error) {
        return reply.code(400).send({
          success: false,
          error: (error as Error).message,
          code: 'VALIDATION_ERROR'
        });
      }

      const data = {
        ...request.body,
        institucionId: usuarioInstitucion.institucionId,
      };

      if (config.nodeEnv === 'development') {
        logger.debug('🔍 CONTROLLER: Llamando al servicio con data', data);

        // Validar que todos los campos requeridos estén presentes y sean válidos
        logger.debug('🔍 CONTROLLER: Validando campos', {
          periodoId: { valor: data.periodoId, tipo: typeof data.periodoId, longitud: data.periodoId?.length },
          grupoId: { valor: data.grupoId, tipo: typeof data.grupoId, longitud: data.grupoId?.length },
          materiaId: { valor: data.materiaId, tipo: typeof data.materiaId, longitud: data.materiaId?.length },
          profesorId: { valor: data.profesorId, tipo: typeof data.profesorId, longitud: data.profesorId?.length },
          diaSemana: { valor: data.diaSemana, tipo: typeof data.diaSemana },
          horaInicio: { valor: data.horaInicio, tipo: typeof data.horaInicio },
          horaFin: { valor: data.horaFin, tipo: typeof data.horaFin },
          institucionId: { valor: data.institucionId, tipo: typeof data.institucionId, longitud: data.institucionId?.length }
        });
      }

      const horario = await HorarioService.createHorario(data);

      return reply.code(201).send({
        success: true,
        data: horario,
        message: 'Horario creado exitosamente',
      });
    } catch (error) {
      logger.error('❌ CONTROLLER: Error en create horario:', error);
      logger.error('❌ CONTROLLER: Stack trace:', (error as Error).stack);

      // Si es un error de validación de Prisma (IDs inválidos), devolver 400
      if ((error as any).code === 'P2025' || (error as any).code === 'P2003') {
        return reply.code(400).send({
          success: false,
          error: 'IDs inválidos en la solicitud',
          code: 'VALIDATION_ERROR'
        });
      }

      throw error;
    }
  }

  /**
   * Actualiza un horario
   */
  public static async update(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorarioParams; Body: UpdateHorarioBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const data = request.body;

      // Verificar que el horario existe y pertenece a la institución del admin
      const existingHorario = await HorarioService.getHorarioById(id);
      if (!existingHorario) {
        throw new NotFoundError('Horario');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingHorario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este horario',
        });
      }

      // Validar formato de horas si se proporcionan
      if (data.horaInicio || data.horaFin) {
        const horaInicio = data.horaInicio || existingHorario.horaInicio;
        const horaFin = data.horaFin || existingHorario.horaFin;
        try {
          validateTimeFormat(horaInicio, horaFin);
        } catch (error) {
          return reply.code(400).send({
            success: false,
            error: (error as Error).message,
            code: 'VALIDATION_ERROR'
          });
        }
      }

      const horario = await HorarioService.updateHorario(id, data);

      if (!horario) {
        throw new NotFoundError('Horario');
      }

      return reply.code(200).send({
        success: true,
        data: horario,
        message: 'Horario actualizado exitosamente',
      });
    } catch (error) {
      logger.error('Error en update horario:', error);
      throw error;
    }
  }

  /**
   * Elimina un horario
   */
  public static async delete(request: AuthenticatedRequest & FastifyRequest<{ Params: GetHorarioParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      // Verificar que el horario existe y pertenece a la institución del admin
      const existingHorario = await HorarioService.getHorarioById(id);
      if (!existingHorario) {
        throw new NotFoundError('Horario');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingHorario.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para eliminar este horario',
        });
      }

      const success = await HorarioService.deleteHorario(id);

      return reply.code(200).send({
        success: true,
        message: 'Horario eliminado exitosamente',
      });
    } catch (error) {
      logger.error('Error en delete horario:', error);
      throw error;
    }
  }
}

export default HorarioController;
