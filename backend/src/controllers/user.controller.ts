import { FastifyReply, FastifyRequest } from 'fastify';
import UserService from '../services/user.service';
import { ApiResponse, NotFoundError, PaginationParams, UserFilters } from '../types';

/**
 * Controlador para gestión de usuarios
 */
export class UserController {

  /**
   * Obtiene todos los usuarios con paginación y filtros
   * GET /usuarios
   */
  public static async getAllUsers(
    request: FastifyRequest<{
      Querystring: {
        page?: string;
        limit?: string;
        rol?: string;
        institucionId?: string;
        activo?: string;
        search?: string;
      };
    }>,
    reply: FastifyReply
  ) {
    try {
      const { page, limit, rol, institucionId, activo, search } = request.query;

      // Construir paginación
      const pagination: PaginationParams = {};
      if (page) pagination.page = parseInt(page, 10);
      if (limit) pagination.limit = parseInt(limit, 10);

      // Construir filtros
      const filters: UserFilters = {};
      if (rol) filters.rol = rol as any;
      if (institucionId) filters.institucionId = institucionId;
      if (activo !== undefined) filters.activo = activo === 'true';
      if (search) filters.search = search;

      const result = await UserService.getAllUsers(pagination, filters);

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
   * Obtiene un usuario por ID
   * GET /usuarios/:id
   */
  public static async getUserById(
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply
  ) {
    try {
      const { id } = request.params;

      const user = await UserService.getUserById(id);

      if (!user) {
        throw new NotFoundError('Usuario');
      }

      return reply.code(200).send({
        success: true,
        data: user,
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene usuarios por rol con paginación y filtros adicionales
   * GET /usuarios/rol/:role
   */
  public static async getUsersByRole(
    request: FastifyRequest<{
      Params: { role: string };
      Querystring: {
        page?: string;
        limit?: string;
        institucionId?: string;
        activo?: string;
        search?: string;
      };
    }>,
    reply: FastifyReply
  ) {
    try {
      const { role } = request.params;
      const { page, limit, institucionId, activo, search } = request.query;

      // Construir paginación
      const pagination: PaginationParams = {};
      if (page) pagination.page = parseInt(page, 10);
      if (limit) pagination.limit = parseInt(limit, 10);

      // Construir filtros adicionales
      const filters: UserFilters = {};
      if (institucionId) filters.institucionId = institucionId;
      if (activo !== undefined) filters.activo = activo === 'true';
      if (search) filters.search = search;

      const result = await UserService.getUsersByRole(role, pagination, filters);

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
   * Obtiene usuarios por institución con paginación y filtros adicionales
   * GET /usuarios/institucion/:institucionId
   */
  public static async getUsersByInstitution(
    request: FastifyRequest<{
      Params: { institucionId: string };
      Querystring: {
        page?: string;
        limit?: string;
        rol?: string;
        activo?: string;
        search?: string;
      };
    }>,
    reply: FastifyReply
  ) {
    try {
      const { institucionId } = request.params;
      const { page, limit, rol, activo, search } = request.query;

      // Construir paginación
      const pagination: PaginationParams = {};
      if (page) pagination.page = parseInt(page, 10);
      if (limit) pagination.limit = parseInt(limit, 10);

      // Construir filtros
      const filters: UserFilters = {};
      if (rol) filters.rol = rol as any;
      if (activo !== undefined) filters.activo = activo === 'true';
      if (search) filters.search = search;

      const result = await UserService.getUsersByInstitution(institucionId, pagination, filters);

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
   * Crea un nuevo usuario
   * POST /usuarios
   */
  public static async createUser(
    request: FastifyRequest<{ Body: any }>,
    reply: FastifyReply
  ) {
    try {
      const userData = request.body as any;
      const invokerRole = (request as any).user?.rol;

      if (!invokerRole) {
        throw new Error('Usuario no autenticado');
      }

      const result = await UserService.createUser(userData, invokerRole);

      return reply.code(201).send({
        success: true,
        data: result,
        message: 'Usuario creado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Actualiza un usuario existente
   * PUT /usuarios/:id
   */
  public static async updateUser(
    request: FastifyRequest<{
      Params: { id: string };
      Body: any;
    }>,
    reply: FastifyReply
  ) {
    try {
      const { id } = request.params;
      const userData = request.body as any;

      const result = await UserService.updateUser(id, userData);

      if (!result) {
        throw new NotFoundError('Usuario');
      }

      return reply.code(200).send({
        success: true,
        data: result,
        message: 'Usuario actualizado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }

  /**
   * Elimina un usuario (desactivación lógica)
   * DELETE /usuarios/:id
   */
  public static async deleteUser(
    request: FastifyRequest<{ Params: { id: string } }>,
    reply: FastifyReply
  ) {
    try {
      const { id } = request.params;

      const result = await UserService.deleteUser(id);

      return reply.code(200).send({
        success: true,
        data: { deleted: result },
        message: 'Usuario eliminado exitosamente',
      } as ApiResponse<any>);
    } catch (error) {
      throw error;
    }
  }
}

export default UserController;