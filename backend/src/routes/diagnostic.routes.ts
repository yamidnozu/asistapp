/**
 * Rutas de Diagnóstico (Temporales)
 * Endpoints para realizar pruebas internas y verificar el estado del sistema.
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authenticate } from '../middleware/auth';
import { AuthenticatedRequest } from '../types';

export async function diagnosticRoutes(fastify: FastifyInstance) {

    /**
     * GET /diag/whoami
     * Endpoint autenticado que simplemente devuelve el objeto 'user' del token.
     * Sirve para verificar que la autenticación (JWT) funciona correctamente desde el cliente.
     */
    fastify.get('/whoami', {
        preHandler: [authenticate]
    }, async (request: AuthenticatedRequest, reply: FastifyReply) => {
        
        request.log.info(request.user, '<<<< DIAGNOSTICO /whoami: Usuario autenticado correctamente.');

        return reply.send({
            success: true,
            message: 'Si ves esto, tu token JWT es válido y la autenticación funciona.',
            user: request.user,
        });
    });
}

export default diagnosticRoutes;
