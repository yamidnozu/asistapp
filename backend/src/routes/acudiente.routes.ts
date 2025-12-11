/**
 * Rutas del Acudiente
 * Endpoints para que los acudientes puedan ver información de sus hijos
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { UserRole } from '../constants/roles';
import { authenticate, authorize } from '../middleware/auth';
import AcudienteService from '../services/acudiente.service';
import PushNotificationService from '../services/push-notification.service';

interface AuthenticatedRequest extends FastifyRequest {
    user?: {
        id: string;
        email: string;
        role: UserRole;
    };
}

interface GetHijosParams {
    id: string;
}

interface GetAsistenciasQuery {
    page?: string;
    limit?: string;
    fechaInicio?: string;
    fechaFin?: string;
    estado?: string;
}

interface NotificacionParams {
    id: string;
}

interface NotificacionesQuery {
    page?: string;
    limit?: string;
    soloNoLeidas?: string;
}

interface RegistrarDispositivoBody {
    token: string;
    plataforma: 'android' | 'ios' | 'web';
    modelo?: string;
}

interface EliminarDispositivoParams {
    token: string;
}

export async function acudienteRoutes(fastify: FastifyInstance) {
    // Todas las rutas requieren autenticación y rol de acudiente
    fastify.addHook('preHandler', authenticate);
    fastify.addHook('preHandler', authorize([UserRole.ACUDIENTE]));

    /**
     * GET /acudiente/hijos
     * Obtiene la lista de hijos vinculados al acudiente
     */
    fastify.get('/hijos', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const acudienteId = request.user!.id;
            const hijos = await AcudienteService.getHijos(acudienteId);

            return reply.send({
                success: true,
                data: hijos,
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            return reply.status(500).send({
                success: false,
                error: err.message || 'Error al obtener hijos',
            });
        }
    });

    /**
     * GET /acudiente/hijos/:id
     * Obtiene el detalle de un hijo específico
     */
    fastify.get('/hijos/:id', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const acudienteId = request.user!.id;
            const { id: estudianteId } = request.params as GetHijosParams;

            const hijo = await AcudienteService.getHijoDetalle(acudienteId, estudianteId);

            return reply.send({
                success: true,
                data: hijo,
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            const status = err.name === 'NotFoundError' ? 404 : err.name === 'AuthorizationError' ? 403 : 500;
            return reply.status(status).send({
                success: false,
                error: err.message || 'Error al obtener detalle del hijo',
            });
        }
    });

    /**
     * GET /acudiente/hijos/:id/asistencias
     * Obtiene el historial de asistencias de un hijo
     */
    fastify.get('/hijos/:id/asistencias', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const acudienteId = request.user!.id;
            const { id: estudianteId } = request.params as GetHijosParams;
            const query = request.query as GetAsistenciasQuery;

            const page = parseInt(query.page || '1', 10);
            const limit = parseInt(query.limit || '20', 10);
            const fechaInicio = query.fechaInicio ? new Date(query.fechaInicio) : undefined;
            const fechaFin = query.fechaFin ? new Date(query.fechaFin) : undefined;

            const result = await AcudienteService.getHistorialAsistencias(
                acudienteId,
                estudianteId,
                page,
                limit,
                fechaInicio,
                fechaFin,
                query.estado
            );

            return reply.send({
                success: true,
                data: result.asistencias,
                pagination: {
                    total: result.total,
                    page,
                    limit,
                    totalPages: Math.ceil(result.total / limit),
                },
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            const status = err.name === 'AuthorizationError' ? 403 : 500;
            return reply.status(status).send({
                success: false,
                error: err.message || 'Error al obtener historial de asistencias',
            });
        }
    });

    /**
     * GET /acudiente/hijos/:id/estadisticas
     * Obtiene estadísticas completas de un hijo
     */
    fastify.get('/hijos/:id/estadisticas', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const acudienteId = request.user!.id;
            const { id: estudianteId } = request.params as GetHijosParams;

            const estadisticas = await AcudienteService.getEstadisticasCompletas(acudienteId, estudianteId);

            return reply.send({
                success: true,
                data: estadisticas,
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            const status = err.name === 'AuthorizationError' ? 403 : 500;
            return reply.status(status).send({
                success: false,
                error: err.message || 'Error al obtener estadísticas',
            });
        }
    });

    // ========== NOTIFICACIONES ==========

    /**
     * GET /acudiente/notificaciones
     * Obtiene las notificaciones del acudiente
     */
    fastify.get('/notificaciones', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const usuarioId = request.user!.id;
            const query = request.query as NotificacionesQuery;

            const page = parseInt(query.page || '1', 10);
            const limit = parseInt(query.limit || '20', 10);
            const soloNoLeidas = query.soloNoLeidas === 'true';

            const result = await PushNotificationService.obtenerNotificaciones(
                usuarioId,
                page,
                limit,
                soloNoLeidas
            );

            return reply.send({
                success: true,
                data: result.notificaciones,
                noLeidas: result.noLeidas,
                pagination: {
                    total: result.total,
                    page,
                    limit,
                    totalPages: Math.ceil(result.total / limit),
                },
            });
        } catch (error) {
            request.log.error(error);
            return reply.status(500).send({
                success: false,
                error: 'Error al obtener notificaciones',
            });
        }
    });

    /**
     * GET /acudiente/notificaciones/no-leidas/count
     * Obtiene el conteo de notificaciones no leídas
     */
    fastify.get('/notificaciones/no-leidas/count', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const usuarioId = request.user!.id;
            const count = await PushNotificationService.contarNoLeidas(usuarioId);

            return reply.send({
                success: true,
                data: { count },
            });
        } catch (error) {
            request.log.error(error);
            return reply.status(500).send({
                success: false,
                error: 'Error al contar notificaciones',
            });
        }
    });

    /**
     * PUT /acudiente/notificaciones/:id/leer
     * Marca una notificación como leída
     */
    fastify.put('/notificaciones/:id/leer', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const usuarioId = request.user!.id;
            const { id: notificacionId } = request.params as NotificacionParams;

            await PushNotificationService.marcarComoLeida(notificacionId, usuarioId);

            return reply.send({
                success: true,
                message: 'Notificación marcada como leída',
            });
        } catch (error) {
            request.log.error(error);
            const err = error as Error;
            const status = err.name === 'NotFoundError' ? 404 : 500;
            return reply.status(status).send({
                success: false,
                error: err.message || 'Error al marcar notificación',
            });
        }
    });

    /**
     * PUT /acudiente/notificaciones/leer-todas
     * Marca todas las notificaciones como leídas
     */
    fastify.put('/notificaciones/leer-todas', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const usuarioId = request.user!.id;
            const count = await PushNotificationService.marcarTodasComoLeidas(usuarioId);

            return reply.send({
                success: true,
                message: `${count} notificaciones marcadas como leídas`,
                data: { count },
            });
        } catch (error) {
            request.log.error(error);
            return reply.status(500).send({
                success: false,
                error: 'Error al marcar notificaciones',
            });
        }
    });

    // ========== DISPOSITIVOS FCM ==========

    /**
     * POST /acudiente/dispositivo
     * Registra un dispositivo para recibir notificaciones push
     */
    fastify.post('/dispositivo', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        request.log.info({ body: request.body, user: request.user }, '<<<< INICIO de registro de dispositivo');
        try {
            const usuarioId = request.user!.id;
            const body = request.body as RegistrarDispositivoBody;

            await PushNotificationService.registrarDispositivo({
                usuarioId,
                token: body.token,
                plataforma: body.plataforma,
                modelo: body.modelo,
            });

            return reply.status(201).send({
                success: true,
                message: 'Dispositivo registrado exitosamente',
            });
        } catch (error) {
            request.log.error(error, 'Error al registrar dispositivo');
            const err = error as Error;
            return reply.status(400).send({
                success: false,
                error: err.message || 'Error al registrar dispositivo',
            });
        }
    });

    /**
     * DELETE /acudiente/dispositivo/:token
     * Elimina un dispositivo de las notificaciones push
     */
    fastify.delete('/dispositivo/:token', async (request: AuthenticatedRequest, reply: FastifyReply) => {
        try {
            const usuarioId = request.user!.id;
            const { token } = request.params as EliminarDispositivoParams;

            await PushNotificationService.eliminarDispositivo(usuarioId, decodeURIComponent(token));

            return reply.send({
                success: true,
                message: 'Dispositivo eliminado',
            });
        } catch (error) {
            request.log.error(error);
            return reply.status(500).send({
                success: false,
                error: 'Error al eliminar dispositivo',
            });
        }
    });
}

export default acudienteRoutes;
