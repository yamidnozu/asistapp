import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { NotFoundError, ValidationError } from '../types';

const prisma = new PrismaClient();

export interface CreateProfesorRequest {
  nombres: string;
  apellidos: string;
  email: string;
  password: string;
  institucionId: string;
  grupoId?: string;
}

export interface UpdateProfesorRequest {
  nombres?: string;
  apellidos?: string;
  email?: string;
  grupoId?: string;
  activo?: boolean;
}

export interface ProfesorFilters {
  institucionId: string;
  activo?: boolean;
  search?: string;
}

/**
 * Servicio para gestión de Profesores
 * Usado por Admins de Institución
 * Los profesores son usuarios con rol 'profesor'
 */
export class ProfesorService {

  /**
   * Obtiene todos los profesores de una institución con paginación y filtros
   */
  public static async getAll(
    institucionId: string,
    pagination?: { page?: number; limit?: number },
    filters?: ProfesorFilters
  ) {
    const page = pagination?.page || 1;
    const limit = pagination?.limit || 10;
    const skip = (page - 1) * limit;

    // Construir where clause
    const where: any = {
      rol: 'profesor',
      usuarioInstituciones: {
        some: {
          institucionId,
          activo: true,
        },
      },
    };

    if (filters?.activo !== undefined) {
      where.activo = filters.activo;
    }

    if (filters?.search) {
      where.OR = [
        { nombres: { contains: filters.search, mode: 'insensitive' } },
        { apellidos: { contains: filters.search, mode: 'insensitive' } },
        { email: { contains: filters.search, mode: 'insensitive' } },
      ];
    }

    // Obtener total para paginación
    const total = await prisma.usuario.count({ where });

    // Obtener profesores con información de institución
    const profesores = await prisma.usuario.findMany({
      where,
      skip,
      take: limit,
      include: {
        usuarioInstituciones: {
          where: {
            institucionId,
            activo: true,
          },
          include: {
            institucion: {
              select: {
                id: true,
                nombre: true,
              },
            },
          },
        },
      },
      orderBy: {
        apellidos: 'asc',
      },
    });

    // Formatear respuesta
    const formattedProfesores = profesores.map(profesor => ({
      id: profesor.id,
      nombres: profesor.nombres,
      apellidos: profesor.apellidos,
      email: profesor.email,
      telefono: profesor.telefono,
      activo: profesor.activo,
      institucion: profesor.usuarioInstituciones[0]?.institucion,
      createdAt: profesor.createdAt,
    }));

    return {
      data: formattedProfesores,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Obtiene un profesor por ID y institución
   */
  public static async getById(id: string, institucionId: string) {
    const profesor = await prisma.usuario.findFirst({
      where: {
        id,
        rol: 'profesor',
        usuarioInstituciones: {
          some: {
            institucionId,
            activo: true,
          },
        },
      },
      include: {
        usuarioInstituciones: {
          where: {
            institucionId,
            activo: true,
          },
          include: {
            institucion: {
              select: {
                id: true,
                nombre: true,
              },
            },
          },
        },
      },
    });

    if (!profesor) return null;

    return {
      id: profesor.id,
      nombres: profesor.nombres,
      apellidos: profesor.apellidos,
      email: profesor.email,
      telefono: profesor.telefono,
      activo: profesor.activo,
      institucion: profesor.usuarioInstituciones[0]?.institucion,
      createdAt: profesor.createdAt,
    };
  }

  /**
   * Crea un nuevo profesor
   */
  public static async create(data: CreateProfesorRequest, createdBy: string) {
    // Verificar que el email no exista
    const existingUser = await prisma.usuario.findUnique({
      where: { email: data.email },
    });

    if (existingUser) {
      throw new ValidationError('El email ya está registrado');
    }

    // Verificar que la institución existe
    const institucion = await prisma.institucion.findUnique({
      where: { id: data.institucionId },
    });

    if (!institucion) {
      throw new NotFoundError('Institución');
    }

    // Hash de la contraseña
    const hashedPassword = await bcrypt.hash(data.password, 10);

    // Crear usuario profesor
    const newProfesor = await prisma.usuario.create({
      data: {
        email: data.email,
        passwordHash: hashedPassword,
        nombres: data.nombres,
        apellidos: data.apellidos,
        rol: 'profesor',
        activo: true,
      },
    });

    // Crear relación con institución
    await prisma.usuarioInstitucion.create({
      data: {
        usuarioId: newProfesor.id,
        institucionId: data.institucionId,
        activo: true,
      },
    });

    // Obtener profesor con institución incluida
    const profesorWithInstitucion = await this.getById(newProfesor.id, data.institucionId);

    return profesorWithInstitucion;
  }

  /**
   * Actualiza un profesor
   */
  public static async update(id: string, institucionId: string, data: UpdateProfesorRequest) {
    // Verificar que el profesor existe y pertenece a la institución
    const existingProfesor = await prisma.usuario.findFirst({
      where: {
        id,
        rol: 'profesor',
        usuarioInstituciones: {
          some: {
            institucionId,
            activo: true,
          },
        },
      },
    });

    if (!existingProfesor) {
      throw new NotFoundError('Profesor');
    }

    // Verificar email único si se está cambiando
    if (data.email && data.email !== existingProfesor.email) {
      const emailExists = await prisma.usuario.findUnique({
        where: { email: data.email },
      });

      if (emailExists) {
        throw new ValidationError('El email ya está registrado para otro usuario');
      }
    }

    const updatedProfesor = await prisma.usuario.update({
      where: { id },
      data: {
        nombres: data.nombres,
        apellidos: data.apellidos,
        email: data.email,
        activo: data.activo,
      },
      include: {
        usuarioInstituciones: {
          where: {
            institucionId,
            activo: true,
          },
          include: {
            institucion: {
              select: {
                id: true,
                nombre: true,
              },
            },
          },
        },
      },
    });

    return {
      id: updatedProfesor.id,
      nombres: updatedProfesor.nombres,
      apellidos: updatedProfesor.apellidos,
      email: updatedProfesor.email,
      telefono: updatedProfesor.telefono,
      activo: updatedProfesor.activo,
      institucion: updatedProfesor.usuarioInstituciones[0]?.institucion,
      createdAt: updatedProfesor.createdAt,
    };
  }

  /**
   * Elimina un profesor (desactivación lógica)
   */
  public static async delete(id: string, institucionId: string) {
    // Verificar que el profesor existe y pertenece a la institución
    const existingProfesor = await prisma.usuario.findFirst({
      where: {
        id,
        rol: 'profesor',
        usuarioInstituciones: {
          some: {
            institucionId,
            activo: true,
          },
        },
      },
    });

    if (!existingProfesor) {
      return false;
    }

    // Desactivar profesor (eliminación lógica)
    await prisma.usuario.update({
      where: { id },
      data: { activo: false },
    });

    return true;
  }

  /**
   * Activa/desactiva un profesor
   */
  public static async toggleStatus(id: string, institucionId: string) {
    // Verificar que el profesor existe y pertenece a la institución
    const existingProfesor = await prisma.usuario.findFirst({
      where: {
        id,
        rol: 'profesor',
        usuarioInstituciones: {
          some: {
            institucionId,
            activo: true,
          },
        },
      },
    });

    if (!existingProfesor) {
      throw new NotFoundError('Profesor');
    }

    const updatedProfesor = await prisma.usuario.update({
      where: { id },
      data: { activo: !existingProfesor.activo },
      include: {
        usuarioInstituciones: {
          where: {
            institucionId,
            activo: true,
          },
          include: {
            institucion: {
              select: {
                id: true,
                nombre: true,
              },
            },
          },
        },
      },
    });

    return {
      id: updatedProfesor.id,
      nombres: updatedProfesor.nombres,
      apellidos: updatedProfesor.apellidos,
      email: updatedProfesor.email,
      telefono: updatedProfesor.telefono,
      activo: updatedProfesor.activo,
      institucion: updatedProfesor.usuarioInstituciones[0]?.institucion,
      createdAt: updatedProfesor.createdAt,
    };
  }
}

export default ProfesorService;