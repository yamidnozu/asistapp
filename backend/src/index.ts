import fastifyCors from '@fastify/cors';
import fastifyRateLimit from '@fastify/rate-limit';
import Fastify from 'fastify';
import { config } from './config/app';
import { databaseService } from './config/database';
import setupErrorHandler from './middleware/errorHandler';
import routes from './routes';
import AuthService from './services/auth.service';

// Crear instancia de Fastify con configuración
const fastify = Fastify({
  logger: config.nodeEnv === 'development',
});

// Registrar CORS para permitir acceso desde cualquier origen
fastify.register(fastifyCors, {
  origin: true, // Permite cualquier origen
  credentials: true, // Permite el envío de cookies y credenciales
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
});

// Registrar rate limiting global
fastify.register(fastifyRateLimit, {
  max: 100, // máximo 100 requests por window
  timeWindow: '15 minutes',
  skipOnError: true, // no bloquear si hay error
});

// Configurar manejo de errores
setupErrorHandler(fastify);

// Registrar rutas
fastify.register(routes);

// Función principal de inicio
const start = async () => {
  try {
    console.log('🚀 Iniciando AsistApp Backend v2.0...');

    // Conectar a la base de datos
    await databaseService.connect();

    // Asegurar que existe un usuario administrador
    await AuthService.ensureAdminUser();

    // Iniciar servidor
    console.log('🌐 Iniciando servidor...');
    await fastify.listen({
      port: config.port,
      host: config.host
    });

    console.log('✅ Servidor corriendo en:');
    console.log(`   - Local:   http://localhost:${config.port}`);
    console.log(`   - Red:     http://192.168.20.22:${config.port}`);
    console.log('🎯 API lista para recibir conexiones');
    console.log('📚 Documentación disponible en las URLs anteriores');

    // Mantener el proceso vivo solo en producción
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

// Manejo de señales de terminación
process.on('SIGINT', async () => {
  console.log('\n🛑 Recibida señal SIGINT, cerrando servidor...');
  // await gracefulShutdown();
});

process.on('SIGTERM', async () => {
  console.log('\n🛑 Recibida señal SIGTERM, cerrando servidor...');
  await gracefulShutdown();
});

// Función de cierre graceful
const gracefulShutdown = async () => {
  try {
    console.log('� Cerrando conexiones...');

    // Cerrar servidor Fastify
    await fastify.close();

    // Cerrar conexión a base de datos
    await databaseService.disconnect();

    console.log('✅ Servidor cerrado correctamente');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error durante el cierre:', error);
    process.exit(1);
  }
};

// Manejo de errores no capturados
process.on('uncaughtException', (err) => {
  console.error('❌ Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('❌ Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});

// Iniciar aplicación
start();

export default fastify;