#!/usr/bin/env node

const axios = require('axios');
const fs = require('fs');

/**
 * AsistApp API Testing Suite - PRUEBAS REALES
 * Archivo auxiliar para validar funcionamiento completo de la API
 * Incluye autenticación real y pruebas de endpoints protegidos
 *
 * Uso: node test-api.js
 */

// Configuración del servidor
const BASE_URL = 'http://localhost:3000';

// Configuración de axios
const api = axios.create({
  baseURL: BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Credenciales de prueba reales
const TEST_USERS = {
  super_admin: {
    email: 'test@asistapp.com',
    password: 'test123',
    expectedRole: 'super_admin'
  },
  admin_institucion: {
    email: 'testadmin@sanjose.edu',
    password: 'testadmin',
    expectedRole: 'admin_institucion'
  },
  profesor: {
    email: 'prof1@sanjose.edu',
    password: 'prof123',
    expectedRole: 'profesor'
  }
};

// Tokens de autenticación
let TOKENS = {};

// Función para hacer pruebas
async function runTests() {
  console.log('🚀 Iniciando pruebas REALES del API...\n');

  const results = {
    total: 0,
    passed: 0,
    failed: 0,
    tests: []
  };

  // Función helper para ejecutar una prueba
  async function runTest(name, testFn) {
    results.total++;
    console.log(`📋 Ejecutando: ${name}`);

    try {
      const result = await testFn();
      results.passed++;
      results.tests.push({ name, status: 'PASSED', result });
      console.log(`✅ PASSED: ${name}\n`);
    } catch (error) {
      results.failed++;
      results.tests.push({ name, status: 'FAILED', error: error.message });
      console.log(`❌ FAILED: ${name}`);
      console.log(`   Error: ${error.message}\n`);
    }
  }  // Pruebas de Health Check
  await runTest('Health Check', async () => {
    const response = await api.get('/');
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.success || !response.data.message.includes('AsistApp Backend')) {
      throw new Error('Respuesta del servidor inválida');
    }
  });

  // Pruebas de Autenticación Real
  await runTest('Login Super Admin', async () => {
    const loginData = {
      email: TEST_USERS.super_admin.email,
      password: TEST_USERS.super_admin.password
    };

    const response = await api.post('/auth/login', loginData);
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.data?.accessToken) {
      throw new Error('No se recibió token de acceso');
    }
    if (response.data.data.usuario.rol !== TEST_USERS.super_admin.expectedRole) {
      throw new Error(`Rol esperado ${TEST_USERS.super_admin.expectedRole}, recibido ${response.data.data.usuario.rol}`);
    }

    // Guardar token para pruebas posteriores
    TOKENS.super_admin = response.data.data.accessToken;
    console.log(`   🔑 Token Super Admin guardado`);
  });

  // Pruebas con Autenticación - Super Admin
  if (TOKENS.super_admin) {
    // Configurar headers con token
    const authApi = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.super_admin}`
      }
    });

    await runTest('Super Admin - Verificación de Token', async () => {
      const response = await authApi.get('/auth/verify');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Verificación de token fallida');
      }
      if (!response.data.data?.usuario) {
        throw new Error('No se recibió información del usuario');
      }
    });

    await runTest('Super Admin - Obtener Instituciones', async () => {
      const response = await authApi.get('/auth/instituciones');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   🏫 Instituciones encontradas: ${response.data.data?.length || 0}`);
    });
  }

  // Pruebas de endpoints que requieren diferentes roles
  await runTest('Endpoint sin Autenticación (debería fallar)', async () => {
    try {
      await api.get('/auth/instituciones');
      throw new Error('Se permitió acceso sin autenticación');
    } catch (error) {
      if (error.response?.status === 401) {
        // Esto es correcto - debe requerir autenticación
        return true;
      }
      throw new Error(`Error inesperado: ${error.message}`);
    }
  });

  // ===== PRUEBAS AVANZADAS DE GESTIÓN DE USUARIOS =====

  // Login Admin de Institución
  await runTest('Login Admin de Institución', async () => {
    const loginData = {
      email: TEST_USERS.admin_institucion.email,
      password: TEST_USERS.admin_institucion.password
    };

    const response = await api.post('/auth/login', loginData);
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.data?.accessToken) {
      throw new Error('No se recibió token de acceso');
    }
    if (response.data.data.usuario.rol !== TEST_USERS.admin_institucion.expectedRole) {
      throw new Error(`Rol esperado ${TEST_USERS.admin_institucion.expectedRole}, recibido ${response.data.data.usuario.rol}`);
    }

    TOKENS.admin_institucion = response.data.data.accessToken;
    console.log(`   🔑 Token Admin Institución guardado`);
  });

  // Login Profesor
  await runTest('Login Profesor', async () => {
    const loginData = {
      email: TEST_USERS.profesor.email,
      password: TEST_USERS.profesor.password
    };

    const response = await api.post('/auth/login', loginData);
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.data?.accessToken) {
      throw new Error('No se recibió token de acceso');
    }
    if (response.data.data.usuario.rol !== TEST_USERS.profesor.expectedRole) {
      throw new Error(`Rol esperado ${TEST_USERS.profesor.expectedRole}, recibido ${response.data.data.usuario.rol}`);
    }

    TOKENS.profesor = response.data.data.accessToken;
    console.log(`   🔑 Token Profesor guardado`);
  });

  // ===== GESTIÓN DE ADMINS DE INSTITUCIÓN (SUPER ADMIN) =====
  // NOTA: Estos endpoints parecen no estar implementados aún
  /*
  if (TOKENS.super_admin) {
    const authApiSuper = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.super_admin}`
      }
    });

    await runTest('Super Admin - Listar Admins de Institución', async () => {
      const response = await authApiSuper.get('/admin-institucion');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   👥 Admins encontrados: ${response.data.data?.length || 0}`);
    });

    await runTest('Super Admin - Listar Admins (Paginación)', async () => {
      const response = await authApiSuper.get('/admin-institucion?page=1&limit=2');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      if (!response.data.pagination) {
        throw new Error('Información de paginación faltante');
      }
      console.log(`   📄 Página ${response.data.pagination.page}, Total: ${response.data.pagination.total}`);
    });

    await runTest('Super Admin - Buscar Admins por Email', async () => {
      const response = await authApiSuper.get('/admin-institucion?search=sanjose');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   🔍 Resultados de búsqueda: ${response.data.data?.length || 0}`);
    });
  }
  */

  // ===== GESTIÓN DE PROFESORES (ADMIN DE INSTITUCIÓN) =====

  if (TOKENS.admin_institucion) {
    const authApiAdmin = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.admin_institucion}`
      }
    });

    await runTest('Admin Inst - Listar Profesores', async () => {
      const response = await authApiAdmin.get('/institution-admin/profesores');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   👨‍🏫 Profesores encontrados: ${response.data.data?.length || 0}`);
    });

    await runTest('Admin Inst - Listar Profesores (Paginación)', async () => {
      const response = await authApiAdmin.get('/institution-admin/profesores?page=1&limit=5');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      if (!response.data.pagination) {
        throw new Error('Información de paginación faltante');
      }
      console.log(`   📄 Página ${response.data.pagination.page}/${response.data.pagination.totalPages}, Total: ${response.data.pagination.total}`);
    });

    await runTest('Admin Inst - Buscar Profesores por Nombre', async () => {
      const response = await authApiAdmin.get('/institution-admin/profesores?search=Juan');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   🔍 Profesores encontrados con "Juan": ${response.data.data?.length || 0}`);
    });

    await runTest('Admin Inst - Filtrar Profesores Activos', async () => {
      const response = await authApiAdmin.get('/institution-admin/profesores?activo=true');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      const allActive = response.data.data?.every(p => p.activo === true) || false;
      if (!allActive) {
        throw new Error('No todos los profesores filtrados están activos');
      }
      console.log(`   ✅ Todos los profesores filtrados están activos: ${response.data.data?.length || 0}`);
    });

    // Crear profesor de prueba
    let createdProfesorId = null;
    await runTest('Admin Inst - Crear Profesor', async () => {
      const newProfesorData = {
        nombres: 'Profesor',
        apellidos: `Test ${Date.now()}`,
        email: `profesor.test${Date.now()}@sanjose.edu`,
        password: 'test123'
      };

      const response = await authApiAdmin.post('/institution-admin/profesores', newProfesorData);
      if (response.status !== 201 && response.status !== 200) {
        throw new Error(`Status esperado 200/201, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('No se pudo crear profesor');
      }
      if (!response.data.data?.id) {
        throw new Error('ID del profesor no devuelto');
      }

      createdProfesorId = response.data.data.id;
      console.log(`   👨‍🏫 Profesor creado: ${response.data.data.email}`);
    });

    // Operaciones con el profesor creado
    if (createdProfesorId) {
      await runTest('Admin Inst - Obtener Profesor por ID', async () => {
        const response = await authApiAdmin.get(`/institution-admin/profesores/${createdProfesorId}`);
        if (response.status !== 200) {
          throw new Error(`Status esperado 200, recibido ${response.status}`);
        }
        if (!response.data.success) {
          throw new Error('Respuesta no exitosa');
        }
        if (response.data.data.id !== createdProfesorId) {
          throw new Error('ID del profesor no coincide');
        }
        console.log(`   📋 Detalles del profesor obtenidos correctamente`);
      });

      await runTest('Admin Inst - Actualizar Profesor', async () => {
        const updateData = {
          nombres: 'Profesor Actualizado',
          apellidos: 'Test Modificado'
        };

        const response = await authApiAdmin.put(`/institution-admin/profesores/${createdProfesorId}`, updateData);
        if (response.status !== 200) {
          throw new Error(`Status esperado 200, recibido ${response.status}`);
        }
        if (!response.data.success) {
          throw new Error('No se pudo actualizar profesor');
        }
        if (response.data.data.nombres !== updateData.nombres) {
          throw new Error('Nombre no actualizado correctamente');
        }
        console.log(`   ✏️ Profesor actualizado: ${response.data.data.nombres}`);
      });

      await runTest('Admin Inst - Cambiar Status del Profesor', async () => {
        const response = await authApiAdmin.patch(`/institution-admin/profesores/${createdProfesorId}/toggle-status`, {}, {
          headers: {
            'Authorization': `Bearer ${TOKENS.admin_institucion}`
            // No enviar Content-Type para requests sin body
          }
        });
        if (response.status !== 200) {
          throw new Error(`Status esperado 200, recibido ${response.status}`);
        }
        if (!response.data.success) {
          throw new Error('No se pudo cambiar status');
        }
        console.log(`   🔄 Status del profesor cambiado`);
      });

      await runTest('Admin Inst - Eliminar Profesor', async () => {
        const response = await authApiAdmin.delete(`/institution-admin/profesores/${createdProfesorId}`, {
          headers: {
            'Authorization': `Bearer ${TOKENS.admin_institucion}`,
            'Content-Type': undefined  // Explicitamente remover Content-Type
          }
        });
        if (response.status !== 200) {
          throw new Error(`Status esperado 200, recibido ${response.status}`);
        }
        if (!response.data.success) {
          throw new Error('No se pudo eliminar profesor');
        }
        console.log(`   🗑️ Profesor eliminado correctamente`);
      });
    }
  }

  // ===== PRUEBAS DE SEGURIDAD =====

  // Super Admin intentando acceder a gestión de profesores (debería ser denegado por seguridad)
  if (TOKENS.super_admin) {
    const authApiSuper = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.super_admin}`
      }
    });

    await runTest('Super Admin - Acceso Restringido a Gestión de Profesores', async () => {
      try {
        await authApiSuper.get('/institution-admin/profesores');
        throw new Error('Super Admin no debería tener acceso directo a gestión de profesores de institución');
      } catch (error) {
        if (error.response?.status === 403) {
          console.log(`   ✅ Super Admin correctamente restringido acceso a gestión específica de institución`);
        } else {
          throw new Error(`Error inesperado: ${error.message}`);
        }
      }
    });
  }

  // Profesor intentando acceder a gestión (debería ser denegado)
  if (TOKENS.profesor) {
    const authApiProf = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.profesor}`
      }
    });

    await runTest('Profesor - Acceso Denegado a Gestión de Profesores', async () => {
      try {
        await authApiProf.get('/institution-admin/profesores');
        throw new Error('Profesor no debería tener acceso a gestión de profesores');
      } catch (error) {
        if (error.response?.status === 403 || error.response?.status === 401) {
          console.log(`   ✅ Profesor correctamente denegado acceso`);
        } else {
          throw new Error(`Error inesperado: ${error.message}`);
        }
      }
    });
  }

  // Resultados finales
  console.log('��� RESULTADOS FINALES:');
  console.log(`Total de pruebas: ${results.total}`);
  console.log(`Pasadas: ${results.passed}`);
  console.log(`Fallidas: ${results.failed}`);
  console.log(`Tasa de éxito: ${((results.passed / results.total) * 100).toFixed(1)}%\n`);

  // Guardar resultados en archivo
  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `test-results-${timestamp}.json`;
  
  fs.writeFileSync(filename, JSON.stringify(results, null, 2));
  console.log(`��� Resultados guardados en: ${filename}`);

  // Resumen detallado
  if (results.failed > 0) {
    console.log('\n❌ PRUEBAS FALLIDAS:');
    results.tests.filter(test => test.status === 'FAILED').forEach(test => {
      console.log(`- ${test.name}: ${test.error}`);
    });
  }

  return results;
}

// Función principal
async function main() {
  try {
    // Verificar que el servidor esté corriendo
    console.log('🔍 Verificando conexión con el servidor...');
    await axios.get(`${BASE_URL}/`, { timeout: 5000 });
    console.log('✅ Servidor conectado\n');
    
    // Ejecutar pruebas
    const results = await runTests();
    
    // Salir con código de error si hay fallos
    process.exit(results.failed > 0 ? 1 : 0);
    
  } catch (error) {
    console.error('❌ Error de conexión con el servidor:');
    console.error(`   ${error.message}`);
    console.log('\n��� Asegúrate de que:');
    console.log('   1. El servidor esté corriendo en localhost:3000');
    console.log('   2. La base de datos esté disponible');
    console.log('   3. Las variables de entorno estén configuradas');
    process.exit(1);
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  main();
}

module.exports = { runTests, api };
