import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { prisma } from '../config/database';
import JWTService from '../config/jwt';
import { AuthenticationError, LoginRequest, LoginResponse, RefreshTokenResponse, UserRole } from '../types';

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
          where: { activo: true },
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
      throw new AuthenticationError('Usuario inactivo');
    }
    const passwordMatch = await bcrypt.compare(password, usuario.passwordHash);
    if (!passwordMatch) {
      throw new AuthenticationError('Credenciales inválidas');
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
      const decodedRefresh = JWTService.decode(refreshToken) as any;
      const exp = decodedRefresh?.exp; // segundos desde epoch
      const expiresAt = exp ? new Date(exp * 1000) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

      const hashed = crypto.createHash('sha256').update(refreshToken).digest('hex');

      await prisma.refreshToken.create({
        data: {
          usuarioId: usuario.id,
          token: hashed,
          expiresAt,
        },
      });
    } catch (err) {
      console.warn('No se pudo guardar refresh token en DB:', err);
    }
    const expiresIn = 24 * 60 * 60; // 24 horas en segundos
    return {
      accessToken,
      refreshToken,
      usuario: {
        id: usuario.id,
        nombres: usuario.nombres,
        apellidos: usuario.apellidos,
        rol: usuario.rol as UserRole,
        instituciones: usuario.usuarioInstituciones.map(ui => ({
          id: ui.institucion.id,
          nombre: ui.institucion.nombre,
          rolEnInstitucion: ui.rolEnInstitucion,
        })),
      },
      expiresIn,
    };
  }

  /**
   * Verifica y decodifica un token JWT
   */
  public static async verifyToken(token: string) {
    const decoded = JWTService.verify(token);
    const usuario = await prisma.usuario.findUnique({
      where: { id: decoded.id },
      select: { tokenVersion: true, activo: true },
    });

    if (!usuario || !usuario.activo) {
      throw new AuthenticationError('Usuario no encontrado o inactivo');
    }

    if (usuario.tokenVersion !== decoded.tokenVersion) {
      throw new AuthenticationError('Token revocado por cambio de versión');
    }

    return decoded;
  }

  /**
   * Refresca un access token usando un refresh token válido
   */
  public static async refreshToken(refreshToken: string): Promise<RefreshTokenResponse> {
    try {
      const decoded = JWTService.verifyRefreshToken(refreshToken);
      const hashed = crypto.createHash('sha256').update(refreshToken).digest('hex');

      const tokenRecord = await prisma.refreshToken.findFirst({
        where: {
          usuarioId: decoded.id,
          token: hashed,
          revoked: false,
        },
      });

      if (!tokenRecord) {
        throw new AuthenticationError('Refresh token inválido o revocado');
      }

      if (tokenRecord.expiresAt <= new Date()) {
        await prisma.refreshToken.update({ where: { id: tokenRecord.id }, data: { revoked: true } });
        throw new AuthenticationError('Refresh token expirado');
      }
      const usuario = await prisma.usuario.findUnique({
        where: { id: decoded.id },
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: {
              institucion: true,
            },
          },
        },
      });

      if (!usuario || !usuario.activo) {
        throw new AuthenticationError('Usuario no encontrado o inactivo');
      }
      if (usuario.tokenVersion !== decoded.tokenVersion) {
        throw new AuthenticationError('Refresh token revocado por cambio de versión');
      }
      await prisma.refreshToken.update({ where: { id: tokenRecord.id }, data: { revoked: true } });
      const newAccessToken = JWTService.signAccessToken({
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
      try {
        const decodedNew = JWTService.decode(newRefreshToken) as any;
        const exp = decodedNew?.exp;
        const expiresAt = exp ? new Date(exp * 1000) : new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);
        const hashedNew = crypto.createHash('sha256').update(newRefreshToken).digest('hex');

        await prisma.refreshToken.create({
          data: {
            usuarioId: usuario.id,
            token: hashedNew,
            expiresAt,
          },
        });
      } catch (err) {
        console.warn('No se pudo guardar nuevo refresh token en DB:', err);
      }
      const expiresIn = 24 * 60 * 60; // 24 horas en segundos

      return {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
        expiresIn,
      };
    } catch (error) {
      if (error instanceof AuthenticationError) {
        throw error;
      }
      throw new AuthenticationError(error instanceof Error ? error.message : 'Refresh token inválido');
    }
  }

  /**
   * Revoca refresh tokens: si se proporciona refreshToken se revoca ese token concreto,
   * si no, se revocan todos los refresh tokens del usuario (logout global).
   */
  public static async revokeRefreshTokens(usuarioId: string, refreshToken?: string): Promise<void> {
    if (refreshToken) {
      const hashed = crypto.createHash('sha256').update(refreshToken).digest('hex');
      await prisma.refreshToken.updateMany({ where: { usuarioId, token: hashed }, data: { revoked: true } });
      return;
    }

    await prisma.refreshToken.updateMany({ where: { usuarioId, revoked: false }, data: { revoked: true } });
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
      console.log('🔍 Verificando usuario administrador...');

      const adminExists = await prisma.usuario.findUnique({
        where: { email: 'admin@asistapp.com' }
      });

      if (!adminExists) {
        console.log('⚠️ No se encontró usuario administrador. Creando usuario por defecto...');

        const adminPassword = await this.hashPassword('pollo');

        const admin = await prisma.usuario.create({
          data: {
            email: 'admin@asistapp.com',
            passwordHash: adminPassword,
            nombres: 'Administrador',
            apellidos: 'Sistema',
            rol: 'super_admin',
            activo: true,
          },
        });

        console.log('✅ Usuario administrador creado exitosamente:', admin.email);
      } else {
        console.log('✅ Usuario administrador ya existe:', adminExists.email);
      }
    } catch (error) {
      console.error('❌ Error al verificar/crear usuario administrador:', error);
      throw error;
    }
  }
}

export default AuthService;