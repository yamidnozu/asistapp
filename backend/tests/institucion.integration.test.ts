/// <reference types="jest" />

import { beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import Fastify from 'fastify';
import { databaseService } from '../src/config/database';
import setupErrorHandler from '../src/middleware/errorHandler';
import routes from '../src/routes';
import AuthService from '../src/services/auth.service';

describe('Institucion Integration Tests', () => {
  let fastify: any;
  let adminToken: string;

  beforeAll(async () => {

    fastify = Fastify({ logger: false });

    setupErrorHandler(fastify);
    fastify.register(routes);

    await databaseService.connect();

    await fastify.ready();
  });

  beforeEach(async () => {

    const client = databaseService.getClient();
    await client.asistencia.deleteMany();
    await client.logNotificacion.deleteMany();
    await client.estudianteGrupo.deleteMany();
    await client.horario.deleteMany();
    await client.grupo.deleteMany();
    await client.materia.deleteMany();
    await client.periodoAcademico.deleteMany();
    await client.configuracion.deleteMany();
    await client.refreshToken.deleteMany();
    await client.usuarioInstitucion.deleteMany();
    await client.estudiante.deleteMany();
    await client.usuario.deleteMany({
      where: {
        email: { not: 'admin@asistapp.com' }
      }
    });
    await client.institucion.deleteMany({
      where: {
        nombre: { not: 'Institución por Defecto' }
      }
    });

    await AuthService.ensureAdminUser();

    // Crear institución por defecto si no existe
    const existingDefault = await databaseService.getClient().institucion.findFirst({
      where: { nombre: 'Institución por Defecto' }
    });

    if (!existingDefault) {
      await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución por Defecto',
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          activa: true,
        },
      });
    }

    const loginResponse = await fastify.inject({
      method: 'POST',
      url: '/auth/login',
      payload: {
        email: 'admin@asistapp.com',
        password: 'pollo',
      },
    });

    const loginBody = JSON.parse(loginResponse.body);
    if (loginBody.success) {
      adminToken = loginBody.data.accessToken;
    } else {
      throw new Error('Could not obtain admin token');
    }
  });

  describe('Token verification', () => {
    it('should verify admin token works', async () => {
      console.log('Testing token:', adminToken.substring(0, 50) + '...');
      
      const response = await fastify.inject({
        method: 'GET',
        url: '/auth/verify',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      console.log('Verify response status:', response.statusCode);
      console.log('Verify response body:', response.body);

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data.valid).toBe(true);
      expect(body.data.usuario.rol).toBe('super_admin');
    });
  });

  describe('GET /instituciones', () => {
    it('should get all instituciones for super_admin', async () => {

      await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución 1',
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          activa: true,
        },
      });

      await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución 2',
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          activa: false,
        },
      });

      const response = await fastify.inject({
        method: 'GET',
        url: '/instituciones',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveLength(3); // 2 creadas + DEFAULT
      expect(body.data[0]).toHaveProperty('id');
      expect(body.data[0]).toHaveProperty('nombre');
      // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
      expect(body.data[0]).toHaveProperty('activa');
    });

    it('should deny access to non-super-admin', async () => {

      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await databaseService.getClient().usuario.create({
        data: {
          email: 'test@example.com',
          passwordHash: hashedPassword,
          nombres: 'Test',
          apellidos: 'User',
          rol: 'admin_institucion',
          activo: true,
        },
      });

      const loginResponse = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'test@example.com',
          password: 'testpass',
        },
      });

      const loginBody = JSON.parse(loginResponse.body);
      const userToken = loginBody.data.accessToken;

      const response = await fastify.inject({
        method: 'GET',
        url: '/instituciones',
        headers: {
          authorization: `Bearer ${userToken}`,
        },
      });

      expect(response.statusCode).toBe(403);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHORIZATION_ERROR');
    });

    it('should deny access without authentication', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/instituciones',
      });

      expect(response.statusCode).toBe(401);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('AUTHENTICATION_ERROR');
    });
  });

  describe('GET /instituciones/:id', () => {
    it('should get institucion by id for super_admin', async () => {
      const institucion = await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución Test',
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          direccion: 'Dirección Test',
          telefono: '123456789',
          email: 'test@institucion.com',
          activa: true,
        },
      });

      const response = await fastify.inject({
        method: 'GET',
        url: `/instituciones/${institucion.id}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data.id).toBe(institucion.id);
      expect(body.data.nombre).toBe('Institución Test');
      // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
      expect(body.data.direccion).toBe('Dirección Test');
      expect(body.data.telefono).toBe('123456789');
      expect(body.data.email).toBe('test@institucion.com');
      expect(body.data.activa).toBe(true);
    });

    it('should return 404 for non-existent institucion', async () => {
      const response = await fastify.inject({
        method: 'GET',
        url: '/instituciones/non-existent-id',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(404);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('NOT_FOUND_ERROR');
    });
  });

  describe('POST /instituciones', () => {
    it('should create new institucion for super_admin', async () => {
      const institucionData = {
        nombre: 'Nueva Institución',
        // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
        direccion: 'Nueva Dirección',
        telefono: '987654321',
        email: 'nueva@institucion.com',
      };

      const response = await fastify.inject({
        method: 'POST',
        url: '/instituciones',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: institucionData,
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data.nombre).toBe('Nueva Institución');
      // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
      expect(body.data.activa).toBe(true); // Por defecto true
      expect(body.message).toBe('Institución creada exitosamente');

      const created = await databaseService.getClient().institucion.findUnique({
        where: { id: body.data.id },
      });
      expect(created).toBeTruthy();
      expect(created?.nombre).toBe('Nueva Institución');
    });

    it('should return 400 for missing required fields', async () => {
      const response = await fastify.inject({
        method: 'POST',
        url: '/instituciones',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: {
          // nombre faltante - campo requerido
        },
      });

      expect(response.statusCode).toBe(400);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('VALIDATION_ERROR');
    });
  });

  describe('PUT /instituciones/:id', () => {
    it('should update institucion for super_admin', async () => {
      const institucion = await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución Original',
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          activa: true,
        },
      });

      const updateData = {
        nombre: 'Institución Actualizada',
        // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
        direccion: 'Dirección Actualizada',
        telefono: '111111111',
        email: 'updated@institucion.com',
        activa: false,
      };

      const response = await fastify.inject({
        method: 'PUT',
        url: `/instituciones/${institucion.id}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: updateData,
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data.nombre).toBe('Institución Actualizada');
      // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
      expect(body.data.activa).toBe(false);
      expect(body.message).toBe('Institución actualizada exitosamente');

      const updated = await databaseService.getClient().institucion.findUnique({
        where: { id: institucion.id },
      });
      expect(updated?.nombre).toBe('Institución Actualizada');
      // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
    });

    it('should return 404 for non-existent institucion', async () => {
      const response = await fastify.inject({
        method: 'PUT',
        url: '/instituciones/non-existent-id',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
        payload: {
          nombre: 'Actualización',
        },
      });

      expect(response.statusCode).toBe(404);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('NOT_FOUND_ERROR');
    });
  });

  describe('DELETE /instituciones/:id', () => {
    it('should delete institucion for super_admin', async () => {
      const institucion = await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución a Eliminar',
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          activa: true,
        },
      });

      const response = await fastify.inject({
        method: 'DELETE',
        url: `/instituciones/${institucion.id}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.message).toBe('Institución eliminada exitosamente');

      const deleted = await databaseService.getClient().institucion.findUnique({
        where: { id: institucion.id },
      });
      expect(deleted).toBeNull();
    });

    it('should return 404 for non-existent institucion', async () => {
      const response = await fastify.inject({
        method: 'DELETE',
        url: '/instituciones/non-existent-id',
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(404);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('NOT_FOUND_ERROR');
    });

    it('should return 409 when trying to delete institucion with active users', async () => {
      const institucion = await databaseService.getClient().institucion.create({
        data: {
          nombre: 'Institución con Usuarios',
          // codigo eliminado - ahora usamos solo el id (UUID) como identificador único
          activa: true,
        },
      });

      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await databaseService.getClient().usuario.create({
        data: {
          email: 'user@institucion.com',
          passwordHash: hashedPassword,
          nombres: 'Test',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });

      await databaseService.getClient().usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          activo: true,
        },
      });

      const response = await fastify.inject({
        method: 'DELETE',
        url: `/instituciones/${institucion.id}`,
        headers: {
          authorization: `Bearer ${adminToken}`,
        },
      });

      expect(response.statusCode).toBe(409);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('CONFLICT_ERROR');
    });
  });
});