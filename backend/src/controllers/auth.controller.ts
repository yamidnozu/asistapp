import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import AuthService from '../services/auth.service';
import { ApiResponse, AuthenticationError, LoginRequest, NotFoundError, RefreshTokenResponse, UsuarioConInstituciones, ValidationError } from '../types';

export class AuthController {
  /**
   * Maneja el login de usuarios
   */
  public static async login(request: FastifyRequest<{ Body: LoginRequest }>, reply: FastifyReply) {
    try {
      console.log('🔐 LOGIN: Request received', request.body);
      const credentials = request.body;

  // Debug: registrar intentos de login para diagnóstico (no guardar contraseñas en logs)
  console.log('🔐 AUTH: intento de login para email:', credentials.email);

      if (!credentials.email || !credentials.password) {
        throw new ValidationError('Email y contraseña son requeridos');
      }

      const result = await AuthService.login(credentials);

      return reply.code(200).send({
        success: true,
        data: {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          expiresIn: result.expiresIn,
          usuario: result.usuario
        }
      });

    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene las instituciones del usuario autenticado
   */
  public static async getUserInstitutions(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const user = request.user;

      if (!user) {
        throw new AuthenticationError('Usuario no autenticado');
      }

      const usuario = await prisma.usuario.findUnique({
        where: { id: user.id },
        include: {
          usuarioInstituciones: {
            include: {
              institucion: true,
            },
          },
        },
      }) as UsuarioConInstituciones | null;

      if (!usuario) {
        throw new NotFoundError('Usuario');
      }

      const instituciones = (usuario.usuarioInstituciones || [])
        .filter(ui => ui.activo && ui.institucion?.activa)
        .map((ui) => ({
          id: ui.institucion.id,
          nombre: ui.institucion.nombre,
          rolEnInstitucion: ui.rolEnInstitucion,
        }));

      return reply.code(200).send({
        success: true,
        data: instituciones,
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene los periodos académicos del usuario autenticado
   */
  public static async getUserPeriodos(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const user = request.user;

      if (!user) {
        throw new AuthenticationError('Usuario no autenticado');
      }

      // Obtener las instituciones del usuario
      const usuarioInstituciones = await prisma.usuarioInstitucion.findMany({
        where: {
          usuarioId: user.id,
          activo: true
        },
        include: {
          institucion: {
            include: {
              periodosAcademicos: {
                where: {
                  activo: true
                },
                orderBy: {
                  fechaInicio: 'desc'
                }
              }
            }
          }
        }
      });

      // Extraer todos los periodos únicos
      const periodosMap = new Map();
      usuarioInstituciones.forEach((ui: any) => {
        if (ui.institucion?.periodosAcademicos) {
          ui.institucion.periodosAcademicos.forEach((periodo: any) => {
            if (!periodosMap.has(periodo.id)) {
              periodosMap.set(periodo.id, {
                id: periodo.id,
                nombre: periodo.nombre,
                fechaInicio: periodo.fechaInicio.toISOString().split('T')[0],
                fechaFin: periodo.fechaFin.toISOString().split('T')[0],
                activo: periodo.activo,
                institucionId: periodo.institucionId,
                institucionNombre: ui.institucion.nombre
              });
            }
          });
        }
      });

      const periodos = Array.from(periodosMap.values());

      return reply.code(200).send({
        success: true,
        data: periodos,
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Cierra la sesión (cliente debe eliminar el token)
   */
  public static async logout(request: FastifyRequest<{ Body: { refreshToken?: string } }>, reply: FastifyReply) {
    try {

      const refreshToken = request.body.refreshToken;

      const authReq = request as unknown as AuthenticatedRequest;
      const user = authReq.user;

      if (!user) {
        throw new AuthenticationError('Usuario no autenticado');
      }

      await AuthService.revokeRefreshTokens(user.id, refreshToken);

      return reply.code(200).send({
        success: true,
        message: 'Sesión cerrada exitosamente',
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Refresca el access token usando un refresh token válido
   */
  public static async refreshToken(request: FastifyRequest<{ Body: { refreshToken: string } }>, reply: FastifyReply) {
    try {

      const refreshToken = request.body.refreshToken;

      if (!refreshToken) {
        throw new ValidationError('Refresh token es requerido');
      }

      const result = await AuthService.refreshToken(refreshToken);

      return reply.code(200).send({
        success: true,
        data: {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          expiresIn: result.expiresIn,
        },
      } as ApiResponse<RefreshTokenResponse>);

    } catch (error) {
      throw error;
    }
  }

  /**
   * Verifica que el token del usuario es válido
   */
  public static async verify(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const user = request.user;

      return reply.code(200).send({
        success: true,
        data: {
          usuario: user,
          valid: true,
        },
      });
    } catch (error) {
      throw error;
    }
  }
}

export default AuthController;