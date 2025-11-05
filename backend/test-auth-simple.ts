#!/usr/bin/env ts-node

/**
 * Test simple de autenticación para rutas del estudiante
 */

import axios from 'axios';

const BASE_URL = 'http://localhost:3001';

// Tokens de prueba (simulados)
const tokens = {
  profesor: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImE5ZjM5ZjM4LWMwZjEtNGQ4ZS1hZjM5LWE5ZjM5ZjM4YzBmMSIsInJvbCI6InByb2Zlc29yIiwiZW1haWwiOiJhbmEubG9wZXpAc2FuanVzZS5lZHUiLCJ0b2tlblZlcnNpb24iOjEsImp0aSI6ImE5ZjM5ZjM4LWMwZjEtNGQ4ZS1hZjM5LWE5ZjM5ZjM4YzBmMSJ9.invalid',
  estudiante: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Imp1YW4ucGVyZXpAc2FuanVzZS5lZHUiLCJyb2wiOiJlc3R1ZGlhbnRlIiwiZW1haWwiOiJqdWFuLnBlcmV6QHNhbmp1c2UuZWR1IiwidG9rZW5WZXJzaW9uIjoxLCJqdGkiOiJqdWFuLnBlcmV6QHNhbmp1c2UuZWR1In0.invalid'
};

async function testRoute(url: string, token: string, description: string) {
  try {
    console.log(`\n🧪 Probando: ${description}`);
    console.log(`📡 URL: ${url}`);
    console.log(`🔑 Token: ${token.substring(0, 20)}...`);

    const response = await axios.get(url, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      timeout: 5000
    });

    console.log(`✅ Status: ${response.status}`);
    console.log(`📄 Respuesta:`, response.data);

  } catch (error: any) {
    console.log(`❌ Error: ${error.response?.status || 'Network error'}`);
    if (error.response?.data) {
      console.log(`📄 Error response:`, error.response.data);
    } else {
      console.log(`💥 Error: ${error.message}`);
    }
  }
}

async function main() {
  console.log('🚀 Iniciando tests de autenticación para rutas del estudiante\n');

  // Test 1: Ruta del estudiante con token de profesor (debe fallar)
  await testRoute(
    `${BASE_URL}/estudiantes/dashboard/clases-hoy`,
    tokens.profesor,
    'Estudiante con token de PROFESOR (debe fallar con 403)'
  );

  // Test 2: Ruta del estudiante con token de estudiante (debe funcionar)
  await testRoute(
    `${BASE_URL}/estudiantes/dashboard/clases-hoy`,
    tokens.estudiante,
    'Estudiante con token de ESTUDIANTE (debe funcionar)'
  );

  // Test 3: Ruta del estudiante sin token (debe fallar)
  try {
    console.log(`\n🧪 Probando: Estudiante sin token (debe fallar con 401)`);
    const response = await axios.get(`${BASE_URL}/estudiantes/dashboard/clases-hoy`);
    console.log(`❌ Status: ${response.status} (esperado 401)`);
  } catch (error: any) {
    console.log(`✅ Status: ${error.response?.status} (esperado 401)`);
  }

  console.log('\n🎯 Tests completados');
}

main().catch(console.error);