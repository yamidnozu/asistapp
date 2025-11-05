import { FastifyReply, FastifyRequest } from 'fastify';
import { prisma } from '../config/database';
import { AuthenticatedRequest } from '../middleware/auth';
import MateriaService from '../services/materia.service';
import { NotFoundError, ValidationError } from '../types';

interface GetMateriasQuery {
  page?: string;
  limit?: string;
  search?: string;
}

interface GetMateriaParams {
  id: string;
}

interface CreateMateriaBody {
  nombre: string;
  codigo?: string;
}

interface UpdateMateriaBody {
  nombre?: string;
  codigo?: string;
}

export class MateriaController {
  /**
   * Obtiene todas las materias de la institución del admin autenticado
   */
  public static async getAll(request: AuthenticatedRequest & FastifyRequest<{ Querystring: GetMateriasQuery }>, reply: FastifyReply) {
    try {
      // Obtener la institución del admin autenticado
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const { page, limit, search } = request.query;

      // Validar parámetros de paginación
      const pageNum = page ? parseInt(page, 10) : 1;
      const limitNum = limit ? parseInt(limit, 10) : 10;

      if (pageNum < 1 || limitNum < 1 || limitNum > 100) {
        throw new ValidationError('Los parámetros de paginación deben ser mayores a 0. El límite máximo es 100.');
      }

      const pagination = {
        page: pageNum,
        limit: limitNum,
      };

      const filters = {
        search: search || undefined,
      };

      const result = await MateriaService.getAllMateriasByInstitucion(usuarioInstitucion.institucionId, pagination, filters);

      return reply.code(200).send({
        success: true,
        data: result.data,
        pagination: result.pagination,
      });
    } catch (error) {
      console.error('Error en getAll materias:', error);
      throw error;
    }
  }

  /**
   * Obtiene una materia por ID
   */
  public static async getById(request: AuthenticatedRequest & FastifyRequest<{ Params: GetMateriaParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      const materia = await MateriaService.getMateriaById(id);

      if (!materia) {
        throw new NotFoundError('Materia');
      }

      // Verificar que la materia pertenece a la institución del admin
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && materia.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para acceder a esta materia',
        });
      }

      return reply.code(200).send({
        success: true,
        data: materia,
      });
    } catch (error) {
      console.error('Error en getById materia:', error);
      throw error;
    }
  }

  /**
   * Crea una nueva materia
   */
  public static async create(request: AuthenticatedRequest & FastifyRequest<{ Body: CreateMateriaBody }>, reply: FastifyReply) {
    try {
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const data = {
        ...request.body,
        institucionId: usuarioInstitucion.institucionId,
      };

      const materia = await MateriaService.createMateria(data);

      return reply.code(201).send({
        success: true,
        data: materia,
        message: 'Materia creada exitosamente',
      });
    } catch (error) {
      console.error('Error en create materia:', error);
      throw error;
    }
  }

  /**
   * Actualiza una materia
   */
  public static async update(request: AuthenticatedRequest & FastifyRequest<{ Params: GetMateriaParams; Body: UpdateMateriaBody }>, reply: FastifyReply) {
    try {
      const { id } = request.params;
      const data = request.body;

      // Verificar que la materia existe y pertenece a la institución del admin
      const existingMateria = await MateriaService.getMateriaById(id);
      if (!existingMateria) {
        throw new NotFoundError('Materia');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingMateria.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para modificar esta materia',
        });
      }

      const materia = await MateriaService.updateMateria(id, data);

      if (!materia) {
        throw new NotFoundError('Materia');
      }

      return reply.code(200).send({
        success: true,
        data: materia,
        message: 'Materia actualizada exitosamente',
      });
    } catch (error) {
      console.error('Error en update materia:', error);
      throw error;
    }
  }

  /**
   * Elimina una materia
   */
  public static async delete(request: AuthenticatedRequest & FastifyRequest<{ Params: GetMateriaParams }>, reply: FastifyReply) {
    try {
      const { id } = request.params;

      // Verificar que la materia existe y pertenece a la institución del admin
      const existingMateria = await MateriaService.getMateriaById(id);
      if (!existingMateria) {
        throw new NotFoundError('Materia');
      }

      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (usuarioInstitucion && existingMateria.institucionId !== usuarioInstitucion.institucionId) {
        return reply.code(403).send({
          success: false,
          error: 'No tienes permisos para eliminar esta materia',
        });
      }

      const success = await MateriaService.deleteMateria(id);

      return reply.code(200).send({
        success: true,
        message: 'Materia eliminada exitosamente',
      });
    } catch (error) {
      console.error('Error en delete materia:', error);
      throw error;
    }
  }

  /**
   * Obtiene las materias disponibles para crear horarios
   */
  public static async getMateriasDisponibles(request: AuthenticatedRequest, reply: FastifyReply) {
    try {
      const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
        where: { usuarioId: request.user!.id, activo: true },
      });

      if (!usuarioInstitucion) {
        return reply.code(400).send({
          success: false,
          error: 'El usuario no tiene una institución asignada',
        });
      }

      const materias = await MateriaService.getMateriasDisponibles(usuarioInstitucion.institucionId);

      return reply.code(200).send({
        success: true,
        data: materias,
      });
    } catch (error) {
      console.error('Error en getMateriasDisponibles:', error);
      throw error;
    }
  }
}

export default MateriaController;