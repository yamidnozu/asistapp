import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import { ConflictError, InstitucionResponse, NotFoundError, ValidationError } from '../types';

interface GetInstitucionParams {
  id: string;
}

interface CreateInstitucionBody {
  nombre: string;
  codigo: string;
  direccion?: string;
  telefono?: string;
  email?: string;
}

interface UpdateInstitucionBody {
  nombre?: string;
  codigo?: string;
  direccion?: string;
  telefono?: string;
  email?: string;
  activa?: boolean;
}

export class InstitucionController {
  /**
   * Obtiene todas las instituciones (solo super_admin)
   */
  public static async getAll(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const instituciones = await prisma.institucion.findMany({
        orderBy: { createdAt: 'desc' },
      });

      const response: InstitucionResponse[] = instituciones.map(inst => ({
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

      return reply.code(200).send({
        success: true,
        data: response,
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Obtiene una institución por ID (solo super_admin)
   */
  public static async getById(request: AuthenticatedRequest & FastifyRequest<{ Params: GetInstitucionParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const institucion = await prisma.institucion.findUnique({
        where: { id },
      });

      if (!institucion) {
        throw new NotFoundError('Institución');
      }

      const response: InstitucionResponse = {
        id: institucion.id,
        nombre: institucion.nombre,
        codigo: institucion.codigo,
        direccion: institucion.direccion,
        telefono: institucion.telefono,
        email: institucion.email,
        activa: institucion.activa,
        createdAt: institucion.createdAt.toISOString(),
        updatedAt: institucion.updatedAt.toISOString(),
      };

      return reply.code(200).send({
        success: true,
        data: response,
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Crea una nueva institución (solo super_admin)
   */
  public static async create(request: AuthenticatedRequest & FastifyRequest<{ Body: CreateInstitucionBody }>, reply: FastifyReply) {
    try {
      const data = request.body;
      if (!data.nombre || !data.codigo) {
        throw new ValidationError('Nombre y código son requeridos');
      }
      const existingInstitucion = await prisma.institucion.findUnique({
        where: { codigo: data.codigo },
      });

      if (existingInstitucion) {
        throw new ConflictError('Ya existe una institución con este código');
      }

      const institucion = await prisma.institucion.create({
        data: {
          nombre: data.nombre,
          codigo: data.codigo,
          direccion: data.direccion,
          telefono: data.telefono,
          email: data.email,
        },
      });

      const response: InstitucionResponse = {
        id: institucion.id,
        nombre: institucion.nombre,
        codigo: institucion.codigo,
        direccion: institucion.direccion,
        telefono: institucion.telefono,
        email: institucion.email,
        activa: institucion.activa,
        createdAt: institucion.createdAt.toISOString(),
        updatedAt: institucion.updatedAt.toISOString(),
      };

      return reply.code(201).send({
        success: true,
        data: response,
        message: 'Institución creada exitosamente',
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Actualiza una institución (solo super_admin)
   */
  public static async update(request: AuthenticatedRequest & FastifyRequest<{ Params: GetInstitucionParams; Body: UpdateInstitucionBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const data = request.body;
      const existingInstitucion = await prisma.institucion.findUnique({
        where: { id },
      });

      if (!existingInstitucion) {
        throw new NotFoundError('Institución');
      }
      if (data.codigo && data.codigo !== existingInstitucion.codigo) {
        const codigoExists = await prisma.institucion.findUnique({
          where: { codigo: data.codigo },
        });

        if (codigoExists) {
          throw new ConflictError('Ya existe una institución con este código');
        }
      }

      const institucion = await prisma.institucion.update({
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

      const response: InstitucionResponse = {
        id: institucion.id,
        nombre: institucion.nombre,
        codigo: institucion.codigo,
        direccion: institucion.direccion,
        telefono: institucion.telefono,
        email: institucion.email,
        activa: institucion.activa,
        createdAt: institucion.createdAt.toISOString(),
        updatedAt: institucion.updatedAt.toISOString(),
      };

      return reply.code(200).send({
        success: true,
        data: response,
        message: 'Institución actualizada exitosamente',
      });
    } catch (error) {
      throw error;
    }
  }

  /**
   * Elimina una institución (solo super_admin)
   */
  public static async delete(request: AuthenticatedRequest & FastifyRequest<{ Params: GetInstitucionParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const existingInstitucion = await prisma.institucion.findUnique({
        where: { id },
      });

      if (!existingInstitucion) {
        throw new NotFoundError('Institución');
      }
      const usuariosCount = await prisma.usuarioInstitucion.count({
        where: { institucionId: id, activo: true },
      });

      if (usuariosCount > 0) {
        throw new ConflictError('No se puede eliminar la institución porque tiene usuarios activos asociados');
      }

      await prisma.institucion.delete({
        where: { id },
      });

      return reply.code(200).send({
        success: true,
        message: 'Institución eliminada exitosamente',
      });
    } catch (error) {
      throw error;
    }
  }
}

export default InstitucionController;