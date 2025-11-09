const http = require('http');

function request(method, path, headers, body) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: '127.0.0.1',
      port: 3000,
      path: path,
      method: method,
      headers: headers
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch {
          resolve(data);
        }
      });
    });
    
    req.on('error', reject);
    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

async function test() {
  console.log('\n=== PASO 1: LOGIN CON SUPERADMIN ===');
  const loginBody = {
    email: 'superadmin@asistapp.com',
    password: 'Admin123!'
  };
  
  const loginRes = await request('POST', '/auth/login', {
    'Content-Type': 'application/json'
  }, loginBody);
  
  console.log('Login response:', JSON.stringify(loginRes, null, 2));
  
  if (!loginRes.success || !loginRes.data?.accessToken) {
    console.error('❌ Login failed');
    return;
  }
  
  const token = loginRes.data.accessToken;
  console.log('✅ Token obtenido (length:', token.length, ')');
  
  console.log('\n=== PASO 2: GET USUARIO PARA EDITAR ===');
  const userId = '85c24d0b-1127-4ffc-a2f9-37e5870803ae';
  
  const getUserRes = await request('GET', '/usuarios/' + userId, {
    'Authorization': 'Bearer ' + token
  });
  
  console.log('GET usuario ANTES de actualizar:');
  console.log(JSON.stringify(getUserRes, null, 2));
  
  console.log('\n=== PASO 3: PUT ACTUALIZAR TITULO Y ESPECIALIDAD ===');
  const updateBody = {
    nombres: getUserRes.data?.nombres || 'Profesor',
    apellidos: getUserRes.data?.apellidos || 'Test',
    identificacion: '1234567890',
    titulo: 'Dr. en Matemáticas Avanzadas',
    especialidad: 'Cálculo Diferencial e Integral'
  };
  
  console.log('Body del PUT:', JSON.stringify(updateBody, null, 2));
  
  const updateRes = await request('PUT', '/usuarios/' + userId, {
    'Authorization': 'Bearer ' + token,
    'Content-Type': 'application/json'
  }, updateBody);
  
  console.log('\nRespuesta del PUT:');
  console.log(JSON.stringify(updateRes, null, 2));
  
  console.log('\n=== PASO 4: GET USUARIO DESPUÉS DEL PUT ===');
  const getUserRes2 = await request('GET', '/usuarios/' + userId, {
    'Authorization': 'Bearer ' + token
  });
  
  console.log('GET usuario DESPUÉS de actualizar:');
  console.log(JSON.stringify(getUserRes2, null, 2));
  
  console.log('\n=== VALIDACIÓN FINAL ===');
  const userData = getUserRes2.data;
  if (userData?.titulo && userData?.especialidad && userData?.identificacion) {
    console.log('✅ ÉXITO: El backend persiste y devuelve los campos');
    console.log('   - identificacion:', userData.identificacion);
    console.log('   - titulo:', userData.titulo);
    console.log('   - especialidad:', userData.especialidad);
  } else {
    console.log('❌ FALLO: Los campos NO están en la respuesta');
    console.log('   - identificacion presente:', !!userData?.identificacion);
    console.log('   - titulo presente:', !!userData?.titulo);
    console.log('   - especialidad presente:', !!userData?.especialidad);
  }
}

test().catch(console.error);
