/// <reference types="jest" />

import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import AuthService from '../src/services/auth.service';
import { testPrisma } from './test-database';

describe('AuthService', () => {
  beforeAll(async () => {
    await testPrisma.$connect();
  });

  afterAll(async () => {
    await testPrisma.$disconnect();
  });

  beforeEach(async () => {
    await testPrisma.refreshToken.deleteMany();
    await testPrisma.usuarioInstitucion.deleteMany();
    await testPrisma.usuario.deleteMany({
      where: {
        email: { not: 'admin@asistapp.com' }
      }
    });
    await testPrisma.institucion.deleteMany({
      where: {
        codigo: { not: 'DEFAULT' }
      }
    });
  });

  describe('login', () => {
    it('should login valid user and return tokens with user institutions', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST001',
          direccion: 'Dirección Test',
          telefono: '123456789',
          email: 'test@institucion.com',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'test@example.com',
          passwordHash: hashedPassword,
          nombres: 'Test',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      const result = await AuthService.login({ email: 'test@example.com', password: 'testpass' });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.usuario.id).toBe(user.id);
      expect(result.usuario.instituciones).toBeDefined();
      expect(result.usuario.instituciones).toHaveLength(1);
      expect(result.usuario.instituciones[0].id).toBe(institucion.id);
      expect(result.expiresIn).toBe(24 * 60 * 60);
      const tokens = await testPrisma.refreshToken.findMany({ where: { usuarioId: user.id } });
      expect(tokens.length).toBe(1);
    });

    it('should login valid user without institutions', async () => {
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'noinst@example.com',
          passwordHash: hashedPassword,
          nombres: 'No Institution',
          apellidos: 'User',
          rol: 'super_admin',
          activo: true,
        },
      });

      const result = await AuthService.login({ email: 'noinst@example.com', password: 'testpass' });

      expect(result).toHaveProperty('accessToken');
      expect(result).toHaveProperty('refreshToken');
      expect(result.usuario.id).toBe(user.id);
      expect(result.usuario.instituciones).toBeDefined();
      expect(result.usuario.instituciones).toHaveLength(0);
      expect(result.expiresIn).toBe(24 * 60 * 60);
    });

    it('should throw error for invalid credentials', async () => {
      await expect(AuthService.login({ email: 'invalid@example.com', password: 'wrong' })).rejects.toThrow('Credenciales inválidas');
    });

    it('should throw error for wrong password', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST002',
          activa: true,
        },
      });

      const hashedPassword = await AuthService.hashPassword('correctpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'wrongpass@example.com',
          passwordHash: hashedPassword,
          nombres: 'Wrong',
          apellidos: 'Password',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      await expect(AuthService.login({ email: 'wrongpass@example.com', password: 'wrongpass' })).rejects.toThrow('Credenciales inválidas');
    });

    it('should throw error for inactive user', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST003',
          activa: true,
        },
      });

      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'inactive@example.com',
          passwordHash: hashedPassword,
          nombres: 'Inactive',
          apellidos: 'User',
          rol: 'estudiante',
          activo: false,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      await expect(AuthService.login({ email: 'inactive@example.com', password: 'testpass' })).rejects.toThrow('Usuario inactivo');
    });

    it('should throw error for missing email', async () => {
      await expect(AuthService.login({ email: '', password: 'testpass' })).rejects.toThrow('Credenciales inválidas');
    });

    it('should throw error for missing password', async () => {
      await expect(AuthService.login({ email: 'test@example.com', password: '' })).rejects.toThrow('Credenciales inválidas');
    });
  });

  describe('refreshToken', () => {
    it('should refresh token and rotate it', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST004',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'refresh@example.com',
          passwordHash: hashedPassword,
          nombres: 'Refresh',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      const loginResult = await AuthService.login({ email: 'refresh@example.com', password: 'testpass' });
      const oldRefreshToken = loginResult.refreshToken;
      const refreshResult = await AuthService.refreshToken(oldRefreshToken);

      expect(refreshResult).toHaveProperty('accessToken');
      expect(refreshResult).toHaveProperty('refreshToken');
      expect(refreshResult.refreshToken).not.toBe(oldRefreshToken);
      const oldTokenRecord = await testPrisma.refreshToken.findFirst({
        where: { usuarioId: user.id, revoked: true },
      });
      expect(oldTokenRecord).toBeTruthy();
      const newTokens = await testPrisma.refreshToken.findMany({
        where: { usuarioId: user.id, revoked: false },
      });
      expect(newTokens.length).toBe(1);
    });

    it('should throw error for invalid refresh token', async () => {
      await expect(AuthService.refreshToken('invalid-token')).rejects.toThrow('Refresh token inválido');
    });

    it('should throw error for malformed JWT', async () => {
      await expect(AuthService.refreshToken('not-a-jwt')).rejects.toThrow('Refresh token inválido');
    });

    it('should throw error for revoked token', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST005',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'revoked@example.com',
          passwordHash: hashedPassword,
          nombres: 'Revoked',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      const loginResult = await AuthService.login({ email: 'revoked@example.com', password: 'testpass' });
      const refreshToken = loginResult.refreshToken;
      await AuthService.revokeRefreshTokens(user.id, refreshToken);
      await expect(AuthService.refreshToken(refreshToken)).rejects.toThrow('Refresh token inválido o revocado');
    });

    it('should throw error for expired token', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST006',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'expired@example.com',
          passwordHash: hashedPassword,
          nombres: 'Expired',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });
      const loginResult = await AuthService.login({ email: 'expired@example.com', password: 'testpass' });
      const refreshToken = loginResult.refreshToken;
      await testPrisma.refreshToken.updateMany({
        where: { usuarioId: user.id },
        data: { expiresAt: new Date(Date.now() - 1000) } // Expirado hace 1 segundo
      });
      await expect(AuthService.refreshToken(refreshToken)).rejects.toThrow('Refresh token expirado');
    });

    it('should throw error for missing refresh token', async () => {
      await expect(AuthService.refreshToken('')).rejects.toThrow('Refresh token inválido');
    });
  });

  describe('revokeRefreshTokens', () => {
    it('should revoke specific token', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST007',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'revoke@example.com',
          passwordHash: hashedPassword,
          nombres: 'Revoke',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      const loginResult = await AuthService.login({ email: 'revoke@example.com', password: 'testpass' });
      const refreshToken = loginResult.refreshToken;

      await AuthService.revokeRefreshTokens(user.id, refreshToken);

      const tokenRecord = await testPrisma.refreshToken.findFirst({
        where: { usuarioId: user.id },
      });
      expect(tokenRecord?.revoked).toBe(true);
    });

    it('should revoke all tokens for user', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST008',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'revokeall@example.com',
          passwordHash: hashedPassword,
          nombres: 'Revoke All',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });
      await AuthService.login({ email: 'revokeall@example.com', password: 'testpass' });
      await AuthService.login({ email: 'revokeall@example.com', password: 'testpass' });

      await AuthService.revokeRefreshTokens(user.id);

      const tokens = await testPrisma.refreshToken.findMany({
        where: { usuarioId: user.id },
      });
      expect(tokens.every(t => t.revoked)).toBe(true);
    });

    it('should handle non-existent token gracefully', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST009',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'nonexist@example.com',
          passwordHash: hashedPassword,
          nombres: 'Non Exist',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });
      await expect(AuthService.revokeRefreshTokens(user.id, 'non-existent-token')).resolves.not.toThrow();
    });
  });

  describe('hashPassword', () => {
    it('should hash password correctly', async () => {
      const password = 'testpassword';
      const hashed = await AuthService.hashPassword(password);

      expect(hashed).toBeDefined();
      expect(typeof hashed).toBe('string');
      expect(hashed.length).toBeGreaterThan(0);
      expect(hashed).not.toBe(password); // Debe ser diferente al password original
    });

    it('should generate different hashes for same password', async () => {
      const password = 'testpassword';
      const hash1 = await AuthService.hashPassword(password);
      const hash2 = await AuthService.hashPassword(password);

      expect(hash1).not.toBe(hash2); // Los hashes deben ser diferentes (salting)
    });
  });

  describe('verifyToken', () => {
    it('should verify valid token', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST010',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'verify@example.com',
          passwordHash: hashedPassword,
          nombres: 'Verify',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true,
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      const loginResult = await AuthService.login({ email: 'verify@example.com', password: 'testpass' });
      const accessToken = loginResult.accessToken;

      const decoded = await AuthService.verifyToken(accessToken);

      expect(decoded.id).toBe(user.id);
      expect(decoded.rol).toBe('estudiante');
      expect(decoded.email).toBe('verify@example.com');
    });

    it('should throw error for invalid token', async () => {
      await expect(AuthService.verifyToken('invalid-token')).rejects.toThrow('Access token inválido');
    });

    it('should throw error for inactive user', async () => {
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST011',
          activa: true,
        },
      });
      const hashedPassword = await AuthService.hashPassword('testpass');
      const user = await testPrisma.usuario.create({
        data: {
          email: 'inactive-verify@example.com',
          passwordHash: hashedPassword,
          nombres: 'Inactive Verify',
          apellidos: 'User',
          rol: 'estudiante',
          activo: true, // Usuario activo inicialmente
        },
      });
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });
      const loginResult = await AuthService.login({ email: 'inactive-verify@example.com', password: 'testpass' });
      const accessToken = loginResult.accessToken;
      await testPrisma.usuario.update({
        where: { id: user.id },
        data: { activo: false },
      });
      await expect(AuthService.verifyToken(accessToken)).rejects.toThrow('Usuario no encontrado o inactivo');
    });
  });
});
