import { prisma } from '../config/database';
import { UsuarioExtendido } from '../types';

export class UserService {
  /**
   * Obtiene todos los usuarios
   */
  public static async getAllUsers(): Promise<UsuarioExtendido[]> {
    return prisma.usuario.findMany({
      include: {
        institucion: true,
      },
    });
  }

  /**
   * Obtiene un usuario por ID
   */
  public static async getUserById(id: string): Promise<UsuarioExtendido | null> {
    return prisma.usuario.findUnique({
      where: { id },
      include: {
        institucion: true,
      },
    });
  }

  /**
   * Obtiene un usuario por email
   */
  public static async getUserByEmail(email: string): Promise<UsuarioExtendido | null> {
    return prisma.usuario.findUnique({
      where: { email },
      include: {
        institucion: true,
      },
    });
  }

  /**
   * Obtiene usuarios por rol
   */
  public static async getUsersByRole(role: string): Promise<UsuarioExtendido[]> {
    return prisma.usuario.findMany({
      where: { rol: role },
      include: {
        institucion: true,
      },
    });
  }

  /**
   * Obtiene usuarios por institución
   */
  public static async getUsersByInstitution(institucionId: string): Promise<UsuarioExtendido[]> {
    return prisma.usuario.findMany({
      where: { institucionId },
      include: {
        institucion: true,
      },
    });
  }
}

export default UserService;