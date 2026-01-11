
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';

// Credenciales del Seed (Confirmadas en prisma/seed.ts)
const CREDS = {
    SUPER_ADMIN: { email: 'superadmin@asistapp.com', password: 'Admin123!' },
    ADMIN_INST: { email: 'admin@sanjose.edu', password: 'SanJose123!' },
    PROFESOR: { email: 'juan.perez@sanjose.edu', password: 'Prof123!' },
    ESTUDIANTE: { email: 'santiago.mendoza@sanjose.edu', password: 'Est123!' },
    ACUDIENTE: { email: 'maria.mendoza@email.com', password: 'Acu123!' }
};

const capturedData = {};

async function fetchAPI(endpoint, method = 'GET', body = null, token = null) {
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;

    // Ajuste para endpoints de notificación que usan prefijo /api
    let fullUrl = BASE_URL + endpoint;
    if (endpoint.startsWith('/notifications') || endpoint.startsWith('/api/')) {
        fullUrl = BASE_URL + '/api' + endpoint.replace('/api', '');
        // Corrección: si el endpoint ya tiene /api, no duplicar, pero mi lógica previa dice que notificationRoutes están bajo /api
        // Voy a asumir que paso la ruta tal cual se define en el router
        if (!endpoint.startsWith('/api')) fullUrl = BASE_URL + '/api' + endpoint;
        else fullUrl = BASE_URL + endpoint;
    } else {
        fullUrl = BASE_URL + endpoint;
    }

    // Corrección rápida para notificationRoutes que están bajo /api en index.ts
    // Si la ruta es '/notifications/...' -> 'http://localhost:3000/api/notifications/...'

    try {
        const res = await fetch(fullUrl, {
            method,
            headers,
            body: body ? JSON.stringify(body) : null
        });

        let data;
        const contentType = res.headers.get("content-type");
        if (contentType && contentType.includes("application/json")) {
            data = await res.json();
        } else {
            data = await res.text();
        }

        return { status: res.status, data };

    } catch (e) {
        return { status: 500, error: e.message };
    }
}

