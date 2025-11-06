// test-qr-authorization.ts
// Script para probar el error de autorización al escanear QR

import axios from 'axios';

const BASE_URL = 'http://localhost:3001';

async function login(email: string, password: string) {
  try {
    const response = await axios.post(`${BASE_URL}/auth/login`, {
      email,
      password,
    });
    return response.data.data.accessToken;
  } catch (error: any) {
    console.error('❌ Error en login:', error.response?.data || error.message);
    throw error;
  }
}

async function testRegistrarAsistenciaQR() {
  console.log('\n🧪 === TEST: Registrar Asistencia con QR ===\n');

  // 1. Login como profesor
  console.log('1️⃣ Login como profesor...');
  const profesorToken = await login('juan.perez@sanjose.edu', 'Prof123!');
  console.log('✅ Token profesor obtenido\n');

  // 2. Obtener horarios del profesor
  console.log('2️⃣ Obteniendo horarios del profesor...');
  const horariosResponse = await axios.get(`${BASE_URL}/profesor/horarios-hoy`, {
    headers: { Authorization: `Bearer ${profesorToken}` },
  });

  const horarios = horariosResponse.data.data;
  console.log(`✅ ${horarios.length} horarios encontrados`);

  if (horarios.length === 0) {
    console.log('⚠️ No hay horarios para hoy');
    return;
  }

  const primerHorario = horarios[0];
  console.log(`\n📚 Horario seleccionado:`);
  console.log(`   - ID: ${primerHorario.id}`);
  console.log(`   - Materia: ${primerHorario.materia.nombre}`);
  console.log(`   - Grupo: ${primerHorario.grupo.nombre}`);
  console.log(`   - Periodo: ${primerHorario.periodo.nombre}\n`);

  // 3. Obtener código QR de un estudiante del grupo
  console.log('3️⃣ Buscando estudiantes del grupo...');
  const asistenciasResponse = await axios.get(
    `${BASE_URL}/horarios/${primerHorario.id}/asistencias`,
    {
      headers: { Authorization: `Bearer ${profesorToken}` },
    }
  );

  const estudiantes = asistenciasResponse.data.data;
  console.log(`✅ ${estudiantes.length} estudiantes en el grupo`);

  if (estudiantes.length === 0) {
    console.log('⚠️ No hay estudiantes en el grupo');
    return;
  }

  const primerEstudiante = estudiantes[0];
  console.log(`\n👤 Estudiante seleccionado:`);
  console.log(`   - Nombre: ${primerEstudiante.nombreCompleto}`);
  console.log(`   - Código QR: ${primerEstudiante.codigoQr}\n`);

  // 4. Intentar registrar asistencia con QR
  console.log('4️⃣ Registrando asistencia con código QR...');
  try {
    const registroResponse = await axios.post(
      `${BASE_URL}/asistencias/registrar`,
      {
        horarioId: primerHorario.id,
        codigoQr: primerEstudiante.codigoQr,
      },
      {
        headers: { Authorization: `Bearer ${profesorToken}` },
      }
    );

    console.log('✅ Asistencia registrada exitosamente');
    console.log('📊 Respuesta:', JSON.stringify(registroResponse.data, null, 2));
  } catch (error: any) {
    if (error.response) {
      console.log(`❌ Error ${error.response.status}:`, error.response.data);
      
      if (error.response.status === 403) {
        console.log('\n🔍 DEBUG: Error de autorización detectado');
        console.log('   Posibles causas:');
        console.log('   1. El estudiante no pertenece al grupo de esta clase');
        console.log('   2. El periodo académico está inactivo');
        console.log('   3. Problema con la relación EstudianteGrupo\n');
      }
      
      if (error.response.status === 400) {
        console.log('\n🔍 DEBUG: Error de validación');
        console.log('   Posible causa: El estudiante ya tiene asistencia registrada hoy\n');
      }
    } else {
      console.log('❌ Error de red:', error.message);
    }
  }

  // 5. Intentar registrar de nuevo (debería dar error 400)
  console.log('\n5️⃣ Intentando registrar de nuevo (debería fallar)...');
  try {
    await axios.post(
      `${BASE_URL}/asistencias/registrar`,
      {
        horarioId: primerHorario.id,
        codigoQr: primerEstudiante.codigoQr,
      },
      {
        headers: { Authorization: `Bearer ${profesorToken}` },
      }
    );
    console.log('⚠️ No debería llegar aquí');
  } catch (error: any) {
    if (error.response?.status === 400) {
      console.log('✅ Error 400 esperado:', error.response.data.message);
    } else {
      console.log(`❌ Error inesperado ${error.response?.status}:`, error.response?.data);
    }
  }
}

// Ejecutar test
testRegistrarAsistenciaQR()
  .then(() => {
    console.log('\n✅ Test completado\n');
    process.exit(0);
  })
  .catch((error) => {
    console.error('\n❌ Test falló:', error.message);
    process.exit(1);
  });
