/// <reference types="jest" />

import Fastify from 'fastify';
import { databaseService } from '../src/config/database';
import setupErrorHandler from '../src/middleware/errorHandler';
import routes from '../src/routes';
import AuthService from '../src/services/auth.service';

describe('Auth Integration Tests', () => {
  let fastify: any;

  beforeAll(async () => {
    // Crear instancia de Fastify para tests
    fastify = Fastify({ logger: false });

    // Registrar plugins y rutas
    setupErrorHandler(fastify);
    fastify.register(routes);

    // Conectar DB
    await databaseService.connect();
    await AuthService.ensureAdminUser();

    await fastify.ready();
  });

  afterAll(async () => {
    await fastify.close();
    await databaseService.disconnect();
  });

  beforeEach(async () => {
    // Limpiar datos de test, pero preservar usuario admin
    const client = databaseService.getClient();
    await client.refreshToken.deleteMany();
    await client.usuario.deleteMany({
      where: {
        email: { not: 'admin@asistapp.com' }
      }
    });
  });

  it('should complete full auth flow: login -> refresh -> logout', async () => {
    // Crear usuario de test
    const hashedPassword = await AuthService.hashPassword('integrationpass');
    await databaseService.getClient().usuario.create({
      data: {
        email: 'integration@example.com',
        passwordHash: hashedPassword,
        nombres: 'Integration',
        apellidos: 'Test',
        rol: 'estudiante',
        activo: true,
      },
    });

    // 1. Login - tokens vienen en el body de la respuesta
    const loginResponse = await fastify.inject({
      method: 'POST',
      url: '/login',
      payload: {
        email: 'integration@example.com',
        password: 'integrationpass',
      },
    });

    expect(loginResponse.statusCode).toBe(200);
    const loginBody = JSON.parse(loginResponse.body);
    expect(loginBody.success).toBe(true);
    expect(loginBody.data).toHaveProperty('accessToken');
    expect(loginBody.data).toHaveProperty('refreshToken'); // Ahora viene en el body

    const accessToken = loginBody.data.accessToken;
    const refreshToken = loginBody.data.refreshToken;

    // 2. Verificar token (usando access token en header Authorization)
    const verifyResponse = await fastify.inject({
      method: 'GET',
      url: '/verify',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
    });

    expect(verifyResponse.statusCode).toBe(200);
    const verifyBody = JSON.parse(verifyResponse.body);
    expect(verifyBody.success).toBe(true);
    expect(verifyBody.data.valid).toBe(true);

    // 3. Refresh token - enviar refreshToken en el body
    const refreshResponse = await fastify.inject({
      method: 'POST',
      url: '/refresh',
      payload: {
        refreshToken: refreshToken,
      },
    });

    expect(refreshResponse.statusCode).toBe(200);
    const refreshBody = JSON.parse(refreshResponse.body);
    expect(refreshBody.success).toBe(true);
    expect(refreshBody.data).toHaveProperty('accessToken');
    expect(refreshBody.data).toHaveProperty('refreshToken');

    // Verificar que el refresh token fue rotado
    expect(refreshBody.data.refreshToken).not.toBe(refreshToken);

    const newAccessToken = refreshBody.data.accessToken;
    const newRefreshToken = refreshBody.data.refreshToken;

    // 4. Logout - enviar refreshToken en el body junto con access token en header
    const logoutResponse = await fastify.inject({
      method: 'POST',
      url: '/logout',
      headers: {
        authorization: `Bearer ${newAccessToken}`,
      },
      payload: {
        refreshToken: newRefreshToken,
      },
    });

    expect(logoutResponse.statusCode).toBe(200);
    const logoutBody = JSON.parse(logoutResponse.body);
    expect(logoutBody.success).toBe(true);

    // Intentar refresh con el token revocado debería fallar
    const refreshAfterLogoutResponse = await fastify.inject({
      method: 'POST',
      url: '/refresh',
      payload: {
        refreshToken: newRefreshToken, // Token revocado
      },
    });

    expect(refreshAfterLogoutResponse.statusCode).toBe(401);
  });
});