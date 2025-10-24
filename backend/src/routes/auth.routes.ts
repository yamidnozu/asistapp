import { FastifyInstance } from 'fastify';
import AuthController from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth';

export default async function authRoutes(fastify: FastifyInstance) {
  // Rate limiting estricto para login (5 intentos por 15 min)
  fastify.register(async function (authRoutes) {

    // Ruta de login (pública) con rate limiting estricto
    authRoutes.post('/login', {
      config: {
        rateLimit: {
          max: 5,
          timeWindow: '15 minutes',
        },
      },
      handler: AuthController.login,
    });

    // Ruta de login alternativa SIN rate limiting (solo para desarrollo/testing)
    authRoutes.post('/login-test', {
      handler: AuthController.login,
    });

    // Rutas protegidas
    authRoutes.get('/verify', {
      preHandler: authenticate,
      handler: AuthController.verify,
    });

    authRoutes.post('/logout', {
      preHandler: authenticate,
      handler: AuthController.logout,
    });

    // Ruta para refresh token (pública, pero con rate limiting)
    authRoutes.post('/refresh', {
      config: {
        rateLimit: {
          max: 10,
          timeWindow: '15 minutes',
        },
      },
      handler: AuthController.refreshToken,
    });
  });
}