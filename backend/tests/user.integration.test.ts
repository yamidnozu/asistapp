/// <reference types="jest" />

import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import Fastify, { FastifyInstance } from 'fastify';
import { databaseService } from '../src/config/database';
import setupErrorHandler from '../src/middleware/errorHandler';
import routes from '../src/routes';
import AuthService from '../src/services/auth.service';

describe('User Integration Tests', () => {
  let fastify: FastifyInstance;
  let adminToken: string;
  let institucionId: string;
  let studentUserId: string;

  beforeAll(async () => {

    fastify = Fastify({ logger: false });

    setupErrorHandler(fastify);
    fastify.register(routes);

    await databaseService.connect();
    await AuthService.ensureAdminUser();

    await fastify.ready();
  });

  afterAll(async () => {
    await fastify.close();
    await databaseService.disconnect();
  });

  beforeEach(async () => {

    const client = databaseService.getClient();
    await client.refreshToken.deleteMany();
    await client.usuarioInstitucion.deleteMany();
    await client.usuario.deleteMany({
      where: {
        email: { not: 'admin@asistapp.com' }
      }
    });
    await client.institucion.deleteMany();

    const institucion = await client.institucion.create({
      data: {
        nombre: 'Institución Test',
        activa: true,
      },
    });
    institucionId = institucion.id;

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

    await client.usuarioInstitucion.create({
      data: {
        usuarioId: student.id,
        institucionId: institucion.id,
        rolEnInstitucion: 'estudiante',
        activo: true,
      },
    });

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

      const emptyInstitution = await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución Vacía',
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

  describe('POST /usuarios', () => {
    it('should create a new profesor user with admin token', async () => {
      const newUser = {
        email: 'profesor@test.com',
        password: 'password123',
        nombres: 'Juan',
        apellidos: 'Pérez',
        rol: 'profesor',
        telefono: '+1234567890',
        institucionId: institucionId,
        rolEnInstitucion: 'profesor',
      };

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: newUser,
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.email).toBe(newUser.email);
      expect(body.data.nombres).toBe(newUser.nombres);
      expect(body.data.rol).toBe(newUser.rol);
      expect(body.data.instituciones).toHaveLength(1);
    });

    it('should create a new estudiante user with admin token', async () => {
      const newUser = {
        email: 'estudiante2@test.com',
        password: 'password123',
        nombres: 'María',
        apellidos: 'García',
        rol: 'estudiante',
        telefono: '+0987654321',
        institucionId: institucionId,
        rolEnInstitucion: 'estudiante',
        identificacion: '123456789',
        nombreResponsable: 'Padre de María',
        telefonoResponsable: '+111111111',
      };

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: newUser,
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.email).toBe(newUser.email);
      expect(body.data.estudiante).toBeDefined();
      expect(body.data.estudiante.identificacion).toBe(newUser.identificacion);
      expect(body.data.estudiante.nombreResponsable).toBe(newUser.nombreResponsable);
    });

    it('should fail to create user with duplicate email', async () => {
      const newUser = {
        email: 'student@test.com', // Email ya existente
        password: 'password123',
        nombres: 'Duplicado',
        apellidos: 'Usuario',
        rol: 'profesor',
      };

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: newUser,
      });

      expect(response.statusCode).toBe(409);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('CONFLICT_ERROR');
    });

    it('should fail to create estudiante without identificacion', async () => {
      const newUser = {
        email: 'estudiante3@test.com',
        password: 'password123',
        nombres: 'Pedro',
        apellidos: 'López',
        rol: 'estudiante',
        // Falta identificacion
      };

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: newUser,
      });

      expect(response.statusCode).toBe(400);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('VALIDATION_ERROR');
    });

    it('should fail without authentication token', async () => {
      const newUser = {
        email: 'test@test.com',
        password: 'password123',
        nombres: 'Test',
        apellidos: 'User',
        rol: 'profesor',
      };

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        payload: newUser,
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });
  });

  describe('PUT /usuarios/:id', () => {
    it('should update user with admin token', async () => {
      const updateData = {
        nombres: 'Estudiante Actualizado',
        telefono: '+555555555',
      };

      const response = await fastify.inject({
        method: 'PUT',
        url: `/usuarios/${studentUserId}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: updateData,
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data.nombres).toBe(updateData.nombres);
      expect(body.data.telefono).toBe(updateData.telefono);
    });

    it('should update estudiante data', async () => {
      const updateData = {
        nombreResponsable: 'Madre Actualizada',
        telefonoResponsable: '+999999999',
      };

      const response = await fastify.inject({
        method: 'PUT',
        url: `/usuarios/${studentUserId}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: updateData,
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data.estudiante.nombreResponsable).toBe(updateData.nombreResponsable);
      expect(body.data.estudiante.telefonoResponsable).toBe(updateData.telefonoResponsable);
    });

    it('should fail to update with duplicate email', async () => {
      // Crear otro usuario primero
      const otherUser = await databaseService.getClient().usuario.create({
        data: {
          email: 'other@test.com',
          passwordHash: await AuthService.hashPassword('password'),
          nombres: 'Otro',
          apellidos: 'Usuario',
          rol: 'profesor',
          activo: true,
        },
      });

      const updateData = {
        email: 'student@test.com', // Email ya existente
      };

      const response = await fastify.inject({
        method: 'PUT',
        url: `/usuarios/${otherUser.id}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: updateData,
      });

      expect(response.statusCode).toBe(409);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('CONFLICT_ERROR');
    });

    it('should fail with invalid user id', async () => {
      const updateData = {
        nombres: 'Nombre Actualizado',
      };

      const response = await fastify.inject({
        method: 'PUT',
        url: '/usuarios/invalid-id-123',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: updateData,
      });

      expect(response.statusCode).toBe(404);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('NOT_FOUND_ERROR');
    });

    it('should fail without authentication token', async () => {
      const updateData = {
        nombres: 'Nombre Actualizado',
      };

      const response = await fastify.inject({
        method: 'PUT',
        url: `/usuarios/${studentUserId}`,
        payload: updateData,
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });
  });

  describe('DELETE /usuarios/:id', () => {
    it('should delete user with super_admin token', async () => {
      const response = await fastify.inject({
        method: 'DELETE',
        url: `/usuarios/${studentUserId}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.message).toBe('Usuario eliminado exitosamente');

      // Verificar que el usuario esté desactivado
      const checkResponse = await fastify.inject({
        method: 'GET',
        url: `/usuarios/${studentUserId}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(checkResponse.statusCode).toBe(200);
      const checkBody = JSON.parse(checkResponse.body);
      expect(checkBody.data.activo).toBe(false);
    });

    it('should fail with invalid user id', async () => {
      const response = await fastify.inject({
        method: 'DELETE',
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
        method: 'DELETE',
        url: `/usuarios/${studentUserId}`,
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });
  });
});
