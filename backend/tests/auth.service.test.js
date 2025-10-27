"use strict";
/// <reference types="jest" />
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const auth_service_1 = __importDefault(require("../src/services/auth.service"));
const prisma = new client_1.PrismaClient();
describe('AuthService', () => {
    beforeAll(async () => {

        await prisma.$connect();
    });
    afterAll(async () => {
        await prisma.$disconnect();
    });
    beforeEach(async () => {

        await prisma.refreshToken.deleteMany();
        await prisma.usuarioInstitucion.deleteMany();
        await prisma.usuario.deleteMany({
            where: {
                email: { not: 'admin@asistapp.com' }
            }
        });
        await prisma.institucion.deleteMany({
            where: {
                codigo: { not: 'DEFAULT' }
            }
        });
    });
    describe('login', () => {
        it('should login valid user and return tokens with user institutions', async () => {

            const institucion = await prisma.institucion.create({
                data: {
                    nombre: 'Institución Test',
                    codigo: 'TEST001',
                    direccion: 'Dirección Test',
                    telefono: '123456789',
                    email: 'test@institucion.com',
                    activa: true,
                },
            });

            const hashedPassword = await auth_service_1.default.hashPassword('testpass');
            const user = await prisma.usuario.create({
                data: {
                    email: 'test@example.com',
                    passwordHash: hashedPassword,
                    nombres: 'Test',
                    apellidos: 'User',
                    rol: 'estudiante',
                    activo: true,
                },
            });

            await prisma.usuarioInstitucion.create({
                data: {
                    usuarioId: user.id,
                    institucionId: institucion.id,
                    rolEnInstitucion: 'estudiante',
                    activo: true,
                },
            });
            const result = await auth_service_1.default.login({ email: 'test@example.com', password: 'testpass' });
            expect(result).toHaveProperty('accessToken');
            expect(result).toHaveProperty('refreshToken');
            expect(result.usuario.id).toBe(user.id);
            expect(result.usuario.instituciones).toBeDefined();
            expect(result.usuario.instituciones).toHaveLength(1);
            expect(result.usuario.instituciones[0].id).toBe(institucion.id);
            expect(result.expiresIn).toBe(24 * 60 * 60);

            const tokens = await prisma.refreshToken.findMany({ where: { usuarioId: user.id } });
            expect(tokens.length).toBe(1);
        });
        it('should throw error for invalid credentials', async () => {
            await expect(auth_service_1.default.login({ email: 'invalid@example.com', password: 'wrong' })).rejects.toThrow('Credenciales inválidas');
        });
        it('should throw error for inactive user', async () => {

            const institucion = await prisma.institucion.create({
                data: {
                    nombre: 'Institución Test',
                    codigo: 'TEST002',
                    activa: true,
                },
            });
            const hashedPassword = await auth_service_1.default.hashPassword('testpass');
            const user = await prisma.usuario.create({
                data: {
                    email: 'inactive@example.com',
                    passwordHash: hashedPassword,
                    nombres: 'Inactive',
                    apellidos: 'User',
                    rol: 'estudiante',
                    activo: false,
                },
            });

            await prisma.usuarioInstitucion.create({
                data: {
                    usuarioId: user.id,
                    institucionId: institucion.id,
                    rolEnInstitucion: 'estudiante',
                    activo: true,
                },
            });
            await expect(auth_service_1.default.login({ email: 'inactive@example.com', password: 'testpass' })).rejects.toThrow('Usuario inactivo');
        });
    });
    describe('refreshToken', () => {
        it('should refresh token and rotate it', async () => {

            const hashedPassword = await auth_service_1.default.hashPassword('testpass');
            const user = await prisma.usuario.create({
                data: {
                    email: 'refresh@example.com',
                    passwordHash: hashedPassword,
                    nombres: 'Refresh',
                    apellidos: 'User',
                    rol: 'estudiante',
                    activo: true,
                },
            });
            const loginResult = await auth_service_1.default.login({ email: 'refresh@example.com', password: 'testpass' });
            const oldRefreshToken = loginResult.refreshToken;

            const refreshResult = await auth_service_1.default.refreshToken(oldRefreshToken);
            expect(refreshResult).toHaveProperty('accessToken');
            expect(refreshResult).toHaveProperty('refreshToken');
            expect(refreshResult.refreshToken).not.toBe(oldRefreshToken);

            const oldTokenRecord = await prisma.refreshToken.findFirst({
                where: { usuarioId: user.id, revoked: true },
            });
            expect(oldTokenRecord).toBeTruthy();

            const newTokens = await prisma.refreshToken.findMany({
                where: { usuarioId: user.id, revoked: false },
            });
            expect(newTokens.length).toBe(1);
        });
        it('should throw error for invalid refresh token', async () => {
            await expect(auth_service_1.default.refreshToken('invalid-token')).rejects.toThrow('Refresh token inválido');
        });
        it('should throw error for revoked token', async () => {
            const hashedPassword = await auth_service_1.default.hashPassword('testpass');
            const user = await prisma.usuario.create({
                data: {
                    email: 'revoked@example.com',
                    passwordHash: hashedPassword,
                    nombres: 'Revoked',
                    apellidos: 'User',
                    rol: 'estudiante',
                    activo: true,
                },
            });
            const loginResult = await auth_service_1.default.login({ email: 'revoked@example.com', password: 'testpass' });
            const refreshToken = loginResult.refreshToken;

            await auth_service_1.default.revokeRefreshTokens(user.id, refreshToken);

            await expect(auth_service_1.default.refreshToken(refreshToken)).rejects.toThrow('Refresh token inválido o revocado');
        });
    });
    describe('revokeRefreshTokens', () => {
        it('should revoke specific token', async () => {
            const hashedPassword = await auth_service_1.default.hashPassword('testpass');
            const user = await prisma.usuario.create({
                data: {
                    email: 'revoke@example.com',
                    passwordHash: hashedPassword,
                    nombres: 'Revoke',
                    apellidos: 'User',
                    rol: 'estudiante',
                    activo: true,
                },
            });
            const loginResult = await auth_service_1.default.login({ email: 'revoke@example.com', password: 'testpass' });
            const refreshToken = loginResult.refreshToken;
            await auth_service_1.default.revokeRefreshTokens(user.id, refreshToken);
            const tokenRecord = await prisma.refreshToken.findFirst({
                where: { usuarioId: user.id },
            });
            expect(tokenRecord?.revoked).toBe(true);
        });
        it('should revoke all tokens for user', async () => {
            const hashedPassword = await auth_service_1.default.hashPassword('testpass');
            const user = await prisma.usuario.create({
                data: {
                    email: 'revokeall@example.com',
                    passwordHash: hashedPassword,
                    nombres: 'Revoke All',
                    apellidos: 'User',
                    rol: 'estudiante',
                    activo: true,
                },
            });

            await auth_service_1.default.login({ email: 'revokeall@example.com', password: 'testpass' });
            await auth_service_1.default.login({ email: 'revokeall@example.com', password: 'testpass' });
            await auth_service_1.default.revokeRefreshTokens(user.id);
            const tokens = await prisma.refreshToken.findMany({
                where: { usuarioId: user.id },
            });
            expect(tokens.every(t => t.revoked)).toBe(true);
        });
    });
});
