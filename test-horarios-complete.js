/**
 * Test completo para verificar sistema de horarios
 * Desde autenticación hasta creación de horarios
 */

const http = require('http');
const https = require('https');

// Configuración
const API_URL = 'http://localhost:3002';
const ADMIN_EMAIL = 'admin@sanjose.edu';
const ADMIN_PASSWORD = 'SanJose123!';

// Colores para consola
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(type, message) {
  const timestamp = new Date().toLocaleTimeString();
  const color = colors[type] || colors.reset;
  console.log(`${color}[${timestamp}] ${type.toUpperCase()}: ${message}${colors.reset}`);
}

function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(API_URL + path);
    const options = {
      method,
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    let bodyStr = null;
    if (body) {
      bodyStr = JSON.stringify(body);
      options.headers['Content-Length'] = Buffer.byteLength(bodyStr);
    }

    const protocol = url.protocol === 'https:' ? https : http;
    const req = protocol.request(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          resolve({
            statusCode: res.statusCode,
            body: parsed,
            headers: res.headers,
          });
        } catch {
          resolve({
            statusCode: res.statusCode,
            body: data,
            headers: res.headers,
          });
        }
      });
    });

    req.on('error', reject);

    if (bodyStr) {
      req.write(bodyStr);
    }

    req.end();
  });
}

