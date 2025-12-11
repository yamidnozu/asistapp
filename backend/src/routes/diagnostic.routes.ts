/**
 * Rutas de Diagnóstico (Temporales)
 * Endpoints para realizar pruebas internas y verificar el estado del sistema.
 */

import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { authenticate } from '../middleware/auth';
import { AuthenticatedRequest } from '../middleware/auth'; // CORREGIDO: Importar desde auth

export async function diagnosticRoutes(fastify: FastifyInstance) {

    /**
     * GET /diag/whoami
     * Endpoint autenticado que simplemente devuelve el objeto 'user' del token.
     * Sirve para verificar que la autenticación (JWT) funciona correctamente desde el cliente.
     */
    fastify.get('/whoami', {
        preHandler: [authenticate]
    }, async (request: FastifyRequest, reply: FastifyReply) => { // CORREGIDO: Usar FastifyRequest genérico
        
        const user = (request as AuthenticatedRequest).user; // CORREGIDO: Castear para acceder a 'user'

        request.log.info(user, '<<<< DIAGNOSTICO /whoami: Usuario autenticado correctamente.');

        return reply.send({
            success: true,
            message: 'Si ves esto, tu token JWT es válido y la autenticación funciona.',
            user: user,
        });
    });
}

export default diagnosticRoutes;
