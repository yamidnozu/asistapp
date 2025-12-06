import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import GrupoService from '../services/grupo.service';
import { NotFoundError, ValidationError } from '../types';

interface GetGruposQuery {
  page?: string;
  limit?: string;
  periodoId?: string;
  grado?: string;
  seccion?: string;
  search?: string;
}

interface GetEstudiantesParams {
  id: string;
}

interface GetEstudiantesSinAsignarQuery {
  page?: string;
  limit?: string;
  search?: string;
}

interface AsignarEstudianteBody {
  estudianteId: string;
}

interface GetGrupoParams {
  id: string;
}

interface CreateGrupoBody {
  nombre: string;
  grado: string;
  seccion?: string;
  periodoId: string;
}

interface UpdateGrupoBody {
  nombre?: string;
  grado?: string;
  seccion?: string;
  periodoId?: string;
}

export class GrupoController {
  /**
   * Obtiene todos los grupos de la institución del admin autenticado
   */
  public static async getAll(request: AuthenticatedRequest & FastifyRequest<{ Querystring: GetGruposQuery }>, reply: FastifyReply) {
    try {
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

      const institucionId = usuarioInstitucion.institucionId;

      const { page, limit, periodoId, grado, seccion, search } = request.query;

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
        periodoId: periodoId || undefined,
        grado: grado || undefined,
        seccion: seccion || undefined,
        search: search || undefined,
      };

      const result = await GrupoService.getAllGruposByInstitucion(institucionId, pagination, filters);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      console.error('Error en getAll grupos:', error);
      throw error;
    }
  }

  /**
   * Obtiene un grupo por ID
   */
  public static async getById(request: AuthenticatedRequest & FastifyRequest<{ Params: GetGrupoParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const grupo = await GrupoService.getGrupoById(id);

      if (!grupo) {
        throw new NotFoundError('Grupo');
      }

      // Verificar que el grupo pertenece a la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && grupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a este grupo',
        });
      }

      return reply.code(200).send({
        success: true,
        data: grupo,
      });
    } catch (error) {
      console.error('Error en getById grupo:', error);
      throw error;
    }
  }

  /**
   * Crea un nuevo grupo
   */
  public static async create(request: AuthenticatedRequest & FastifyRequest<{ Body: CreateGrupoBody }>, reply: FastifyReply) {
    try {
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const data = {
        ...request.body,
        institucionId: usuarioInstitucion.institucionId,
      };

      const grupo = await GrupoService.createGrupo(data);

      return reply.code(201).send({
        success: true,
        data: grupo,
        message: 'Grupo creado exitosamente',
      });
    } catch (error) {
      console.error('Error en create grupo:', error);
      throw error;
    }
  }

  /**
   * Actualiza un grupo
   */
  public static async update(request: AuthenticatedRequest & FastifyRequest<{ Params: GetGrupoParams; Body: UpdateGrupoBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const data = request.body;

      // Verificar que el grupo existe y pertenece a la institución del admin
      const existingGrupo = await GrupoService.getGrupoById(id);
      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingGrupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este grupo',
        });
      }

      const grupo = await GrupoService.updateGrupo(id, data);

      if (!grupo) {
        throw new NotFoundError('Grupo');
      }

      return reply.code(200).send({
        success: true,
        data: grupo,
        message: 'Grupo actualizado exitosamente',
      });
    } catch (error) {
      console.error('Error en update grupo:', error);
      throw error;
    }
  }

  /**
   * Elimina un grupo
   */
  public static async delete(request: AuthenticatedRequest & FastifyRequest<{ Params: GetGrupoParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      // Verificar que el grupo existe y pertenece a la institución del admin
      const existingGrupo = await GrupoService.getGrupoById(id);
      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingGrupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para eliminar este grupo',
        });
      }

      const success = await GrupoService.deleteGrupo(id);

      return reply.code(200).send({
        success: true,
        message: 'Grupo eliminado exitosamente',
      });
    } catch (error) {
      console.error('Error en delete grupo:', error);
      throw error;
    }
  }

  /**
   * Activa/desactiva un grupo
   */
  public static async toggleStatus(request: AuthenticatedRequest & FastifyRequest<{ Params: GetGrupoParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      // Verificar que el grupo existe y pertenece a la institución del admin
      const existingGrupo = await GrupoService.getGrupoById(id);
      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingGrupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este grupo',
        });
      }

      const grupo = await GrupoService.toggleGrupoStatus(id);

      if (grupo === null) {
        // No hay periodo alternativo, el grupo ya está en el estado correcto
        return reply.code(200).send({
          success: true,
          message: 'El grupo ya está en el estado correcto (no hay periodo alternativo disponible)',
        });
      }

      return reply.code(200).send({
        success: true,
        message: `Grupo ${grupo.periodoAcademico.activo ? 'activado' : 'desactivado'} exitosamente`,
      });
    } catch (error) {
      console.error('Error en toggleStatus grupo:', error);
      throw error;
    }
  }

  /**
   * Obtiene los grupos disponibles para asignar estudiantes (solo periodos activos)
   */
  public static async getGruposDisponibles(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const grupos = await GrupoService.getGruposDisponibles(usuarioInstitucion.institucionId);

      return reply.code(200).send({
        success: true,
        data: grupos,
      });
    } catch (error) {
      console.error('Error en getGruposDisponibles:', error);
      throw error;
    }
  }

  /**
   * Obtiene los estudiantes asignados a un grupo
   */
  public static async getEstudiantesByGrupo(request: AuthenticatedRequest & FastifyRequest<{ Params: GetEstudiantesParams; Querystring: GetEstudiantesSinAsignarQuery }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const { page, limit } = request.query;

      // Verificar que el grupo existe y pertenece a la institución del admin
      const existingGrupo = await GrupoService.getGrupoById(id);
      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingGrupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a este grupo',
        });
      }

      const pageNum = page ? parseInt(page, 10) : 1;
      const limitNum = limit ? parseInt(limit, 10) : 10;

      if (pageNum < 1 || limitNum < 1 || limitNum > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const pagination = {
        page: pageNum,
        limit: limitNum,
      };

      const result = await GrupoService.getEstudiantesByGrupo(id, pagination);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      console.error('Error en getEstudiantesByGrupo:', error);
      throw error;
    }
  }

  /**
   * Obtiene estudiantes sin asignar a ningún grupo en el período activo
   */
  public static async getEstudiantesSinAsignar(request: AuthenticatedRequest & FastifyRequest<{ Querystring: GetEstudiantesSinAsignarQuery }>, reply: FastifyReply) {
    try {
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const { page, limit, search } = request.query;

      const pageNum = page ? parseInt(page, 10) : 1;
      const limitNum = limit ? parseInt(limit, 10) : 10;

      if (pageNum < 1 || limitNum < 1 || limitNum > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const pagination = {
        page: pageNum,
        limit: limitNum,
      };

      const result = await GrupoService.getEstudiantesSinAsignar(usuarioInstitucion.institucionId, pagination, search);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      console.error('Error en getEstudiantesSinAsignar:', error);
      throw error;
    }
  }

  /**
   * Asigna un estudiante a un grupo
   */
  public static async asignarEstudiante(request: AuthenticatedRequest & FastifyRequest<{ Params: GetEstudiantesParams; Body: AsignarEstudianteBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const { estudianteId } = request.body;

      // Verificar que el grupo existe y pertenece a la institución del admin
      const existingGrupo = await GrupoService.getGrupoById(id);
      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingGrupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este grupo',
        });
      }

      const success = await GrupoService.asignarEstudiante(id, estudianteId);

      return reply.code(200).send({
        success: true,
        message: 'Estudiante asignado al grupo exitosamente',
      });
    } catch (error) {
      console.error('Error en asignarEstudiante:', error);
      throw error;
    }
  }

  /**
   * Desasigna un estudiante de un grupo
   */
  public static async desasignarEstudiante(request: AuthenticatedRequest & FastifyRequest<{ Params: GetEstudiantesParams; Body: AsignarEstudianteBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const { estudianteId } = request.body;

      // Verificar que el grupo existe y pertenece a la institución del admin
      const existingGrupo = await GrupoService.getGrupoById(id);
      if (!existingGrupo) {
        throw new NotFoundError('Grupo');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingGrupo.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar este grupo',
        });
      }

      const success = await GrupoService.desasignarEstudiante(id, estudianteId);

      return reply.code(200).send({
        success: true,
        message: 'Estudiante desasignado del grupo exitosamente',
      });
    } catch (error) {
      console.error('Error en desasignarEstudiante:', error);
      throw error;
    }
  }
}

export default GrupoController;