async function test() {
  try {
    log('blue', '=== INICIANDO PRUEBAS DEL SISTEMA DE HORARIOS ===\n');

    // 1. Login
    log('yellow', 'PASO 1: Autenticación');
    const loginRes = await makeRequest('POST', '/auth/login', {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD,
    });

    if (loginRes.statusCode !== 200) {
      throw new Error(`Login fallido: ${loginRes.statusCode} - ${JSON.stringify(loginRes.body)}`);
    }

    const accessToken = loginRes.body.data.accessToken;
    const userId = loginRes.body.data.usuario.id;
    const institucionId = loginRes.body.data.institucionId;
    log('green', `✓ Autenticación exitosa. Token: ${accessToken.substring(0, 20)}...`);
    log('green', `✓ Usuario ID: ${userId}`);
    log('green', `✓ Institución ID: ${institucionId}\n`);

    // 2. Obtener horarios actuales
    log('yellow', 'PASO 2: Obtener horarios actuales');
    const horariosRes = await makeRequest('GET', '/horarios', null, accessToken);
    
    if (horariosRes.statusCode !== 200) {
      log('red', `✗ Error obteniendo horarios: ${horariosRes.statusCode}`);
      log('red', JSON.stringify(horariosRes.body, null, 2));
    } else {
      const horarios = horariosRes.body.data || [];
      log('green', `✓ Horarios obtenidos exitosamente: ${horarios.length} registros`);
      
      if (horarios.length > 0) {
        log('cyan', `Primeros 3 horarios:`);
        horarios.slice(0, 3).forEach((h, i) => {
          log('cyan', `  ${i + 1}. ${h.grupo.nombre} - ${h.materia.nombre} (${h.diaSemana}, ${h.horaInicio}-${h.horaFin})`);
        });
      }
      log('green', '');
    }

    // 3. Obtener periodos académicos
    log('yellow', 'PASO 3: Obtener períodos académicos');
    const periodosRes = await makeRequest('GET', '/periodos-academicos', null, accessToken);
    
    if (periodosRes.statusCode !== 200) {
      throw new Error(`Error obteniendo períodos: ${periodosRes.statusCode}`);
    }

    const periodos = periodosRes.body.data || [];
    const periodo = periodos.find(p => p.activo);
    
    if (!periodo) {
      throw new Error('No hay período académico activo');
    }

    log('green', `✓ Período académico activo: ${periodo.nombre} (ID: ${periodo.id})`);
    log('green', `✓ Fecha: ${periodo.fechaInicio} a ${periodo.fechaFin}\n`);

    // 4. Obtener grupos
    log('yellow', 'PASO 4: Obtener grupos');
    const gruposRes = await makeRequest('GET', '/grupos', null, accessToken);
    
    if (gruposRes.statusCode !== 200) {
      throw new Error(`Error obteniendo grupos: ${gruposRes.statusCode}`);
    }

    const grupos = gruposRes.body.data || [];
    const grupo = grupos[0];
    
    if (!grupo) {
      throw new Error('No hay grupos disponibles');
    }

    log('green', `✓ Grupos obtenidos: ${grupos.length} registros`);
    log('green', `✓ Primer grupo: ${grupo.nombre} (ID: ${grupo.id}, Período: ${grupo.periodoId})\n`);

    // 5. Obtener materias
    log('yellow', 'PASO 5: Obtener materias');
    const materiasRes = await makeRequest('GET', '/materias', null, accessToken);
    
    if (materiasRes.statusCode !== 200) {
      throw new Error(`Error obteniendo materias: ${materiasRes.statusCode}`);
    }

    const materias = materiasRes.body.data || [];
    const materia = materias[0];
    
    if (!materia) {
      throw new Error('No hay materias disponibles');
    }

    log('green', `✓ Materias obtenidas: ${materias.length} registros`);
    log('green', `✓ Primera materia: ${materia.nombre} (ID: ${materia.id})\n`);

    // 6. Obtener profesores
    log('yellow', 'PASO 6: Obtener profesores');
    const usuariosRes = await makeRequest('GET', `/usuarios?rol=profesor`, null, accessToken);
    
    if (usuariosRes.statusCode !== 200) {
      log('yellow', `⚠ Advertencia: Error obteniendo profesores: ${usuariosRes.statusCode}`);
      log('yellow', `  Continuando sin profesor asignado\n`);
    }

    let profesor = null;
    if (usuariosRes.statusCode === 200) {
      const usuarios = usuariosRes.body.data || [];
      // Buscar profesores de la institución
      // Basándonos en el seed, los profesores de San José son Juan Pérez y Laura Gómez
      profesor = usuarios.find(u => u.email === 'juan.perez@sanjose.edu') || usuarios[0];
      if (profesor) {
        log('green', `✓ Profesores obtenidos: ${usuarios.length} registros`);
        log('green', `✓ Profesor seleccionado: ${profesor.nombres} ${profesor.apellidos} (ID: ${profesor.id}) - ${profesor.email}\n`);
      }
    }

    // 7. Intentar crear un horario
    log('yellow', 'PASO 7: Intentar crear horario');
    
    const createHorarioData = {
      periodoId: periodo.id,
      grupoId: grupo.id,
      materiaId: materia.id,
      profesorId: profesor?.id || null,
      diaSemana: 1,
      horaInicio: '06:00',
      horaFin: '07:00',
    };

    log('cyan', 'Datos de envío:');
    Object.entries(createHorarioData).forEach(([key, value]) => {
      log('cyan', `  ${key}: ${value}`);
    });
    log('cyan', '');

    const createRes = await makeRequest('POST', '/horarios', createHorarioData, accessToken);

    if (createRes.statusCode === 201) {
      const newHorario = createRes.body.data;
      log('green', `✓ Horario creado exitosamente!`);
      log('green', `  ID: ${newHorario.id}`);
      log('green', `  Grupo: ${newHorario.grupo.nombre}`);
      log('green', `  Materia: ${newHorario.materia.nombre}`);
      log('green', `  Horario: ${newHorario.horaInicio} - ${newHorario.horaFin}\n`);
    } else {
      log('red', `✗ Error creando horario: ${createRes.statusCode}`);
      log('red', JSON.stringify(createRes.body, null, 2));
      log('red', '');
    }

    // 8. Verificar horarios nuevamente
    log('yellow', 'PASO 8: Verificar horarios después de crear');
    const horariosRes2 = await makeRequest('GET', '/horarios', null, accessToken);
    
    if (horariosRes2.statusCode === 200) {
      const horariosActuales = horariosRes2.body.data || [];
      log('green', `✓ Horarios actuales: ${horariosActuales.length} registros\n`);
    }

    log('blue', '=== PRUEBAS COMPLETADAS ===\n');
  } catch (error) {
    log('red', `Error: ${error.message}`);
    log('red', error.stack);
    process.exit(1);
  }
}

test();
