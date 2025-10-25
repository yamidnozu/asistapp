"use strict";
/// <reference types="jest" />
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const fastify_1 = __importDefault(require("fastify"));
const database_1 = require("../src/config/database");
const errorHandler_1 = __importDefault(require("../src/middleware/errorHandler"));
const routes_1 = __importDefault(require("../src/routes"));
const auth_service_1 = __importDefault(require("../src/services/auth.service"));
describe('Auth Integration Tests', () => {
    let fastify;
    beforeAll(async () => {
        // Crear instancia de Fastify para tests
        fastify = (0, fastify_1.default)({ logger: false });
        // Registrar plugins y rutas
        (0, errorHandler_1.default)(fastify);
        fastify.register(routes_1.default);
        // Conectar DB
        await database_1.databaseService.connect();
        await auth_service_1.default.ensureAdminUser();
        await fastify.ready();
    });
    afterAll(async () => {
        await fastify.close();
        await database_1.databaseService.disconnect();
    });
    beforeEach(async () => {
        // Limpiar datos de test, pero preservar usuario admin
        const client = database_1.databaseService.getClient();
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
        const institucion = await database_1.databaseService.getClient().institucion.create({
            data: {
                nombre: 'Institución Integration',
                codigo: 'INT001',
                activa: true,
            },
        });
        // Crear usuario de test
        const hashedPassword = await auth_service_1.default.hashPassword('integrationpass');
        const user = await database_1.databaseService.getClient().usuario.create({
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
        await database_1.databaseService.getClient().usuarioInstitucion.create({
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
});
