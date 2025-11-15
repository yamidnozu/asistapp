import { FastifyInstance } from 'fastify';
import AuthController from '../controllers/auth.controller';
import { authenticate } from '../middleware/auth';

export default async function authRoutes(fastify: FastifyInstance) {
  console.log('🔐 Registrando rutas de autenticación...');

  // Login route
  fastify.post('/login', {
    schema: {
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 5 }
        }
      }
    }
  }, AuthController.login);

  // Verify token route
  fastify.get('/verify', {
    preHandler: authenticate
  }, AuthController.verify);

  // Get user institutions route
  fastify.get('/institutions', {
    preHandler: authenticate
  }, AuthController.getUserInstitutions);

  // Get user academic periods route
  fastify.get('/periods', {
    preHandler: authenticate
  }, AuthController.getUserPeriodos);

  console.log('✅ Rutas de autenticación registradas exitosamente');
}
