/// <reference types="jest" />

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import Fastify from 'fastify';
import { databaseService } from '../../src/config/database';
import setupErrorHandler from '../../src/middleware/errorHandler';
import routes from '../../src/routes';
import AuthService from '../../src/services/auth.service';

describe('Institucion fallback contact test', () => {
  let fastify: any;
  let tokenSuperAdmin: string;

  beforeAll(async () => {
    fastify = Fastify({ logger: false });
    setupErrorHandler(fastify);
    fastify.register(routes);
    await databaseService.connect();
    await AuthService.ensureAdminUser();
    await fastify.ready();
    // Clean institutions and users except the default admin
    const client = databaseService.getClient();
    // Eliminar asistencias primero (tienen FK a usuarios/profesores)
    if ((client as any).asistencia) {
      await (client as any).asistencia.deleteMany();
    }
    await client.usuarioInstitucion.deleteMany();
    await client.usuario.deleteMany({ where: { email: { not: 'admin@asistapp.com' } } });
    await client.institucion.deleteMany();
  });

  afterAll(async () => {
    await fastify.close();
    await databaseService.disconnect();
  });

  it('should fall back to admin contact when institution lacks fields', async () => {
    // Login as super admin
    const loginRes = await fastify.inject({ method: 'POST', url: '/auth/login', payload: { email: 'admin@asistapp.com', password: 'pollo' } });
    tokenSuperAdmin = JSON.parse(loginRes.body).data.accessToken;

    // Create institution without email/telefono
    const resInst = await fastify.inject({ method: 'POST', url: '/instituciones', headers: { authorization: `Bearer ${tokenSuperAdmin}` }, payload: { nombre: 'Prueba Fallback Institucion', activa: true } });
    expect(resInst.statusCode).toBe(201);
    const instId = JSON.parse(resInst.body).data.id;

    // Create an admin with contact info
    const resUser = await fastify.inject({ method: 'POST', url: '/usuarios', headers: { authorization: `Bearer ${tokenSuperAdmin}` }, payload: { email: 'admin_fallback@test.com', password: 'test123', nombres: 'Fallback', apellidos: 'Admin', rol: 'admin_institucion', institucionId: instId, telefono: '+573001112233' } });
    expect(resUser.statusCode).toBe(201);

    // Request institution detail
    const resGet = await fastify.inject({ method: 'GET', url: `/instituciones/${instId}`, headers: { authorization: `Bearer ${tokenSuperAdmin}` } });
    expect(resGet.statusCode).toBe(200);
    const body = JSON.parse(resGet.body);
    expect(body.data.email).toBe('admin_fallback@test.com');
    expect(body.data.telefono).toBe('+573001112233');
  });
});

