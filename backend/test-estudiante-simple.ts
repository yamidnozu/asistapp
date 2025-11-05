import axios from 'axios';

const API_URL = 'http://localhost:3001';

async function testCreateEstudiante() {
  try {
    console.log('🔐 Iniciando sesión como admin...');
    
    // Login
    const loginResponse = await axios.post(`${API_URL}/auth/login`, {
      email: 'admin@sanjose.edu',
      password: 'Admin123!',
    });

    const token = loginResponse.data.data.token;
    console.log('✅ Login exitoso\n');

    console.log('🎓 Intentando crear estudiante...');
    
    const timestamp = Date.now();
    const createResponse = await axios.post(
      `${API_URL}/institution-admin/estudiantes`,
      {
        nombres: 'Test',
        apellidos: `Estudiante ${timestamp}`,
        email: `test.${timestamp}@sanjose.edu`,
        password: 'Test123!',
        identificacion: `ID-${timestamp}`,
        nombreResponsable: 'Responsable Test',
        telefonoResponsable: '555-1234',
      },
      {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 30000,
      }
    );

    console.log('✅ Estudiante creado exitosamente:');
    console.log(JSON.stringify(createResponse.data, null, 2));
    
  } catch (error: any) {
    console.error('❌ Error:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
      console.error('Response status:', error.response.status);
    }
  }
}

testCreateEstudiante();
