import bcrypt from 'bcryptjs';
import { randomBytes } from 'crypto';
import { prisma } from '../config/database';
import { ConflictError, CreateUserRequest, CreateUserResponse, NotFoundError, PaginatedResponse, PaginationParams, UpdateUserRequest, UserFilters, UserRole, UsuarioExtendido, ValidationError } from '../types';
import logger from '../utils/logger';

export class UserService {
  /**
   * Obtiene todos los usuarios con paginación y filtros
   */
  public static async getAllUsers(pagination?: PaginationParams, filters?: UserFilters): Promise<PaginatedResponse<UsuarioExtendido>> {
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 50;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

      // Construir cláusula where dinámicamente
      const where: any = {};

      if (filters?.activo !== undefined) {
        where.activo = filters.activo;
      }
      if (filters?.rol) {
        // Soportar múltiples roles pasados como string separado por comas ("super_admin,admin_institucion")
        // o como un array.
        const rolFilter: any = filters.rol as any;
        if (Array.isArray(rolFilter)) {
          where.rol = { in: rolFilter };
        } else if (typeof rolFilter === 'string' && rolFilter.includes(',')) {
          where.rol = { in: rolFilter.split(',').map(r => r.trim()) };
        } else {
          where.rol = rolFilter;
        }
      }
      if (filters?.institucionId) {
        where.usuarioInstituciones = {
          some: { institucionId: filters.institucionId, activo: true },
        };
      }
      if (filters?.search) {
        where.OR = [
          { nombres: { contains: filters.search, mode: 'insensitive' } },
          { apellidos: { contains: filters.search, mode: 'insensitive' } },
          { email: { contains: filters.search, mode: 'insensitive' } },
        ];
      }

      // Get total count
      const total = await prisma.usuario.count({ where });

      // Get paginated users
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
        skip,
        take: limit,
        where,
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: users,
        pagination: {
          page,
          limit,
          total,
          totalPages,
          hasNext: page < totalPages,
          hasPrev: page > 1,
        },
      };
    } catch (error) {
      logger.error('Error al obtener todos los usuarios:', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener los usuarios');
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
          estudiante: true,
        },
      });

      return user;
    } catch (error) {
      logger.error(`Error al obtener usuario con ID ${id}:`, error);
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
      logger.error(`Error al obtener usuario con email ${email}:`, error);
      throw error;
    }
  }

  /**
   * Obtiene usuarios por rol con paginación
   */
  public static async getUsersByRole(role: string, pagination?: PaginationParams, filters?: UserFilters): Promise<PaginatedResponse<UsuarioExtendido>> {
    const combinedFilters = { ...filters, rol: role as UserRole };
    return this.getAllUsers(pagination, combinedFilters);
  }

  /**
   * Obtiene usuarios por institución con paginación y filtros
   */
  public static async getUsersByInstitution(institucionId: string, pagination?: PaginationParams, filters?: UserFilters): Promise<PaginatedResponse<UsuarioExtendido>> {
    const combinedFilters = { ...filters, institucionId };
    return this.getAllUsers(pagination, combinedFilters);
  }

  /**
   * Crea un nuevo usuario
   */
  public static async createUser(userData: CreateUserRequest, invokerRole?: UserRole): Promise<CreateUserResponse> {
    try {
      const validRoles: UserRole[] = [UserRole.SUPER_ADMIN, UserRole.ADMIN_INSTITUCION, UserRole.PROFESOR, UserRole.ESTUDIANTE];
      if (!validRoles.includes(userData.rol)) {
        throw new ValidationError('Rol inválido');
      }

// Verificar si el email ya existe
const emailAvailable = await this.isEmailAvailable(userData.email);
if (!emailAvailable) {
  throw new ConflictError('El email ya está registrado');
}

// Hash de la contraseña
const hashedPassword = await bcrypt.hash(userData.password, 10);

// Generar código QR único para estudiantes
let codigoQr: string | undefined;
if (userData.rol === UserRole.ESTUDIANTE) {
  if (!userData.identificacion) {
    throw new ValidationError('La identificación es requerida para estudiantes');
  }
  codigoQr = this.generateUniqueQRCode();
}

// Crear usuario en una transacción
const result = await prisma.$transaction(async (tx: any) => {
  // Crear usuario base
  const newUser = await tx.usuario.create({
    data: {
      email: userData.email.toLowerCase(),
      passwordHash: hashedPassword,
      nombres: userData.nombres,
      apellidos: userData.apellidos,
      rol: userData.rol,
      telefono: userData.telefono,
      identificacion: userData.identificacion,
      // Campos profesor (opcional)
      titulo: userData.titulo,
      especialidad: userData.especialidad,
    },
  });

  // Si se especifica institución, crear relación
  if (userData.institucionId) {
    await tx.usuarioInstitucion.create({
      data: {
        usuarioId: newUser.id,
        institucionId: userData.institucionId,
        rolEnInstitucion: userData.rolEnInstitucion,
      },
    });
  }

  // Si es estudiante, crear registro de estudiante
  let estudianteData: {
    id: string;
    usuarioId: string;
    identificacion: string;
    codigoQr: string;
    nombreResponsable: string | null;
    telefonoResponsable: string | null;
  } | null = null;
  if (userData.rol === UserRole.ESTUDIANTE && userData.identificacion) {
    estudianteData = await tx.estudiante.create({
      data: {
        usuarioId: newUser.id,
        identificacion: userData.identificacion,
        codigoQr: codigoQr!,
        nombreResponsable: userData.nombreResponsable,
        telefonoResponsable: userData.telefonoResponsable,
      },
    });
  }

  return { newUser, estudianteData };
});

// Obtener usuario completo con relaciones
const userWithRelations = await this.getUserById(result.newUser.id);
if (!userWithRelations) {
  throw new Error('Error al obtener usuario creado');
}

// Formatear respuesta
const response: CreateUserResponse = {
  id: userWithRelations.id,
  email: userWithRelations.email,
  nombres: userWithRelations.nombres,
  apellidos: userWithRelations.apellidos,
  rol: userWithRelations.rol as UserRole,
  telefono: userWithRelations.telefono,
  titulo: (userWithRelations as any).titulo ?? null,
  especialidad: (userWithRelations as any).especialidad ?? null,
  activo: userWithRelations.activo,
  instituciones: userWithRelations.usuarioInstituciones?.map(ui => ({
    id: ui.institucion.id,
    nombre: ui.institucion.nombre,
    rolEnInstitucion: ui.rolEnInstitucion,
    activo: ui.activo,
  })) || [],
};

if (result.estudianteData) {
  response.estudiante = {
    id: result.estudianteData.id,
    identificacion: result.estudianteData.identificacion,
    codigoQr: result.estudianteData.codigoQr,
    nombreResponsable: result.estudianteData.nombreResponsable,
    telefonoResponsable: result.estudianteData.telefonoResponsable,
  };
}

      return response;

    } catch (error) {
      logger.error('Error al crear usuario:', error);
      throw error;
    }
  }

  /**
   * Actualiza un usuario
   */
  public static async updateUser(id: string, userData: UpdateUserRequest): Promise < UsuarioExtendido | null > {
  try {
    if(!id || typeof id !== 'string') {
  throw new ValidationError('ID de usuario inválido');
}

// Verificar si el usuario existe
const existingUser = await this.getUserById(id);
if (!existingUser) {
  throw new ValidationError('Usuario no encontrado');
}

// Verificar email si se está cambiando
if (userData.email && userData.email !== existingUser.email) {
  const emailAvailable = await this.isEmailAvailable(userData.email, id);
  if (!emailAvailable) {
    throw new ConflictError('El email ya está registrado');
  }
}

// Actualizar usuario en transacción
const result = await prisma.$transaction(async (tx: any) => {
  // Actualizar usuario base
  const updateData: {
    email?: string;
    nombres?: string;
    apellidos?: string;
    telefono?: string | null;
    activo?: boolean;
    identificacion?: string | null;
    titulo?: string | null;
    especialidad?: string | null;
  } = {};
  if (userData.email !== undefined) updateData.email = userData.email.toLowerCase();
  if (userData.nombres !== undefined) updateData.nombres = userData.nombres;
  if (userData.apellidos !== undefined) updateData.apellidos = userData.apellidos;
  if (userData.telefono !== undefined) updateData.telefono = userData.telefono;
  if (userData.activo !== undefined) updateData.activo = userData.activo;
  if (userData.identificacion !== undefined) updateData.identificacion = userData.identificacion;
  // Actualizar campos de profesor si se proporcionan
  if ((userData as any).titulo !== undefined) updateData.titulo = (userData as any).titulo;
  if ((userData as any).especialidad !== undefined) updateData.especialidad = (userData as any).especialidad;

  const updatedUser = await tx.usuario.update({
    where: { id },
    data: updateData,
  });

  // Actualizar datos de estudiante si aplica
  if (existingUser.rol === UserRole.ESTUDIANTE && (userData.identificacion || userData.nombreResponsable || userData.telefonoResponsable)) {
    const estudianteUpdateData: {
      identificacion?: string;
      nombreResponsable?: string | null;
      telefonoResponsable?: string | null;
    } = {};
    if (userData.identificacion !== undefined) estudianteUpdateData.identificacion = userData.identificacion;
    if (userData.nombreResponsable !== undefined) estudianteUpdateData.nombreResponsable = userData.nombreResponsable;
    if (userData.telefonoResponsable !== undefined) estudianteUpdateData.telefonoResponsable = userData.telefonoResponsable;

    await tx.estudiante.update({
      where: { usuarioId: id },
      data: estudianteUpdateData,
    });
  }

  return updatedUser;
});

// Obtener usuario actualizado con relaciones
return await this.getUserById(id);

    } catch (error) {
  logger.error(`Error al actualizar usuario con ID ${id}:`, error);
  throw error;
}
  }

  /**
   * Cambia la contraseña de un usuario y aumenta tokenVersion para invalidar sesiones
   */
  public static async changeUserPassword(userId: string, newPassword: string): Promise < boolean > {
  try {
    if(!userId || typeof userId !== 'string') {
  throw new ValidationError('ID de usuario inválido');
}
if (!newPassword || typeof newPassword !== 'string' || newPassword.length < 8) {
  throw new ValidationError('La nueva contraseña debe tener al menos 8 caracteres');
}

const user = await prisma.usuario.findUnique({ where: { id: userId } });
if (!user) {
  throw new NotFoundError('Usuario');
}

const hashed = await bcrypt.hash(newPassword, 10);

await prisma.usuario.update({
  where: { id: userId },
  data: {
    passwordHash: hashed,
    tokenVersion: (user.tokenVersion ?? 0) + 1,
  },
});

return true;
    } catch (error) {
  logger.error(`Error changing password for user ${userId}:`, error);
  throw error;
}
  }

  /**
   * Elimina un usuario (desactivación lógica)
   */
  public static async deleteUser(id: string): Promise < boolean > {
  try {
    if(!id || typeof id !== 'string') {
  throw new ValidationError('ID de usuario inválido');
}

// Verificar si el usuario existe
const existingUser = await this.getUserById(id);
if (!existingUser) {
  throw new ValidationError('Usuario no encontrado');
}

// Desactivar usuario (borrado lógico)
await prisma.usuario.update({
  where: { id },
  data: { activo: false },
});

return true;

    } catch (error) {
  logger.error(`Error al eliminar usuario con ID ${id}:`, error);
  throw error;
}
  }

  /**
   * Genera un código QR único
   */
  private static generateUniqueQRCode(): string {
  return randomBytes(16).toString('hex').toUpperCase();
}

  /**
   * Verifica si un usuario existe
   */
  public static async userExists(id: string): Promise < boolean > {
  try {
    if(!id || typeof id !== 'string') {
  return false;
}

const count = await prisma.usuario.count({
  where: { id },
});

return count > 0;
    } catch (error) {
  logger.error(`Error al verificar existencia de usuario ${id}:`, error);
  return false;
}
  }

  /**
   * Verifica si un email está disponible
   */
  public static async isEmailAvailable(email: string, excludeUserId ?: string): Promise < boolean > {
  try {
    if(!email || typeof email !== 'string' || !email.includes('@')) {
  return false;
}

const whereClause: {
  email: string;
  id?: { not: string };
} = { email: email.toLowerCase() };
if (excludeUserId) {
  whereClause.id = { not: excludeUserId };
}

const count = await prisma.usuario.count({
  where: whereClause,
});

return count === 0;
    } catch (error) {
  logger.error(`Error al verificar disponibilidad de email ${email}:`, error);
  return false;
}
  }
}

export default UserService;