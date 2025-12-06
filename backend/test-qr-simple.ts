// test-qr-simple.ts
// Test simplificado para verificar registro de asistencia con QR

import axios from 'axios';

const BASE_URL = 'http://localhost:3000';

interface LoginResponse {
  success: boolean;
  data: {
    accessToken: string;
    usuario: {
      id: string;
      rol: string;
    };
  };
}

async function login(email: string, password: string): Promise<{ token: string; userId: string }> {
  try {
    const response = await axios.post<LoginResponse>(`${BASE_URL}/auth/login`, {
      email,
      password,
    });
    return {
      token: response.data.data.accessToken,
      userId: response.data.data.usuario.id,
    };
  } catch (error: any) {
    console.error(`   Error login ${email}:`, error.message);
    throw error;
  }
}

async function getHorarioValido(profesorToken: string, adminToken: string, profesorId: string): Promise<string | null> {
  try {
    // 1. Intentar obtener clases del día del profesor (lo ideal)
    console.log('   Consultando clases de hoy para el profesor...');
    const response = await axios.get(`${BASE_URL}/profesores/dashboard/clases-hoy`, {
      headers: { Authorization: `Bearer ${profesorToken}` },
    });

    const clases = response.data.data;
    if (clases && clases.length > 0) {
      console.log(`   ✅ Encontradas ${clases.length} clases para hoy.`);
      return clases[0].id;
    }
    
    console.log('   ⚠️ No hay clases hoy para el profesor. Buscando cualquier horario del profesor (vía Admin)...');

    // 2. Si no hay clases hoy, buscar cualquier horario del profesor usando token de ADMIN
    const horariosResponse = await axios.get(`${BASE_URL}/horarios`, {
      headers: { Authorization: `Bearer ${adminToken}` },
      params: { limit: 100 }
    });

    const horarios = horariosResponse.data.data?.items || horariosResponse.data.data || [];
    
    // Filtrar horarios del profesor
    const horariosProfesor = horarios.filter((h: any) => h.profesorId === profesorId || h.profesor?.id === profesorId);

    if (horariosProfesor.length > 0) {
      console.log(`   ✅ Encontrados ${horariosProfesor.length} horarios para el profesor (cualquier día).`);
      const hoy = new Date().getDay(); // 0-6
      const horarioHoy = horariosProfesor.find((h: any) => h.diaSemana === hoy);
      
      if (horarioHoy) {
         console.log(`   ✅ Encontrado horario para el día de hoy (Día ${hoy}).`);
         return horarioHoy.id;
      } else {
         console.log(`   ⚠️ No se encontró horario para el día de hoy (Día ${hoy}). Usando el primero disponible (puede fallar validación).`);
         return horariosProfesor[0].id;
      }
    }

    return null;
  } catch (error: any) {
    console.log(`   Error obteniendo horarios: ${error.message}`);
    if (error.response) {
        console.log(`   Status: ${error.response.status}`);
        console.log(`   Data: ${JSON.stringify(error.response.data)}`);
    }
    return null;
  }
}

