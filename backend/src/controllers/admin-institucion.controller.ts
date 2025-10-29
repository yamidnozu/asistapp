import { FastifyReply, FastifyRequest } from 'fastify';
import AdminInstitucionService, { CreateAdminInstitucionRequest, UpdateAdminInstitucionRequest } from '../services/admin-institucion.service';
import { ApiResponse, NotFoundError, PaginationParams } from '../types';

/**
 * Controlador para gestión de Admins de Institución (Super Admin)
 */
export class AdminInstitucionController {
  /**
   * Obtiene todos los Admins de Institución
   * GET /admin-institucion
   */
  public static async getAll(request: FastifyRequest<{ Querystring: { page?: string; limit?: string } }>, reply: FastifyReply) {
    try {
      const { page, limit } = request.query;

      const pagination: PaginationParams = {};
      if (page) pagination.page = parseInt(page, 10);
      if (limit) pagination.limit = parseInt(limit, 10);

      const result = await AdminInstitucionService.getAll(pagination);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene un Admin de Institución por ID
   * GET /admin-institucion/:id
   */
  public static async getById(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const admin = await AdminInstitucionService.getById(id);

      if (!admin) {
        throw new NotFoundError('Admin de Institución');
      }

      return reply.code(200).send({
        success: true,
        data: admin,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Crea un nuevo Admin de Institución
   * POST /admin-institucion
   */
  public static async create(request: FastifyRequest<{ Body: CreateAdminInstitucionRequest }>, reply: FastifyReply) {
    try {
      const adminData = request.body;
      const newAdmin = await AdminInstitucionService.create(adminData);

      return reply.code(201).send({
        success: true,
        data: newAdmin,
        message: 'Admin de institución creado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Actualiza un Admin de Institución
   * PUT /admin-institucion/:id
   */
  public static async update(request: FastifyRequest<{ Params: { id: string }; Body: UpdateAdminInstitucionRequest }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const adminData = request.body;

      const updatedAdmin = await AdminInstitucionService.update(id, adminData);

      if (!updatedAdmin) {
        throw new NotFoundError('Admin de Institución');
      }

      return reply.code(200).send({
        success: true,
        data: updatedAdmin,
        message: 'Admin de institución actualizado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Elimina un Admin de Institución
   * DELETE /admin-institucion/:id
   */
  public static async delete(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const deleted = await AdminInstitucionService.delete(id);

      if (!deleted) {
        throw new NotFoundError('Admin de Institución');
      }

      return reply.code(200).send({
        success: true,
        data: null,
        message: 'Admin de institución eliminado exitosamente',
      } as ApiResponse<null>);
    } catch (error) {
      throw error;
    }
  }
}

export default AdminInstitucionController;