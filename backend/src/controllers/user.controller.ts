import { FastifyReply, FastifyRequest } from 'fastify';
import UserService from '../services/user.service';
import { ApiResponse, UsuarioExtendido } from '../types';

export class UserController {
  /**
   * Obtiene todos los usuarios
   */
  public static async getAllUsers(request: FastifyRequest, reply: FastifyReply) {
    try {
      const users = await UserService.getAllUsers();

      return reply.code(200).send({
        success: true,
        data: users,
      } as ApiResponse<UsuarioExtendido[]>);

    } catch (error: any) {
      throw error;
    }
  }

  /**
   * Obtiene un usuario por ID
   */
  public static async getUserById(request: FastifyRequest<{ Params: { id: string } }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const user = await UserService.getUserById(id);

      if (!user) {
        return reply.code(404).send({
          success: false,
          error: 'Usuario no encontrado',
        });
      }

      return reply.code(200).send({
        success: true,
        data: user,
      } as ApiResponse<UsuarioExtendido>);

    } catch (error: any) {
      throw error;
    }
  }

  /**
   * Obtiene usuarios por rol
   */
  public static async getUsersByRole(request: FastifyRequest<{ Params: { role: string } }>, reply: FastifyReply) {
    try {
      const { role } = request.params;

      const users = await UserService.getUsersByRole(role);

      return reply.code(200).send({
        success: true,
        data: users,
      } as ApiResponse<UsuarioExtendido[]>);

    } catch (error: any) {
      throw error;
    }
  }

  /**
   * Obtiene usuarios por institución
   */
  public static async getUsersByInstitution(request: FastifyRequest<{ Params: { institucionId: string } }>, reply: FastifyReply) {
    try {
      const { institucionId } = request.params;

      const users = await UserService.getUsersByInstitution(institucionId);

      return reply.code(200).send({
        success: true,
        data: users,
      } as ApiResponse<UsuarioExtendido[]>);

    } catch (error: any) {
      throw error;
    }
  }
}

export default UserController;