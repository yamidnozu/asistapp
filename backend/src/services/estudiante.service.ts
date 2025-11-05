import { prisma } from '../config/database';
import { ConflictError, NotFoundError } from '../types';

export interface CreateEstudianteRequest {
  nombres: string;
  apellidos: string;
  email: string;
  password: string;
  identificacion: string;
  nombreResponsable?: string;
  telefonoResponsable?: string;
  grupoId?: string;
}

export interface UpdateEstudianteRequest {
  nombres?: string;
  apellidos?: string;
  identificacion?: string;
  nombreResponsable?: string;
  telefonoResponsable?: string;
  grupoId?: string;
}

export interface EstudianteFilters {
  activo?: boolean;
  search?: string;
  grupoId?: string;
}

/**
 * Servicio para gestión de estudiantes
 */
export class EstudianteService {

  /**
   * Obtiene todos los estudiantes de una institución
   */
  static async getAllEstudiantesByInstitucion(
    institucionId: string,
    filters: EstudianteFilters = {},
    page: number = 1,
    limit: number = 10
  ) {
    const { activo, search, grupoId } = filters;

    const where: any = {
      usuario: {
        usuarioInstituciones: {
          some: {
            institucionId,
            activo: true,
          },
        },
      },
    };

    // Filtros adicionales
    if (activo !== undefined) {
      where.usuario = { ...where.usuario, activo };
    }

    if (search) {
      where.OR = [
        { usuario: { nombres: { contains: search, mode: 'insensitive' } } },
        { usuario: { apellidos: { contains: search, mode: 'insensitive' } } },
        { identificacion: { contains: search } },
      ];
    }

    if (grupoId) {
      where.estudiantesGrupos = {
        some: { grupoId },
      };
    }

    const [estudiantes, total] = await Promise.all([
      prisma.estudiante.findMany({
        where,
        include: {
          usuario: {
            select: {
              id: true,
              nombres: true,
              apellidos: true,
              email: true,
              activo: true,
              createdAt: true,
            },
          },
          estudiantesGrupos: {
            include: {
              grupo: {
                select: {
                  id: true,
                  nombre: true,
                  grado: true,
                  seccion: true,
                },
              },
            },
          },
          _count: {
            select: {
              asistencias: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * limit,
        take: limit,
      }),
      prisma.estudiante.count({ where }),
    ]);

    return {
      estudiantes,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Obtiene un estudiante por ID
   */
  static async getEstudianteById(id: string, institucionId: string) {
    const estudiante = await prisma.estudiante.findFirst({
      where: {
        id,
        usuario: {
          usuarioInstituciones: {
            some: {
              institucionId,
              activo: true,
            },
          },
        },
      },
      include: {
        usuario: {
          select: {
            id: true,
            nombres: true,
            apellidos: true,
            email: true,
            activo: true,
            createdAt: true,
          },
        },
        estudiantesGrupos: {
          include: {
            grupo: {
              select: {
                id: true,
                nombre: true,
                grado: true,
                seccion: true,
                periodoAcademico: {
                  select: {
                    id: true,
                    nombre: true,
                    activo: true,
                  },
                },
              },
            },
          },
        },
        _count: {
          select: {
            asistencias: true,
          },
        },
      },
    });

    if (!estudiante) {
      throw new NotFoundError('Estudiante no encontrado');
    }

    return estudiante;
  }

  /**
   * Crea un nuevo estudiante
   */
  static async createEstudiante(data: CreateEstudianteRequest, institucionId: string) {
    const {
      nombres,
      apellidos,
      email,
      password,
      identificacion,
      nombreResponsable,
      telefonoResponsable,
      grupoId,
    } = data;

    // Validar que el email no exista
    const existingUser = await prisma.usuario.findUnique({
      where: { email },
    });

    if (existingUser) {
      throw new ConflictError('El email ya está registrado');
    }

    // Validar que la identificación no exista
    const existingEstudiante = await prisma.estudiante.findUnique({
      where: { identificacion },
    });

    if (existingEstudiante) {
      throw new ConflictError('La identificación ya está registrada');
    }

    // Crear el usuario
    const usuario = await prisma.usuario.create({
      data: {
        email,
        passwordHash: await this.hashPassword(password),
        nombres,
        apellidos,
        rol: 'estudiante',
        activo: true,
      },
    });

    // Vincular usuario a institución
    await prisma.usuarioInstitucion.create({
      data: {
        usuarioId: usuario.id,
        institucionId,
        activo: true,
      },
    });

    // Generar código QR único
    const codigoQr = await this.generateUniqueQrCode();

    // Crear el estudiante
    const estudiante = await prisma.estudiante.create({
      data: {
        usuarioId: usuario.id,
        identificacion,
        codigoQr,
        nombreResponsable,
        telefonoResponsable,
      },
      include: {
        usuario: {
          select: {
            id: true,
            nombres: true,
            apellidos: true,
            email: true,
            activo: true,
          },
        },
      },
    });

    // Si se especificó un grupo, asignarlo
    if (grupoId) {
      await this.assignEstudianteToGrupo(estudiante.id, grupoId);
    }

    return estudiante;
  }

  /**
   * Actualiza un estudiante
   */
  static async updateEstudiante(id: string, data: UpdateEstudianteRequest, institucionId: string) {
    const estudiante = await this.getEstudianteById(id, institucionId);

    const {
      nombres,
      apellidos,
      identificacion,
      nombreResponsable,
      telefonoResponsable,
      grupoId,
    } = data;

    // Validar identificación única si se está cambiando
    if (identificacion && identificacion !== estudiante.identificacion) {
      const existingEstudiante = await prisma.estudiante.findUnique({
        where: { identificacion },
      });

      if (existingEstudiante) {
        throw new ConflictError('La identificación ya está registrada');
      }
    }

    // Actualizar usuario si hay datos
    if (nombres || apellidos) {
      await prisma.usuario.update({
        where: { id: estudiante.usuarioId },
        data: {
          ...(nombres && { nombres }),
          ...(apellidos && { apellidos }),
        },
      });
    }

    // Actualizar estudiante
    const estudianteActualizado = await prisma.estudiante.update({
      where: { id },
      data: {
        ...(identificacion && { identificacion }),
        ...(nombreResponsable !== undefined && { nombreResponsable }),
        ...(telefonoResponsable !== undefined && { telefonoResponsable }),
      },
      include: {
        usuario: {
          select: {
            id: true,
            nombres: true,
            apellidos: true,
            email: true,
            activo: true,
          },
        },
        estudiantesGrupos: {
          include: {
            grupo: {
              select: {
                id: true,
                nombre: true,
                grado: true,
                seccion: true,
              },
            },
          },
        },
      },
    });

    // Actualizar grupo si se especificó
    if (grupoId !== undefined) {
      // Remover de todos los grupos actuales
      await prisma.estudianteGrupo.deleteMany({
        where: { estudianteId: id },
      });

      // Asignar al nuevo grupo si se especificó
      if (grupoId) {
        await this.assignEstudianteToGrupo(id, grupoId);
      }
    }

    return estudianteActualizado;
  }

  /**
   * Elimina un estudiante (desactivación lógica)
   */
  static async deleteEstudiante(id: string, institucionId: string) {
    const estudiante = await this.getEstudianteById(id, institucionId);

    // Desactivar usuario
    await prisma.usuario.update({
      where: { id: estudiante.usuarioId },
      data: { activo: false },
    });

    return { message: 'Estudiante eliminado exitosamente' };
  }

  /**
   * Activa/desactiva un estudiante
   */
  static async toggleEstudianteStatus(id: string, institucionId: string) {
    const estudiante = await this.getEstudianteById(id, institucionId);

    const usuario = await prisma.usuario.findUnique({
      where: { id: estudiante.usuarioId },
    });

    if (!usuario) {
      throw new NotFoundError('Usuario no encontrado');
    }

    const nuevoEstado = !usuario.activo;

    await prisma.usuario.update({
      where: { id: estudiante.usuarioId },
      data: { activo: nuevoEstado },
    });

    return {
      id,
      activo: nuevoEstado,
      message: `Estudiante ${nuevoEstado ? 'activado' : 'desactivado'} exitosamente`,
    };
  }

  /**
   * Asigna un estudiante a un grupo
   */
  static async assignEstudianteToGrupo(estudianteId: string, grupoId: string) {
    // Verificar que el estudiante y grupo existan
    const estudiante = await prisma.estudiante.findUnique({
      where: { id: estudianteId },
    });

    if (!estudiante) {
      throw new NotFoundError('Estudiante no encontrado');
    }

    const grupo = await prisma.grupo.findUnique({
      where: { id: grupoId },
    });

    if (!grupo) {
      throw new NotFoundError('Grupo no encontrado');
    }

    // Verificar que no esté ya asignado
    const existingAssignment = await prisma.estudianteGrupo.findFirst({
      where: {
        estudianteId,
        grupoId,
      },
    });

    if (existingAssignment) {
      throw new ConflictError('El estudiante ya está asignado a este grupo');
    }

    // Crear la asignación
    await prisma.estudianteGrupo.create({
      data: {
        estudianteId,
        grupoId,
      },
    });

    return { message: 'Estudiante asignado al grupo exitosamente' };
  }

  /**
   * Remueve un estudiante de un grupo
   */
  static async removeEstudianteFromGrupo(estudianteId: string, grupoId: string) {
    const assignment = await prisma.estudianteGrupo.findFirst({
      where: {
        estudianteId,
        grupoId,
      },
    });

    if (!assignment) {
      throw new NotFoundError('El estudiante no está asignado a este grupo');
    }

    await prisma.estudianteGrupo.delete({
      where: { id: assignment.id },
    });

    return { message: 'Estudiante removido del grupo exitosamente' };
  }

  /**
   * Genera un código QR único
   */
  private static async generateUniqueQrCode(): Promise<string> {
    let codigoQr: string;
    let exists: any;

    do {
      codigoQr = `EST${Date.now()}${Math.random().toString(36).substr(2, 5).toUpperCase()}`;
      exists = await prisma.estudiante.findUnique({
        where: { codigoQr },
      });
    } while (exists);

    return codigoQr;
  }

  /**
   * Hashea una contraseña
   */
  private static async hashPassword(password: string): Promise<string> {
    const bcrypt = await import('bcryptjs');
    return bcrypt.hash(password, 10);
  }
}

export default EstudianteService;