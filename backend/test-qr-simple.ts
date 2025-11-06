// test-qr-simple.ts
// Test simplificado para verificar registro de asistencia con QR

import axios from 'axios';

const BASE_URL = 'http://localhost:3001';

async function login(email: string, password: string) {
  const response = await axios.post(`${BASE_URL}/auth/login`, {
    email,
    password,
  });
  return response.data.data.accessToken;
}

async function test() {
  console.log('\n🧪 === TEST: QR Scanner AuthorizationError ===\n');

  // Login como profesor Juan Pérez
  const token = await login('juan.perez@sanjose.edu', 'Prof123!');
  console.log('✅ Login exitoso\n');

  // Datos de prueba (basado en DATOS_PRUEBA.md)
  // Estudiante: Ana Martínez (10-A) - código QR: QR-EST-001
  // Horario: Cualquier horario de 10-A con Juan Pérez
  
  console.log('📝 Intentando registrar asistencia...');
  console.log('   Estudiante: Ana Martínez (QR-EST-001)');
  console.log('   Grupo: 10-A');
  console.log('   Profesor: Juan Pérez\n');

  try {
    // Primero necesitamos un horarioId válido
    // Como no tenemos endpoint para listar horarios, vamos a probar con IDs directamente
    
    console.log('⚠️ Nota: Este test requiere un horarioId válido');
    console.log('   Por favor ejecuta primero: docker compose exec backend npx prisma studio');
    console.log('   Y obtén el ID de un horario del grupo 10-A\n');
    
    // Ejemplo de estructura que debería funcionar:
    const testData = {
      horarioId: 'REEMPLAZAR_CON_ID_REAL',  // Se necesita obtener de la BD
      codigoQr: 'QR-EST-001',  // Ana Martínez del grupo 10-A
    };
    
    console.log('📊 Estructura de petición esperada:');
    console.log(JSON.stringify(testData, null, 2));
    console.log('\n❌ Test no puede continuar sin horarioId válido');
    console.log('   Solución: Obtener horarioId desde Prisma Studio o crear endpoint para listar horarios\n');
    
  } catch (error: any) {
    console.error('❌ Error:', error.message);
  }
}

test().catch(console.error);
