import { FastifyInstance } from 'fastify';
import adminInstitucionRoutes from './admin-institucion.routes';
import asistenciaRoutes from './asistencia.routes';
import authRoutes from './auth.routes';
import estudianteRoutes from './estudiante.routes';
import grupoRoutes from './grupo.routes';
import horarioRoutes from './horario.routes';
import institucionRoutes from './institucion.routes';
import institutionAdminRoutes from './institution-admin.routes';
import materiaRoutes from './materia.routes';
import profesorRoutes from './profesor.routes';
import userRoutes from './user.routes';

console.log('🔄 Iniciando registro de rutas...');

export default async function routes(fastify: FastifyInstance) {
  console.log('📋 Registrando rutas básicas...');

  fastify.get('/', async (request, reply) => {
    return {
      success: true,
      message: 'Hola Mundo desde AsistApp Backend v2.0!',
      timestamp: new Date().toISOString(),
    };
  });

  fastify.get('/health', async (request, reply) => {
    return reply.code(200).send({
      success: true,
      status: 'healthy',
      timestamp: new Date().toISOString(),
      services: {
        server: 'running'
      },
      uptime: process.uptime()
    });
  });

  await fastify.register(authRoutes, { prefix: '/auth' });
  await fastify.register(userRoutes, { prefix: '/usuarios' });
  await fastify.register(adminInstitucionRoutes, { prefix: '/admin-institucion' });
  await fastify.register(institutionAdminRoutes, { prefix: '/institution-admin' });
  await fastify.register(institucionRoutes, { prefix: '/instituciones' });
  await fastify.register(grupoRoutes, { prefix: '/grupos' });
  await fastify.register(materiaRoutes, { prefix: '/materias' });
  await fastify.register(horarioRoutes, { prefix: '/horarios' });
  await fastify.register(profesorRoutes, { prefix: '/profesores' });
  await fastify.register(asistenciaRoutes, { prefix: '/asistencias' });

  console.log('🎓 Registrando rutas del estudiante...');
  await fastify.register(estudianteRoutes, { prefix: '/estudiantes' });
  console.log('✅ Rutas del estudiante registradas');

  console.log('🎉 Todas las rutas registradas exitosamente');
}