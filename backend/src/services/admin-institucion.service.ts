import bcrypt from 'bcryptjs';
import { prisma } from '../config/database';
import { ConflictError, PaginatedResponse, PaginationParams, ValidationError } from '../types';
import { UserRole } from '../constants/roles';
import logger from '../utils/logger';

export interface CreateAdminInstitucionRequest {
  email: string;
  password: string;
  nombres: string;
  apellidos: string;
  telefono?: string;
  institucionId: string;
}

export interface UpdateAdminInstitucionRequest {
  email?: string;
  nombres?: string;
  apellidos?: string;
  telefono?: string;
  activo?: boolean;
}

export interface AdminInstitucionResponse {
  id: string;
  email: string;
  nombres: string;
  apellidos: string;
  telefono: string | null;
  activo: boolean;
  institucion: {
    id: string;
    nombre: string;
  };
  createdAt: string;
  updatedAt: string;
}

export class AdminInstitucionService {
  /**
   * Obtiene todos los Admins de Institución (solo Super Admin)
   */
  public static async getAll(pagination?: PaginationParams): Promise<PaginatedResponse<AdminInstitucionResponse>> {
    try {
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 20;
      const skip = (page - 1) * limit;

      // Get total count
      const total = await prisma.usuario.count({
        where: { rol: UserRole.ADMIN_INSTITUCION },
      });

      // Get paginated admins
      const admins = await prisma.usuario.findMany({
        where: { rol: UserRole.ADMIN_INSTITUCION },
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
      });

      const totalPages = Math.ceil(total / limit);

      const data: AdminInstitucionResponse[] = admins.map((admin: any) => ({
        id: admin.id,
        email: admin.email,
        nombres: admin.nombres,
        apellidos: admin.apellidos,
        telefono: admin.telefono,
        activo: admin.activo,
        institucion: admin.usuarioInstituciones[0] ? {
          id: admin.usuarioInstituciones[0].institucion.id,
          nombre: admin.usuarioInstituciones[0].institucion.nombre,
        } : { id: '', nombre: '' },
        createdAt: admin.createdAt.toISOString(),
        updatedAt: admin.updatedAt.toISOString(),
      }));

      return {
        data,
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
      logger.error('Error al obtener admins de institución:', error);
      throw error;
    }
  }

  /**
   * Obtiene un Admin de Institución por ID
   */
  public static async getById(id: string): Promise<AdminInstitucionResponse | null> {
    try {
      const admin = await prisma.usuario.findFirst({
        where: {
          id,
          rol: UserRole.ADMIN_INSTITUCION,
        },
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: {
              institucion: true,
            },
          },
        },
      });

      if (!admin) {
        return null;
      }

      return {
        id: admin.id,
        email: admin.email,
        nombres: admin.nombres,
        apellidos: admin.apellidos,
        telefono: admin.telefono,
        activo: admin.activo,
        institucion: admin.usuarioInstituciones[0] ? {
          id: admin.usuarioInstituciones[0].institucion.id,
          nombre: admin.usuarioInstituciones[0].institucion.nombre,
        } : { id: '', nombre: '' },
        createdAt: admin.createdAt.toISOString(),
        updatedAt: admin.updatedAt.toISOString(),
      };
    } catch (error) {
      logger.error(`Error al obtener admin de institución ${id}:`, error);
      throw error;
    }
  }

  /**
   * Crea un nuevo Admin de Institución
   */
  public static async create(data: CreateAdminInstitucionRequest): Promise<AdminInstitucionResponse> {
    try {
      // Validaciones
      if (!data.email || !data.password || !data.nombres || !data.apellidos || !data.institucionId) {
        throw new ValidationError('Campos requeridos faltantes');
      }

      // Verificar que la institución existe
      const institucion = await prisma.institucion.findUnique({
        where: { id: data.institucionId },
      });

      if (!institucion) {
        throw new ValidationError('Institución no encontrada');
      }

      // Verificar que no haya otro admin para esta institución
      const existingAdmin = await prisma.usuarioInstitucion.findFirst({
        where: {
          institucionId: data.institucionId,
          rolEnInstitucion: 'admin',
          activo: true,
        },
      });

      if (existingAdmin) {
        throw new ConflictError('Ya existe un admin para esta institución');
      }

      // Verificar email único
      const emailExists = await prisma.usuario.findUnique({
        where: { email: data.email.toLowerCase() },
      });

      if (emailExists) {
        throw new ConflictError('El email ya está registrado');
      }

      // Hash password
      const hashedPassword = await bcrypt.hash(data.password, 10);

      // Crear admin en transacción
      const result = await prisma.$transaction(async (tx: any) => {
        const admin = await tx.usuario.create({
          data: {
            email: data.email.toLowerCase(),
            passwordHash: hashedPassword,
            nombres: data.nombres,
            apellidos: data.apellidos,
            rol: UserRole.ADMIN_INSTITUCION,
            telefono: data.telefono,
          },
        });

        await tx.usuarioInstitucion.create({
          data: {
            usuarioId: admin.id,
            institucionId: data.institucionId,
            rolEnInstitucion: 'admin',
          },
        });

        return admin;
      });

      // Obtener admin completo
      return await this.getById(result.id) as AdminInstitucionResponse;
    } catch (error) {
      logger.error('Error al crear admin de institución:', error);
      throw error;
    }
  }

  /**
   * Actualiza un Admin de Institución
   */
  public static async update(id: string, data: UpdateAdminInstitucionRequest): Promise<AdminInstitucionResponse | null> {
    try {
      // Verificar que existe
      const existingAdmin = await this.getById(id);
      if (!existingAdmin) {
        throw new ValidationError('Admin de institución no encontrado');
      }

      // Verificar email único si se cambia
      if (data.email && data.email !== existingAdmin.email) {
        const emailExists = await prisma.usuario.findUnique({
          where: { email: data.email.toLowerCase() },
        });

        if (emailExists) {
          throw new ConflictError('El email ya está registrado');
        }
      }

      // Actualizar
      await prisma.usuario.update({
        where: { id },
        data: {
          email: data.email?.toLowerCase(),
          nombres: data.nombres,
          apellidos: data.apellidos,
          telefono: data.telefono,
          activo: data.activo,
        },
      });

      return await this.getById(id);
    } catch (error) {
      logger.error(`Error al actualizar admin de institución ${id}:`, error);
      throw error;
    }
  }

  /**
   * Elimina un Admin de Institución (desactivación lógica)
   */
  public static async delete(id: string): Promise<boolean> {
    try {
      const existingAdmin = await this.getById(id);
      if (!existingAdmin) {
        throw new ValidationError('Admin de institución no encontrado');
      }

      await prisma.usuario.update({
        where: { id },
        data: { activo: false },
      });

      return true;
    } catch (error) {
      logger.error(`Error al eliminar admin de institución ${id}:`, error);
      throw error;
    }
  }

  /**
   * Verifica si un usuario es admin de institución
   */
  public static async isAdminOfInstitution(userId: string, institucionId: string): Promise<boolean> {
    try {
      const relacion = await prisma.usuarioInstitucion.findFirst({
        where: {
          usuarioId: userId,
          institucionId,
          rolEnInstitucion: 'admin',
          activo: true,
        },
      });

      return !!relacion;
    } catch (error) {
      logger.error(`Error al verificar admin de institución ${userId}:`, error);
      return false;
    }
  }
}

export default AdminInstitucionService;