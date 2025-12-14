import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { prisma } from '../config/database';
import JWTService from '../config/jwt';
import { AuthenticationError, JWTPayload, LoginRequest, LoginResponse, RefreshTokenResponse } from '../types';
import { UserRole } from '../constants/roles';
import logger from '../utils/logger';
import { config } from '../config/app';

export class AuthService {
  /**
   * Autentica un usuario con email y contraseña
   */
  public static async login(credentials: LoginRequest): Promise<LoginResponse> {
    const { email, password } = credentials;

    const usuario = await prisma.usuario.findUnique({
      where: { email },
      include: {
        usuarioInstituciones: {
          include: {
            institucion: true,
          },
        },
      },
    });

    if (!usuario) {
      throw new AuthenticationError('Credenciales inválidas');
    }

    if (!usuario.activo) {
      throw new AuthenticationError('Tu cuenta de usuario está inactiva. Contacta al administrador.');
    }

    const passwordMatch = await bcrypt.compare(password, usuario.passwordHash);
    if (!passwordMatch) {
      throw new AuthenticationError('Credenciales inválidas');
    }

    // Filtrar instituciones activas (relación activa y la institución también activa)
    const institucionesActivas = (usuario.usuarioInstituciones || []).filter((ui: any) => ui.activo && ui.institucion?.activa);

    // Si el usuario no es super_admin y no tiene instituciones activas, denegar acceso
    if (usuario.rol !== UserRole.SUPER_ADMIN && institucionesActivas.length === 0) {
      throw new AuthenticationError('No tienes acceso a ninguna institución activa. Contacta al administrador.');
    }

    const accessToken = JWTService.signAccessToken({
      id: usuario.id,
      rol: usuario.rol as UserRole,
      email: usuario.email,
      tokenVersion: usuario.tokenVersion,
    });

    const refreshToken = JWTService.signRefreshToken({
      id: usuario.id,
      rol: usuario.rol as UserRole,
      email: usuario.email,
      tokenVersion: usuario.tokenVersion,
    });

    try {
      const decodedRefresh = JWTService.decode(refreshToken) as JWTPayload & { exp?: number };
      const exp = decodedRefresh?.exp; // segundos desde epoch
      const expiresAt = exp ? new Date(exp * 1000) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

      const hashed = crypto.createHash('sha256').update(refreshToken).digest('hex');

      // ESTRATEGIA LOGIN-CENTRIC: Desactivar todos los tokens FCM previos al hacer login
      // Esto asegura que solo la sesión actual tenga notificaciones activas
      try {
        await prisma.dispositivoFCM.updateMany({
          where: { usuarioId: usuario.id },
          data: { activo: false }
        });
        logger.info(`🔄 Tokens FCM previos desactivados para usuario ${usuario.id} en nuevo login`);
      } catch (fcmError) {
        logger.error('Error desactivando tokens FCM en login:', fcmError);
        // No bloquear el login si falla la desactivación de FCM
      }

      await prisma.refreshToken.create({
        data: {
          usuarioId: usuario.id,
          token: hashed,
          expiresAt,
        },
      });

      if (refreshToken) {
        const hashed = crypto.createHash('sha256').update(refreshToken).digest('hex');
        await prisma.refreshToken.updateMany({ where: { usuarioId: usuario.id, token: hashed }, data: { revoked: true } });
      } else {
        await prisma.refreshToken.updateMany({ where: { usuarioId: usuario.id, revoked: false }, data: { revoked: true } });
      }
    } catch (error) {
      logger.error('Error al guardar refresh token:', error);
    }

    return {
      accessToken,
      refreshToken,
      usuario: {
        id: usuario.id,
        nombres: usuario.nombres,
        apellidos: usuario.apellidos,
        rol: usuario.rol as UserRole,
        instituciones: institucionesActivas.map((ui: any) => ({
          id: ui.institucion.id,
          nombre: ui.institucion.nombre,
          rolEnInstitucion: ui.rolEnInstitucion,
        })),
      },
      expiresIn: parseInt(config.jwtExpiresIn) || 3600,
    };
  }

  /**
   * Incrementa la versión de tokens del usuario (revoca todos los tokens existentes)
   */
  public static async revokeAllUserTokens(usuarioId: string): Promise<void> {
    await prisma.usuario.update({
      where: { id: usuarioId },
      data: { tokenVersion: { increment: 1 } },
    });
  }

  /**
   * Hashea una contraseña
   */
  public static async hashPassword(password: string): Promise<string> {
    const saltRounds = 10;
    return bcrypt.hash(password, saltRounds);
  }

