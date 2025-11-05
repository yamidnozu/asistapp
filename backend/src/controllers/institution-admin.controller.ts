import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import EstudianteService from '../services/estudiante.service';
import ProfesorService, { ProfesorFilters, UpdateProfesorRequest } from '../services/profesor.service';
import { ApiResponse, AuthenticatedRequest, NotFoundError, PaginationParams, ValidationError } from '../types';

interface CreateProfesorBody {
  nombres: string;
  apellidos: string;
  email: string;
  password: string;
  grupoId?: string;
}

/**
 * Controlador para Admin de Institución
 * Gestiona profesores y estudiantes de su institución
 */
export class InstitutionAdminController {

  // ========== GESTIÓN DE PROFESORES ==========

  /**
   * Obtiene todos los profesores de la institución del admin
   * GET /institution-admin/profesores
   */
  public static async getAllProfesores(
    request: FastifyRequest<{
      Querystring: {
        page?: string;
        limit?: string;
        activo?: string;
        search?: string;
      };
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { page, limit, activo, search } = request.query;

      // Obtener la institución del admin desde la base de datos
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          message: 'No tienes una institución asignada',
        });
      }

      const institucionId = usuarioInstitucion.institucionId;

      // Construir paginación con validación
      const pagination: PaginationParams = {};
      if (page) {
        const pageNum = parseInt(page, 10);
        if (pageNum < 1) {
          throw new ValidationError('El parámetro page debe ser mayor a 0.');
        }
        pagination.page = pageNum;
      }
      if (limit) {
        const limitNum = parseInt(limit, 10);
        if (limitNum < 1 || limitNum > 100) {
          throw new ValidationError('El parámetro limit debe ser mayor a 0 y máximo 100.');
        }
        pagination.limit = limitNum;
      }

      // Construir filtros
      const filters: ProfesorFilters = { institucionId };
      if (activo !== undefined && activo !== null) {
        filters.activo = String(activo).toLowerCase() === 'true';
      }
      if (search) filters.search = search;

      // Obtener profesores
      const result = await ProfesorService.getAll(institucionId, pagination, filters);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene un profesor por ID
   * GET /institution-admin/profesores/:id
   */
  public static async getProfesorById(
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;

      // Obtener la institución del admin desde la base de datos
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          message: 'No tienes una institución asignada',
        });
      }

      const institucionId = usuarioInstitucion.institucionId;

      const profesor = await ProfesorService.getById(id, institucionId);

      if (!profesor) {
        throw new NotFoundError('Profesor');
      }

      return reply.code(200).send({
        success: true,
        data: profesor,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Crea un nuevo profesor
   * POST /institution-admin/profesores
   */
  public static async createProfesor(
    request: FastifyRequest<{ Body: CreateProfesorBody }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const profesorData = request.body;

      // Obtener la institución del admin desde la base de datos
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          message: 'No tienes una institución asignada',
        });
      }

      const institucionId = usuarioInstitucion.institucionId;

      // Asegurar que el profesor se crea en la institución del admin

      const newProfesor = await ProfesorService.create({
        nombres: profesorData.nombres,
        apellidos: profesorData.apellidos,
        email: profesorData.email,
        password: profesorData.password,
        institucionId: institucionId,
        grupoId: profesorData.grupoId,
      }, user.id);

      return reply.code(201).send({
        success: true,
        data: newProfesor,
        message: 'Profesor creado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Actualiza un profesor
   * PUT /institution-admin/profesores/:id
   */
  public static async updateProfesor(
    request: FastifyRequest<{
      Params: { id: string };
      Body: UpdateProfesorRequest;
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;
      const profesorData = request.body;

      // Obtener la institución del admin desde la base de datos
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          message: 'No tienes una institución asignada',
        });
      }

      const institucionId = usuarioInstitucion.institucionId;

      const updatedProfesor = await ProfesorService.update(id, institucionId, profesorData);

      if (!updatedProfesor) {
        throw new NotFoundError('Profesor');
      }

      return reply.code(200).send({
        success: true,
        data: updatedProfesor,
        message: 'Profesor actualizado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Elimina un profesor (desactivación lógica)
   * DELETE /institution-admin/profesores/:id
   */
  public static async deleteProfesor(
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;

      // Obtener la institución del admin desde la base de datos
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          message: 'No tienes una institución asignada',
        });
      }

      const institucionId = usuarioInstitucion.institucionId;

      const deleted = await ProfesorService.delete(id, institucionId);

      if (!deleted) {
        throw new NotFoundError('Profesor');
      }

      return reply.code(200).send({
        success: true,
        data: null,
        message: 'Profesor eliminado exitosamente',
      } as ApiResponse<null>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Activa/desactiva un profesor
   * PATCH /institution-admin/profesores/:id/toggle-status
   */
  public static async toggleProfesorStatus(
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;

      // Obtener la institución del admin desde la base de datos
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          message: 'No tienes una institución asignada',
        });
      }

      const institucionId = usuarioInstitucion.institucionId;

      const profesor = await ProfesorService.toggleStatus(id, institucionId);

      if (!profesor) {
        throw new NotFoundError('Profesor');
      }

      return reply.code(200).send({
        success: true,
        data: profesor,
        message: `Profesor ${profesor.activo ? 'activado' : 'desactivado'} exitosamente`,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  // ========== GESTIÓN DE ESTUDIANTES ==========

  /**
   * Obtiene todos los estudiantes de la institución del admin
   * GET /institution-admin/estudiantes
   */
  public static async getAllEstudiantes(
    request: FastifyRequest<{
      Querystring: {
        page?: string;
        limit?: string;
        activo?: string;
        search?: string;
        grupoId?: string;
      };
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { page = '1', limit = '10', activo, search, grupoId } = request.query;

      // Obtener la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes una institución asignada',
          code: 'FORBIDDEN',
        } as ApiResponse<any>);
      }

      const filters = {
        ...(activo !== undefined && { activo: activo === 'true' }),
        ...(search && { search }),
        ...(grupoId && { grupoId }),
      };

      const result = await EstudianteService.getAllEstudiantesByInstitucion(
        usuarioInstitucion.institucionId,
        filters,
        parseInt(page),
        parseInt(limit)
      );

      reply.send({
        success: true,
        data: result.estudiantes,
        pagination: result.pagination,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene un estudiante específico por ID
   * GET /institution-admin/estudiantes/:id
   */
  public static async getEstudianteById(
    request: FastifyRequest<{
      Params: { id: string };
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;

      // Obtener la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes una institución asignada',
          code: 'FORBIDDEN',
        } as ApiResponse<any>);
      }

      const estudiante = await EstudianteService.getEstudianteById(id, usuarioInstitucion.institucionId);

      reply.send({
        success: true,
        data: estudiante,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Crea un nuevo estudiante
   * POST /institution-admin/estudiantes
   */
  public static async createEstudiante(
    request: FastifyRequest<{
      Body: {
        nombres: string;
        apellidos: string;
        email: string;
        password: string;
        identificacion: string;
        nombreResponsable?: string;
        telefonoResponsable?: string;
        grupoId?: string;
      };
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const estudianteData = request.body;

      // Obtener la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes una institución asignada',
          code: 'FORBIDDEN',
        } as ApiResponse<any>);
      }

      const estudiante = await EstudianteService.createEstudiante(estudianteData, usuarioInstitucion.institucionId);

      reply.code(201).send({
        success: true,
        data: estudiante,
        message: 'Estudiante creado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Actualiza un estudiante
   * PUT /institution-admin/estudiantes/:id
   */
  public static async updateEstudiante(
    request: FastifyRequest<{
      Params: { id: string };
      Body: {
        nombres?: string;
        apellidos?: string;
        identificacion?: string;
        nombreResponsable?: string;
        telefonoResponsable?: string;
        grupoId?: string;
      };
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;
      const updateData = request.body;

      // Obtener la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes una institución asignada',
          code: 'FORBIDDEN',
        } as ApiResponse<any>);
      }

      const estudiante = await EstudianteService.updateEstudiante(id, updateData, usuarioInstitucion.institucionId);

      reply.send({
        success: true,
        data: estudiante,
        message: 'Estudiante actualizado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Elimina un estudiante (desactivación lógica)
   * DELETE /institution-admin/estudiantes/:id
   */
  public static async deleteEstudiante(
    request: FastifyRequest<{
      Params: { id: string };
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;

      // Obtener la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes una institución asignada',
          code: 'FORBIDDEN',
        } as ApiResponse<any>);
      }

      await EstudianteService.deleteEstudiante(id, usuarioInstitucion.institucionId);

      reply.send({
        success: true,
        message: 'Estudiante eliminado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Activa/desactiva un estudiante
   * PATCH /institution-admin/estudiantes/:id/toggle-status
   */
  public static async toggleEstudianteStatus(
    request: FastifyRequest<{
      Params: { id: string };
    }>,
    reply: FastifyReply
  ) {
    try {
      const user = (request as AuthenticatedRequest).user;
      const { id } = request.params;

      // Obtener la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: user.id,
          activo: true,
        },
        include: {
          institucion: true,
        },
      });

      if (!usuarioInstitucion) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes una institución asignada',
          code: 'FORBIDDEN',
        } as ApiResponse<any>);
      }

      const result = await EstudianteService.toggleEstudianteStatus(id, usuarioInstitucion.institucionId);

      reply.send({
        success: true,
        data: result,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }
}

export default InstitutionAdminController;