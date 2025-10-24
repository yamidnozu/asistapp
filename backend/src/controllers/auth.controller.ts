import { FastifyReply, FastifyRequest } from 'fastify';
import { AuthenticatedRequest } from '../middleware/auth';
import AuthService from '../services/auth.service';
import { ApiResponse, LoginRequest, RefreshTokenResponse } from '../types';

export class AuthController {
  /**
   * Maneja el login de usuarios
   */
  public static async login(request: FastifyRequest<{ Body: LoginRequest }>, reply: FastifyReply) {
    try {
      const credentials = request.body;

      // Validar entrada
      if (!credentials.email || !credentials.password) {
        return reply.code(400).send({
          success: false,
          error: 'Email y contraseña son requeridos',
        });
      }

      // Intentar login
      const result = await AuthService.login(credentials);

      // Devolver respuesta con accessToken y refreshToken en el body
      return reply.code(200).send({
        success: true,
        data: {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          expiresIn: result.expiresIn,
          usuario: result.usuario
        }
      });

    } catch (error: any) {
      // El error será manejado por el error handler global
      throw error;
    }
  }

  /**
   * Verifica el estado de autenticación del usuario
   */
  public static async verify(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      // Si llega aquí, el middleware de auth ya validó el token
      return reply.code(200).send({
        success: true,
        data: {
          valid: true,
          user: request.user,
        },
      });
    } catch (error: any) {
      throw error;
    }
  }

  /**
   * Cierra la sesión (cliente debe eliminar el token)
   */
  public static async logout(request: FastifyRequest<{ Body: { refreshToken?: string } }>, reply: FastifyReply) {
    try {
      // Obtener refreshToken del body de la petición
      const refreshToken = request.body.refreshToken;

      // request.user viene del middleware authenticate
      const authReq = request as unknown as AuthenticatedRequest;
      const user = authReq.user;

      if (!user) {
        return reply.code(401).send({ success: false, error: 'Usuario no autenticado' });
      }

      await AuthService.revokeRefreshTokens(user.id, refreshToken);

      return reply.code(200).send({
        success: true,
        message: 'Sesión cerrada exitosamente',
      });
    } catch (error: any) {
      throw error;
    }
  }

  /**
   * Refresca el access token usando un refresh token válido
   */
  public static async refreshToken(request: FastifyRequest<{ Body: { refreshToken: string } }>, reply: FastifyReply) {
    try {
      // Obtener refreshToken del body de la petición
      const refreshToken = request.body.refreshToken;

      // Validar entrada
      if (!refreshToken) {
        return reply.code(400).send({
          success: false,
          error: 'Refresh token es requerido',
        });
      }

      // Intentar refresh
      const result = await AuthService.refreshToken(refreshToken);

      return reply.code(200).send({
        success: true,
        data: {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          expiresIn: result.expiresIn,
        },
      } as ApiResponse<RefreshTokenResponse>);

    } catch (error: any) {
      throw error;
    }
  }
}

export default AuthController;