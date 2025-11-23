import fastifyCors from '@fastify/cors';
import fastifyFormbody from '@fastify/formbody';
import 'dotenv/config';
import Fastify from 'fastify';
import { config } from './config/app';
import { databaseService } from './config/database';
import { authenticate } from './middleware/auth';
import setupErrorHandler from './middleware/errorHandler';
import routes from './routes';
import AuthService from './services/auth.service';

const fastify = Fastify({
  logger: config.nodeEnv === 'development',
});

fastify.register(fastifyCors, {
  origin: true, // Permite cualquier origen
  credentials: true, // Permite el envío de cookies y credenciales
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});

fastify.register(fastifyFormbody);

// Register authentication decorator
fastify.decorate('authenticate', authenticate);

// TEMPORALMENTE DESHABILITADO PARA PRUEBAS
// fastify.register(fastifyRateLimit, {
//   max: 100, // máximo 100 requests por window
//   timeWindow: '15 minutes',
//   skipOnError: true, // no bloquear si hay error
// });

setupErrorHandler(fastify);

fastify.register(routes);

const start = async () => {
  try {
    if (config.nodeEnv === 'development') {
      console.log('🚀 Iniciando AsistApp Backend v2.0...');
    }

    await databaseService.connect();

    await AuthService.ensureAdminUser();

    if (config.nodeEnv === 'development') {
      console.log('🌐 Iniciando servidor...');
    }
    await fastify.listen({
      port: config.port,
      host: config.host
    });

    if (config.nodeEnv === 'development') {
      console.log('✅ Servidor corriendo en:');
      console.log(`   - Local:   http://localhost:${config.port}`);
      console.log(`   - Red:     http://192.168.20.22:${config.port}`);
      console.log('🎯 API lista para recibir conexiones');
      console.log('📚 Documentación disponible en las URLs anteriores');
    }

    if (config.nodeEnv === 'production') {
      setInterval(() => {
        console.log('💓 Servidor activo...');
      }, 300000); // 5 minutos
    }

  } catch (err) {
    console.error('❌ Error al iniciar servidor:', err);
    fastify.log.error(err);
    process.exit(1);
  }
};

process.on('SIGINT', async () => {
  console.log('\n🛑 Recibida señal SIGINT, cerrando servidor...');

});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Recibida señal SIGTERM, cerrando servidor...');
  await gracefulShutdown();
});

const gracefulShutdown = async () => {
  try {
    console.log('� Cerrando conexiones...');

    await fastify.close();

    await databaseService.disconnect();

    console.log('✅ Servidor cerrado correctamente');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error durante el cierre:', error);
    process.exit(1);
  }
};

process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

start();

export default fastify;