import { FastifyReply, FastifyRequest } from 'fastify';
import InstitucionService from '../services/institucion.service';
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
  public static async getAll(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const { page, limit, activa, search } = request.query as {
        page?: string;
        limit?: string;
        activa?: string;
        search?: string;
      };

      const pagination = {
        page: page ? parseInt(page, 10) : 1,
        limit: limit ? parseInt(limit, 10) : 10,
      };

      const filters = {
        activa: activa !== undefined ? activa === 'true' : undefined,
        search: search || undefined,
      };

      const result = await InstitucionService.getAllInstitutions(pagination, filters);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
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

      const institution = await InstitucionService.getInstitutionById(id);

      if (!institution) {
        throw new NotFoundError('Institución');
      }

      return reply.code(200).send({
        success: true,
        data: institution,
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

      const institution = await InstitucionService.createInstitution(data);

      return reply.code(201).send({
        success: true,
        data: institution,
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

      const institution = await InstitucionService.updateInstitution(id, data);

      if (!institution) {
        throw new NotFoundError('Institución');
      }

      return reply.code(200).send({
        success: true,
        data: institution,
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

      const success = await InstitucionService.deleteInstitution(id);

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