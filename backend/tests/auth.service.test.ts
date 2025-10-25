/// <reference types="jest" />

import { afterAll, beforeAll, beforeEach, describe, expect, it } from '@jest/globals';
import AuthService from '../src/services/auth.service';
import { testPrisma } from './test-database';

describe('AuthService', () => {
  beforeAll(async () => {
    // Conectar a DB de test si es necesario
    await testPrisma.$connect();
  });

  afterAll(async () => {
    await testPrisma.$disconnect();
  });

  beforeEach(async () => {
    // Limpiar datos de test, pero preservar usuario admin
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
      // Crear institución de test
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

      // Crear usuario de test
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

      // Crear relación usuario-institución
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

      // Verificar que se guardó el refresh token
      const tokens = await testPrisma.refreshToken.findMany({ where: { usuarioId: user.id } });
      expect(tokens.length).toBe(1);
    });

    it('should login valid user without institutions', async () => {
      // Crear usuario de test sin institución
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
      // Crear institución de test
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

      // Crear relación usuario-institución
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
      // Crear institución de test
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

      // Crear relación usuario-institución
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
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST004',
          activa: true,
        },
      });

      // Crear usuario y login para obtener token inicial
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

      // Crear relación usuario-institución
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

      // Refresh
      const refreshResult = await AuthService.refreshToken(oldRefreshToken);

      expect(refreshResult).toHaveProperty('accessToken');
      expect(refreshResult).toHaveProperty('refreshToken');
      expect(refreshResult.refreshToken).not.toBe(oldRefreshToken);

      // Verificar que el token viejo está revocado
      const oldTokenRecord = await testPrisma.refreshToken.findFirst({
        where: { usuarioId: user.id, revoked: true },
      });
      expect(oldTokenRecord).toBeTruthy();

      // Verificar que hay un nuevo token
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
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST005',
          activa: true,
        },
      });

      // Crear usuario
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

      // Crear relación usuario-institución
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

      // Revocar el token
      await AuthService.revokeRefreshTokens(user.id, refreshToken);

      // Intentar refresh con token revocado
      await expect(AuthService.refreshToken(refreshToken)).rejects.toThrow('Refresh token inválido o revocado');
    });

    it('should throw error for expired token', async () => {
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST006',
          activa: true,
        },
      });

      // Crear usuario
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

      // Crear relación usuario-institución
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      // Crear un token expirado manualmente (esto es complicado de testear directamente)
      // En su lugar, probamos con un token válido pero luego lo expiramos en la DB
      const loginResult = await AuthService.login({ email: 'expired@example.com', password: 'testpass' });
      const refreshToken = loginResult.refreshToken;

      // Hacer que el token expire inmediatamente
      await testPrisma.refreshToken.updateMany({
        where: { usuarioId: user.id },
        data: { expiresAt: new Date(Date.now() - 1000) } // Expirado hace 1 segundo
      });

      // Intentar refresh con token expirado
      await expect(AuthService.refreshToken(refreshToken)).rejects.toThrow('Refresh token expirado');
    });

    it('should throw error for missing refresh token', async () => {
      await expect(AuthService.refreshToken('')).rejects.toThrow('Refresh token inválido');
    });
  });

  describe('revokeRefreshTokens', () => {
    it('should revoke specific token', async () => {
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST007',
          activa: true,
        },
      });

      // Crear usuario
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

      // Crear relación usuario-institución
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
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST008',
          activa: true,
        },
      });

      // Crear usuario
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

      // Crear relación usuario-institución
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      // Login dos veces para tener dos tokens
      await AuthService.login({ email: 'revokeall@example.com', password: 'testpass' });
      await AuthService.login({ email: 'revokeall@example.com', password: 'testpass' });

      await AuthService.revokeRefreshTokens(user.id);

      const tokens = await testPrisma.refreshToken.findMany({
        where: { usuarioId: user.id },
      });
      expect(tokens.every(t => t.revoked)).toBe(true);
    });

    it('should handle non-existent token gracefully', async () => {
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST009',
          activa: true,
        },
      });

      // Crear usuario
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

      // Crear relación usuario-institución
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      // Intentar revocar un token que no existe - no debería lanzar error
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
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST010',
          activa: true,
        },
      });

      // Crear usuario
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

      // Crear relación usuario-institución
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
      // Crear institución de test
      const institucion = await testPrisma.institucion.create({
        data: {
          nombre: 'Institución Test',
          codigo: 'TEST011',
          activa: true,
        },
      });

      // Crear usuario activo inicialmente
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

      // Crear relación usuario-institución
      await testPrisma.usuarioInstitucion.create({
        data: {
          usuarioId: user.id,
          institucionId: institucion.id,
          rolEnInstitucion: 'estudiante',
          activo: true,
        },
      });

      // Login exitoso para obtener token
      const loginResult = await AuthService.login({ email: 'inactive-verify@example.com', password: 'testpass' });
      const accessToken = loginResult.accessToken;

      // Desactivar usuario después de obtener token
      await testPrisma.usuario.update({
        where: { id: user.id },
        data: { activo: false },
      });

      // Ahora verificar token debería fallar porque usuario está inactivo
      await expect(AuthService.verifyToken(accessToken)).rejects.toThrow('Usuario no encontrado o inactivo');
    });
  });
});
