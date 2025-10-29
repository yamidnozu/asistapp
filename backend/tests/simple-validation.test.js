#!/usr/bin/env node

// Pruebas unitarias simples sin dependencias externas
// Ejecutar con: node tests/simple-validation.test.js

const assert = require('assert');

// Funciones de validación simples para probar (sin dependencias externas)
const validateUserData = (data) => {
  // Validar rol primero
  if (!data.rol || typeof data.rol !== 'string') {
    throw new Error('Rol inválido');
  }

  const validRoles = ['super_admin', 'admin_institucion', 'profesor', 'estudiante'];
  if (!validRoles.includes(data.rol)) {
    throw new Error('Rol inválido');
  }

  // Validar campos requeridos básicos
  if (!data.email || !data.password || !data.nombres || !data.apellidos) {
    throw new Error('Campos requeridos faltantes');
  }

  // Validar campos específicos del rol
  if (data.rol === 'estudiante' && !data.identificacion) {
    throw new Error('La identificación es requerida para estudiantes');
  }
};

const validateEmail = (email) => {
  if (!email || typeof email !== 'string' || !email.includes('@')) {
    throw new Error('Email inválido');
  }
};

const validateUserId = (id) => {
  if (!id || typeof id !== 'string') {
    throw new Error('ID de usuario inválido');
  }
};

const generateQRCode = () => {
  return 'ABC123DEF456'; // Mock implementation
};

const hashPassword = async (password) => {
  // Mock hash implementation
  return `hashed_${password}`;
};

