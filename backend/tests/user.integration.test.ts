/// <reference types="jest" />

import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import Fastify from 'fastify';
import { databaseService } from '../src/config/database';
import setupErrorHandler from '../src/middleware/errorHandler';
import routes from '../src/routes';
import AuthService from '../src/services/auth.service';

describe('User Integration Tests', () => {
  let fastify: any;
  let adminToken: string;
  let institucionId: string;
  let studentUserId: string;

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

    // Crear institución de test
    const uniqueCode = `INT${Date.now()}`;
    const institucion = await client.institucion.create({
      data: {
        nombre: 'Institución Test',
        codigo: uniqueCode,
        activa: true,
      },
    });
    institucionId = institucion.id;

    // Crear usuario estudiante de test
    const hashedPassword = await AuthService.hashPassword('studentpass');
    const student = await client.usuario.create({
      data: {
        email: 'student@test.com',
        passwordHash: hashedPassword,
        nombres: 'Estudiante',
        apellidos: 'Test',
        rol: 'estudiante',
        activo: true,
      },
    });
    studentUserId = student.id;

    // Crear relación usuario-institución
    await client.usuarioInstitucion.create({
      data: {
        usuarioId: student.id,
        institucionId: institucion.id,
        rolEnInstitucion: 'estudiante',
        activo: true,
      },
    });

    // Login como admin y obtener token
    const loginResponse = await fastify.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'admin@asistapp.com',
        password: 'pollo',
      },
    });

    const loginBody = JSON.parse(loginResponse.body);
    adminToken = loginBody.data.accessToken;
  });

  describe('GET /usuarios', () => {
    it('should get all users with admin token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data)).toBe(true);
      expect(body.data.length).toBeGreaterThan(0);
    });

    it('should fail without authentication token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios',
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });

    it('should fail with student token (insufficient permissions)', async () => {
      // Login como estudiante
      const loginResponse = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'student@test.com',
          password: 'studentpass',
        },
      });

      const loginBody = JSON.parse(loginResponse.body);
      const studentToken = loginBody.data.accessToken;

      // Intentar acceder con token de estudiante
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${studentToken}`,
        },
      });

      expect(response.statusCode).toBe(403);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHORIZATION_ERROR');
    });
  });

  describe('GET /usuarios/:id', () => {
    it('should get user by id with valid token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: `/usuarios/${studentUserId}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id', studentUserId);
      expect(body.data).toHaveProperty('email', 'student@test.com');
    });

    it('should fail with invalid user id', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios/invalid-id-123',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(404);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('NOT_FOUND_ERROR');
    });

    it('should fail without authentication token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: `/usuarios/${studentUserId}`,
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });
  });

  describe('GET /usuarios/rol/:role', () => {
    it('should get users by role with admin token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios/rol/estudiante',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data)).toBe(true);
      expect(body.data.length).toBeGreaterThan(0);
      expect(body.data[0]).toHaveProperty('rol', 'estudiante');
    });

    it('should return empty array for role with no users', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios/rol/profesor',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data)).toBe(true);
      expect(body.data.length).toBe(0);
    });

    it('should fail without authentication token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios/rol/estudiante',
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });

    it('should fail with student token (insufficient permissions)', async () => {
      // Login como estudiante
      const loginResponse = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'student@test.com',
          password: 'studentpass',
        },
      });

      const loginBody = JSON.parse(loginResponse.body);
      const studentToken = loginBody.data.accessToken;

      // Intentar acceder con token de estudiante
      const response = await fastify.inject({
        method: 'GET',
        url: '/usuarios/rol/estudiante',
        headers: {
          authorization: `Bearer ${studentToken}`,
        },
      });

      expect(response.statusCode).toBe(403);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHORIZATION_ERROR');
    });
  });

  describe('GET /usuarios/institucion/:institucionId', () => {
    it('should get users by institution with valid token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: `/usuarios/institucion/${institucionId}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data)).toBe(true);
      expect(body.data.length).toBeGreaterThan(0);
    });

    it('should return empty array for institution with no users', async () => {
      // Crear institución sin usuarios
      const uniqueCode = `INT${Date.now()}`;
      const emptyInstitution = await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución Vacía',
          codigo: uniqueCode,
          activa: true,
        },
      });

      const response = await fastify.inject({
        method: 'GET',
        url: `/usuarios/institucion/${emptyInstitution.id}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(Array.isArray(body.data)).toBe(true);
      expect(body.data.length).toBe(0);
    });

    it('should fail without authentication token', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: `/usuarios/institucion/${institucionId}`,
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });
  });

  describe('POST /usuarios/admin/cleanup-tokens', () => {
    it('should cleanup expired tokens with super_admin token', async () => {
      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios/admin/cleanup-tokens',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('message');
    });

    it('should fail without authentication token', async () => {
      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios/admin/cleanup-tokens',
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });

    it('should fail with student token (insufficient permissions)', async () => {
      // Login como estudiante
      const loginResponse = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'student@test.com',
          password: 'studentpass',
        },
      });

      const loginBody = JSON.parse(loginResponse.body);
      const studentToken = loginBody.data.accessToken;

      // Intentar acceder con token de estudiante
      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios/admin/cleanup-tokens',
        headers: {
          authorization: `Bearer ${studentToken}`,
        },
      });

      expect(response.statusCode).toBe(403);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHORIZATION_ERROR');
    });
  });
});
