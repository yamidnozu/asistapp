import { prisma } from '../config/database';
import { ConflictError, NotFoundError, PaginatedResponse, PaginationParams, ValidationError } from '../types';

export interface MateriaFilters {
  search?: string;
}

export interface CreateMateriaRequest {
  nombre: string;
  codigo?: string;
  institucionId: string;
}

export interface UpdateMateriaRequest {
  nombre?: string;
  codigo?: string;
}

export interface MateriaResponse {
  id: string;
  nombre: string;
  codigo: string | null;
  institucionId: string;
  createdAt: string;
  _count?: {
    horarios: number;
  };
}

export class MateriaService {
  /**
   * Obtiene todas las materias de una institución con paginación y filtros
   */
  public static async getAllMateriasByInstitucion(
    institucionId: string,
    pagination?: PaginationParams,
    filters?: MateriaFilters
  ): Promise<PaginatedResponse<MateriaResponse>> {
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

      // Construir cláusula where dinámicamente
      const where: any = {
        institucionId: institucionId,
      };

      if (filters?.search) {
        where.OR = [
          { nombre: { contains: filters.search, mode: 'insensitive' } },
          { codigo: { contains: filters.search, mode: 'insensitive' } },
        ];
      }

      // Obtener total de registros
      const total = await prisma.materia.count({ where });

      // Obtener registros paginados
      const materias = await prisma.materia.findMany({
        where,
        skip,
        take: limit,
        orderBy: [
          { nombre: 'asc' },
        ],
        include: {
          _count: {
            select: {
              horarios: true,
            },
          },
        },
      });

      const totalPages = Math.ceil(total / limit);

      return {
        data: materias.map((materia: any) => ({
          id: materia.id,
          nombre: materia.nombre,
          codigo: materia.codigo,
          institucionId: materia.institucionId,
          createdAt: materia.createdAt.toISOString(),
          _count: materia._count,
        })),
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
      console.error('Error al obtener materias:', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener las materias');
    }
  }

  /**
   * Obtiene una materia por ID
   */
  public static async getMateriaById(id: string): Promise<MateriaResponse | null> {
    try {
      const materia = await prisma.materia.findUnique({
        where: { id },
        include: {
          _count: {
            select: {
              horarios: true,
            },
          },
        },
      });

      if (!materia) {
        return null;
      }

      return {
        id: materia.id,
        nombre: materia.nombre,
        codigo: materia.codigo,
        institucionId: materia.institucionId,
        createdAt: materia.createdAt.toISOString(),
        _count: materia._count,
      };
    } catch (error) {
      console.error('Error al obtener materia:', error);
      throw new Error('Error al obtener la materia');
    }
  }

  /**
   * Crea una nueva materia
   */
  public static async createMateria(data: CreateMateriaRequest): Promise<MateriaResponse> {
    try {
      // Validaciones de campos requeridos
      if (!data.nombre || data.nombre.trim() === '') {
        throw new ValidationError('El nombre de la materia es requerido');
      }

      // Validar que no exista una materia con el mismo nombre en la institución
      const existingMateria = await prisma.materia.findFirst({
        where: {
          nombre: data.nombre.trim(),
          institucionId: data.institucionId,
        },
      });

      if (existingMateria) {
        throw new ConflictError('Ya existe una materia con este nombre en la institución');
      }

      // Si se proporciona código, validar que no exista otro con el mismo código
      if (data.codigo && data.codigo.trim() !== '') {
        const existingCodigo = await prisma.materia.findFirst({
          where: {
            codigo: data.codigo.trim(),
            institucionId: data.institucionId,
          },
        });

        if (existingCodigo) {
          throw new ConflictError('Ya existe una materia con este código en la institución');
        }
      }

      const materia = await prisma.materia.create({
        data: {
          nombre: data.nombre.trim(),
          codigo: data.codigo?.trim() || null,
          institucionId: data.institucionId,
        },
        include: {
          _count: {
            select: {
              horarios: true,
            },
          },
        },
      });

      return {
        id: materia.id,
        nombre: materia.nombre,
        codigo: materia.codigo,
        institucionId: materia.institucionId,
        createdAt: materia.createdAt.toISOString(),
        _count: materia._count,
      };
    } catch (error) {
      console.error('Error al crear materia:', error);
      if (error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al crear la materia');
    }
  }

  /**
   * Actualiza una materia
   */
  public static async updateMateria(id: string, data: UpdateMateriaRequest): Promise<MateriaResponse | null> {
    try {
      // Verificar que la materia existe
      const existingMateria = await prisma.materia.findUnique({
        where: { id },
      });

      if (!existingMateria) {
        throw new NotFoundError('Materia');
      }

      // Si se está cambiando el nombre, validar que no exista otra materia con el mismo nombre
      if (data.nombre && data.nombre !== existingMateria.nombre) {
        const existingMateriaWithName = await prisma.materia.findFirst({
          where: {
            nombre: data.nombre,
            institucionId: existingMateria.institucionId,
            id: { not: id },
          },
        });

        if (existingMateriaWithName) {
          throw new ConflictError('Ya existe una materia con este nombre en la institución');
        }
      }

      // Si se está cambiando el código, validar que no exista otro con el mismo código
      if (data.codigo && data.codigo !== existingMateria.codigo) {
        const existingMateriaWithCodigo = await prisma.materia.findFirst({
          where: {
            codigo: data.codigo,
            institucionId: existingMateria.institucionId,
            id: { not: id },
          },
        });

        if (existingMateriaWithCodigo) {
          throw new ConflictError('Ya existe una materia con este código en la institución');
        }
      }

      const materia = await prisma.materia.update({
        where: { id },
        data: {
          nombre: data.nombre,
          codigo: data.codigo,
        },
        include: {
          _count: {
            select: {
              horarios: true,
            },
          },
        },
      });

      return {
        id: materia.id,
        nombre: materia.nombre,
        codigo: materia.codigo,
        institucionId: materia.institucionId,
        createdAt: materia.createdAt.toISOString(),
        _count: materia._count,
      };
    } catch (error) {
      console.error('Error al actualizar materia:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError || error instanceof ConflictError) {
        throw error;
      }
      throw new Error('Error al actualizar la materia');
    }
  }

  /**
   * Elimina una materia
   */
  public static async deleteMateria(id: string): Promise<boolean> {
    try {
      // Verificar que la materia existe
      const existingMateria = await prisma.materia.findUnique({
        where: { id },
        include: {
          _count: {
            select: {
              horarios: true,
            },
          },
        },
      });

      if (!existingMateria) {
        throw new NotFoundError('Materia');
      }

      // Verificar que no tenga horarios asignados
      if (existingMateria._count.horarios > 0) {
        throw new ValidationError('No se puede eliminar la materia porque tiene horarios asignados');
      }

      await prisma.materia.delete({
        where: { id },
      });

      return true;
    } catch (error) {
      console.error('Error al eliminar materia:', error);
      if (error instanceof NotFoundError || error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al eliminar la materia');
    }
  }

  /**
   * Obtiene las materias disponibles para crear horarios
   */
  public static async getMateriasDisponibles(institucionId: string): Promise<MateriaResponse[]> {
    try {
      const materias = await prisma.materia.findMany({
        where: {
          institucionId: institucionId,
        },
        orderBy: [
          { nombre: 'asc' },
        ],
        include: {
          _count: {
            select: {
              horarios: true,
            },
          },
        },
      });

      return materias.map((materia: any) => ({
        id: materia.id,
        nombre: materia.nombre,
        codigo: materia.codigo,
        institucionId: materia.institucionId,
        createdAt: materia.createdAt.toISOString(),
        _count: materia._count,
      }));
    } catch (error) {
      console.error('Error al obtener materias disponibles:', error);
      throw new Error('Error al obtener las materias disponibles');
    }
  }
}

export default MateriaService;