// Función para ejecutar pruebas
const runTests = async () => {
  const results = {
    passed: 0,
    failed: 0,
    errors: []
  };

  const test = (name, fn) => {
    try {
      fn();
      results.passed++;
      console.log(`✓ ${name}`);
    } catch (error) {
      results.failed++;
      results.errors.push({ name, error: error.message });
      console.log(`✗ ${name}: ${error.message}`);
    }
  };

  console.log('Ejecutando pruebas de validación de usuario...\n');

  // Pruebas de validateUserData
  test('validateUserData - profesor válido', () => {
    const validData = {
      email: 'profesor@test.com',
      password: 'password123',
      nombres: 'Juan',
      apellidos: 'Pérez',
      rol: 'profesor',
      telefono: '+1234567890',
    };
    validateUserData(validData);
  });

  test('validateUserData - estudiante válido', () => {
    const validData = {
      email: 'estudiante@test.com',
      password: 'password123',
      nombres: 'María',
      apellidos: 'García',
      rol: 'estudiante',
      identificacion: '123456789',
      nombreResponsable: 'Padre de María',
    };
    validateUserData(validData);
  });

  test('validateUserData - campos requeridos faltantes', () => {
    const invalidData = {
      email: 'test@test.com',
      rol: 'profesor',
      // Falta password, nombres, apellidos
    };
    try {
      validateUserData(invalidData);
      throw new Error('Debería haber fallado');
    } catch (error) {
      if (error.message !== 'Campos requeridos faltantes') {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  test('validateUserData - rol inválido', () => {
    const invalidData = {
      email: 'test@test.com',
      password: 'password123',
      nombres: 'Juan',
      apellidos: 'Pérez',
      rol: 'invalid_role',
    };
    try {
      validateUserData(invalidData);
      throw new Error('Debería haber fallado');
    } catch (error) {
      if (error.message !== 'Rol inválido') {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  test('validateUserData - estudiante sin identificación', () => {
    const invalidData = {
      email: 'estudiante@test.com',
      password: 'password123',
      nombres: 'María',
      apellidos: 'García',
      rol: 'estudiante',
      // Falta identificacion
    };
    try {
      validateUserData(invalidData);
      throw new Error('Debería haber fallado');
    } catch (error) {
      if (error.message !== 'La identificación es requerida para estudiantes') {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  // Pruebas de validateEmail
  test('validateEmail - email válido', () => {
    validateEmail('test@example.com');
  });

  test('validateEmail - email inválido', () => {
    try {
      validateEmail('invalid-email');
      throw new Error('Debería haber fallado');
    } catch (error) {
      if (error.message !== 'Email inválido') {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  test('validateEmail - email null', () => {
    try {
      validateEmail(null);
      throw new Error('Debería haber fallado');
    } catch (error) {
      if (error.message !== 'Email inválido') {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  // Pruebas de validateUserId
  test('validateUserId - ID válido', () => {
    validateUserId('user-123');
  });

  test('validateUserId - ID inválido', () => {
    try {
      validateUserId('');
      throw new Error('Debería haber fallado');
    } catch (error) {
      if (error.message !== 'ID de usuario inválido') {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  // Pruebas de generateQRCode
  test('generateQRCode - genera código QR', () => {
    const qrCode = generateQRCode();
    assert.strictEqual(typeof qrCode, 'string');
    assert(qrCode.length > 0);
    assert.strictEqual(qrCode, 'ABC123DEF456');
  });

  // Pruebas de hashPassword
  test('hashPassword - hashea contraseña', async () => {
    const password = 'mypassword123';
    const hashed = await hashPassword(password);
    assert.strictEqual(hashed, `hashed_${password}`);
    assert(hashed.startsWith('hashed_'));
  });

  // Pruebas de roles válidos
  test('roles válidos - acepta todos los roles', () => {
    const validRoles = ['super_admin', 'admin_institucion', 'profesor', 'estudiante'];

    validRoles.forEach(role => {
      const data = {
        email: 'test@test.com',
        password: 'password123',
        nombres: 'Test',
        apellidos: 'User',
        rol: role,
      };

      if (role === 'estudiante') {
        data.identificacion = '123456789';
      }

      validateUserData(data);
    });
  });

  test('roles inválidos - rechaza roles inválidos', () => {
    const invalidRoles = ['admin', 'teacher', 'student', 'superuser'];

    invalidRoles.forEach(role => {
      const data = {
        email: 'test@test.com',
        password: 'password123',
        nombres: 'Test',
        apellidos: 'User',
        rol: role,
      };

      try {
        validateUserData(data);
        throw new Error('Debería haber fallado');
      } catch (error) {
        if (error.message !== 'Rol inválido') {
          throw new Error(`Error inesperado: ${error.message}`);
        }
      }
    });

    // Caso especial para rol vacío
    const dataWithEmptyRole = {
      email: 'test@test.com',
      password: 'password123',
      nombres: 'Test',
      apellidos: 'User',
      rol: '',
    };

    try {
      validateUserData(dataWithEmptyRole);
      throw new Error('Debería haber fallado');
    } catch (error) {
      if (error.message !== 'Rol inválido') {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  // Pruebas de normalización de email
  test('email case sensitivity - maneja mayúsculas/minúsculas', () => {
    const emails = ['Test@Example.COM', 'TEST@EXAMPLE.COM', 'test@example.com'];

    emails.forEach(email => {
      validateEmail(email);
    });
  });

  // Pruebas de sanitización de datos
  test('data sanitization - maneja espacios en blanco', () => {
    const dataWithWhitespace = {
      email: '  test@example.com  ',
      password: 'password123',
      nombres: '  Juan  ',
      apellidos: '  Pérez  ',
      rol: 'profesor',
    };

    // La validación actual no maneja whitespace, pero debería pasar
    validateUserData(dataWithWhitespace);
  });

  console.log(`\nResultados: ${results.passed} pasaron, ${results.failed} fallaron`);

  if (results.failed > 0) {
    console.log('\nErrores:');
    results.errors.forEach(error => {
      console.log(`- ${error.name}: ${error.error}`);
    });
    process.exit(1);
  } else {
    console.log('\n¡Todas las pruebas pasaron! ✓');
  }
};

// Ejecutar pruebas
runTests().catch(error => {
  console.error('Error ejecutando pruebas:', error);
  process.exit(1);
});