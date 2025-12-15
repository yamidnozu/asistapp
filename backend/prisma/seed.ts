// backend/prisma/seed.ts
// Seed maestro completo para AsistApp - Mantiene usuarios de login + Nueva estructura
// Última actualización: Diciembre 2025

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Iniciando seed maestro para AsistApp...');
  console.log('📅 Fecha de ejecución:', new Date().toISOString());

  // ============================================================================
  // 1. LIMPIEZA COMPLETA DE LA BASE DE DATOS
  // ============================================================================
  console.log('\n🧹 Limpiando base de datos...');
  await prisma.notificacionInApp.deleteMany();
  await prisma.dispositivoFCM.deleteMany();
  await prisma.acudienteEstudiante.deleteMany();
  await prisma.logNotificacion.deleteMany();
  await prisma.colaNotificacion.deleteMany();
  await prisma.asistencia.deleteMany();
  await prisma.horario.deleteMany();
  await prisma.estudianteGrupo.deleteMany();
  await prisma.materia.deleteMany();
  await prisma.grupo.deleteMany();
  await prisma.periodoAcademico.deleteMany();
  await prisma.usuarioInstitucion.deleteMany();
  await prisma.refreshToken.deleteMany();
  await prisma.estudiante.deleteMany();
  await prisma.usuario.deleteMany();
  await prisma.configuracion.deleteMany();
  await prisma.institucion.deleteMany();
  console.log('✅ Base de datos limpia.');

  const hashPassword = (password: string) => bcrypt.hashSync(password, 10);
  const TELEFONO_1 = '+573103816321'; // Para pruebas WhatsApp
  const TELEFONO_2 = '+573217645654'; // Alternativo

  // ============================================================================
  // 2. CREAR INSTITUCIONES (mantener las originales del login)
  // ============================================================================
  console.log('\n🏫 Creando instituciones...');

  const colegioSanJose = await prisma.institucion.create({
    data: {
      nombre: 'Colegio San José',
      direccion: 'Carrera 12 #45-67, Bogotá',
      telefono: '+573215551234',
      email: 'contacto@sanjose.edu.co',
      activa: true,
    },
  });

  const liceoSantander = await prisma.institucion.create({
    data: {
      nombre: 'Liceo Santander',
      direccion: 'Calle 9 #10-20, Bucaramanga',
      telefono: '+573215551235',
      email: 'contacto@santander.edu.co',
      activa: true,
    },
  });

  const colegioBolivar = await prisma.institucion.create({
    data: {
      nombre: 'Colegio Simón Bolívar',
      direccion: 'Avenida Principal #100-50, Medellín',
      telefono: '+573215551237',
      email: 'contacto@bolivar.edu.co',
      activa: true,
    },
  });

  console.log('✅ 3 instituciones creadas');

  // ============================================================================
  // 3. CONFIGURACIONES DE NOTIFICACIONES
  // ============================================================================
  console.log('\n⚙️ Configurando notificaciones...');

  await prisma.configuracion.createMany({
    data: [
      {
        institucionId: colegioSanJose.id,
        notificacionesActivas: true,
        canalNotificacion: 'WHATSAPP',
        modoNotificacionAsistencia: 'INSTANT',
        horaDisparoNotificacion: '18:00:00',
        notificarAusenciaTotalDiaria: true,
      },
      {
        institucionId: liceoSantander.id,
        notificacionesActivas: true,
        canalNotificacion: 'BOTH',
        modoNotificacionAsistencia: 'MANUAL_ONLY',
        horaDisparoNotificacion: '17:00:00',
        notificarAusenciaTotalDiaria: false,
      },
      {
        institucionId: colegioBolivar.id,
        notificacionesActivas: true,
        canalNotificacion: 'PUSH',
        modoNotificacionAsistencia: 'END_OF_DAY',
        horaDisparoNotificacion: '16:00:00',
        notificarAusenciaTotalDiaria: true,
      },
    ],
  });

  console.log('✅ Configuraciones creadas');

  // ============================================================================
  // 4. CREAR USUARIOS - MANTENER LOS DEL LOGIN
  // ============================================================================
  console.log('\n👥 Creando usuarios del login...');

  // ==================== SUPER ADMIN ====================
  const superAdmin = await prisma.usuario.create({
    data: {
      email: 'superadmin@asistapp.com',
      passwordHash: hashPassword('Admin123!'),
      nombres: 'Super',
      apellidos: 'Administrador',
      identificacion: 'SA-001',
      rol: 'super_admin',
      activo: true,
      telefono: '+573001234567',
    },
  });
  console.log('   ✅ Super Admin: superadmin@asistapp.com / Admin123!');

  // ==================== ADMINS DE INSTITUCIÓN ====================
  const adminSanJose = await prisma.usuario.create({
    data: {
      email: 'admin@sanjose.edu',
      passwordHash: hashPassword('SanJose123!'),
      nombres: 'Administrador',
      apellidos: 'San José',
      identificacion: 'ADM-SJ-001',
      rol: 'admin_institucion',
      activo: true,
      telefono: '+573300123456',
    },
  });
  console.log('   ✅ Admin San José: admin@sanjose.edu / SanJose123!');

  const adminSantander = await prisma.usuario.create({
    data: {
      email: 'admin@santander.edu',
      passwordHash: hashPassword('Santander123!'),
      nombres: 'Administrador',
      apellidos: 'Santander',
      identificacion: 'ADM-ST-001',
      rol: 'admin_institucion',
      activo: true,
      telefono: '+573300123457',
    },
  });
  console.log('   ✅ Admin Santander: admin@santander.edu / Santander123!');

  const adminMultiSede = await prisma.usuario.create({
    data: {
      email: 'multiadmin@asistapp.com',
      passwordHash: hashPassword('Multi123!'),
      nombres: 'Admin',
      apellidos: 'Multi-Sede',
      identificacion: 'ADM-MULTI-001',
      rol: 'admin_institucion',
      activo: true,
      telefono: '+573300123458',
    },
  });
  console.log('   ✅ Admin Multi-Sede: multiadmin@asistapp.com / Multi123!');

  // ==================== PROFESORES DEL LOGIN ====================
  const profesorJuan = await prisma.usuario.create({
    data: {
      email: 'juan.perez@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Juan',
      apellidos: 'Pérez',
      identificacion: 'PROF-JP-001',
      titulo: 'Licenciado en Matemáticas',
      especialidad: 'Cálculo y Álgebra',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234567',
    },
  });

  const profesorLaura = await prisma.usuario.create({
    data: {
      email: 'laura.gomez@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Laura',
      apellidos: 'Gómez',
      identificacion: 'PROF-LG-001',
      titulo: 'Licenciada en Ciencias',
      especialidad: 'Física y Química',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234568',
    },
  });

  const profesorVacio = await prisma.usuario.create({
    data: {
      email: 'vacio.profe@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Pedro',
      apellidos: 'Sin Clases',
      identificacion: 'PROF-SC-001',
      titulo: 'Licenciado en Educación',
      especialidad: 'Educación Física',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234569',
    },
  });

  const profesorCarlos = await prisma.usuario.create({
    data: {
      email: 'carlos.diaz@santander.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Carlos',
      apellidos: 'Díaz',
      identificacion: 'PROF-CD-001',
      titulo: 'Licenciado en Ciencias Sociales',
      especialidad: 'Historia y Geografía',
      rol: 'profesor',
      activo: true,
      telefono: '+573101234570',
    },
  });

  console.log('   ✅ 4 profesores del login creados');

  // ==================== ESTUDIANTES DEL LOGIN ====================
  const estudianteSantiago = await prisma.usuario.create({
    data: {
      email: 'santiago.mendoza@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Santiago',
      apellidos: 'Mendoza',
      identificacion: 'EST-SM-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  const estudianteMateo = await prisma.usuario.create({
    data: {
      email: 'mateo.castro@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Mateo',
      apellidos: 'Castro',
      identificacion: 'EST-MC-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  const estudianteValentina = await prisma.usuario.create({
    data: {
      email: 'valentina.rojas@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Valentina',
      apellidos: 'Rojas',
      identificacion: 'EST-VR-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  const estudianteSofia = await prisma.usuario.create({
    data: {
      email: 'sofia.nunez@santander.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Sofía',
      apellidos: 'Núñez',
      identificacion: 'EST-SN-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  console.log('   ✅ 4 estudiantes del login creados');

  // ==================== ACUDIENTES DEL LOGIN ====================
  const acudienteMaria = await prisma.usuario.create({
    data: {
      email: 'maria.mendoza@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'María',
      apellidos: 'Mendoza',
      identificacion: 'ACU-MM-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_1,
    },
  });

  const acudientePatricia = await prisma.usuario.create({
    data: {
      email: 'patricia.castro@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'Patricia',
      apellidos: 'Castro',
      identificacion: 'ACU-PC-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_1,
    },
  });

  const acudienteCarmen = await prisma.usuario.create({
    data: {
      email: 'carmen.lopez@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'Carmen',
      apellidos: 'López',
      identificacion: 'ACU-CL-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_2,
    },
  });

  const acudienteCarlosN = await prisma.usuario.create({
    data: {
      email: 'carlos.nunez@email.com',
      passwordHash: hashPassword('Acu123!'),
      nombres: 'Carlos',
      apellidos: 'Núñez',
      identificacion: 'ACU-CN-001',
      rol: 'acudiente',
      activo: true,
      telefono: TELEFONO_2,
    },
  });

  console.log('   ✅ 4 acudientes del login creados');

  // ============================================================================
  // 5. CREAR PROFESORES ADICIONALES PARA COMPLETAR PLANTILLA
  // ============================================================================
  console.log('\n👨‍🏫 Creando profesores adicionales...');

  const nombresProf = ['Roberto', 'Claudia', 'Andrés', 'Beatriz', 'Javier', 'Diana', 'Alberto', 'Mónica',
    'Rafael', 'Patricia', 'Jorge', 'Isabel', 'Fernando', 'Gloria', 'Miguel', 'Carmen',
    'Eduardo', 'Silvia', 'Ricardo', 'Teresa'];

  const profesoresAdicionales = [];
  for (let i = 0; i < 20; i++) {
    const prof = await prisma.usuario.create({
      data: {
        email: `profesor${i + 5}@sanjose.edu`,
        passwordHash: hashPassword('Prof123!'),
        nombres: nombresProf[i],
        apellidos: `Docente ${i + 5}`,
        identificacion: `PROF-${String(i + 5).padStart(3, '0')}`,
        titulo: 'Licenciado en Educación',
        especialidad: 'Educación General',
        rol: 'profesor',
        activo: true,
        telefono: `+57310${String(1234570 + i).slice(-7)}`,
      },
    });
    profesoresAdicionales.push(prof);
  }

  const todosProfesores = [profesorJuan, profesorLaura, profesorVacio, profesorCarlos, ...profesoresAdicionales];
  console.log(`   ✅ ${profesoresAdicionales.length} profesores adicionales creados (total: ${todosProfesores.length})`);

  // ============================================================================
  // 6. VINCULAR USUARIOS A INSTITUCIONES
  // ============================================================================
  console.log('\n🔗 Vinculando usuarios a instituciones...');

  await prisma.usuarioInstitucion.createMany({
    data: [
      // Admins
      { usuarioId: adminSanJose.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminSantander.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: colegioBolivar.id, rolEnInstitucion: 'admin' },

      // Profesores a San José
      ...todosProfesores.map(p => ({ usuarioId: p.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' })),
    ],
  });

  console.log('✅ Vínculos creados');

  // ============================================================================
  // 7. PERÍODOS ACADÉMICOS
  // ============================================================================
  console.log('\n📚 Creando períodos académicos...');

  const currentYear = new Date().getFullYear();

  const periodoSanJose = await prisma.periodoAcademico.create({
    data: {
      nombre: `Año Lectivo ${currentYear}`,
      fechaInicio: new Date(`${currentYear}-02-01`),
      fechaFin: new Date(`${currentYear}-11-30`),
      activo: true,
      institucionId: colegioSanJose.id,
    },
  });

  const periodoSantander = await prisma.periodoAcademico.create({
    data: {
      nombre: `Año Lectivo ${currentYear}`,
      fechaInicio: new Date(`${currentYear}-02-01`),
      fechaFin: new Date(`${currentYear}-11-30`),
      activo: true,
      institucionId: liceoSantander.id,
    },
  });

  console.log(`✅ 2 períodos académicos creados (${currentYear})`);

  // ============================================================================
  // 8. MATERIAS
  // ============================================================================
  console.log('\n📖 Creando materias...');

  const nombresMaterias = ['Matemáticas', 'Español', 'Inglés', 'Ciencias Naturales', 'Ciencias Sociales',
    'Física', 'Química', 'Biología', 'Filosofía', 'Educación Física', 'Artes', 'Tecnología'];

  const materiasSanJose = [];
  for (const nombre of nombresMaterias) {
    const materia = await prisma.materia.create({
      data: {
        nombre,
        codigo: nombre.substring(0, 3).toUpperCase() + '-101',
        institucionId: colegioSanJose.id,
      },
    });
    materiasSanJose.push(materia);
  }

  console.log(`✅ ${materiasSanJose.length} materias creadas`);

  // ============================================================================
  // 9. GRUPOS (11 grados × 2 secciones = 22 grupos)
  // ============================================================================
  console.log('\n👥 Creando grupos...');

  const grados = [
    { nombre: 'Primero', grado: '1' },
    { nombre: 'Segundo', grado: '2' },
    { nombre: 'Tercero', grado: '3' },
    { nombre: 'Cuarto', grado: '4' },
    { nombre: 'Quinto', grado: '5' },
    { nombre: 'Sexto', grado: '6' },
    { nombre: 'Séptimo', grado: '7' },
    { nombre: 'Octavo', grado: '8' },
    { nombre: 'Noveno', grado: '9' },
    { nombre: 'Décimo', grado: '10' },
    { nombre: 'Once', grado: '11' },
  ];

  const secciones = ['A', 'B'];
  const grupos = [];

  for (const gradoInfo of grados) {
    for (const seccion of secciones) {
      const grupo = await prisma.grupo.create({
        data: {
          nombre: `${gradoInfo.nombre} ${seccion}`,
          grado: gradoInfo.grado,
          seccion: seccion,
          periodoId: periodoSanJose.id,
          institucionId: colegioSanJose.id,
        },
      });
      grupos.push(grupo);
    }
  }

  console.log(`✅ ${grupos.length} grupos creados (1° a 11°, secciones A y B)`);

  // ============================================================================
  // 10. CREAR PERFILES DE ESTUDIANTES DEL LOGIN
  // ============================================================================
  console.log('\n🎓 Creando perfiles de estudiantes del login...');

  const perfilSantiago = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteSantiago.id,
      identificacion: 'TI-1001234567',
      codigoQr: 'QR-SANTIAGO-001',
      nombreResponsable: 'María Mendoza',
      telefonoResponsable: TELEFONO_1,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilMateo = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteMateo.id,
      identificacion: 'TI-1001234568',
      codigoQr: 'QR-MATEO-002',
      nombreResponsable: 'Patricia Castro',
      telefonoResponsable: TELEFONO_1,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilValentina = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteValentina.id,
      identificacion: 'TI-1001234569',
      codigoQr: 'QR-VALENTINA-003',
      nombreResponsable: 'María Mendoza',
      telefonoResponsable: TELEFONO_1,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilSofia = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteSofia.id,
      identificacion: 'TI-2001234567',
      codigoQr: 'QR-SOFIA-005',
      nombreResponsable: 'Carlos Núñez',
      telefonoResponsable: TELEFONO_2,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  // Asignar a grupos
  await prisma.estudianteGrupo.createMany({
    data: [
      { estudianteId: perfilSantiago.id, grupoId: grupos[18].id }, // 10-A
      { estudianteId: perfilMateo.id, grupoId: grupos[20].id }, // 11-A
      { estudianteId: perfilValentina.id, grupoId: grupos[18].id }, // 10-A (hermana de Santiago)
    ],
  });

  await prisma.usuarioInstitucion.createMany({
    data: [
      { usuarioId: estudianteSantiago.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteMateo.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteValentina.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteSofia.id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: acudienteMaria.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'acudiente' },
      { usuarioId: acudientePatricia.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'acudiente' },
      { usuarioId: acudienteCarmen.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'acudiente' },
      { usuarioId: acudienteCarlosN.id, institucionId: liceoSantander.id, rolEnInstitucion: 'acudiente' },
    ],
  });

  // Vincular acudientes con estudiantes del login
  await prisma.acudienteEstudiante.createMany({
    data: [
      { acudienteId: acudienteMaria.id, estudianteId: perfilSantiago.id, parentesco: 'madre', esPrincipal: true, activo: true },
      { acudienteId: acudienteMaria.id, estudianteId: perfilValentina.id, parentesco: 'madre', esPrincipal: true, activo: true },
      { acudienteId: acudientePatricia.id, estudianteId: perfilMateo.id, parentesco: 'madre', esPrincipal: true, activo: true },
      { acudienteId: acudienteCarlosN.id, estudianteId: perfilSofia.id, parentesco: 'padre', esPrincipal: true, activo: true },
    ],
  });

  console.log('✅ 4 perfiles de estudiantes del login creados y asignados');

  // ============================================================================
  // 11. CREAR ESTUDIANTES MASIVOS (~30 por grupo = ~660 estudiantes)
  // ============================================================================
  console.log('\n🎓 Creando estudiantes masivos...');

  const nombresEst = ['Alejandro', 'Sofía', 'Mateo', 'Valentina', 'Santiago', 'Isabella', 'Sebastián', 'Camila',
    'Nicolás', 'Mariana', 'Daniel', 'Daniela', 'Diego', 'Gabriela', 'Juan', 'María'];

  let estudianteIdx = 5; // Empezar después de los del login
  const todosEstudiantes = [perfilSantiago, perfilMateo, perfilValentina, perfilSofia];

  for (const grupo of grupos) {
    const numEstudiantes = 28 + Math.floor(Math.random() * 5);

    for (let i = 0; i < numEstudiantes; i++) {
      const nombre = nombresEst[Math.floor(Math.random() * nombresEst.length)];
      const usaTelefono1 = estudianteIdx % 2 === 0; // Alternar entre los dos teléfonos

      const usuario = await prisma.usuario.create({
        data: {
          email: `estudiante${estudianteIdx}@sanjose.edu`,
          passwordHash: hashPassword('Est123!'),
          nombres: nombre,
          apellidos: `Est ${estudianteIdx}`,
          identificacion: `EST-${String(estudianteIdx).padStart(4, '0')}`,
          rol: 'estudiante',
          activo: true,
        },
      });

      const estudiante = await prisma.estudiante.create({
        data: {
          usuarioId: usuario.id,
          identificacion: `TI-${String(1000000000 + estudianteIdx)}`,
          codigoQr: `QR-EST-${String(estudianteIdx).padStart(4, '0')}`,
          nombreResponsable: `Acudiente ${estudianteIdx}`,
          telefonoResponsable: usaTelefono1 ? TELEFONO_1 : TELEFONO_2,
          telefonoResponsableVerificado: true,
          aceptaNotificaciones: true,
        },
      });

      await prisma.estudianteGrupo.create({
        data: {
          estudianteId: estudiante.id,
          grupoId: grupo.id,
        },
      });

      await prisma.usuarioInstitucion.create({
        data: {
          usuarioId: usuario.id,
          institucionId: colegioSanJose.id,
          rolEnInstitucion: 'estudiante',
        },
      });

      todosEstudiantes.push(estudiante);
      estudianteIdx++;
    }
  }

  console.log(`✅ ${estudianteIdx - 5} estudiantes adicionales creados (total: ${estudianteIdx - 1})`);

  // ============================================================================
  // 12. CREAR ACUDIENTES PARA ESTUDIANTES MASIVOS
  // ============================================================================
  console.log('\n👨‍👩‍👧 Creando acudientes masivos...');

  const acudientesAdicionales = [];
  const numAcudientes = Math.floor((estudianteIdx - 5) / 2); // 1 acudiente por cada 2 estudiantes aprox

  for (let i = 0; i < numAcudientes; i++) {
    const usaTelefono1 = i % 2 === 0;

    const acudiente = await prisma.usuario.create({
      data: {
        email: `acudiente${i + 5}@email.com`,
        passwordHash: hashPassword('Acu123!'),
        nombres: `Acudiente`,
        apellidos: `Familia ${i + 5}`,
        identificacion: `ACU-${String(i + 5).padStart(4, '0')}`,
        rol: 'acudiente',
        activo: true,
        telefono: usaTelefono1 ? TELEFONO_1 : TELEFONO_2,
      },
    });

    await prisma.usuarioInstitucion.create({
      data: {
        usuarioId: acudiente.id,
        institucionId: colegioSanJose.id,
        rolEnInstitucion: 'acudiente',
      },
    });

    acudientesAdicionales.push(acudiente);
  }

  console.log(`✅ ${acudientesAdicionales.length} acudientes adicionales creados`);

  // Vincular acudientes con estudiantes masivos
  const todosAcudientes = [acudienteMaria, acudientePatricia, acudienteCarmen, acudienteCarlosN, ...acudientesAdicionales];
  let acudienteActualIdx = 4; // Empezar después de los del login

  for (let i = 4; i < todosEstudiantes.length; i++) {
    const estudiante = todosEstudiantes[i];
    const numHijos = Math.random() < 0.3 ? 2 : 1; // 30% tienen 2 hijos

    // Asignar acudiente
    const acudiente = todosAcudientes[acudienteActualIdx % todosAcudientes.length];

    await prisma.acudienteEstudiante.create({
      data: {
        acudienteId: acudiente.id,
        estudianteId: estudiante.id,
        parentesco: Math.random() < 0.5 ? 'madre' : 'padre',
        esPrincipal: true,
        activo: true,
      },
    });

    if (numHijos === 1) {
      acudienteActualIdx++;
    }
  }

  console.log('✅ Vínculos acudiente-estudiante creados');

  // ============================================================================
  // 13. CREAR HORARIOS
  // ============================================================================
  console.log('\n📅 Creando horarios...');

  const diasSemana = [1, 2, 3, 4, 5]; // Lunes a Viernes
  // Bloques en intervalos de 30 minutos (horas enteras o medias horas)
  const bloques = [
    { inicio: '07:00', fin: '08:00' },
    { inicio: '08:00', fin: '09:00' },
    { inicio: '09:00', fin: '10:00' },
    { inicio: '10:30', fin: '11:30' }, // Descanso de 10:00 a 10:30
    { inicio: '11:30', fin: '12:30' },
    { inicio: '14:00', fin: '15:00' }, // Almuerzo de 12:30 a 14:00
  ];

  let totalHorarios = 0;

  for (const grupo of grupos) {
    for (let diaIdx = 0; diaIdx < diasSemana.length; diaIdx++) {
      const dia = diasSemana[diaIdx];

      for (let bloqueIdx = 0; bloqueIdx < bloques.length; bloqueIdx++) {
        const bloque = bloques[bloqueIdx];
        const materiaIdx = (diaIdx * bloques.length + bloqueIdx) % materiasSanJose.length;
        const materia = materiasSanJose[materiaIdx];
        const profesor = todosProfesores[materiaIdx % todosProfesores.length];

        await prisma.horario.create({
          data: {
            grupoId: grupo.id,
            materiaId: materia.id,
            profesorId: profesor.id,
            institucionId: colegioSanJose.id, // ← AGREGADO
            periodoId: periodoSanJose.id,     // ← AGREGADO
            diaSemana: dia,                    // ← AHORA ES NÚMERO
            horaInicio: bloque.inicio,
            horaFin: bloque.fin,
          },
        });

        totalHorarios++;
      }
    }
  }

  console.log(`✅ ${totalHorarios} horarios creados`);

  // ============================================================================
  // RESUMEN FINAL
  // ============================================================================
  console.log('\n\n═══════════════════════════════════════════════════════════════');
  console.log('✅ SEED COMPLETADO EXITOSAMENTE');
  console.log('═══════════════════════════════════════════════════════════════');
  console.log('\n📊 RESUMEN:');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`🏫 Instituciones: 3 (San José, Santander, Bolívar)`);
  console.log(`📚 Períodos: 2 (${currentYear})`);
  console.log(`📖 Materias: ${materiasSanJose.length}`);
  console.log(`👥 Grupos: ${grupos.length} (1° a 11°, secciones A y B)`);
  console.log(`👨‍🏫 Profesores: ${todosProfesores.length}`);
  console.log(`🎓 Estudiantes: ~${estudianteIdx - 1} (~30 por grupo)`);
  console.log(`👨‍👩‍👧 Acudientes: ${todosAcudientes.length}`);
  console.log(`📅 Horarios: ${totalHorarios}`);
  console.log(`📱 Teléfonos: ${TELEFONO_1} y ${TELEFONO_2}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('\n🔐 CREDENCIALES (coinciden con pantalla de login):');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('👑 Super Admin: superadmin@asistapp.com / Admin123!');
  console.log('🏫 Admin San José: admin@sanjose.edu / SanJose123!');
  console.log('🏫 Admin Santander: admin@santander.edu / Santander123!');
  console.log('🏫 Admin Multi-Sede: multiadmin@asistapp.com / Multi123!');
  console.log('👨‍🏫 Juan Pérez: juan.perez@sanjose.edu / Prof123!');
  console.log('👨‍🏫 Laura Gómez: laura.gomez@sanjose.edu / Prof123!');
  console.log('👨‍🏫 Pedro Sin Clases: vacio.profe@sanjose.edu / Prof123!');
  console.log('👨‍🏫 Carlos Díaz: carlos.diaz@santander.edu / Prof123!');
  console.log('🎓 Santiago Mendoza: santiago.mendoza@sanjose.edu / Est123!');
  console.log('🎓 Mateo Castro: mateo.castro@sanjose.edu / Est123!');
  console.log('🎓 Sofía Núñez: sofia.nunez@santander.edu / Est123!');
  console.log('👨‍👩‍👧 María Mendoza: maria.mendoza@email.com / Acu123!');
  console.log('👨‍👩‍👧 Patricia Castro: patricia.castro@email.com / Acu123!');
  console.log('👨‍👩‍👧 Carmen López: carmen.lopez@email.com / Acu123!');
  console.log('👨‍👩‍👧 Carlos Núñez: carlos.nunez@email.com / Acu123!');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('\n✨ Listos para probar paginación, búsquedas, filtros y más!\n');
}

main()
  .catch((e) => {
    console.error('❌ Error durante el seed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
