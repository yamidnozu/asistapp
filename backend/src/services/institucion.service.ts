import { prisma } from '../config/database';
import { ConflictError, PaginatedResponse, PaginationParams, ValidationError } from '../types';

export interface InstitutionFilters {
  activa?: boolean;
  search?: string;
}

export interface CreateInstitutionRequest {
  nombre: string;
  codigo: string;
  direccion?: string;
  telefono?: string;
  email?: string;
}

export interface UpdateInstitutionRequest {
  nombre?: string;
  codigo?: string;
  direccion?: string;
  telefono?: string;
  email?: string;
  activa?: boolean;
}

export interface InstitutionResponse {
  id: string;
  nombre: string;
  codigo: string;
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
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;
      const skip = (page - 1) * limit;

      // Construir cláusula where dinámicamente
      const where: any = {};

      if (filters?.activa !== undefined) {
        where.activa = filters.activa;
      }
      if (filters?.search) {
        where.OR = [
          { nombre: { contains: filters.search, mode: 'insensitive' } },
          { codigo: { contains: filters.search, mode: 'insensitive' } },
          { email: { contains: filters.search, mode: 'insensitive' } },
        ];
      }

      // Get total count
      const total = await prisma.institucion.count({ where });

      // Get paginated institutions
      const institutions = await prisma.institucion.findMany({
        orderBy: {
          createdAt: 'desc',
        },
        skip,
        take: limit,
        where,
      });

      const totalPages = Math.ceil(total / limit);

      const data: InstitutionResponse[] = institutions.map(inst => ({
        id: inst.id,
        nombre: inst.nombre,
        codigo: inst.codigo,
        direccion: inst.direccion,
        telefono: inst.telefono,
        email: inst.email,
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
      console.error('Error al obtener todas las instituciones:', error);
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

      const institution = await prisma.institucion.findUnique({
        where: { id },
      });

      if (!institution) {
        return null;
      }

      return {
        id: institution.id,
        nombre: institution.nombre,
        codigo: institution.codigo,
        direccion: institution.direccion,
        telefono: institution.telefono,
        email: institution.email,
        activa: institution.activa,
        createdAt: institution.createdAt.toISOString(),
        updatedAt: institution.updatedAt.toISOString(),
      };
    } catch (error) {
      console.error(`Error al obtener institución con ID ${id}:`, error);
      throw error;
    }
  }

  /**
   * Crea una nueva institución
   */
  public static async createInstitution(data: CreateInstitutionRequest): Promise<InstitutionResponse> {
    try {
      // Validaciones
      if (!data.nombre || !data.codigo) {
        throw new ValidationError('Nombre y código son requeridos');
      }

      // Verificar código único
      const existingInstitution = await prisma.institucion.findUnique({
        where: { codigo: data.codigo },
      });

      if (existingInstitution) {
        throw new ConflictError('Ya existe una institución con este código');
      }

      const institution = await prisma.institucion.create({
        data: {
          nombre: data.nombre,
          codigo: data.codigo,
          direccion: data.direccion,
          telefono: data.telefono,
          email: data.email,
        },
      });

      return {
        id: institution.id,
        nombre: institution.nombre,
        codigo: institution.codigo,
        direccion: institution.direccion,
        telefono: institution.telefono,
        email: institution.email,
        activa: institution.activa,
        createdAt: institution.createdAt.toISOString(),
        updatedAt: institution.updatedAt.toISOString(),
      };
    } catch (error) {
      console.error('Error al crear institución:', error);
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

      // Verificar código único si se cambia
      if (data.codigo && data.codigo !== existingInstitution.codigo) {
        const codigoExists = await prisma.institucion.findUnique({
          where: { codigo: data.codigo },
        });

        if (codigoExists) {
          throw new ConflictError('Ya existe una institución con este código');
        }
      }

      const institution = await prisma.institucion.update({
        where: { id },
        data: {
          nombre: data.nombre,
          codigo: data.codigo,
          direccion: data.direccion,
          telefono: data.telefono,
          email: data.email,
          activa: data.activa,
        },
      });

      return {
        id: institution.id,
        nombre: institution.nombre,
        codigo: institution.codigo,
        direccion: institution.direccion,
        telefono: institution.telefono,
        email: institution.email,
        activa: institution.activa,
        createdAt: institution.createdAt.toISOString(),
        updatedAt: institution.updatedAt.toISOString(),
      };
    } catch (error) {
      console.error(`Error al actualizar institución con ID ${id}:`, error);
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
      console.error(`Error al eliminar institución con ID ${id}:`, error);
      throw error;
    }
  }

  /**
   * Verifica si un código está disponible
   */
  public static async isCodeAvailable(codigo: string, excludeInstitutionId?: string): Promise<boolean> {
    try {
      if (!codigo || typeof codigo !== 'string') {
        return false;
      }

      const whereClause: {
        codigo: string;
        id?: { not: string };
      } = { codigo };
      if (excludeInstitutionId) {
        whereClause.id = { not: excludeInstitutionId };
      }

      const count = await prisma.institucion.count({
        where: whereClause,
      });

      return count === 0;
    } catch (error) {
      console.error(`Error al verificar disponibilidad de código ${codigo}:`, error);
      return false;
    }
  }
}

export default InstitucionService;