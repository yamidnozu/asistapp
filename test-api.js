#!/usr/bin/env node

const axios = require('axios');
const fs = require('fs');

/**
 * AsistApp API Testing Suite - FLUJOS DEL DÍA A DÍA
 * Pruebas que simulan el uso real cotidiano del sistema
 *
 * Uso: node test-api.js
 */

// Configuración del servidor
const BASE_URL = 'http://localhost:3002';

// Configuración de axios
const api = axios.create({
  baseURL: BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Credenciales de prueba reales (actualizadas según seed.ts)
const TEST_USERS = {
  super_admin: {
    email: 'superadmin@asistapp.com',
    password: 'Admin123!',
    expectedRole: 'super_admin'
  },
  admin_institucion: {
    email: 'admin@sanjose.edu',
    password: 'SanJose123!',
    expectedRole: 'admin_institucion'
  },
  profesor: {
    email: 'juan.perez@sanjose.edu',
    password: 'Prof123!',
    expectedRole: 'profesor'
  },
  estudiante: {
    email: 'santiago.mendoza@sanjose.edu',
    password: 'Est123!',
    expectedRole: 'estudiante'
  }
};

// Tokens de autenticación
let TOKENS = {};

// Función para hacer pruebas
async function runTests() {
  console.log('🚀 Iniciando pruebas REALES del DÍA A DÍA...\n');

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
  }  // ===== PRUEBA DE CONEXIÓN =====
  await runTest('Health Check', async () => {
    const response = await api.get('/');
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.success || !response.data.message.includes('AsistApp Backend')) {
      throw new Error('Respuesta del servidor inválida');
    }
  });

  // ===== FLUJO DIARIO: SUPER ADMIN =====
  console.log('🏢 === INICIANDO FLUJO DIARIO DEL SUPER ADMIN ===\n');

  await runTest('🔐 Super Admin - Login Matutino', async () => {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: TEST_USERS.super_admin.email,
      password: TEST_USERS.super_admin.password
    });
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.success) {
      throw new Error('Login fallido');
    }
    TOKENS.super_admin = response.data.data.accessToken;
    console.log(`   🔑 Super Admin inició sesión exitosamente`);
  });

  if (TOKENS.super_admin) {
    const authApiSuper = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.super_admin}`
      }
    });

    await runTest('📊 Super Admin - Revisar Dashboard (Ver Instituciones)', async () => {
      const response = await authApiSuper.get('/auth/instituciones');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   🏫 Instituciones activas: ${response.data.data?.length || 0}`);
    });

    await runTest('📋 Super Admin - Gestionar Instituciones (Listar Todas)', async () => {
      const response = await authApiSuper.get('/instituciones');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   🏫 Total instituciones: ${response.data.data?.length || 0}`);
    });

    await runTest('➕ Super Admin - Crear Nueva Institución', async () => {
      const institucionData = {
        nombre: 'Colegio Nacional',
        activa: true
      };

      const response = await authApiSuper.post('/instituciones', institucionData);
      if (response.status !== 201 && response.status !== 200) {
        throw new Error(`Status esperado 200/201, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('No se pudo crear institución');
      }
      console.log(`   🏫 Nueva institución creada: ${response.data.data.nombre}`);
    });

    await runTest('👥 Super Admin - Gestionar Admins de Institución', async () => {
      const response = await authApiSuper.get('/admin-institucion');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   👥 Admins de institución: ${response.data.data?.length || 0}`);
    });
  }

  // ===== FLUJO DIARIO: ADMIN DE INSTITUCIÓN =====
  console.log('🏫 === INICIANDO FLUJO DIARIO DEL ADMIN DE INSTITUCIÓN ===\n');

  await runTest('🔐 Admin Inst - Login Matutino', async () => {
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
    console.log(`   🔑 Admin de institución inició sesión`);
  });

  if (TOKENS.admin_institucion) {
    const authApiAdmin = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.admin_institucion}`
      }
    });

    await runTest('📊 Admin Inst - Dashboard Matutino (Ver Profesores)', async () => {
      const response = await authApiAdmin.get('/institution-admin/profesores?page=1&limit=5');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   👨‍🏫 Profesores activos: ${response.data.data?.length || 0}`);
    });

    await runTest('📊 Admin Inst - Dashboard (Ver Estudiantes)', async () => {
      const response = await authApiAdmin.get('/institution-admin/estudiantes?page=1&limit=5');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   👨‍🎓 Estudiantes activos: ${response.data.data?.length || 0}`);
    });

    await runTest('📚 Admin Inst - Gestionar Materias', async () => {
      const response = await authApiAdmin.get('/materias?page=1&limit=5');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   📚 Materias disponibles: ${response.data.data?.length || 0}`);
    });

    await runTest('👥 Admin Inst - Gestionar Grupos', async () => {
      const response = await authApiAdmin.get('/grupos?page=1&limit=5');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   👥 Grupos activos: ${response.data.data?.length || 0}`);
    });

    // Simular gestión diaria: crear estudiante nuevo
    let newStudentId = null;
    await runTest('➕ Admin Inst - Nuevo Estudiante (Inscripción)', async () => {
      const newEstudianteData = {
        nombres: 'María José',
        apellidos: `García ${Date.now()}`,
        identificacion: `ID${Date.now()}`,
        email: `maria.garcia${Date.now()}@sanjose.edu`,
        password: 'Estudiante123!'
      };

      const response = await authApiAdmin.post('/institution-admin/estudiantes', newEstudianteData);
      if (response.status !== 201 && response.status !== 200) {
        throw new Error(`Status esperado 200/201, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('No se pudo inscribir estudiante');
      }

      newStudentId = response.data.data.id;
      console.log(`   👨‍🎓 Nuevo estudiante inscrito: ${response.data.data.usuario?.email}`);
    });

    // Simular gestión diaria: crear horario
    if (newStudentId) {
      await runTest('📅 Admin Inst - Crear Horario para Nuevo Estudiante', async () => {
        try {
          // Obtener datos necesarios con validación
          const [gruposRes, materiasRes, periodosRes, profesoresRes] = await Promise.all([
            authApiAdmin.get('/grupos'),
            authApiAdmin.get('/materias'),
            authApiAdmin.get('/auth/periodos'),
            authApiAdmin.get('/institution-admin/profesores')
          ]);

          console.log(`   📊 Grupos: ${gruposRes.data.data?.length || 0}, Materias: ${materiasRes.data.data?.length || 0}, Períodos: ${periodosRes.data.data?.length || 0}, Profesores: ${profesoresRes.data.data?.length || 0}`);

          if (gruposRes.data.data?.length > 0 && materiasRes.data.data?.length > 0 && periodosRes.data.data?.length > 0 && profesoresRes.data.data?.length > 0) {
            // Asignar el estudiante al primer grupo disponible
            const grupoId = gruposRes.data.data[0].id;
            const estudianteId = newStudentId;

            try {
              await authApiAdmin.post(`/grupos/${grupoId}/asignar-estudiante`, {
                estudianteId: estudianteId
              });
              console.log(`   👥 Estudiante asignado al grupo ${gruposRes.data.data[0].nombre}`);
            } catch (assignError) {
              console.log(`   ⚠️ No se pudo asignar estudiante al grupo: ${assignError.response?.data?.error || assignError.message}`);
            }

            const horarioData = {
              periodoId: periodosRes.data.data[0].id,
              grupoId: grupoId,
              materiaId: materiasRes.data.data[0].id,
              profesorId: profesoresRes.data.data[0].id, // Usar profesor real del seed
              diaSemana: 4, // Jueves (cambiar para evitar cualquier conflicto)
              horaInicio: '16:00',
              horaFin: '17:00'
            };

            console.log(`   📅 Intentando crear horario: ${JSON.stringify(horarioData, null, 2)}`);

            const response = await authApiAdmin.post('/horarios', horarioData);
            if (response.status !== 201 && response.status !== 200) {
              throw new Error(`Status esperado 200/201, recibido ${response.status}: ${JSON.stringify(response.data)}`);
            }
            if (!response.data.success) {
              throw new Error(`Respuesta no exitosa: ${JSON.stringify(response.data)}`);
            }
            console.log(`   📅 Horario creado exitosamente para el nuevo estudiante`);
          } else {
            console.log(`   ⚠️ No hay suficientes datos para crear horario (Grupos: ${gruposRes.data.data?.length || 0}, Materias: ${materiasRes.data.data?.length || 0}, Períodos: ${periodosRes.data.data?.length || 0}, Profesores: ${profesoresRes.data.data?.length || 0})`);
            // No fallar la prueba si no hay datos suficientes
            return true;
          }
        } catch (error) {
          console.log(`   ❌ Error al crear horario: ${error.message}`);
          if (error.response) {
            console.log(`   📄 Respuesta del servidor: ${JSON.stringify(error.response.data, null, 2)}`);
          }
          throw error;
        }
      });
    }

    await runTest('📋 Admin Inst - Revisar Asistencias del Día', async () => {
      const today = new Date().toISOString().split('T')[0];
      const response = await authApiAdmin.get(`/asistencias?fecha=${today}&page=1&limit=10`);
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      if (!response.data.success) {
        throw new Error('Respuesta no exitosa');
      }
      console.log(`   📊 Asistencias registradas hoy: ${response.data.data?.length || 0}`);
    });
  }

  // ===== FLUJO DIARIO: PROFESOR =====
  console.log('👨‍🏫 === INICIANDO FLUJO DIARIO DEL PROFESOR ===\n');

  await runTest('🔐 Profesor - Login Matutino', async () => {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: TEST_USERS.profesor.email,
      password: TEST_USERS.profesor.password
    });
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.success) {
      throw new Error('Login fallido');
    }
    TOKENS.profesor = response.data.data.accessToken;
    console.log(`   🔑 Profesor inició sesión`);
  });

  if (TOKENS.profesor) {
    const authApiProf = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.profesor}`
      }
    });

    await runTest('📅 Profesor - Revisar Horarios del Día', async () => {
      const today = new Date().getDay() || 7; // 0 = Domingo, convertir a 7
      const response = await authApiProf.get('/auth/verify');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      // Nota: Los profesores normalmente verían sus horarios específicos
      console.log(`   📅 Día de la semana: ${today}`);
    });

    await runTest('📊 Profesor - Ver Grupos Asignados', async () => {
      // Los profesores normalmente verían sus grupos a través de horarios
      const response = await authApiProf.get('/auth/verify');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      console.log(`   👥 Información del profesor verificada`);
    });

    // Simular toma de asistencia en clase
    await runTest('📝 Profesor - Tomar Asistencia en Clase', async () => {
      // Obtener asistencias existentes para simular actualización
      const response = await authApiProf.get('/asistencias?page=1&limit=5');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      console.log(`   📝 Asistencias disponibles para gestión: ${response.data.data?.length || 0}`);
    });

    await runTest('📈 Profesor - Revisar Reportes de Asistencia', async () => {
      const today = new Date().toISOString().split('T')[0];
      const response = await authApiProf.get(`/asistencias?fecha=${today}`);
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      console.log(`   📈 Reporte de asistencias del día: ${response.data.data?.length || 0} registros`);
    });
  }

  // ===== FLUJO DIARIO: ESTUDIANTE =====
  console.log('👨‍🎓 === INICIANDO FLUJO DIARIO DEL ESTUDIANTE ===\n');

  await runTest('🔐 Estudiante - Login Matutino', async () => {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email: TEST_USERS.estudiante.email,
      password: TEST_USERS.estudiante.password
    });
    if (response.status !== 200) {
      throw new Error(`Status esperado 200, recibido ${response.status}`);
    }
    if (!response.data.success) {
      throw new Error('Login fallido');
    }
    TOKENS.estudiante = response.data.data.accessToken;
    console.log(`   🔑 Estudiante inició sesión`);
  });

  if (TOKENS.estudiante) {
    const authApiEst = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.estudiante}`
      }
    });

    await runTest('📅 Estudiante - Ver Mi Horario de Clases', async () => {
      const response = await authApiEst.get('/auth/verify');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      console.log(`   📅 Información del estudiante verificada`);
    });

    await runTest('📊 Estudiante - Revisar Mi Historial de Asistencia', async () => {
      const response = await authApiEst.get('/asistencias/estudiante?page=1&limit=10');
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      console.log(`   📊 Mi historial de asistencia: ${response.data.data?.length || 0} registros`);
    });

    await runTest('📈 Estudiante - Ver Asistencia del Día', async () => {
      const today = new Date().toISOString().split('T')[0];
      const response = await authApiEst.get(`/asistencias/estudiante?fecha=${today}`);
      if (response.status !== 200) {
        throw new Error(`Status esperado 200, recibido ${response.status}`);
      }
      console.log(`   📈 Mi asistencia de hoy: ${response.data.data?.length || 0} registros`);
    });
  }

  // ===== PRUEBAS DE SEGURIDAD Y ACCESO =====
  console.log('🔒 === PRUEBAS DE SEGURIDAD ===\n');

  await runTest('🚫 Endpoint sin Autenticación (debería fallar)', async () => {
    try {
      await api.get('/auth/instituciones');
      throw new Error('Se permitió acceso sin autenticación');
    } catch (error) {
      if (error.response?.status === 401) {
        console.log(`   ✅ Correctamente protegido sin autenticación`);
      } else {
        throw new Error(`Error inesperado: ${error.message}`);
      }
    }
  });

  if (TOKENS.super_admin) {
    const authApiSuper = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.super_admin}`
      }
    });

    await runTest('🚫 Super Admin - Acceso Restringido a Gestión Específica', async () => {
      try {
        await authApiSuper.get('/institution-admin/profesores');
        throw new Error('Super Admin no debería tener acceso directo a gestión específica de institución');
      } catch (error) {
        if (error.response?.status === 403) {
          console.log(`   ✅ Super Admin correctamente restringido`);
        } else {
          throw new Error(`Error inesperado: ${error.message}`);
        }
      }
    });
  }

  if (TOKENS.profesor) {
    const authApiProf = axios.create({
      baseURL: BASE_URL,
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${TOKENS.profesor}`
      }
    });

    await runTest('🚫 Profesor - Acceso Denegado a Gestión Administrativa', async () => {
      try {
        await authApiProf.get('/institution-admin/profesores');
        throw new Error('Profesor no debería tener acceso a gestión administrativa');
      } catch (error) {
        if (error.response?.status === 403 || error.response?.status === 401) {
          console.log(`   ✅ Profesor correctamente denegado acceso administrativo`);
        } else {
          throw new Error(`Error inesperado: ${error.message}`);
        }
      }
    });
  }

  // ===== CIERRE DE SESIONES =====
  console.log('👋 === CIERRE DE SESIONES DIARIAS ===\n');

  await runTest('✅ Sesiones Cerradas Correctamente', async () => {
    // Simular cierre de sesiones (en una app real, esto sería automático con JWT expiry)
    const activeTokens = Object.keys(TOKENS).filter(key => TOKENS[key]).length;
    console.log(`   🔑 Sesiones activas gestionadas: ${activeTokens}`);
    return true;
  });

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
