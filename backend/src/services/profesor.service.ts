import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import { NotFoundError, ValidationError } from '../types';
import { UserRole } from '../constants/roles';
import logger from '../utils/logger';

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

export interface ClaseDelDiaResponse {
  id: string;
  diaSemana: number;
  horaInicio: string;
  horaFin: string;
  grupo: {
    id: string;
    nombre: string;
    grado: string;
    seccion: string | null;
  };
  materia: {
    id: string;
    nombre: string;
    codigo: string | null;
  };
  periodoAcademico: {
    id: string;
    nombre: string;
    activo: boolean;
  };
  institucion: {
    id: string;
    nombre: string;
  };
}

export class ProfesorService {
  public static async getAll(
    institucionId: string,
    pagination?: { page?: number; limit?: number },
    filters?: ProfesorFilters
  ) {
    try {
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const skip = (page - 1) * limit;

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

      const total = await prisma.usuario.count({ where });

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

      const formattedProfesores = profesores.map((profesor: any) => ({
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
    } catch (error) {
      logger.error('Error al obtener profesores', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener los profesores');
    }
  }

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

  public static async create(data: CreateProfesorRequest, createdBy: string) {
    const existingUser = await prisma.usuario.findUnique({
      where: { email: data.email },
    });

    if (existingUser) {
      throw new ValidationError('El email ya está registrado');
    }

    const institucion = await prisma.institucion.findUnique({
      where: { id: data.institucionId },
    });

    if (!institucion) {
      throw new NotFoundError('Institución');
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);

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

    await prisma.usuarioInstitucion.create({
      data: {
        usuarioId: newProfesor.id,
        institucionId: data.institucionId,
        activo: true,
      },
    });

    const profesorWithInstitucion = await this.getById(newProfesor.id, data.institucionId);

    return profesorWithInstitucion;
  }

  public static async update(id: string, institucionId: string, data: UpdateProfesorRequest) {
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

  public static async delete(id: string, institucionId: string) {
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

    await prisma.usuario.update({
      where: { id },
      data: { activo: false },
    });

    return true;
  }

  public static async toggleStatus(id: string, institucionId: string) {
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

  public static async getClasesDelDia(profesorId: string): Promise<ClaseDelDiaResponse[]> {
    try {
      const hoy = new Date();
      const diaSemana = hoy.getDay() === 0 ? 7 : hoy.getDay();

      const clases = await prisma.horario.findMany({
        where: {
          profesorId: profesorId,
          diaSemana: diaSemana,
          periodoAcademico: {
            activo: true,
          },
        },
        orderBy: [{ horaInicio: 'asc' }],
        include: {
          grupo: {
            select: {
              id: true,
              nombre: true,
              grado: true,
              seccion: true,
            },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              activo: true,
            },
          },
          institucion: {
            select: {
              id: true,
              nombre: true,
            },
          },
        },
      });

      return clases.map((clase: any) => ({
        id: clase.id,
        diaSemana: clase.diaSemana,
        horaInicio: clase.horaInicio,
        horaFin: clase.horaFin,
        grupo: clase.grupo,
        materia: clase.materia,
        periodoAcademico: clase.periodoAcademico,
        institucion: clase.institucion,
      }));
    } catch (error) {
      logger.error('Error al obtener clases del día', error);
      throw new Error('Error al obtener las clases del día');
    }
  }

  public static async getClasesPorDia(profesorId: string, diaSemana: number): Promise<ClaseDelDiaResponse[]> {
    try {
      if (diaSemana < 1 || diaSemana > 7) {
        throw new Error('El día de la semana debe estar entre 1 (Lunes) y 7 (Domingo)');
      }

      const clases = await prisma.horario.findMany({
        where: {
          profesorId: profesorId,
          diaSemana: diaSemana,
          periodoAcademico: {
            activo: true,
          },
        },
        orderBy: [{ horaInicio: 'asc' }],
        include: {
          grupo: {
            select: {
              id: true,
              nombre: true,
              grado: true,
              seccion: true,
            },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              activo: true,
            },
          },
          institucion: {
            select: {
              id: true,
              nombre: true,
            },
          },
        },
      });

      return clases.map((clase: any) => ({
        id: clase.id,
        diaSemana: clase.diaSemana,
        horaInicio: clase.horaInicio,
        horaFin: clase.horaFin,
        grupo: clase.grupo,
        materia: clase.materia,
        periodoAcademico: clase.periodoAcademico,
        institucion: clase.institucion,
      }));
    } catch (error) {
      logger.error('Error al obtener clases por día', error);
      throw new Error('Error al obtener las clases por día');
    }
  }

  /**
   * ✅ OPTIMIZADO: Obtiene el horario semanal completo con UNA SOLA QUERY
   * Antes: 7 queries secuenciales (una por día)
   * Ahora: 1 query que trae todos los días y agrupa en memoria
   */
  public static async getHorarioSemanal(profesorId: string): Promise<{
    [key: number]: ClaseDelDiaResponse[];
  }> {
    try {
      logger.debug('Obteniendo horario semanal optimizado', { profesorId });

      // ✅ UNA SOLA QUERY para traer TODOS los días de la semana
      const todasLasClases = await prisma.horario.findMany({
        where: {
          profesorId: profesorId,
          periodoAcademico: {
            activo: true,
          },
        },
        orderBy: [
          { diaSemana: 'asc' },
          { horaInicio: 'asc' },
        ],
        include: {
          grupo: {
            select: {
              id: true,
              nombre: true,
              grado: true,
              seccion: true,
            },
          },
          materia: {
            select: {
              id: true,
              nombre: true,
              codigo: true,
            },
          },
          periodoAcademico: {
            select: {
              id: true,
              nombre: true,
              activo: true,
            },
          },
          institucion: {
            select: {
              id: true,
              nombre: true,
            },
          },
        },
      });

      // Agrupar clases por día en memoria (muy rápido, O(n))
      const horarioSemanal: { [key: number]: ClaseDelDiaResponse[] } = {};

      // Inicializar todos los días con arrays vacíos
      for (let dia = 1; dia <= 7; dia++) {
        horarioSemanal[dia] = [];
      }

      // Agrupar las clases por día
      for (const clase of todasLasClases) {
        const formatted: ClaseDelDiaResponse = {
          id: clase.id,
          diaSemana: clase.diaSemana,
          horaInicio: clase.horaInicio,
          horaFin: clase.horaFin,
          grupo: clase.grupo,
          materia: clase.materia,
          periodoAcademico: clase.periodoAcademico,
          institucion: clase.institucion,
        };

        horarioSemanal[clase.diaSemana].push(formatted);
      }

      logger.debug('Horario semanal obtenido exitosamente', {
        profesorId,
        totalClases: todasLasClases.length,
      });

      return horarioSemanal;
    } catch (error) {
      logger.error('Error al obtener horario semanal', error);
      throw new Error('Error al obtener el horario semanal');
    }
  }
}

export default ProfesorService;
