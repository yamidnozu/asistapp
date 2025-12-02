/**
 * Test de integración para la creación de horarios (POST /horarios)
 * 
 * Valida que el fix de la query raw de conflictos funcione correctamente
 * con la base de datos real (tabla "horarios", columnas snake_case).
 */
import Fastify, { FastifyInstance } from 'fastify';
import jwt from 'jsonwebtoken';
import { prisma } from '../../src/config/database';
import setupErrorHandler from '../../src/middleware/errorHandler';
import horarioRoutes from '../../src/routes/horario.routes';
// Usar los globals de Jest (describe/it) en lugar de `node:test`

// Mock del middleware de autenticación para tests
jest.mock('../../src/middleware/auth', () => ({
    authenticate: async (request: any, reply: any) => {
        const authHeader = request.headers.authorization;
        if (!authHeader) {
            return reply.code(401).send({ success: false, error: 'No token' });
        }
        // Decodificar token mock
        const token = authHeader.replace('Bearer ', '');
        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET || 'test-secret');
            request.user = decoded;
        } catch {
            return reply.code(401).send({ success: false, error: 'Invalid token' });
        }
    },
    authorize: () => async (request: any, reply: any) => {
        // Pass through for tests
    },
    AuthenticatedRequest: {}
}));

describe('Horario Create Integration Tests', () => {
    let fastify: FastifyInstance;
    let adminToken: string;
    let testInstitucionId: string;
    let testPeriodoId: string;
    let testGrupoId: string;
    let testMateriaId: string;
    let testProfesorId: string;
    let testAdminId: string;

    beforeAll(async () => {
        // Crear instancia de Fastify
        fastify = Fastify({ logger: false });
        setupErrorHandler(fastify);
        await fastify.register(horarioRoutes, { prefix: '/horarios' });
        await fastify.ready();

        // Crear datos de prueba en la base de datos
        // 1. Crear institución
        const institucion = await prisma.institucion.create({
            data: {
                nombre: 'Test Institution Horarios',
                email: 'test-horarios@test.com',
                activa: true
            }
        });
        testInstitucionId = institucion.id;

        // 2. Crear admin
        const admin = await prisma.usuario.create({
            data: {
                email: `admin-horarios-${Date.now()}@test.com`,
                passwordHash: 'hashed_password',
                nombres: 'Admin',
                apellidos: 'Test',
                rol: 'admin_institucion',
                activo: true
            }
        });
        testAdminId = admin.id;

        // 3. Asociar admin a institución
        await prisma.usuarioInstitucion.create({
            data: {
                usuarioId: admin.id,
                institucionId: institucion.id,
                activo: true
            }
        });

        // 4. Crear periodo académico
        const periodo = await prisma.periodoAcademico.create({
            data: {
                institucionId: institucion.id,
                nombre: 'Test Period 2025',
                fechaInicio: new Date('2025-01-01'),
                fechaFin: new Date('2025-12-31'),
                activo: true
            }
        });
        testPeriodoId = periodo.id;

        // 5. Crear grupo
        const grupo = await prisma.grupo.create({
            data: {
                institucionId: institucion.id,
                periodoId: periodo.id,
                nombre: 'Test Group 10-A',
                grado: '10',
                seccion: 'A'
            }
        });
        testGrupoId = grupo.id;

        // 6. Crear materia
        const materia = await prisma.materia.create({
            data: {
                institucionId: institucion.id,
                nombre: 'Test Math',
                codigo: 'MATH101'
            }
        });
        testMateriaId = materia.id;

        // 7. Crear profesor
        const profesor = await prisma.usuario.create({
            data: {
                email: `profesor-horarios-${Date.now()}@test.com`,
                passwordHash: 'hashed_password',
                nombres: 'Profesor',
                apellidos: 'Test',
                rol: 'profesor',
                activo: true
            }
        });
        testProfesorId = profesor.id;

        // 8. Asociar profesor a institución
        await prisma.usuarioInstitucion.create({
            data: {
                usuarioId: profesor.id,
                institucionId: institucion.id,
                activo: true
            }
        });

        // Generar token JWT para el admin
        adminToken = jwt.sign(
            {
                id: admin.id,
                rol: 'admin_institucion',
                email: admin.email,
                tokenVersion: 1
            },
            process.env.JWT_SECRET || 'test-secret',
            { expiresIn: '1h' }
        );
    });

    afterAll(async () => {
        // Limpiar datos de prueba en orden inverso
        await prisma.horario.deleteMany({
            where: { institucionId: testInstitucionId }
        });
        await prisma.materia.deleteMany({
            where: { institucionId: testInstitucionId }
        });
        await prisma.grupo.deleteMany({
            where: { institucionId: testInstitucionId }
        });
        await prisma.periodoAcademico.deleteMany({
            where: { institucionId: testInstitucionId }
        });
        await prisma.usuarioInstitucion.deleteMany({
            where: { institucionId: testInstitucionId }
        });
        await prisma.usuario.deleteMany({
            where: { id: { in: [testAdminId, testProfesorId] } }
        });
        await prisma.institucion.deleteMany({
            where: { id: testInstitucionId }
        });

        await fastify.close();
        await prisma.$disconnect();
    });

    describe('POST /horarios - Create Schedule', () => {
        it('should create a new horario successfully', async () => {
            const horarioData = {
                periodoId: testPeriodoId,
                grupoId: testGrupoId,
                materiaId: testMateriaId,
                profesorId: testProfesorId,
                diaSemana: 1, // Lunes
                horaInicio: '08:00',
                horaFin: '10:00'
            };

            const response = await fastify.inject({
                method: 'POST',
                url: '/horarios',
                headers: {
                    Authorization: `Bearer ${adminToken}`
                },
                payload: horarioData
            });

            expect(response.statusCode).toBe(201);
            const body = JSON.parse(response.body);
            expect(body.success).toBe(true);
            expect(body.data).toBeDefined();
            expect(body.data.diaSemana).toBe(1);
            expect(body.data.horaInicio).toBe('08:00');
            expect(body.data.horaFin).toBe('10:00');
        });

        it('should detect group conflict when creating overlapping schedule', async () => {
            // Primero crear un horario
            const horario1 = {
                periodoId: testPeriodoId,
                grupoId: testGrupoId,
                materiaId: testMateriaId,
                profesorId: testProfesorId,
                diaSemana: 2, // Martes
                horaInicio: '10:00',
                horaFin: '12:00'
            };

            const response1 = await fastify.inject({
                method: 'POST',
                url: '/horarios',
                headers: {
                    Authorization: `Bearer ${adminToken}`
                },
                payload: horario1
            });

            expect(response1.statusCode).toBe(201);

            // Intentar crear otro horario que se solape (mismo grupo, mismo día, horas solapadas)
            const horario2 = {
                periodoId: testPeriodoId,
                grupoId: testGrupoId,
                materiaId: testMateriaId,
                profesorId: testProfesorId,
                diaSemana: 2, // Mismo día (Martes)
                horaInicio: '11:00', // Se solapa con 10:00-12:00
                horaFin: '13:00'
            };

            const response2 = await fastify.inject({
                method: 'POST',
                url: '/horarios',
                headers: {
                    Authorization: `Bearer ${adminToken}`
                },
                payload: horario2
            });

            // Debe fallar con 409 Conflict
            expect(response2.statusCode).toBe(409);
            const body2 = JSON.parse(response2.body);
            expect(body2.success).toBe(false);
            expect(body2.code).toBe('CONFLICT_ERROR');
            expect(body2.error).toContain('grupo');
        });

        it('should allow non-overlapping schedules for same group', async () => {
            // Crear horario en día diferente
            const horarioData = {
                periodoId: testPeriodoId,
                grupoId: testGrupoId,
                materiaId: testMateriaId,
                profesorId: testProfesorId,
                diaSemana: 3, // Miércoles (diferente a los anteriores)
                horaInicio: '14:00',
                horaFin: '16:00'
            };

            const response = await fastify.inject({
                method: 'POST',
                url: '/horarios',
                headers: {
                    Authorization: `Bearer ${adminToken}`
                },
                payload: horarioData
            });

            expect(response.statusCode).toBe(201);
            const body = JSON.parse(response.body);
            expect(body.success).toBe(true);
        });

        it('should validate time format', async () => {
            const horarioData = {
                periodoId: testPeriodoId,
                grupoId: testGrupoId,
                materiaId: testMateriaId,
                profesorId: testProfesorId,
                diaSemana: 4,
                horaInicio: '25:00', // Hora inválida
                horaFin: '26:00'
            };

            const response = await fastify.inject({
                method: 'POST',
                url: '/horarios',
                headers: {
                    Authorization: `Bearer ${adminToken}`
                },
                payload: horarioData
            });

            expect(response.statusCode).toBe(400);
            const body = JSON.parse(response.body);
            expect(body.success).toBe(false);
        });

        it('should validate that start time is before end time', async () => {
            const horarioData = {
                periodoId: testPeriodoId,
                grupoId: testGrupoId,
                materiaId: testMateriaId,
                profesorId: testProfesorId,
                diaSemana: 5,
                horaInicio: '14:00',
                horaFin: '12:00' // Fin antes del inicio
            };

            const response = await fastify.inject({
                method: 'POST',
                url: '/horarios',
                headers: {
                    Authorization: `Bearer ${adminToken}`
                },
                payload: horarioData
            });

            expect(response.statusCode).toBe(400);
            const body = JSON.parse(response.body);
            expect(body.success).toBe(false);
        });
    });

    describe('GET /horarios - List Schedules', () => {
        it('should list horarios for the institution', async () => {
            const response = await fastify.inject({
                method: 'GET',
                url: '/horarios',
                headers: {
                    Authorization: `Bearer ${adminToken}`
                }
            });

            expect(response.statusCode).toBe(200);
            const body = JSON.parse(response.body);
            expect(body.success).toBe(true);
            expect(Array.isArray(body.data)).toBe(true);
            // Should have at least the horarios we created
            expect(body.data.length).toBeGreaterThanOrEqual(1);
        });

        it('should filter horarios by grupoId', async () => {
            const response = await fastify.inject({
                method: 'GET',
                url: `/horarios?grupoId=${testGrupoId}`,
                headers: {
                    Authorization: `Bearer ${adminToken}`
                }
            });

            expect(response.statusCode).toBe(200);
            const body = JSON.parse(response.body);
            expect(body.success).toBe(true);
            // All returned horarios should be for the specified group
            body.data.forEach((horario: any) => {
                expect(horario.grupoId).toBe(testGrupoId);
            });
        });
    });
});
