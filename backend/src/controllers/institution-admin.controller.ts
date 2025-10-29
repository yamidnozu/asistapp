import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import ProfesorService, { ProfesorFilters, UpdateProfesorRequest } from '../services/profesor.service';
import { ApiResponse, NotFoundError, PaginationParams } from '../types';

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
      const user = (request as any).user;
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

      // Construir paginación
      const pagination: PaginationParams = {};
      if (page) pagination.page = parseInt(page, 10);
      if (limit) pagination.limit = parseInt(limit, 10);

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
      const user = (request as any).user;
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
      const user = (request as any).user;
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
      const user = (request as any).user;
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
      const user = (request as any).user;
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
      const user = (request as any).user;
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

  // TODO: Agregar gestión de estudiantes aquí
}

export default InstitutionAdminController;