async function getEstudianteDeGrupo(token: string, adminToken: string, horarioId: string): Promise<string | null> {
  try {
    const response = await axios.get(`${BASE_URL}/horarios/${horarioId}/asistencias`, {
      headers: { Authorization: `Bearer ${token}` },
    });

    const asistencias = response.data.data;
    if (asistencias && asistencias.length > 0) {
      const asistencia = asistencias[0];
      // La estructura puede ser asistencia.estudiante (objeto Estudiante)
      // O si el endpoint devuelve estudiantes directamente (depende del controlador)
      // Asumimos que devuelve Asistencias con include: { estudiante: { include: { usuario: true } } }
      
      const estudianteObj = asistencia.estudiante;
      
      if (!estudianteObj) {
          console.log('   ⚠️ Objeto estudiante no encontrado en la respuesta de asistencia.');
          return null;
      }

      const nombre = estudianteObj.nombres || estudianteObj.usuario?.nombres || "Desconocido";
      const apellido = estudianteObj.apellidos || estudianteObj.usuario?.apellidos || "";
      
      console.log(`   Estudiante encontrado: ${nombre} ${apellido}`);
      
      // Intentar obtener codigoQr directamente
      if (estudianteObj.codigoQr) {
          console.log(`   ✅ Código QR encontrado directamente: ${estudianteObj.codigoQr}`);
          return estudianteObj.codigoQr;
      }

      // Si no está, buscar por usuarioId usando Admin
      const usuarioId = estudianteObj.usuarioId;
      if (usuarioId) {
          console.log(`   ⚠️ Código QR no visible. Consultando perfil completo vía Admin (Usuario ID: ${usuarioId})...`);
          try {
              const userResponse = await axios.get(`${BASE_URL}/usuarios/${usuarioId}`, {
                  headers: { Authorization: `Bearer ${adminToken}` }
              });
              
              const fullUser = userResponse.data.data;
              if (fullUser && fullUser.estudiante && fullUser.estudiante.codigoQr) {
                  console.log(`   ✅ Código QR recuperado vía Admin: ${fullUser.estudiante.codigoQr}`);
                  return fullUser.estudiante.codigoQr;
              }
          } catch (err: any) {
              console.log(`   ❌ Error consultando usuario admin: ${err.message}`);
          }
      }

      // Si no tenemos usuarioId, buscar por nombre (fallback)
      if (nombre !== "Desconocido") {
          console.log(`   ⚠️ Buscando usuario por nombre: ${nombre} ${apellido}...`);
          try {
              const searchResponse = await axios.get(`${BASE_URL}/usuarios`, {
                  headers: { Authorization: `Bearer ${adminToken}` },
                  params: { search: nombre, limit: 5 }
              });
              
              const users = searchResponse.data.data;
              
              // Buscar coincidencia exacta o aproximada
              const foundUser = users.find((u: any) => 
                  u.nombres.includes(nombre) && u.apellidos.includes(apellido)
              );

              if (foundUser) {
                  console.log(`   ✅ Usuario encontrado: ${foundUser.nombres} ${foundUser.apellidos} (ID: ${foundUser.id})`);
                  
                  // Ahora obtener el detalle completo para tener el QR
                  try {
                      const detailResponse = await axios.get(`${BASE_URL}/usuarios/${foundUser.id}`, {
                          headers: { Authorization: `Bearer ${adminToken}` }
                      });
                      
                      const fullUserDetail = detailResponse.data.data;
                      if (fullUserDetail && fullUserDetail.estudiante && fullUserDetail.estudiante.codigoQr) {
                          console.log(`   ✅ Código QR recuperado del detalle: ${fullUserDetail.estudiante.codigoQr}`);
                          return fullUserDetail.estudiante.codigoQr;
                      } else {
                          console.log('   ⚠️ El usuario encontrado no tiene perfil de estudiante o código QR.');
                      }
                  } catch (detailErr: any) {
                      console.log(`   ❌ Error obteniendo detalle del usuario: ${detailErr.message}`);
                  }
              }
          } catch (err: any) {
              console.log(`   ❌ Error buscando usuario por nombre: ${err.message}`);
          }
      }
      
      // Fallback: Si todo falla, intentar usar el ID como QR (aunque sabemos que fallará si el backend valida formato)
      // O devolver null
      console.log('   ❌ No se pudo obtener el código QR real.');
      return null;
    }
    return null;
  } catch (error: any) {
    console.log(`   Error obteniendo estudiantes: ${error.message}`);
    return null;
  }
}

async function test() {
  console.log('\n=== TEST: Registro de Asistencia con QR (Automatizado) ===\n');

  try {
    // Paso 1: Login como Admin (para respaldo)
    console.log('[1] Iniciando sesión como Admin (San José)...');
    const adminAuth = await login('admin@sanjose.edu', 'SanJose123!');
    console.log('   Login Admin exitoso\n');

    // Paso 2: Login como profesor
    console.log('[2] Iniciando sesión como profesor...');
    const profAuth = await login('juan.perez@sanjose.edu', 'Prof123!');
    console.log('   Login Profesor exitoso\n');

    // Paso 3: Obtener un horario válido
    console.log('[3] Buscando horario válido...');
    const horarioId = await getHorarioValido(profAuth.token, adminAuth.token, profAuth.userId);
    
    if (!horarioId) {
      console.log('   ❌ No se encontraron horarios para el profesor. Asegúrate de tener datos de seed.\n');
      return;
    }
    console.log(`   Horario ID seleccionado: ${horarioId}\n`);

    // Paso 4: Obtener estudiante del grupo
    console.log('[4] Obteniendo estudiante del grupo...');
    // Pasamos adminToken también
    const codigoQr = await getEstudianteDeGrupo(profAuth.token, adminAuth.token, horarioId);

    if (!codigoQr) {
      console.log('   ❌ No se pudo obtener un código QR válido para pruebas.\n');
      return;
    }
    console.log(`   Código QR a usar: ${codigoQr}\n`);

    // Paso 5: Simular registro de asistencia
    console.log('[5] Registrando asistencia...');
    const registroData = {
      horarioId,
      codigoQr: codigoQr,
    };

    console.log('   Datos enviados:', JSON.stringify(registroData, null, 2));

    const response = await axios.post(`${BASE_URL}/asistencias/registrar`, registroData, {
      headers: { Authorization: `Bearer ${profAuth.token}` },
    });

    console.log('   ✅ Respuesta:', JSON.stringify(response.data, null, 2));
    console.log('\n   ��� Asistencia registrada exitosamente!\n');

  } catch (error: any) {
    if (error.response) {
      console.error('   ❌ Error HTTP:', error.response.status);
      console.error('   Respuesta:', JSON.stringify(error.response.data, null, 2));
    } else {
      console.error('   ❌ Error:', error.message);
    }
  }
}

test().catch(console.error);
