/// <reference types="jest" />

import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';
import { prisma } from '../../src/config/database';
import UserService from '../../src/services/user.service';
import { ConflictError, ValidationError } from '../../src/types';

// Mock de Prisma
jest.mock('../../src/config/database', () => ({
  prisma: {
    usuario: {
      create: jest.fn(),
      update: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
    estudiante: {
      create: jest.fn(),
      update: jest.fn(),
    },
    usuarioInstitucion: {
      create: jest.fn(),
    },
    $transaction: jest.fn(),
  },
}));

// Mock de bcrypt
jest.mock('bcryptjs', () => ({
  hash: jest.fn(),
}));

// Mock de crypto
jest.mock('crypto', () => ({
  randomBytes: jest.fn(),
}));

describe('UserService Unit Tests', () => {
  const mockPrisma = prisma as jest.Mocked<typeof prisma>;
  const mockBcrypt = require('bcryptjs');
  const mockCrypto = require('crypto');

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.resetAllMocks();
    jest.restoreAllMocks();
  });

  describe('createUser', () => {
    const validUserData = {
      email: 'test@example.com',
      password: 'password123',
      nombres: 'Juan',
      apellidos: 'Pérez',
      rol: 'profesor' as const,
      telefono: '+1234567890',
      institucionId: 'inst-123',
      rolEnInstitucion: 'profesor',
    };

    const validStudentData = {
      email: 'student@example.com',
      password: 'password123',
      nombres: 'María',
      apellidos: 'García',
      rol: 'estudiante' as const,
      identificacion: '123456789',
      nombreResponsable: 'Padre de María',
      telefonoResponsable: '+0987654321',
      institucionId: 'inst-123',
    };

    it('should create a profesor user successfully', async () => {
      const hashedPassword = 'hashedPassword123';
      const userId = 'user-123';

      mockBcrypt.hash.mockResolvedValue(hashedPassword);
      mockPrisma.$transaction.mockImplementation(async (callback: any) => {
        return callback(mockPrisma);
      });

      mockPrisma.usuario.create.mockResolvedValue({
        id: userId,
        email: validUserData.email,
        passwordHash: hashedPassword,
        nombres: validUserData.nombres,
        apellidos: validUserData.apellidos,
        rol: validUserData.rol,
        telefono: validUserData.telefono,
        activo: true,
        tokenVersion: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await UserService.createUser(validUserData);

      expect(mockBcrypt.hash).toHaveBeenCalledWith(validUserData.password, 10);
      expect(mockPrisma.usuario.create).toHaveBeenCalledWith({
        data: {
          email: validUserData.email.toLowerCase(),
          passwordHash: hashedPassword,
          nombres: validUserData.nombres,
          apellidos: validUserData.apellidos,
          rol: validUserData.rol,
          telefono: validUserData.telefono,
        },
      });
      expect(mockPrisma.usuarioInstitucion.create).toHaveBeenCalledWith({
        data: {
          usuarioId: userId,
          institucionId: validUserData.institucionId,
          rolEnInstitucion: validUserData.rolEnInstitucion,
        },
      });
      expect(result).toHaveProperty('id', userId);
      expect(result).toHaveProperty('email', validUserData.email);
      expect(result).toHaveProperty('rol', validUserData.rol);
    });

    it('should create a estudiante user successfully', async () => {
      const hashedPassword = 'hashedPassword123';
      const userId = 'user-456';
      const studentId = 'student-456';
      const qrCode = 'ABC123DEF456';

      mockBcrypt.hash.mockResolvedValue(hashedPassword);
      mockCrypto.randomBytes.mockReturnValue({
        toString: jest.fn().mockReturnValue(qrCode),
      });
      mockPrisma.$transaction.mockImplementation(async (callback: any) => {
        return callback(mockPrisma);
      });

      mockPrisma.usuario.create.mockResolvedValue({
        id: userId,
        email: validStudentData.email,
        passwordHash: hashedPassword,
        nombres: validStudentData.nombres,
        apellidos: validStudentData.apellidos,
        rol: validStudentData.rol,
        telefono: null,
        activo: true,
        tokenVersion: 1,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      mockPrisma.estudiante.create.mockResolvedValue({
        id: studentId,
        usuarioId: userId,
        identificacion: validStudentData.identificacion!,
        codigoQr: qrCode,
        nombreResponsable: validStudentData.nombreResponsable,
        telefonoResponsable: validStudentData.telefonoResponsable,
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      const result = await UserService.createUser(validStudentData);

      expect(mockCrypto.randomBytes).toHaveBeenCalledWith(16);
      expect(mockPrisma.estudiante.create).toHaveBeenCalledWith({
        data: {
          usuarioId: userId,
          identificacion: validStudentData.identificacion,
          codigoQr: qrCode,
          nombreResponsable: validStudentData.nombreResponsable,
          telefonoResponsable: validStudentData.telefonoResponsable,
        },
      });
      expect(result.estudiante).toBeDefined();
      expect(result.estudiante?.identificacion).toBe(validStudentData.identificacion);
      expect(result.estudiante?.codigoQr).toBe(qrCode);
    });

    it('should throw ValidationError for missing required fields', async () => {
      const invalidData = {
        email: 'test@example.com',
        // Falta password, nombres, apellidos, rol
      };

      await expect(UserService.createUser(invalidData as any)).rejects.toThrow(ValidationError);
    });

    it('should throw ValidationError for invalid role', async () => {
      const invalidData = {
        ...validUserData,
        rol: 'invalid_role' as any,
      };

      await expect(UserService.createUser(invalidData)).rejects.toThrow(ValidationError);
    });

    it('should throw ValidationError for estudiante without identificacion', async () => {
      const invalidStudentData = {
        ...validStudentData,
        identificacion: undefined,
      };

      await expect(UserService.createUser(invalidStudentData as any)).rejects.toThrow(ValidationError);
    });

    it('should throw ConflictError for duplicate email', async () => {
      const existingUser = {
        id: 'existing-user',
        email: validUserData.email,
      };

      mockPrisma.usuario.findUnique.mockResolvedValue(existingUser as any);

      // Mock isEmailAvailable to return false
      jest.spyOn(UserService, 'isEmailAvailable').mockResolvedValue(false);

      await expect(UserService.createUser(validUserData)).rejects.toThrow(ConflictError);
    });
  });

  describe('updateUser', () => {
    const userId = 'user-123';
    const updateData = {
      nombres: 'Juan Carlos',
      telefono: '+9876543210',
    };

    it('should update user successfully', async () => {
      const existingUser = {
        id: userId,
        email: 'test@example.com',
        nombres: 'Juan',
        apellidos: 'Pérez',
        rol: 'profesor',
        activo: true,
      };

      const updatedUser = {
        ...existingUser,
        nombres: updateData.nombres,
        telefono: updateData.telefono,
      };

      mockPrisma.usuario.findUnique
        .mockResolvedValueOnce(existingUser as any) // Para getUserById
        .mockResolvedValueOnce(updatedUser as any); // Para la segunda llamada

      mockPrisma.$transaction.mockImplementation(async (callback: any) => {
        return callback(mockPrisma);
      });

      mockPrisma.usuario.update.mockResolvedValue(updatedUser as any);

      const result = await UserService.updateUser(userId, updateData);

      expect(mockPrisma.usuario.update).toHaveBeenCalledWith({
        where: { id: userId },
        data: updateData,
      });
      expect(result).toHaveProperty('nombres', updateData.nombres);
      expect(result).toHaveProperty('telefono', updateData.telefono);
    });

    it('should update estudiante data', async () => {
      const existingUser = {
        id: userId,
        email: 'student@example.com',
        nombres: 'María',
        apellidos: 'García',
        rol: 'estudiante',
        activo: true,
      };

      const estudianteUpdateData = {
        nombreResponsable: 'Madre de María',
        telefonoResponsable: '+111111111',
      };

      mockPrisma.usuario.findUnique.mockResolvedValue(existingUser as any);
      mockPrisma.$transaction.mockImplementation(async (callback: any) => {
        return callback(mockPrisma);
      });

      mockPrisma.usuario.update.mockResolvedValue(existingUser as any);
      mockPrisma.estudiante.update.mockResolvedValue({
        id: 'student-123',
        usuarioId: userId,
        ...estudianteUpdateData,
      } as any);

      const result = await UserService.updateUser(userId, estudianteUpdateData);

      expect(mockPrisma.estudiante.update).toHaveBeenCalledWith({
        where: { usuarioId: userId },
        data: estudianteUpdateData,
      });
    });

    it('should throw ValidationError for invalid user id', async () => {
      await expect(UserService.updateUser('', updateData)).rejects.toThrow(ValidationError);
    });

    it('should throw ValidationError for non-existent user', async () => {
      mockPrisma.usuario.findUnique.mockResolvedValue(null);

      await expect(UserService.updateUser(userId, updateData)).rejects.toThrow(ValidationError);
    });

    it('should throw ConflictError for duplicate email', async () => {
      const existingUser = {
        id: userId,
        email: 'test@example.com',
        nombres: 'Juan',
        apellidos: 'Pérez',
        rol: 'profesor',
        activo: true,
      };

      mockPrisma.usuario.findUnique.mockResolvedValue(existingUser as any);

      // Mock isEmailAvailable to return false
      jest.spyOn(UserService, 'isEmailAvailable').mockResolvedValue(false);

      const emailUpdate = { email: 'existing@example.com' };

      await expect(UserService.updateUser(userId, emailUpdate)).rejects.toThrow(ConflictError);
    });
  });

  describe('deleteUser', () => {
    const userId = 'user-123';

    it('should delete user successfully', async () => {
      const existingUser = {
        id: userId,
        email: 'test@example.com',
        activo: true,
      };

      mockPrisma.usuario.findUnique.mockResolvedValue(existingUser as any);
      mockPrisma.usuario.update.mockResolvedValue({
        ...existingUser,
        activo: false,
      } as any);

      const result = await UserService.deleteUser(userId);

      expect(mockPrisma.usuario.update).toHaveBeenCalledWith({
        where: { id: userId },
        data: { activo: false },
      });
      expect(result).toBe(true);
    });

    it('should throw ValidationError for invalid user id', async () => {
      await expect(UserService.deleteUser('')).rejects.toThrow(ValidationError);
    });

    it('should throw ValidationError for non-existent user', async () => {
      mockPrisma.usuario.findUnique.mockResolvedValue(null);

      await expect(UserService.deleteUser(userId)).rejects.toThrow(ValidationError);
    });
  });

  describe('getUserById', () => {
    it('should return user with estudiante data', async () => {
      const userId = 'user-123';
      const userData = {
        id: userId,
        email: 'student@example.com',
        nombres: 'María',
        apellidos: 'García',
        rol: 'estudiante',
        activo: true,
        estudiante: {
          id: 'student-123',
          identificacion: '123456789',
          codigoQr: 'QR123',
        },
      };

      mockPrisma.usuario.findUnique.mockResolvedValue(userData as any);

      const result = await UserService.getUserById(userId);

      expect(mockPrisma.usuario.findUnique).toHaveBeenCalledWith({
        where: { id: userId },
        include: {
          usuarioInstituciones: {
            where: { activo: true },
            include: { institucion: true },
          },
          estudiante: true,
        },
      });
      expect(result).toEqual(userData);
    });

    it('should throw ValidationError for invalid id', async () => {
      await expect(UserService.getUserById('')).rejects.toThrow(ValidationError);
    });
  });

  describe('isEmailAvailable', () => {
    it('should return true for available email', async () => {
      mockPrisma.usuario.count.mockResolvedValue(0);

      const result = await UserService.isEmailAvailable('new@example.com');

      expect(mockPrisma.usuario.count).toHaveBeenCalledWith({
        where: { email: 'new@example.com' },
      });
      expect(result).toBe(true);
    });

    it('should return false for taken email', async () => {
      mockPrisma.usuario.count.mockResolvedValue(1);

      const result = await UserService.isEmailAvailable('taken@example.com');

      expect(result).toBe(false);
    });

    it('should exclude user when updating', async () => {
      mockPrisma.usuario.count.mockResolvedValue(0);

      const result = await UserService.isEmailAvailable('test@example.com', 'user-123');

      expect(mockPrisma.usuario.count).toHaveBeenCalledWith({
        where: {
          email: 'test@example.com',
          id: { not: 'user-123' },
        },
      });
      expect(result).toBe(true);
    });

    it('should return false for invalid email', async () => {
      const result = await UserService.isEmailAvailable('invalid-email');

      expect(result).toBe(false);
    });
  });

  describe('userExists', () => {
    it('should return true for existing user', async () => {
      mockPrisma.usuario.count.mockResolvedValue(1);

      const result = await UserService.userExists('user-123');

      expect(mockPrisma.usuario.count).toHaveBeenCalledWith({
        where: { id: 'user-123' },
      });
      expect(result).toBe(true);
    });

    it('should return false for non-existing user', async () => {
      mockPrisma.usuario.count.mockResolvedValue(0);

      const result = await UserService.userExists('non-existent');

      expect(result).toBe(false);
    });

    it('should return false for invalid id', async () => {
      const result = await UserService.userExists('');

      expect(result).toBe(false);
    });
  });
});