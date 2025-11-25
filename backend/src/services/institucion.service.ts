import { prisma } from '../config/database';
import { ConflictError, PaginatedResponse, PaginationParams, ValidationError } from '../types';
import logger from '../utils/logger';

export interface InstitutionFilters {
  activa?: boolean;
  search?: string;
}

export interface CreateInstitutionRequest {
  nombre: string;
  direccion?: string;
  telefono?: string;
  email?: string;
}

export interface UpdateInstitutionRequest {
  nombre?: string;
  direccion?: string;
  telefono?: string;
  email?: string;
  activa?: boolean;
}

export interface InstitutionResponse {
  id: string;
  nombre: string;
  direccion: string | null;
  telefono: string | null;
  email: string | null;
  activa: boolean;
  createdAt: string;
  updatedAt: string;
}

export class InstitucionService {
  /**
   * Obtiene todas las instituciones con paginación y filtros
   */
  public static async getAllInstitutions(pagination?: PaginationParams, filters?: InstitutionFilters): Promise<PaginatedResponse<InstitutionResponse>> {
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

      // Construir cláusula where dinámicamente
      const where: any = {};

      if (filters?.activa !== undefined) {
        where.activa = filters.activa;
      }
      if (filters?.search) {
        where.OR = [
          { nombre: { contains: filters.search, mode: 'insensitive' } },
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          { email: { contains: filters.search, mode: 'insensitive' } },
        ];
      }

      // Get total count
      const total = await prisma.institucion.count({ where });

      // Get paginated institutions; include one admin user if exists to use as contact fallback
      const institutions = await prisma.institucion.findMany({
        orderBy: {
          createdAt: 'desc',
        },
        skip,
        take: limit,
        where,
        include: {
          usuarioInstituciones: {
            where: { rolEnInstitucion: 'admin', activo: true },
            include: { usuario: true },
            take: 1,
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      const data: InstitutionResponse[] = institutions.map((inst: any) => ({
        id: inst.id,
        nombre: inst.nombre,
        // If direccion/telefono/email are null, try to use the first admin's contact as a fallback
        direccion: inst.direccion ?? (inst.usuarioInstituciones?.[0]?.usuario?.direccion ?? null),
        telefono: inst.telefono ?? (inst.usuarioInstituciones?.[0]?.usuario?.telefono ?? null),
        email: inst.email ?? (inst.usuarioInstituciones?.[0]?.usuario?.email ?? null),
        activa: inst.activa,
        createdAt: inst.createdAt.toISOString(),
        updatedAt: inst.updatedAt.toISOString(),
      }));

      const result = {
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

      return result;
    } catch (error) {
      logger.error('Error al obtener todas las instituciones:', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener las instituciones');
    }
  }

  /**
   * Obtiene todos los administradores asociados a una institución
   */
  public static async getAdminsByInstitution(institutionId: string) {
    try {
      if (!institutionId) throw new ValidationError('ID de institución inválido');

      const relations = await prisma.usuarioInstitucion.findMany({
        where: {
          institucionId: institutionId,
          rolEnInstitucion: 'admin',
          activo: true,
        },
        include: {
          usuario: true,
        },
      });

      // Mapear a una estructura usable
      const admins = relations.map((rel: any) => ({
        usuarioId: rel.usuario.id,
        email: rel.usuario.email,
        nombres: rel.usuario.nombres,
        apellidos: rel.usuario.apellidos,
        telefono: rel.usuario.telefono,
        activo: rel.usuario.activo,
        institucionId: rel.institucionId,
        rolEnInstitucion: rel.rolEnInstitucion,
      }));

      return admins;
    } catch (error) {
      logger.error(`Error al obtener admins de la institución ${institutionId}:`, error);
      throw error;
    }
  }

  /**
   * Asigna un usuario existente como admin a una institución
   */
  public static async assignAdminToInstitution(institutionId: string, userId: string) {
    try {
      if (!institutionId || !userId) throw new ValidationError('Parámetros inválidos');

      // Verificar existencia de institución
      const institucion = await prisma.institucion.findUnique({ where: { id: institutionId } });
      if (!institucion) throw new ValidationError('Institución no encontrada');

      // Verificar existencia de usuario
      const usuario = await prisma.usuario.findUnique({ where: { id: userId } });
      if (!usuario) throw new ValidationError('Usuario no encontrado');

      // Actualizar rol principal del usuario a admin_institucion si no lo es
      if (usuario.rol !== 'admin_institucion') {
        await prisma.usuario.update({ where: { id: userId }, data: { rol: 'admin_institucion' } });
      }

      // Crear o Reactivar la relación usuarioInstitucion
      const existingRel = await prisma.usuarioInstitucion.findUnique({
        where: { usuarioId_institucionId: { usuarioId: userId, institucionId: institutionId } },
      });

      if (existingRel) {
        // Reactivar y establecer rol
        await prisma.usuarioInstitucion.update({
          where: { usuarioId_institucionId: { usuarioId: userId, institucionId: institutionId } },
          data: { rolEnInstitucion: 'admin', activo: true },
        });
      } else {
        await prisma.usuarioInstitucion.create({
          data: { usuarioId: userId, institucionId: institutionId, rolEnInstitucion: 'admin', activo: true },
        });
      }

      // Devolver el usuario actualizado
      const updatedUser = await prisma.usuario.findUnique({ where: { id: userId } });
      return updatedUser;
    } catch (error) {
      logger.error(`Error al asignar admin ${userId} a institución ${institutionId}:`, error);
      throw error;
    }
  }

  /**
   * Remueve el rol de administrador de un usuario en una institución (desactiva la relación)
   */
  public static async removeAdminFromInstitution(institutionId: string, userId: string) {
    try {
      if (!institutionId || !userId) throw new ValidationError('Parámetros inválidos');

      const rel = await prisma.usuarioInstitucion.findUnique({
        where: { usuarioId_institucionId: { usuarioId: userId, institucionId: institutionId } },
      });

      if (!rel) {
        throw new ValidationError('Relación usuario-institución no encontrada');
      }

      // Desactivar la relación
      await prisma.usuarioInstitucion.update({
        where: { usuarioId_institucionId: { usuarioId: userId, institucionId: institutionId } },
        data: { activo: false },
      });

      // Si el usuario no tiene otras relaciones activas como admin, degradarlo a 'user'
      const otherActiveAdmin = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: userId, rolEnInstitucion: 'admin', activo: true },
      });

      if (!otherActiveAdmin) {
        // Solo cambiar rol si actualmente es admin_institucion
        const usuario = await prisma.usuario.findUnique({ where: { id: userId } });
        if (usuario && usuario.rol === 'admin_institucion') {
          await prisma.usuario.update({ where: { id: userId }, data: { rol: 'user' } });
        }
      }

  return { usuarioId: userId, institutionId, removed: true };
    } catch (error) {
      logger.error(`Error al remover admin ${userId} de institución ${institutionId}:`, error);
      throw error;
    }
  }

  /**
   * Obtiene una institución por ID
   */
  public static async getInstitutionById(id: string): Promise<InstitutionResponse | null> {
    try {
      if (!id || typeof id !== 'string') {
        throw new ValidationError('ID de institución inválido');
      }

  // Include the first admin user (if any) to use as fallback for missing contact fields.
  // This ensures that institutions without explicit contact info can still
  // show a usable email/phone in the UI by using the admin's contact details.
      const institution = await prisma.institucion.findUnique({
        where: { id },
        include: {
          usuarioInstituciones: {
            where: { rolEnInstitucion: 'admin', activo: true },
            include: { usuario: true },
            take: 1,
          },
        },
      });

      if (!institution) {
        return null;
      }

      // Merge fallback from admin user if institution fields are null
      const fallbackAdmin = institution.usuarioInstituciones?.[0]?.usuario;
  const direccion = institution.direccion ?? null; // no usuario.direccion field; keep null if missing
  const telefono = institution.telefono ?? (fallbackAdmin?.telefono ?? null);
  const email = institution.email ?? (fallbackAdmin?.email ?? null);

      const result = {
        id: institution.id,
        nombre: institution.nombre,
        direccion,
        telefono,
        email,
        activa: institution.activa,
        createdAt: institution.createdAt.toISOString(),
        updatedAt: institution.updatedAt.toISOString(),
      };

      logger.debug(`Institution loaded by id=${id}: ${JSON.stringify(result)}`);

      return result;
    } catch (error) {
      logger.error(`Error al obtener institución con ID ${id}:`, error);
      throw error;
    }
  }

  /**
   * Crea una nueva institución
   */
  public static async createInstitution(data: CreateInstitutionRequest): Promise<InstitutionResponse> {
    try {
      // Validaciones
      if (!data.nombre) {
        throw new ValidationError('Nombre es requerido');
      }

      const institution = await prisma.institucion.create({
        data: {
          nombre: data.nombre,
          direccion: data.direccion,
          telefono: data.telefono,
          email: data.email,
        },
      });

      return {
        id: institution.id,
        nombre: institution.nombre,
        direccion: institution.direccion,
        telefono: institution.telefono,
        email: institution.email,
        activa: institution.activa,
        createdAt: institution.createdAt.toISOString(),
        updatedAt: institution.updatedAt.toISOString(),
      };
    } catch (error) {
      logger.error('Error al crear institución:', error);
      throw error;
    }
  }

  /**
   * Actualiza una institución
   */
  public static async updateInstitution(id: string, data: UpdateInstitutionRequest): Promise<InstitutionResponse | null> {
    try {
      if (!id || typeof id !== 'string') {
        throw new ValidationError('ID de institución inválido');
      }

      // Verificar si la institución existe
      const existingInstitution = await this.getInstitutionById(id);
      if (!existingInstitution) {
        throw new ValidationError('Institución no encontrada');
      }

      const institution = await prisma.institucion.update({
        where: { id },
        data: {
          nombre: data.nombre,
          direccion: data.direccion,
          telefono: data.telefono,
          email: data.email,
          activa: data.activa,
        },
      });

      return {
        id: institution.id,
        nombre: institution.nombre,
        direccion: institution.direccion,
        telefono: institution.telefono,
        email: institution.email,
        activa: institution.activa,
        createdAt: institution.createdAt.toISOString(),
        updatedAt: institution.updatedAt.toISOString(),
      };
    } catch (error) {
      logger.error(`Error al actualizar institución con ID ${id}:`, error);
      throw error;
    }
  }

  /**
   * Elimina una institución
   */
  public static async deleteInstitution(id: string): Promise<boolean> {
    try {
      if (!id || typeof id !== 'string') {
        throw new ValidationError('ID de institución inválido');
      }

      // Verificar si la institución existe
      const existingInstitution = await this.getInstitutionById(id);
      if (!existingInstitution) {
        throw new ValidationError('Institución no encontrada');
      }

      // Verificar si tiene usuarios activos
      const usuariosCount = await prisma.usuarioInstitucion.count({
        where: { institucionId: id, activo: true },
      });

      if (usuariosCount > 0) {
        throw new ConflictError('No se puede eliminar la institución porque tiene usuarios activos asociados');
      }

      await prisma.institucion.delete({
        where: { id },
      });

      return true;
    } catch (error) {
      logger.error(`Error al eliminar institución con ID ${id}:`, error);
      throw error;
    }
  }
}

export default InstitucionService;