async function runHarvest() {
    console.log('🚀 Iniciando COSECHA TOTAL de respuestas reales...');

    // ==========================================
    // 1. AUTENTICACIÓN Y TOKENS
    // ==========================================
    const tokens = {};
    const ids = {};

    for (const [rol, creds] of Object.entries(CREDS)) {
        console.log(`🔑 Logueando ${rol}...`);
        const res = await fetchAPI('/auth/login', 'POST', creds);
        capturedData[`Login_${rol}`] = res;

        if (res.data.success) {
            tokens[rol] = res.data.data.accessToken;
            ids[rol] = res.data.data.usuario.id;
            if (rol === 'ADMIN_INST') {
                ids['INSTITUCION'] = res.data.data.usuario.instituciones[0].id;
            }
        }
    }

    // ==========================================
    // 2. SUPER ADMIN & ADMIN INSTITUCIÓN DATA
    // ==========================================
    if (tokens.SUPER_ADMIN) {
        console.log('📡 Cosechando endpoints SUPER ADMIN...');
        capturedData['Listar_Instituciones'] = await fetchAPI('/instituciones', 'GET', null, tokens.SUPER_ADMIN);
        capturedData['Listar_Usuarios'] = await fetchAPI('/usuarios', 'GET', null, tokens.SUPER_ADMIN);
        capturedData['Verificar_Token'] = await fetchAPI('/auth/verify', 'GET', null, tokens.SUPER_ADMIN);
    }

    if (tokens.ADMIN_INST) {
        console.log('📡 Cosechando endpoints ADMIN INSTITUCIÓN...');
        const perRes = await fetchAPI('/periodos-academicos', 'GET', null, tokens.ADMIN_INST);
        capturedData['Listar_Periodos'] = perRes;
        ids['PERIODO'] = perRes.data.data?.[0]?.id;

        capturedData['Listar_Materias'] = await fetchAPI('/materias', 'GET', null, tokens.ADMIN_INST);

        const grupRes = await fetchAPI('/grupos', 'GET', null, tokens.ADMIN_INST);
        capturedData['Listar_Grupos'] = grupRes;
        ids['GRUPO'] = grupRes.data.data?.[0]?.id;

        if (ids.GRUPO) {
            capturedData['Listar_Estudiantes_Grupo'] = await fetchAPI(`/grupos/${ids.GRUPO}/estudiantes`, 'GET', null, tokens.ADMIN_INST);

            const horRes = await fetchAPI(`/horarios/grupo/${ids.GRUPO}`, 'GET', null, tokens.ADMIN_INST);
            capturedData['Listar_Horarios_Grupo'] = horRes;
            ids['HORARIO'] = horRes.data.data?.[0]?.id;
        }
    }

    // ==========================================
    // 3. PROFESOR
    // ==========================================
    if (tokens.PROFESOR) {
        console.log('👨‍🏫 Cosechando endpoints PROFESOR...');
        capturedData['Profesor_Dashboard_ClasesHoy'] = await fetchAPI('/profesores/dashboard/clases-hoy', 'GET', null, tokens.PROFESOR);
        capturedData['Profesor_Dashboard_Semanal'] = await fetchAPI('/profesores/dashboard/horario-semanal', 'GET', null, tokens.PROFESOR);

        if (ids.HORARIO) {
            capturedData['Profesor_Stats_Asistencia'] = await fetchAPI(`/asistencias/estadisticas/${ids.HORARIO}`, 'GET', null, tokens.PROFESOR);
        }
    }

    // ==========================================
    // 4. ESTUDIANTE
    // ==========================================
    if (tokens.ESTUDIANTE) {
        console.log('🎓 Cosechando endpoints ESTUDIANTE...');
        capturedData['Estudiante_Me'] = await fetchAPI('/estudiantes/me', 'GET', null, tokens.ESTUDIANTE);
        capturedData['Estudiante_Perfil'] = await fetchAPI('/estudiantes/perfil', 'GET', null, tokens.ESTUDIANTE);
        capturedData['Estudiante_Dashboard_Hoy'] = await fetchAPI('/estudiantes/dashboard/clases-hoy', 'GET', null, tokens.ESTUDIANTE);
        capturedData['Estudiante_Horario_Semanal'] = await fetchAPI('/estudiantes/dashboard/horario-semanal', 'GET', null, tokens.ESTUDIANTE);
        capturedData['Estudiante_Grupos'] = await fetchAPI('/estudiantes/grupos', 'GET', null, tokens.ESTUDIANTE);
        capturedData['Estudiante_Mis_Asistencias'] = await fetchAPI('/asistencias/estudiante', 'GET', null, tokens.ESTUDIANTE);
    }

    // ==========================================
    // 5. ACUDIENTE
    // ==========================================
    if (tokens.ACUDIENTE) {
        console.log('👪 Cosechando endpoints ACUDIENTE...');
        const hijosRes = await fetchAPI('/acudiente/hijos', 'GET', null, tokens.ACUDIENTE);
        capturedData['Acudiente_Listar_Hijos'] = hijosRes;

        const hijoId = hijosRes.data.data?.[0]?.estudianteId;
        if (hijoId) {
            capturedData['Acudiente_Detalle_Hijo'] = await fetchAPI(`/acudiente/hijos/${hijoId}`, 'GET', null, tokens.ACUDIENTE);
            capturedData['Acudiente_Asistencias_Hijo'] = await fetchAPI(`/acudiente/hijos/${hijoId}/asistencias`, 'GET', null, tokens.ACUDIENTE);
            capturedData['Acudiente_Stats_Hijo'] = await fetchAPI(`/acudiente/hijos/${hijoId}/estadisticas`, 'GET', null, tokens.ACUDIENTE);
        }

        capturedData['Acudiente_Notificaciones'] = await fetchAPI('/acudiente/notificaciones', 'GET', null, tokens.ACUDIENTE);
        capturedData['Acudiente_Count_NoLeidas'] = await fetchAPI('/acudiente/notificaciones/no-leidas/count', 'GET', null, tokens.ACUDIENTE);
    }

    // ==========================================
    // 6. NOTIFICACIONES (SISTEMA)
    // ==========================================
    if (tokens.SUPER_ADMIN) {
        console.log('🔔 Cosechando endpoints SISTEMA...');
        capturedData['Sistema_Logs_Notificaciones'] = await fetchAPI('/notifications/logs', 'GET', null, tokens.SUPER_ADMIN);
        capturedData['Sistema_Queue_Stats'] = await fetchAPI('/notifications/queue/stats', 'GET', null, tokens.SUPER_ADMIN);

        if (ids.INSTITUCION) {
            // Nota: este endpoint es PUT pero intentaremos capturar su respuesta de éxito simulando un update inofensivo
            const configBody = {
                notificacionesActivas: true,
                canalNotificacion: "WHATSAPP",
                modoNotificacionAsistencia: "INSTANT",
                horaDisparoNotificacion: "18:00:00"
            };
            // PREFIJO ESPECIAL: /api/institutions/...  (según analisis previo)
            capturedData['Sistema_Config_Institucion'] = await fetchAPI(`/institutions/${ids.INSTITUCION}/notification-config`, 'PUT', configBody, tokens.SUPER_ADMIN);
        }
    }

    fs.writeFileSync('captured_responses_full.json', JSON.stringify(capturedData, null, 2));
    console.log('✅ Cosecha completa guardada en captured_responses_full.json');
}

runHarvest();
