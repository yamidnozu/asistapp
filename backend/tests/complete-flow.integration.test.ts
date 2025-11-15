/// <reference types="jest" />

import { afterAll, beforeAll, describe, expect, it } from '@jest/globals';
import Fastify from 'fastify';
import { databaseService } from '../src/config/database';
import setupErrorHandler from '../src/middleware/errorHandler';
import routes from '../src/routes';
import AuthService from '../src/services/auth.service';

describe('Complete Application Flow Integration Test', () => {
  let fastify: any;
  let adminGeneralToken: string;
  let adminInstitucionToken: string;
  let profesorToken: string;
  let estudianteToken: string;

  // IDs de entidades creadas
  let institucionId: string;
  let adminInstitucionId: string;
  let profesorId: string;
  let estudianteUsuarioId: string; // ID del usuario estudiante
  let estudianteId: string; // ID del registro estudiante (para asignaciones)
  let periodoId: string;
  let grupoId: string;
  let materiaId: string;
  let horarioId: string;

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

  describe('Complete Application Flow Test', () => {
    beforeAll(async () => {
      // Limpiar base de datos una vez al inicio del flujo completo
      const client = databaseService.getClient();

      // Eliminar en orden correcto respetando dependencias
      await client.asistencia.deleteMany();
      await client.estudianteGrupo.deleteMany();
      await client.horario.deleteMany();
      await client.materia.deleteMany();
      await client.grupo.deleteMany();
      await client.periodoAcademico.deleteMany();
      await client.usuarioInstitucion.deleteMany();
      await client.refreshToken.deleteMany();
      await client.estudiante.deleteMany();
      await client.usuario.deleteMany({
        where: { email: { not: 'admin@asistapp.com' } }
      });
      await client.institucion.deleteMany();
    });

    it('FASE 1.1: should login as admin general', async () => {
      console.log('🔐 FASE 1.1: Login Admin General');

      const response = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'admin@asistapp.com',
          password: 'pollo',
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('accessToken');
      expect(body.data.usuario.rol).toBe('super_admin');

      adminGeneralToken = body.data.accessToken;
      console.log('✅ Admin General autenticado');
    });

    it('FASE 1.2: should create institution', async () => {
      console.log('🏫 FASE 1.2: Crear Institución');

      const response = await fastify.inject({
        method: 'POST',
        url: '/instituciones',
        headers: {
          authorization: `Bearer ${adminGeneralToken}`,
        },
        payload: {
          nombre: 'Institución de Prueba Completa',
          descripcion: 'Institución para testing completo del flujo',
          activa: true,
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.nombre).toBe('Institución de Prueba Completa');

      institucionId = body.data.id;
      console.log('✅ Institución creada:', institucionId);
    });

    it('FASE 1.3: should create admin institution user', async () => {
      console.log('👨‍💼 FASE 1.3: Crear Admin de Institución');

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminGeneralToken}`,
        },
        payload: {
          email: 'admin.institucion@test.com',
          password: 'admin123',
          nombres: 'Admin',
          apellidos: 'Institución',
          rol: 'admin_institucion',
          institucionId: institucionId,
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.email).toBe('admin.institucion@test.com');

      adminInstitucionId = body.data.id;
      console.log('✅ Admin de Institución creado:', adminInstitucionId);
    });

    it('FASE 1.4: should login as admin institution', async () => {
      console.log('🔐 FASE 1.4: Login Admin de Institución');

      const response = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'admin.institucion@test.com',
          password: 'admin123',
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('accessToken');
      expect(body.data.usuario.rol).toBe('admin_institucion');

      adminInstitucionToken = body.data.accessToken;
      console.log('✅ Admin de Institución autenticado');
    });

    it('FASE 2.1: should create academic period', async () => {
      console.log('📅 FASE 2.1: Crear Periodo Académico');

      const fechaInicio = new Date();
      const fechaFin = new Date();
      fechaFin.setMonth(fechaFin.getMonth() + 6);

      const response = await fastify.inject({
        method: 'POST',
        url: '/periodos-academicos',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          nombre: 'Periodo 2024-2025',
          fechaInicio: fechaInicio.toISOString().split('T')[0],
          fechaFin: fechaFin.toISOString().split('T')[0],
          descripcion: 'Periodo académico de prueba',
          activo: true,
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.nombre).toBe('Periodo 2024-2025');

      periodoId = body.data.id;
      console.log('✅ Periodo Académico creado:', periodoId);
    });

    it('FASE 2.2: should create groups', async () => {
      console.log('👥 FASE 2.2: Crear Grupos');

      const response = await fastify.inject({
        method: 'POST',
        url: '/grupos',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          nombre: 'Grupo A',
          grado: '1ro',
          seccion: 'A',
          descripcion: 'Grupo de primer grado sección A',
          periodoId: periodoId,
          capacidadMaxima: 30,
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.nombre).toBe('Grupo A');

      grupoId = body.data.id;
      console.log('✅ Grupo creado:', grupoId);
    });

    it('FASE 2.3: should create subjects', async () => {
      console.log('📚 FASE 2.3: Crear Materias');

      const response = await fastify.inject({
        method: 'POST',
        url: '/materias',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          nombre: 'Matemáticas',
          codigo: 'MAT101',
          descripcion: 'Matemáticas básicas',
          creditos: 3,
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.nombre).toBe('Matemáticas');

      materiaId = body.data.id;
      console.log('✅ Materia creada:', materiaId);
    });

    it('FASE 2.4: should create professor', async () => {
      console.log('👨‍🏫 FASE 2.4: Crear Profesor');

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          email: 'profesor@test.com',
          password: 'prof123',
          nombres: 'Juan',
          apellidos: 'Pérez',
          rol: 'profesor',
          institucionId: institucionId,
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data.email).toBe('profesor@test.com');

      profesorId = body.data.id;
      console.log('✅ Profesor creado:', profesorId);
    });

    it('FASE 2.5: should create student', async () => {
      console.log('👨‍🎓 FASE 2.5: Crear Estudiante');

      const response = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          email: 'estudiante@test.com',
          password: 'est123',
          nombres: 'María',
          apellidos: 'García',
          rol: 'estudiante',
          institucionId: institucionId,
          identificacion: '1234567890', // Campo requerido para estudiantes
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');
      expect(body.data).toHaveProperty('estudiante');
      expect(body.data.email).toBe('estudiante@test.com');

      estudianteUsuarioId = body.data.id; // ID del usuario
      estudianteId = body.data.estudiante.id; // ID del estudiante (para asignaciones)
      console.log('✅ Estudiante creado:', estudianteUsuarioId, '-> Estudiante ID:', estudianteId);
    });

    it('FASE 2.6: should assign student to group', async () => {
      console.log('🔗 FASE 2.6: Asignar Estudiante a Grupo');

      const response = await fastify.inject({
        method: 'POST',
        url: `/grupos/${grupoId}/asignar-estudiante`,
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          estudianteId: estudianteId,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.message).toContain('asignado');

      console.log('✅ Estudiante asignado a grupo');
    });

    it('FASE 2.7: should get estudiantes by grupo and include usuario object', async () => {
      console.log('📋 FASE 2.7: Obtener Estudiantes por Grupo con estructura esperada');

      const response = await fastify.inject({
        method: 'GET',
        url: `/grupos/${grupoId}/estudiantes?page=1&limit=10`,
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toBeInstanceOf(Array);
      // Si hay estudiantes asignados, validar que la estructura incluya 'nombres', 'apellidos' y 'usuario'
      if (body.data.length > 0) {
        const estudiante = body.data[0];
        expect(estudiante).toHaveProperty('nombres');
        expect(estudiante).toHaveProperty('apellidos');
        expect(estudiante).toHaveProperty('usuario');
        // usuario debería incluir al menos nombres y apellidos
        expect(estudiante.usuario).toHaveProperty('nombres');
        expect(estudiante.usuario).toHaveProperty('apellidos');
        // Los otros campos deben existir y ser strings
        expect(typeof estudiante.nombres).toBe('string');
        expect(typeof estudiante.apellidos).toBe('string');
      }

      console.log('✅ Respuesta de estudiantes por grupo tiene la estructura esperada');
    });

    it('FASE 3.1: should create schedule', async () => {
      console.log('📅 FASE 3.1: Crear Horario');

      const response = await fastify.inject({
        method: 'POST',
        url: '/horarios',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          periodoId: periodoId,
          grupoId: grupoId,
          materiaId: materiaId,
          profesorId: profesorId,
          diaSemana: 1, // Lunes
          horaInicio: '08:00',
          horaFin: '09:00',
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('id');

      horarioId = body.data.id;
      console.log('✅ Horario creado:', horarioId);
    });

    it('FASE 3.2: should get schedules by group', async () => {
      console.log('📋 FASE 3.2: Obtener Horarios por Grupo');

      const response = await fastify.inject({
        method: 'GET',
        url: `/horarios/grupo/${grupoId}`,
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveLength(1);
      expect(body.data[0].id).toBe(horarioId);
  // Verificar que el grupo incluido contiene periodoAcademico
  expect(body.data[0].grupo).toHaveProperty('periodoAcademico');
  expect(body.data[0].grupo.periodoAcademico).toHaveProperty('id');

      console.log('✅ Horarios obtenidos por grupo');
    });

    it('FASE 3.3: should not allow creating overlapping schedule for same group', async () => {
      console.log('📅 FASE 3.3: Crear Horario conflictivo (mismo grupo/hora)');

      const response = await fastify.inject({
        method: 'POST',
        url: '/horarios',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
        payload: {
          periodoId: periodoId,
          grupoId: grupoId,
          materiaId: materiaId,
          profesorId: profesorId,
          diaSemana: 1, // Lunes (mismo dia)
          horaInicio: '08:30', // overlap
          horaFin: '09:30',
        },
      });

      expect(response.statusCode).toBe(409);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.code).toBe('CONFLICT_ERROR');
  expect(body.reason).toBe('grupo_conflict');
  expect(body.meta).toBeDefined();
  expect(Array.isArray(body.meta.conflictingHorarioIds)).toBe(true);
  expect(body.meta.conflictingHorarioIds).toContain(horarioId);

      console.log('✅ Conflicto de horario detectado con code y reason correctos');
    });

    it('FASE 4.1: should login as professor', async () => {
      console.log('🔐 FASE 4.1: Login Profesor');

      const response = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'profesor@test.com',
          password: 'prof123',
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('accessToken');
      expect(body.data.usuario.rol).toBe('profesor');

      profesorToken = body.data.accessToken;
      console.log('✅ Profesor autenticado');
    });

    it('FASE 4.1-B: should get students without group and include usuario when available', async () => {
      console.log('📋 FASE 4.1-B: Obtener estudiantes sin asignar con estructura esperada');

      const response = await fastify.inject({
        method: 'GET',
        url: '/grupos/estudiantes-sin-asignar?page=1&limit=10',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toBeInstanceOf(Array);
      if (body.data.length > 0) {
        const estudiante = body.data[0];
        expect(estudiante).toHaveProperty('nombres');
        expect(estudiante).toHaveProperty('apellidos');
        expect(estudiante).toHaveProperty('usuario');
        expect(estudiante.usuario).toHaveProperty('nombres');
        expect(estudiante.usuario).toHaveProperty('apellidos');
      }

      console.log('✅ Respuesta de estudiantes sin asignar tiene la estructura esperada');
    });

    it('FASE 4.2: should get professor classes for today', async () => {
      console.log('📚 FASE 4.2: Obtener Clases del Día del Profesor');

      const response = await fastify.inject({
        method: 'GET',
        url: '/profesores/dashboard/clases-hoy',
        headers: {
          authorization: `Bearer ${profesorToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      // Puede estar vacío si hoy no es lunes, pero la estructura debe ser correcta
      expect(body.data).toBeInstanceOf(Array);

      console.log('✅ Clases del día obtenidas');
    });

    it('FASE 4.3: should get professor weekly schedule', async () => {
      console.log('📅 FASE 4.3: Obtener Horario Semanal del Profesor');

      const response = await fastify.inject({
        method: 'GET',
        url: '/profesores/dashboard/horario-semanal',
        headers: {
          authorization: `Bearer ${profesorToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toBeInstanceOf(Object);

      console.log('✅ Horario semanal obtenido');
    });

    it('FASE 4.4: should get attendance list for class', async () => {
      console.log('📝 FASE 4.4: Obtener Lista de Asistencia de la Clase');

      const response = await fastify.inject({
        method: 'GET',
        url: `/horarios/${horarioId}/asistencias`,
        headers: {
          authorization: `Bearer ${profesorToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toBeInstanceOf(Array);
      expect(body.data).toHaveLength(1); // Un estudiante asignado
      expect(body.data[0].estudiante.nombres).toBe('María');

      console.log('✅ Lista de asistencia obtenida');
    });

    it('FASE 4.5: should register manual attendance', async () => {
      console.log('✅ FASE 4.5: Registrar Asistencia Manual');

      const response = await fastify.inject({
        method: 'POST',
        url: '/asistencias/registrar-manual',
        headers: {
          authorization: `Bearer ${profesorToken}`,
        },
        payload: {
          horarioId: horarioId,
          estudianteId: estudianteId, // Usar el ID del estudiante (no del usuario)
        },
      });

      expect(response.statusCode).toBe(201);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data.estado).toBe('PRESENTE');

      console.log('✅ Asistencia manual registrada');
    });

    it('FASE 5.1: should login as student', async () => {
      console.log('🔐 FASE 5.1: Login Estudiante');

      const response = await fastify.inject({
        method: 'POST',
        url: '/auth/login',
        payload: {
          email: 'estudiante@test.com',
          password: 'est123',
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('accessToken');
      expect(body.data.usuario.rol).toBe('estudiante');

      estudianteToken = body.data.accessToken;
      console.log('✅ Estudiante autenticado');
    });

    it('FASE 5.2: should get student QR code', async () => {
      console.log('📱 FASE 5.2: Obtener Código QR del Estudiante');

      const response = await fastify.inject({
        method: 'GET',
        url: '/estudiantes/me',
        headers: {
          authorization: `Bearer ${estudianteToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('codigoQr');

      console.log('✅ Código QR obtenido');
    });

    it('FASE 5.3: should register attendance with QR', async () => {
      console.log('📱 FASE 5.3: Registrar Asistencia con QR');

      // Primero obtener el código QR del estudiante
      const qrResponse = await fastify.inject({
        method: 'GET',
        url: '/estudiantes/me',
        headers: {
          authorization: `Bearer ${estudianteToken}`,
        },
      });

      const qrBody = JSON.parse(qrResponse.body);
      const codigoQr = qrBody.data.codigoQr;

      // Intentar registrar asistencia con QR - debería fallar porque ya existe asistencia manual
      const response = await fastify.inject({
        method: 'POST',
        url: '/asistencias/registrar',
        headers: {
          authorization: `Bearer ${profesorToken}`, // El profesor registra la asistencia
        },
        payload: {
          horarioId: horarioId,
          codigoQr: codigoQr,
        },
      });

      // Debería fallar con 400 porque ya existe asistencia para hoy
      expect(response.statusCode).toBe(400);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(false);
      expect(body.error).toBe('ValidationError');

      console.log('✅ Validación de asistencia duplicada funciona correctamente');
    });

    it('FASE 6.1: should get all schedules', async () => {
      console.log('📋 FASE 6.1: Obtener Todos los Horarios');

      const response = await fastify.inject({
        method: 'GET',
        url: '/horarios',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveLength(1);
      expect(body.data[0].id).toBe(horarioId);
  // Verificar que el grupo incluido contiene periodoAcademico
  expect(body.data[0].grupo).toHaveProperty('periodoAcademico');
  expect(body.data[0].grupo.periodoAcademico).toHaveProperty('id');

      console.log('✅ Todos los horarios obtenidos');
    });

    it('FASE 6.2: should get all attendances', async () => {
      console.log('📊 FASE 6.2: Obtener Todas las Asistencias');

      const response = await fastify.inject({
        method: 'GET',
        url: '/asistencias',
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveLength(1); // Solo una asistencia (manual)
      expect(body.pagination.total).toBe(1);

      console.log('✅ Todas las asistencias obtenidas');
    });

    it('FASE 6.3: should get attendance statistics', async () => {
      console.log('📈 FASE 6.3: Obtener Estadísticas de Asistencia');

      const response = await fastify.inject({
        method: 'GET',
        url: `/asistencias/estadisticas/${horarioId}`,
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });

      expect(response.statusCode).toBe(200);
      const body = JSON.parse(response.body);
      expect(body.success).toBe(true);
      expect(body.data).toHaveProperty('totalEstudiantes');
      expect(body.data).toHaveProperty('presentes');
      expect(body.data.presentes).toBe(1); // Solo una asistencia exitosa

      console.log('✅ Estadísticas de asistencia obtenidas');
    });

    it('FASE 7.1: should verify complete data integrity', async () => {
      console.log('🔍 FASE 7.1: Verificar Integridad de Datos');

      // Verificar institución
      const instResponse = await fastify.inject({
        method: 'GET',
        url: `/instituciones/${institucionId}`,
        headers: {
          authorization: `Bearer ${adminGeneralToken}`,
        },
      });
      expect(instResponse.statusCode).toBe(200);

      // Verificar periodo
      const periodoResponse = await fastify.inject({
        method: 'GET',
        url: `/periodos-academicos/${periodoId}`,
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });
      expect(periodoResponse.statusCode).toBe(200);

      // Verificar grupo
      const grupoResponse = await fastify.inject({
        method: 'GET',
        url: `/grupos/${grupoId}`,
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });
      expect(grupoResponse.statusCode).toBe(200);

      // Verificar horario
      const horarioResponse = await fastify.inject({
        method: 'GET',
        url: `/horarios/${horarioId}`,
        headers: {
          authorization: `Bearer ${adminInstitucionToken}`,
        },
      });
      expect(horarioResponse.statusCode).toBe(200);

      console.log('✅ Integridad de datos verificada');
    });

    it('FASE 7.2: should verify role-based access control', async () => {
      console.log('🔒 FASE 7.2: Verificar Control de Acceso por Roles');

      // Estudiante no puede acceder a rutas de admin
      const adminRouteResponse = await fastify.inject({
        method: 'GET',
        url: '/horarios',
        headers: {
          authorization: `Bearer ${estudianteToken}`,
        },
      });
      expect(adminRouteResponse.statusCode).toBe(403);

      // Profesor no puede acceder a rutas de creación de usuarios
      const userCreationResponse = await fastify.inject({
        method: 'POST',
        url: '/usuarios',
        headers: {
          authorization: `Bearer ${profesorToken}`,
        },
        payload: {
          email: 'test@test.com',
          password: 'test123',
          nombres: 'Test',
          apellidos: 'User',
          rol: 'estudiante',
          institucionId: institucionId,
        },
      });
      expect(userCreationResponse.statusCode).toBe(403);

      console.log('✅ Control de acceso por roles verificado');
    });

    it('FASE 7.3: should complete full application flow successfully', async () => {
      console.log('🎉 FASE 7.3: Flujo Completo de Aplicación Completado');

      // Verificación final: todos los componentes principales funcionan
      expect(adminGeneralToken).toBeDefined();
      expect(adminInstitucionToken).toBeDefined();
      expect(profesorToken).toBeDefined();
      expect(estudianteToken).toBeDefined();
      expect(institucionId).toBeDefined();
      expect(periodoId).toBeDefined();
      expect(grupoId).toBeDefined();
      expect(materiaId).toBeDefined();
      expect(horarioId).toBeDefined();

      console.log('✅ Flujo completo de aplicación exitoso');
      console.log('📊 Resumen del flujo completado:');
      console.log(`   • Institución: ${institucionId}`);
      console.log(`   • Periodo: ${periodoId}`);
      console.log(`   • Grupo: ${grupoId}`);
      console.log(`   • Materia: ${materiaId}`);
      console.log(`   • Horario: ${horarioId}`);
      console.log(`   • Admin Institución: ${adminInstitucionId}`);
      console.log(`   • Profesor: ${profesorId}`);
      console.log(`   • Estudiante: ${estudianteUsuarioId}`);
      console.log('   • Autenticaciones: ✅ Admin General, Admin Institución, Profesor, Estudiante');
      console.log('   • Asistencias: ✅ Manual (QR validado como duplicado)');
      console.log('   • Consultas: ✅ Horarios, Asistencias, Estadísticas');
    });
  });
});