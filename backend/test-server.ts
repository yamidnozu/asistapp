import Fastify from 'fastify';

// Crear servidor simple para probar
const fastify = Fastify({ logger: true });

fastify.get('/', async (request, reply) => {
  return { message: 'Hola Mundo desde AsistApp Backend refactorizado!' };
});

fastify.get('/usuarios', async (request, reply) => {
  return { message: 'Endpoint de usuarios funcionando' };
});

fastify.post('/login', async (request, reply) => {
  return { message: 'Endpoint de login funcionando' };
});

// Iniciar servidor
const start = async () => {
  try {
    await fastify.listen({ port: 3000, host: '0.0.0.0' });
    console.log('✅ Servidor de prueba corriendo en http://localhost:3000');
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

start();