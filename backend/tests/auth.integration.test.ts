/// <reference types="jest" />

import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
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
    await client.usuarioInstitucion.deleteMany();
    await client.usuario.deleteMany({
      where: {
        email: { not: 'admin@asistapp.com' }
      }
    });
    await client.institucion.deleteMany({
      where: {
        codigo: { not: 'DEFAULT' }
      }
    });
  });

  it('should complete full auth flow: login -> get institutions -> refresh -> logout', async () => {
    // Crear institución de test
    const uniqueCode = `INT${Date.now()}`;
    const institucion = await databaseService.getClient().institucion.create({
      data: {
        nombre: 'Institución Integration',
        codigo: uniqueCode,
        activa: true,
      },
    });

    // Crear usuario de test
    const hashedPassword = await AuthService.hashPassword('integrationpass');
    const user = await databaseService.getClient().usuario.create({
      data: {
        email: 'integration@example.com',
        passwordHash: hashedPassword,
        nombres: 'Integration',
        apellidos: 'Test',
        rol: 'estudiante',
        activo: true,
      },
    });

    // Crear relación usuario-institución
    await databaseService.getClient().usuarioInstitucion.create({
      data: {
        usuarioId: user.id,
        institucionId: institucion.id,
        rolEnInstitucion: 'estudiante',
        activo: true,
      },
    });

    // 1. Login - tokens vienen en el body de la respuesta
    const loginResponse = await fastify.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'integration@example.com',
        password: 'integrationpass',
      },
    });

    expect(loginResponse.statusCode).toBe(200);
    const loginBody = JSON.parse(loginResponse.body);
    expect(loginBody.success).toBe(true);
    expect(loginBody.data).toHaveProperty('accessToken');
    expect(loginBody.data).toHaveProperty('refreshToken');
    expect(loginBody.data.usuario).toHaveProperty('instituciones');
    expect(loginBody.data.usuario.instituciones).toHaveLength(1);

    const accessToken = loginBody.data.accessToken;
    const refreshToken = loginBody.data.refreshToken;

    // 2. Obtener instituciones del usuario
    const institutionsResponse = await fastify.inject({
      method: 'GET',
      url: '/auth/instituciones',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
    });

    expect(institutionsResponse.statusCode).toBe(200);
    const institutionsBody = JSON.parse(institutionsResponse.body);
    expect(institutionsBody.success).toBe(true);
    expect(institutionsBody.data).toHaveLength(1);
    expect(institutionsBody.data[0].id).toBe(institucion.id);

    // 3. Verificar token (usando access token en header Authorization)
    const verifyResponse = await fastify.inject({
      method: 'GET',
      url: '/auth/verify',
      headers: {
        authorization: `Bearer ${accessToken}`,
      },
    });

    expect(verifyResponse.statusCode).toBe(200);
    const verifyBody = JSON.parse(verifyResponse.body);
    expect(verifyBody.success).toBe(true);
    expect(verifyBody.data.valid).toBe(true);

    // 4. Refresh token - enviar refreshToken en el body
    const refreshResponse = await fastify.inject({
      method: 'POST',
      url: '/auth/refresh',
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

    // 5. Logout - enviar refreshToken en el body junto con access token en header
    const logoutResponse = await fastify.inject({
      method: 'POST',
      url: '/auth/logout',
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
      url: '/auth/refresh',
      payload: {
        refreshToken: newRefreshToken, // Token revocado
      },
    });

    expect(refreshAfterLogoutResponse.statusCode).toBe(401);
  });

  it('should handle login with invalid credentials', async () => {
    const response = await fastify.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'nonexistent@example.com',
        password: 'wrongpassword',
      },
    });

    expect(response.statusCode).toBe(401);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(false);
    expect(body.code).toBe('AUTHENTICATION_ERROR');
  });

  it('should handle missing authorization header', async () => {
    const response = await fastify.inject({
      method: 'GET',
      url: '/auth/instituciones',
    });

    expect(response.statusCode).toBe(401);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(false);
    expect(body.code).toBe('AUTHENTICATION_ERROR');
  });

  it('should handle invalid JWT token', async () => {
    const response = await fastify.inject({
      method: 'GET',
      url: '/auth/instituciones',
      headers: {
        authorization: 'Bearer invalid.jwt.token',
      },
    });

    expect(response.statusCode).toBe(401);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(false);
    expect(body.code).toBe('AUTHENTICATION_ERROR');
  });

  it('should handle expired refresh token', async () => {
    // Crear institución de test
    const uniqueCode = `INT${Date.now()}`;
    const institucion = await databaseService.getClient().institucion.create({
      data: {
        nombre: 'Institución Integration',
        codigo: uniqueCode,
        activa: true,
      },
    });

    // Crear usuario de test
    const hashedPassword = await AuthService.hashPassword('integrationpass');
    const user = await databaseService.getClient().usuario.create({
      data: {
        email: 'integration@example.com',
        passwordHash: hashedPassword,
        nombres: 'Integration',
        apellidos: 'Test',
        rol: 'estudiante',
        activo: true,
      },
    });

    // Crear relación usuario-institución
    await databaseService.getClient().usuarioInstitucion.create({
      data: {
        usuarioId: user.id,
        institucionId: institucion.id,
        rolEnInstitucion: 'estudiante',
        activo: true,
      },
    });

    // Crear refresh token expirado manualmente
    const expiredToken = await databaseService.getClient().refreshToken.create({
      data: {
        usuarioId: user.id,
        token: 'expired_token_hash',
        expiresAt: new Date(Date.now() - 1000), // Expirado
        revoked: false,
      },
    });

    // Intentar refresh con token expirado
    const response = await fastify.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: {
        refreshToken: 'expired_token_hash',
      },
    });

    expect(response.statusCode).toBe(401);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(false);
    expect(body.code).toBe('AUTHENTICATION_ERROR');
  });

  it('should handle revoked refresh token', async () => {
    // Crear institución de test
    const uniqueCode = `INT${Date.now()}`;
    const institucion = await databaseService.getClient().institucion.create({
      data: {
        nombre: 'Institución Integration',
        codigo: uniqueCode,
        activa: true,
      },
    });

    // Crear usuario de test
    const hashedPassword = await AuthService.hashPassword('integrationpass');
    const user = await databaseService.getClient().usuario.create({
      data: {
        email: 'integration@example.com',
        passwordHash: hashedPassword,
        nombres: 'Integration',
        apellidos: 'Test',
        rol: 'estudiante',
        activo: true,
      },
    });

    // Crear relación usuario-institución
    await databaseService.getClient().usuarioInstitucion.create({
      data: {
        usuarioId: user.id,
        institucionId: institucion.id,
        rolEnInstitucion: 'estudiante',
        activo: true,
      },
    });

    // Crear refresh token revocado manualmente
    const revokedToken = await databaseService.getClient().refreshToken.create({
      data: {
        usuarioId: user.id,
        token: 'revoked_token_hash',
        expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // Válido
        revoked: true,
      },
    });

    // Intentar refresh con token revocado
    const response = await fastify.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: {
        refreshToken: 'revoked_token_hash',
      },
    });

    expect(response.statusCode).toBe(401);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(false);
    expect(body.code).toBe('AUTHENTICATION_ERROR');
  });

  it('should handle login with inactive user', async () => {
    // Crear institución de test
    const uniqueCode = `INT${Date.now()}`;
    const institucion = await databaseService.getClient().institucion.create({
      data: {
        nombre: 'Institución Integration',
        codigo: uniqueCode,
        activa: true,
      },
    });

    // Crear usuario inactivo
    const hashedPassword = await AuthService.hashPassword('inactivepass');
    const user = await databaseService.getClient().usuario.create({
      data: {
        email: 'inactive@example.com',
        passwordHash: hashedPassword,
        nombres: 'Inactive',
        apellidos: 'User',
        rol: 'estudiante',
        activo: false, // Usuario inactivo
      },
    });

    // Crear relación usuario-institución
    await databaseService.getClient().usuarioInstitucion.create({
      data: {
        usuarioId: user.id,
        institucionId: institucion.id,
        rolEnInstitucion: 'estudiante',
        activo: true,
      },
    });

    const response = await fastify.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'inactive@example.com',
        password: 'inactivepass',
      },
    });

    expect(response.statusCode).toBe(401);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(false);
    expect(body.code).toBe('AUTHENTICATION_ERROR');
  });

  it('should handle missing required fields in login', async () => {
    // Login sin email
    const response1 = await fastify.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        password: 'somepassword',
      },
    });

    expect(response1.statusCode).toBe(400);
    const body1 = JSON.parse(response1.body);
    expect(body1.success).toBe(false);
    expect(body1.code).toBe('VALIDATION_ERROR');

    // Login sin password
    const response2 = await fastify.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'test@example.com',
      },
    });

    expect(response2.statusCode).toBe(400);
    const body2 = JSON.parse(response2.body);
    expect(body2.success).toBe(false);
    expect(body2.code).toBe('VALIDATION_ERROR');
  });

  it('should handle malformed refresh token request', async () => {
    // Refresh sin token
    const response = await fastify.inject({
      method: 'POST',
      url: '/auth/refresh',
      payload: {},
    });

    expect(response.statusCode).toBe(400);
    const body = JSON.parse(response.body);
    expect(body.success).toBe(false);
    expect(body.code).toBe('VALIDATION_ERROR');
  });
});