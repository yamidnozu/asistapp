/// <reference types="jest" />

import { afterEach, beforeEach, describe, expect, it, jest } from '@jest/globals';
import UserController from '../../src/controllers/user.controller';
import UserService from '../../src/services/user.service';
import { ConflictError, CreateUserRequest, UpdateUserRequest, ValidationError } from '../../src/types';

// Mock de UserService
jest.mock('../../src/services/user.service');

// Mock de FastifyRequest y FastifyReply
const mockRequest = (body?: any, params?: any) => ({
  body,
  params: params || {},
});

const mockReply = () => {
  const res: any = {};
  res.code = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  return res;
};

describe('UserController Unit Tests', () => {
  const mockUserService = UserService as jest.Mocked<typeof UserService>;

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.resetAllMocks();
  });

  describe('createUser', () => {
    const validUserData: CreateUserRequest = {
      email: 'test@example.com',
      password: 'password123',
      nombres: 'Juan',
      apellidos: 'Pérez',
      rol: 'profesor',
      telefono: '+1234567890',
      institucionId: 'inst-123',
      rolEnInstitucion: 'profesor',
    };

    const mockResponse = {
      id: 'user-123',
      email: validUserData.email,
      nombres: validUserData.nombres,
      apellidos: validUserData.apellidos,
      rol: validUserData.rol,
      telefono: validUserData.telefono,
      activo: true,
      instituciones: [{
        id: validUserData.institucionId,
        nombre: 'Institución Test',
        rolEnInstitucion: validUserData.rolEnInstitucion,
        activo: true,
      }],
    };

    it('should create user and return success response', async () => {
      mockUserService.createUser.mockResolvedValue(mockResponse);

      const request = mockRequest(validUserData);
      const reply = mockReply();

      const result = await UserController.createUser(request as any, reply as any);

      expect(mockUserService.createUser).toHaveBeenCalledWith(validUserData);
      expect(reply.code).toHaveBeenCalledWith(201);
      expect(reply.send).toHaveBeenCalledWith({
        success: true,
        data: mockResponse,
        message: 'Usuario creado exitosamente',
      });
    });

    it('should handle ValidationError and throw it', async () => {
      const validationError = new ValidationError('Campos requeridos faltantes');
      mockUserService.createUser.mockRejectedValue(validationError);

      const request = mockRequest({ email: 'test@example.com' });
      const reply = mockReply();

      await expect(UserController.createUser(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.createUser).toHaveBeenCalled();
    });

    it('should handle ConflictError and throw it', async () => {
      const conflictError = new ConflictError('El email ya está registrado');
      mockUserService.createUser.mockRejectedValue(conflictError);

      const request = mockRequest(validUserData);
      const reply = mockReply();

      await expect(UserController.createUser(request as any, reply as any)).rejects.toThrow(ConflictError);
      expect(mockUserService.createUser).toHaveBeenCalled();
    });
  });

  describe('updateUser', () => {
    const userId = 'user-123';
    const updateData: UpdateUserRequest = {
      nombres: 'Juan Carlos',
      telefono: '+9876543210',
    };

    const mockResponse = {
      id: userId,
      email: 'test@example.com',
      nombres: updateData.nombres,
      apellidos: 'Pérez',
      rol: 'profesor',
      telefono: updateData.telefono,
      activo: true,
      usuarioInstituciones: [],
    };

    it('should update user and return success response', async () => {
      mockUserService.updateUser.mockResolvedValue(mockResponse);

      const request = mockRequest(updateData, { id: userId });
      const reply = mockReply();

      const result = await UserController.updateUser(request as any, reply as any);

      expect(mockUserService.updateUser).toHaveBeenCalledWith(userId, updateData);
      expect(reply.code).toHaveBeenCalledWith(200);
      expect(reply.send).toHaveBeenCalledWith({
        success: true,
        data: mockResponse,
        message: 'Usuario actualizado exitosamente',
      });
    });

    it('should handle ValidationError for invalid user id', async () => {
      const validationError = new ValidationError('ID de usuario inválido');
      mockUserService.updateUser.mockRejectedValue(validationError);

      const request = mockRequest(updateData, { id: '' });
      const reply = mockReply();

      await expect(UserController.updateUser(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.updateUser).toHaveBeenCalledWith('', updateData);
    });

    it('should handle ValidationError for non-existent user', async () => {
      const validationError = new ValidationError('Usuario no encontrado');
      mockUserService.updateUser.mockRejectedValue(validationError);

      const request = mockRequest(updateData, { id: 'non-existent' });
      const reply = mockReply();

      await expect(UserController.updateUser(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.updateUser).toHaveBeenCalledWith('non-existent', updateData);
    });

    it('should handle ConflictError for duplicate email', async () => {
      const conflictError = new ConflictError('El email ya está registrado');
      mockUserService.updateUser.mockRejectedValue(conflictError);

      const emailUpdate = { email: 'existing@example.com' };
      const request = mockRequest(emailUpdate, { id: userId });
      const reply = mockReply();

      await expect(UserController.updateUser(request as any, reply as any)).rejects.toThrow(ConflictError);
      expect(mockUserService.updateUser).toHaveBeenCalledWith(userId, emailUpdate);
    });
  });

  describe('deleteUser', () => {
    const userId = 'user-123';

    it('should delete user and return success response', async () => {
      mockUserService.deleteUser.mockResolvedValue(true);

      const request = mockRequest(undefined, { id: userId });
      const reply = mockReply();

      const result = await UserController.deleteUser(request as any, reply as any);

      expect(mockUserService.deleteUser).toHaveBeenCalledWith(userId);
      expect(reply.code).toHaveBeenCalledWith(200);
      expect(reply.send).toHaveBeenCalledWith({
        success: true,
        data: null,
        message: 'Usuario eliminado exitosamente',
      });
    });

    it('should handle ValidationError for invalid user id', async () => {
      const validationError = new ValidationError('ID de usuario inválido');
      mockUserService.deleteUser.mockRejectedValue(validationError);

      const request = mockRequest(undefined, { id: '' });
      const reply = mockReply();

      await expect(UserController.deleteUser(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.deleteUser).toHaveBeenCalledWith('');
    });

    it('should handle ValidationError for non-existent user', async () => {
      const validationError = new ValidationError('Usuario no encontrado');
      mockUserService.deleteUser.mockRejectedValue(validationError);

      const request = mockRequest(undefined, { id: 'non-existent' });
      const reply = mockReply();

      await expect(UserController.deleteUser(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.deleteUser).toHaveBeenCalledWith('non-existent');
    });
  });

  describe('getUserById', () => {
    const userId = 'user-123';
    const mockUser = {
      id: userId,
      email: 'test@example.com',
      nombres: 'Juan',
      apellidos: 'Pérez',
      rol: 'profesor',
      telefono: '+1234567890',
      activo: true,
      usuarioInstituciones: [],
    };

    it('should get user by id and return success response', async () => {
      mockUserService.getUserById.mockResolvedValue(mockUser);

      const request = mockRequest(undefined, { id: userId });
      const reply = mockReply();

      const result = await UserController.getUserById(request as any, reply as any);

      expect(mockUserService.getUserById).toHaveBeenCalledWith(userId);
      expect(reply.code).toHaveBeenCalledWith(200);
      expect(reply.send).toHaveBeenCalledWith({
        success: true,
        data: mockUser,
      });
    });

    it('should handle ValidationError for invalid id', async () => {
      const validationError = new ValidationError('ID de usuario inválido');
      mockUserService.getUserById.mockRejectedValue(validationError);

      const request = mockRequest(undefined, { id: '' });
      const reply = mockReply();

      await expect(UserController.getUserById(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.getUserById).toHaveBeenCalledWith('');
    });

    it('should handle NotFoundError for non-existent user', async () => {
      const notFoundError = new (class NotFoundError extends Error {
        constructor(message: string) {
          super(message);
          this.name = 'NotFoundError';
        }
      })('Usuario no encontrado');
      mockUserService.getUserById.mockRejectedValue(notFoundError);

      const request = mockRequest(undefined, { id: 'non-existent' });
      const reply = mockReply();

      await expect(UserController.getUserById(request as any, reply as any)).rejects.toThrow();
      expect(mockUserService.getUserById).toHaveBeenCalledWith('non-existent');
    });
  });

  describe('getAllUsers', () => {
    const mockUsers = [
      {
        id: 'user-1',
        email: 'user1@example.com',
        nombres: 'Juan',
        apellidos: 'Pérez',
        rol: 'profesor',
        activo: true,
        usuarioInstituciones: [],
      },
      {
        id: 'user-2',
        email: 'user2@example.com',
        nombres: 'María',
        apellidos: 'García',
        rol: 'estudiante',
        activo: true,
        usuarioInstituciones: [],
        estudiante: {
          id: 'student-1',
          identificacion: '123456789',
          codigoQr: 'QR123',
        },
      },
    ];

    it('should get all users and return success response', async () => {
      mockUserService.getAllUsers.mockResolvedValue(mockUsers);

      const request = mockRequest();
      const reply = mockReply();

      const result = await UserController.getAllUsers(request as any, reply as any);

      expect(mockUserService.getAllUsers).toHaveBeenCalled();
      expect(reply.code).toHaveBeenCalledWith(200);
      expect(reply.send).toHaveBeenCalledWith({
        success: true,
        data: mockUsers,
      });
    });

    it('should handle service errors', async () => {
      const serviceError = new Error('Database connection failed');
      mockUserService.getAllUsers.mockRejectedValue(serviceError);

      const request = mockRequest();
      const reply = mockReply();

      await expect(UserController.getAllUsers(request as any, reply as any)).rejects.toThrow('Database connection failed');
      expect(mockUserService.getAllUsers).toHaveBeenCalled();
    });
  });

  describe('getUsersByRole', () => {
    const role = 'profesor';
    const mockUsers = [
      {
        id: 'user-1',
        email: 'prof1@example.com',
        nombres: 'Juan',
        apellidos: 'Pérez',
        rol: 'profesor',
        activo: true,
        usuarioInstituciones: [],
      },
    ];

    it('should get users by role and return success response', async () => {
      mockUserService.getUsersByRole.mockResolvedValue(mockUsers);

      const request = mockRequest(undefined, { role });
      const reply = mockReply();

      const result = await UserController.getUsersByRole(request as any, reply as any);

      expect(mockUserService.getUsersByRole).toHaveBeenCalledWith(role);
      expect(reply.code).toHaveBeenCalledWith(200);
      expect(reply.send).toHaveBeenCalledWith({
        success: true,
        data: mockUsers,
      });
    });

    it('should handle ValidationError for invalid role', async () => {
      const validationError = new ValidationError('Rol inválido');
      mockUserService.getUsersByRole.mockRejectedValue(validationError);

      const request = mockRequest(undefined, { role: 'invalid_role' });
      const reply = mockReply();

      await expect(UserController.getUsersByRole(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.getUsersByRole).toHaveBeenCalledWith('invalid_role');
    });
  });

  describe('getUsersByInstitution', () => {
    const institucionId = 'inst-123';
    const mockUsers = [
      {
        id: 'user-1',
        email: 'user1@example.com',
        nombres: 'Juan',
        apellidos: 'Pérez',
        rol: 'profesor',
        activo: true,
        usuarioInstituciones: [{
          institucion: { id: institucionId, nombre: 'Institución Test' },
          rolEnInstitucion: 'profesor',
          activo: true,
        }],
      },
    ];

    it('should get users by institution and return success response', async () => {
      mockUserService.getUsersByInstitution.mockResolvedValue(mockUsers);

      const request = mockRequest(undefined, { institucionId });
      const reply = mockReply();

      const result = await UserController.getUsersByInstitution(request as any, reply as any);

      expect(mockUserService.getUsersByInstitution).toHaveBeenCalledWith(institucionId);
      expect(reply.code).toHaveBeenCalledWith(200);
      expect(reply.send).toHaveBeenCalledWith({
        success: true,
        data: mockUsers,
      });
    });

    it('should handle ValidationError for invalid institution id', async () => {
      const validationError = new ValidationError('ID de institución inválido');
      mockUserService.getUsersByInstitution.mockRejectedValue(validationError);

      const request = mockRequest(undefined, { institucionId: '' });
      const reply = mockReply();

      await expect(UserController.getUsersByInstitution(request as any, reply as any)).rejects.toThrow(ValidationError);
      expect(mockUserService.getUsersByInstitution).toHaveBeenCalledWith('');
    });
  });
});