import { prisma } from '../config/database';
import { UserRole, UsuarioExtendido, ValidationError } from '../types';

export class UserService {
  /**
   * Obtiene todos los usuarios
   */
  public static async getAllUsers(): Promise<UsuarioExtendido[]> {
    try {
      const users = await prisma.usuario.findMany({
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: {
              institucion: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      return users;
    } catch (error) {
      console.error('Error al obtener todos los usuarios:', error);
      throw error;
    }
  }

  /**
   * Obtiene un usuario por ID
   */
  public static async getUserById(id: string): Promise<UsuarioExtendido | null> {
    try {
      if (!id || typeof id !== 'string') {
        throw new ValidationError('ID de usuario inválido');
      }

      const user = await prisma.usuario.findUnique({
        where: { id },
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: {
              institucion: true,
            },
          },
        },
      });

      return user;
    } catch (error) {
      console.error(`Error al obtener usuario con ID ${id}:`, error);
      throw error;
    }
  }

  /**
   * Obtiene un usuario por email
   */
  public static async getUserByEmail(email: string): Promise<UsuarioExtendido | null> {
    try {
      if (!email || typeof email !== 'string' || !email.includes('@')) {
        throw new ValidationError('Email inválido');
      }

      const user = await prisma.usuario.findUnique({
        where: { email: email.toLowerCase() },
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: {
              institucion: true,
            },
          },
        },
      });

      return user;
    } catch (error) {
      console.error(`Error al obtener usuario con email ${email}:`, error);
      throw error;
    }
  }

  /**
   * Obtiene usuarios por rol
   */
  public static async getUsersByRole(role: string): Promise<UsuarioExtendido[]> {
    try {
      const validRoles: UserRole[] = ['super_admin', 'admin_institucion', 'profesor', 'estudiante'];
      if (!role || !validRoles.includes(role as UserRole)) {
        throw new ValidationError('Rol inválido');
      }

      const users = await prisma.usuario.findMany({
        where: { rol: role },
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: {
              institucion: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      return users;
    } catch (error) {
      console.error(`Error al obtener usuarios con rol ${role}:`, error);
      throw error;
    }
  }

  /**
   * Obtiene usuarios por institución
   */
  public static async getUsersByInstitution(institucionId: string): Promise<UsuarioExtendido[]> {
    try {
      if (!institucionId || typeof institucionId !== 'string') {
        throw new ValidationError('ID de institución inválido');
      }

      const users = await prisma.usuario.findMany({
        where: {
          usuarioInstituciones: {
            some: {
              institucionId: institucionId,
              activo: true,
            },
          },
        },
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: {
              institucion: true,
            },
          },
        },
        orderBy: {
          createdAt: 'desc',
        },
      });

      return users;
    } catch (error) {
      console.error(`Error al obtener usuarios de institución ${institucionId}:`, error);
      throw error;
    }
  }

  /**
   * Verifica si un usuario existe
   */
  public static async userExists(id: string): Promise<boolean> {
    try {
      if (!id || typeof id !== 'string') {
        return false;
      }

      const count = await prisma.usuario.count({
        where: { id },
      });

      return count > 0;
    } catch (error) {
      console.error(`Error al verificar existencia de usuario ${id}:`, error);
      return false;
    }
  }

  /**
   * Verifica si un email está disponible
   */
  public static async isEmailAvailable(email: string, excludeUserId?: string): Promise<boolean> {
    try {
      if (!email || typeof email !== 'string' || !email.includes('@')) {
        return false;
      }

      const whereClause: any = { email: email.toLowerCase() };
      if (excludeUserId) {
        whereClause.id = { not: excludeUserId };
      }

      const count = await prisma.usuario.count({
        where: whereClause,
      });

      return count === 0;
    } catch (error) {
      console.error(`Error al verificar disponibilidad de email ${email}:`, error);
      return false;
    }
  }
}

export default UserService;