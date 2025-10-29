#!/usr/bin/env node

/**
 * 🛠️ AsistApp cURL Generator
 * Genera comandos cURL listos para usar para probar la API
 *
 * Uso: node curl-generator.js
 */

const CONFIG = {
  BASE_URL: 'http://localhost:3000',
  TEST_USERS: {
    super_admin: {
      email: 'admin@asistapp.com',
      password: 'Admin123!'
    },
    admin_institucion: {
      email: 'admin@colegio.edu',
      password: 'Admin123!'
    },
    profesor: {
      email: 'profesor@colegio.edu',
      password: 'Profesor123!'
    }
  }
};

class CurlGenerator {
  constructor() {
    this.tokens = {};
  }

  // Generar comando curl para login
  generateLoginCurl(email, password, role) {
    return `curl -X POST ${CONFIG.BASE_URL}/auth/login \\
  -H "Content-Type: application/json" \\
  -d '{"email":"${email}","password":"${password}"}' \\
  --silent | jq '.data.accessToken' | tr -d '"'`;
  }

  // Generar comando curl con token
  generateAuthenticatedCurl(method, endpoint, data = null, tokenVar = '$TOKEN') {
    let cmd = `curl -X ${method} ${CONFIG.BASE_URL}${endpoint} \\
  -H "Authorization: Bearer ${tokenVar}"`;

    if (data) {
      cmd += ` \\
  -H "Content-Type: application/json" \\
  -d '${JSON.stringify(data, null, 2)}'`;
    }

    return cmd;
  }

  // Generar todos los comandos
  generateAllCommands() {
    console.log('# 🚀 AsistApp API - Comandos cURL');
    console.log('# Copia y pega estos comandos en tu terminal');
    console.log('');

    // Login commands
    console.log('# 🔐 AUTENTICACIÓN');
    console.log('# ================');
    console.log('');

    Object.entries(CONFIG.TEST_USERS).forEach(([role, user]) => {
      console.log(`# Login ${role.replace('_', ' ').toUpperCase()}`);
      console.log(`TOKEN_${role.toUpperCase()}=$(${this.generateLoginCurl(user.email, user.password, role)})`);
      console.log('');
    });

    console.log('# Usar token:');
    console.log('export TOKEN=$TOKEN_ADMIN_INSTITUCION  # Cambiar según el rol que necesites');
    console.log('');

    // Profesores commands
    console.log('# 👨‍🏫 GESTIÓN DE PROFESORES (Admin Institución)');
    console.log('# ============================================');
    console.log('');

    // Listar profesores
    console.log('# Listar profesores (paginación básica)');
    console.log(this.generateAuthenticatedCurl('GET', '/institution-admin/profesores?page=1&limit=10'));
    console.log('');

    console.log('# Listar profesores (con filtros)');
    console.log(this.generateAuthenticatedCurl('GET', '/institution-admin/profesores?page=1&limit=5&search=juan&activo=true'));
    console.log('');

    // Crear profesor
    console.log('# Crear profesor');
    console.log(this.generateAuthenticatedCurl('POST', '/institution-admin/profesores', {
      nombre: 'Ana',
      apellido: 'Martínez',
      email: `ana.martinez.${Date.now()}@test.com`,
      password: 'Profesor123!',
      telefono: '3001234567'
    }));
    console.log('');

    // Obtener detalle (placeholder)
    console.log('# Obtener detalle de profesor (reemplaza {id})');
    console.log(this.generateAuthenticatedCurl('GET', '/institution-admin/profesores/{id}'));
    console.log('');

    // Actualizar profesor
    console.log('# Actualizar profesor (reemplaza {id})');
    console.log(this.generateAuthenticatedCurl('PUT', '/institution-admin/profesores/{id}', {
      nombres: 'Ana María',
      apellidos: 'Martínez López',
      telefono: '3009876543'
    }));
    console.log('');

    // Toggle status
    console.log('# Cambiar estado del profesor (reemplaza {id})');
    console.log(this.generateAuthenticatedCurl('PATCH', '/institution-admin/profesores/{id}/toggle-status'));
    console.log('');

    // Eliminar profesor
    console.log('# Eliminar profesor (reemplaza {id})');
    console.log(this.generateAuthenticatedCurl('DELETE', '/institution-admin/profesores/{id}'));
    console.log('');

    // Permisos commands
    console.log('# 🔒 TESTS DE PERMISOS');
    console.log('# ===================');
    console.log('');

    console.log('# Intentar acceder sin token (debe dar 401)');
    console.log(`curl -X GET ${CONFIG.BASE_URL}/institution-admin/profesores`);
    console.log('');

    console.log('# Intentar acceder con token de profesor (debe dar 403)');
    console.log(`curl -X GET ${CONFIG.BASE_URL}/institution-admin/profesores \\
  -H "Authorization: Bearer $TOKEN_PROFESOR"`);
    console.log('');

    console.log('# Acceder con token correcto (debe dar 200)');
    console.log(`curl -X GET ${CONFIG.BASE_URL}/institution-admin/profesores \\
  -H "Authorization: Bearer $TOKEN_ADMIN_INSTITUCION"`);
    console.log('');

    // Utilidades
    console.log('# 🛠️ UTILIDADES');
    console.log('# =============');
    console.log('');

    console.log('# Ver respuesta formateada (instala jq primero)');
    console.log('curl -X GET http://localhost:3000/institution-admin/profesores \\');
    console.log('  -H "Authorization: Bearer $TOKEN" | jq .');
    console.log('');

    console.log('# Ver headers de respuesta');
    console.log('curl -X GET http://localhost:3000/institution-admin/profesores \\');
    console.log('  -H "Authorization: Bearer $TOKEN" -v');
    console.log('');

    console.log('# Guardar respuesta en archivo');
    console.log('curl -X GET http://localhost:3000/institution-admin/profesores \\');
    console.log('  -H "Authorization: Bearer $TOKEN" -o respuesta.json');
    console.log('');

    // Tests de validación
    console.log('# ✅ TESTS DE VALIDACIÓN');
    console.log('# ======================');
    console.log('');

    console.log('# Email duplicado (debe dar error)');
    console.log(this.generateAuthenticatedCurl('POST', '/institution-admin/profesores', {
      nombre: 'Test',
      apellido: 'Duplicado',
      email: 'ana.martinez@test.com', // Email que ya existe
      password: 'Profesor123!'
    }));
    console.log('');

    console.log('# Datos faltantes (debe dar error)');
    console.log(this.generateAuthenticatedCurl('POST', '/institution-admin/profesores', {
      nombre: 'Test'
      // Falta apellido, email, password
    }));
    console.log('');
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  const generator = new CurlGenerator();
  generator.generateAllCommands();
}

module.exports = { CurlGenerator };