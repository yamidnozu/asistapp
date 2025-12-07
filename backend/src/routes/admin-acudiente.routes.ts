/**
 * Rutas Admin para gestión de Acudientes
 * Endpoints para que los admins vinculen acudientes con estudiantes
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { UserRole } from '../constants/roles';
import { authenticate, authorize } from '../middleware/auth';
import AcudienteService from '../services/acudiente.service';

interface AuthenticatedRequest extends FastifyRequest {
    user?: {
        id: string;
        email: string;
        role: UserRole;
    };
}

interface VincularParams {
    acudienteId: string;
}

interface VincularBody {
    estudianteId: string;
    parentesco: string;
    esPrincipal?: boolean;
}

interface DesvincularParams {
    acudienteId: string;
    estudianteId: string;
}

interface EstudianteParams {
    estudianteId: string;
}

export async function adminAcudienteRoutes(fastify: FastifyInstance) {
    // Todas las rutas requieren autenticación y rol de admin
    fastify.addHook('preHandler', authenticate);
    fastify.addHook('preHandler', authorize([UserRole.ADMIN_INSTITUCION, UserRole.SUPER_ADMIN]));

    /**
     * POST /admin/acudientes/:acudienteId/vincular
     * Vincula un estudiante a un acudiente
     */
    fastify.post('/acudientes/:acudienteId/vincular', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const { acudienteId } = request.params as VincularParams;
            const { estudianteId, parentesco, esPrincipal } = request.body as VincularBody;

            if (!estudianteId || !parentesco) {
                return reply.status(400).send({
                    success: false,
                    error: 'estudianteId y parentesco son requeridos',
                });
            }

            const vinculo = await AcudienteService.vincularEstudiante(
                acudienteId,
                estudianteId,
                parentesco,
                esPrincipal ?? false
            );

            return reply.status(201).send({
                success: true,
                data: vinculo,
                message: 'Estudiante vinculado exitosamente',
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            const status = err.name === 'NotFoundError' ? 404 :
                err.name === 'ValidationError' ? 400 : 500;
            return reply.status(status).send({
                success: false,
                error: err.message || 'Error al vincular estudiante',
            });
        }
    });

    /**
     * DELETE /admin/acudientes/:acudienteId/desvincular/:estudianteId
     * Desvincula un estudiante de un acudiente
     */
    fastify.delete('/acudientes/:acudienteId/desvincular/:estudianteId', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const { acudienteId, estudianteId } = request.params as DesvincularParams;

            await AcudienteService.desvincularEstudiante(acudienteId, estudianteId);

            return reply.send({
                success: true,
                message: 'Estudiante desvinculado exitosamente',
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            const status = err.name === 'NotFoundError' ? 404 : 500;
            return reply.status(status).send({
                success: false,
                error: err.message || 'Error al desvincular estudiante',
            });
        }
    });

    /**
     * GET /admin/estudiantes/:estudianteId/acudientes
     * Obtiene los acudientes de un estudiante
     */
    fastify.get('/estudiantes/:estudianteId/acudientes', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const { estudianteId } = request.params as EstudianteParams;

            const acudientes = await AcudienteService.getAcudientesDeEstudiante(estudianteId);

            return reply.send({
                success: true,
                data: acudientes,
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            const status = err.name === 'NotFoundError' ? 404 : 500;
            return reply.status(status).send({
                success: false,
                error: err.message || 'Error al obtener acudientes',
            });
        }
    });
}

export default adminAcudienteRoutes;
