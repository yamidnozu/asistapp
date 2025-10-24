import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';
import Fastify from 'fastify';

const fastify = Fastify({ logger: true });

// Inicializar Prisma de manera lazy
let prisma: PrismaClient;

const getPrisma = () => {
  if (!prisma) {
    console.log('Creando cliente Prisma...');
    prisma = new PrismaClient();
    console.log('Cliente Prisma creado');
  }
  return prisma;
};

// Función para asegurar que existe un usuario administrador
const ensureAdminUser = async () => {
  try {
    console.log('🔍 Verificando usuario administrador...');

    const adminExists = await getPrisma().usuario.findFirst({
      where: { rol: 'super_admin' }
    });

    if (!adminExists) {
      console.log('⚠️ No se encontró usuario administrador. Creando usuario por defecto...');

      const adminPassword = await bcrypt.hash('pollo', 10);

      const admin = await getPrisma().usuario.create({
        data: {
          correoElectronico: 'admin@asistapp.com',
          contrasena: adminPassword,
          nombre: 'Administrador',
          apellidos: 'Sistema',
          rol: 'super_admin',
          activo: true,
        },
      });

      console.log('✅ Usuario administrador creado exitosamente:', admin.correoElectronico);
    } else {
      console.log('✅ Usuario administrador ya existe:', adminExists.correoElectronico);
    }
  } catch (error) {
    console.error('❌ Error al verificar/crear usuario administrador:', error);
    // No salimos del proceso, solo logueamos el error
  }
};

// Ruta de prueba
fastify.get('/', async (request, reply) => {
  return { message: 'Hola Mundo desde AsistApp Backend!' };
});

// Ruta para obtener usuarios
fastify.get('/usuarios', async (request, reply) => {
  try {
    const usuarios = await getPrisma().usuario.findMany();
    return usuarios;
  } catch (error) {
    fastify.log.error(error);
    return { error: 'Error al conectar con la base de datos' };
  }
});

// Iniciar servidor
const start = async () => {
  try {
    console.log('🚀 Iniciando AsistApp Backend...');

    // Asegurar que existe un usuario administrador
    await ensureAdminUser();

    console.log('🌐 Iniciando servidor...');
    await fastify.listen({ port: 3000, host: '0.0.0.0' });
    console.log('✅ Servidor corriendo en http://localhost:3000');
    console.log('🎯 API lista para recibir conexiones');

    // Mantener el proceso vivo
    setInterval(() => {
      console.log('💓 Servidor activo...');
    }, 30000);
  } catch (err) {
    console.error('❌ Error al iniciar servidor:', err);
    fastify.log.error(err);
    process.exit(1);
  }
};

start();

// Manejo de errores no capturados
process.on('uncaughtException', (err) => {
  console.error('Uncaught Exception:', err);
  process.exit(1);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
  process.exit(1);
});