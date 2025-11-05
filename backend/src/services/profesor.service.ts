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
    try {
      // Validar parámetros de paginación
      const page = pagination?.page || 1;
      const limit = pagination?.limit || 10;

      if (page < 1 || limit < 1 || limit > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

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
      console.error('Error al obtener profesores:', error);
      if (error instanceof ValidationError) {
        throw error;
      }
      throw new Error('Error al obtener los profesores');
    }
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

  /**
   * Obtiene las clases que el profesor tiene hoy
   * Calcula el día de la semana actual y filtra los horarios correspondientes
   */
  public static async getClasesDelDia(profesorId: string): Promise<ClaseDelDiaResponse[]> {
    try {
      // Obtener el día de la semana actual (1 = Lunes, 7 = Domingo)
      const hoy = new Date();
      const diaSemana = hoy.getDay() === 0 ? 7 : hoy.getDay(); // Convertir 0 (Domingo) a 7

      // Obtener las clases del profesor para hoy
      const clases = await prisma.horario.findMany({
        where: {
          profesorId: profesorId,
          diaSemana: diaSemana,
          periodoAcademico: {
            activo: true, // Solo periodos activos
          },
        },
        orderBy: [
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

      return clases.map((clase: any) => ({
        id: clase.id,
        diaSemana: clase.diaSemana,
        horaInicio: clase.horaInicio,
        horaFin: clase.horaFin,
        grupo: {
          id: clase.grupo.id,
          nombre: clase.grupo.nombre,
          grado: clase.grupo.grado,
          seccion: clase.grupo.seccion,
        },
        materia: {
          id: clase.materia.id,
          nombre: clase.materia.nombre,
          codigo: clase.materia.codigo,
        },
        periodoAcademico: {
          id: clase.periodoAcademico.id,
          nombre: clase.periodoAcademico.nombre,
          activo: clase.periodoAcademico.activo,
        },
        institucion: {
          id: clase.institucion.id,
          nombre: clase.institucion.nombre,
        },
      }));
    } catch (error) {
      console.error('Error al obtener clases del día:', error);
      throw new Error('Error al obtener las clases del día');
    }
  }

  /**
   * Obtiene las clases que el profesor tiene en un día específico de la semana
   */
  public static async getClasesPorDia(profesorId: string, diaSemana: number): Promise<ClaseDelDiaResponse[]> {
    try {
      // Validar que diaSemana esté en rango 1-7
      if (diaSemana < 1 || diaSemana > 7) {
        throw new Error('El día de la semana debe estar entre 1 (Lunes) y 7 (Domingo)');
      }

      const clases = await prisma.horario.findMany({
        where: {
          profesorId: profesorId,
          diaSemana: diaSemana,
          periodoAcademico: {
            activo: true, // Solo periodos activos
          },
        },
        orderBy: [
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

      return clases.map((clase: any) => ({
        id: clase.id,
        diaSemana: clase.diaSemana,
        horaInicio: clase.horaInicio,
        horaFin: clase.horaFin,
        grupo: {
          id: clase.grupo.id,
          nombre: clase.grupo.nombre,
          grado: clase.grupo.grado,
          seccion: clase.grupo.seccion,
        },
        materia: {
          id: clase.materia.id,
          nombre: clase.materia.nombre,
          codigo: clase.materia.codigo,
        },
        periodoAcademico: {
          id: clase.periodoAcademico.id,
          nombre: clase.periodoAcademico.nombre,
          activo: clase.periodoAcademico.activo,
        },
        institucion: {
          id: clase.institucion.id,
          nombre: clase.institucion.nombre,
        },
      }));
    } catch (error) {
      console.error('Error al obtener clases por día:', error);
      throw new Error('Error al obtener las clases por día');
    }
  }

  /**
   * Obtiene el horario semanal completo del profesor
   */
  public static async getHorarioSemanal(profesorId: string): Promise<{
    [key: number]: ClaseDelDiaResponse[];
  }> {
    try {
      const horarioSemanal: { [key: number]: ClaseDelDiaResponse[] } = {};

      // Obtener clases para cada día de la semana
      for (let dia = 1; dia <= 7; dia++) {
        horarioSemanal[dia] = await this.getClasesPorDia(profesorId, dia);
      }

      return horarioSemanal;
    } catch (error) {
      console.error('Error al obtener horario semanal:', error);
      throw new Error('Error al obtener el horario semanal');
    }
  }
}

export default ProfesorService;