  /**
   * Verifica si existe un usuario administrador y lo crea si no existe
   */
  public static async ensureAdminUser(): Promise<void> {
    try {
      logger.debug('🔍 Verificando usuario administrador...');

      const adminExists = await prisma.usuario.findUnique({
        where: { email: 'admin@asistapp.com' }
      });

      if (!adminExists) {
        logger.debug('⚠️ No se encontró usuario administrador. Creando usuario por defecto...');

        const adminPassword = await this.hashPassword('pollo');

        const admin = await prisma.usuario.create({
          data: {
            email: 'admin@asistapp.com',
            passwordHash: adminPassword,
            nombres: 'Administrador',
            apellidos: 'Sistema',
            rol: UserRole.SUPER_ADMIN,
            activo: true,
          },
        });

        logger.debug('✅ Usuario administrador creado exitosamente:', admin.email);
      } else {
        logger.debug('✅ Usuario administrador ya existe:', adminExists.email);
      }
    } catch (error) {
      logger.debug('⚠️  No se pudo verificar/crear usuario administrador (DB no disponible):', error instanceof Error ? error.message : String(error));
      // No fallar, continuar sin admin
    }
  }

  /**
   * Revoca los refresh tokens de un usuario
   * También desactiva todos los dispositivos FCM para evitar envío de notificaciones post-logout
   */
  public static async revokeRefreshTokens(usuarioId: string, refreshToken?: string): Promise<void> {
    if (refreshToken) {
      const hashed = crypto.createHash('sha256').update(refreshToken).digest('hex');
      await prisma.refreshToken.updateMany({
        where: { usuarioId, token: hashed },
        data: { revoked: true }
      });
    }

    // SEGURIDAD: Desactivar todos los dispositivos FCM al cerrar sesión
    // Esto evita que se envíen notificaciones push a un usuario que ya cerró sesión
    try {
      await prisma.dispositivoFCM.updateMany({
        where: { usuarioId },
        data: { activo: false }
      });
      logger.info(`🔒 Dispositivos FCM desactivados para usuario ${usuarioId} en logout`);
    } catch (error) {
      logger.error('Error desactivando dispositivos FCM en logout:', error);
      // No lanzar error para no bloquear el logout
    }
  }

  /**
   * Refresca el access token
   */
  public static async refreshToken(token: string): Promise<RefreshTokenResponse> {
    // 1. Verificar token
    let decoded: JWTPayload;
    try {
      decoded = JWTService.verifyRefreshToken(token);
    } catch (error) {
      throw new AuthenticationError('Refresh token inválido o expirado');
    }

    // 2. Buscar en DB
    const hashed = crypto.createHash('sha256').update(token).digest('hex');
    const savedToken = await prisma.refreshToken.findFirst({
      where: { usuarioId: decoded.id, token: hashed }
    });

    if (!savedToken || savedToken.revoked) {
      // Si el token fue revocado, posible robo. Revocar todos los tokens del usuario.
      await this.revokeAllUserTokens(decoded.id);
      throw new AuthenticationError('Refresh token inválido o reutilizado');
    }

    // 3. Verificar usuario
    const usuario = await prisma.usuario.findUnique({
      where: { id: decoded.id },
      include: {
        usuarioInstituciones: {
          include: { institucion: true }
        }
      }
    });

    if (!usuario || !usuario.activo) {
      throw new AuthenticationError('Usuario no encontrado o inactivo');
    }

    if (usuario.tokenVersion !== decoded.tokenVersion) {
      throw new AuthenticationError('Sesión invalidada');
    }

    // 4. Generar nuevos tokens
    const accessToken = JWTService.signAccessToken({
      id: usuario.id,
      rol: usuario.rol as UserRole,
      email: usuario.email,
      tokenVersion: usuario.tokenVersion,
    });

    const newRefreshToken = JWTService.signRefreshToken({
      id: usuario.id,
      rol: usuario.rol as UserRole,
      email: usuario.email,
      tokenVersion: usuario.tokenVersion,
    });

    // 5. Rotar tokens (revocar anterior, guardar nuevo)
    const newHashed = crypto.createHash('sha256').update(newRefreshToken).digest('hex');
    const exp = (JWTService.decode(newRefreshToken) as any).exp;
    const expiresAt = new Date(exp * 1000);

    await prisma.$transaction([
      prisma.refreshToken.update({
        where: { id: savedToken.id },
        data: { revoked: true }
      }),
      prisma.refreshToken.create({
        data: {
          usuarioId: usuario.id,
          token: newHashed,
          expiresAt
        }
      })
    ]);

    return {
      accessToken,
      refreshToken: newRefreshToken,
      expiresIn: parseInt(config.jwtExpiresIn) || 3600,
    };
  }

  /**
   * Verifica un token de acceso
   */
  public static async verifyToken(token: string): Promise<JWTPayload> {
    try {
      return JWTService.verifyAccessToken(token);
    } catch (error) {
      throw new AuthenticationError('Token inválido o expirado');
    }
  }
}

export default AuthService;