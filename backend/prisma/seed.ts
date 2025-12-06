// backend/prisma/seed.ts
// Seed maestro completo para AsistApp
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

  // Función para hashear contraseñas
  const hashPassword = (password: string) => bcrypt.hashSync(password, 10);

  // Número de teléfono de prueba para WhatsApp (REAL - registrado en Meta)
  const TELEFONO_TEST = '+573103816321';

  // ============================================================================
  // 2. CREAR INSTITUCIONES
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

  const institutoPasado = await prisma.institucion.create({
    data: {
      nombre: 'Instituto del Pasado (Inactivo)',
      direccion: 'Avenida 1 #22-33, Ciudad',
      telefono: '+573215551236',
      email: 'contacto@institutopasado.edu.co',
      activa: false, // Institución inactiva para probar filtros
    },
  });

  console.log('✅ 4 instituciones creadas (3 activas, 1 inactiva).');

  // ============================================================================
  // 3. CONFIGURACIÓN DE NOTIFICACIONES POR INSTITUCIÓN
  // ============================================================================
  console.log('\n⚙️ Configurando notificaciones por institución...');

  await prisma.configuracion.createMany({
    data: [
      {
        institucionId: colegioSanJose.id,
        notificacionesActivas: true,
        canalNotificacion: 'WHATSAPP',
        modoNotificacionAsistencia: 'INSTANT', // Notificación inmediata al registrar ausencia
        horaDisparoNotificacion: '18:00:00',
      },
      {
        institucionId: liceoSantander.id,
        notificacionesActivas: true,
        canalNotificacion: 'WHATSAPP',
        modoNotificacionAsistencia: 'MANUAL_ONLY', // Solo envío manual (botón)
        horaDisparoNotificacion: '17:00:00',
      },
      {
        institucionId: colegioBolivar.id,
        notificacionesActivas: true,
        canalNotificacion: 'WHATSAPP',
        modoNotificacionAsistencia: 'END_OF_DAY', // Resumen al final del día
        horaDisparoNotificacion: '16:00:00',
      },
      {
        institucionId: institutoPasado.id,
        notificacionesActivas: false,
        canalNotificacion: 'NONE',
        modoNotificacionAsistencia: 'MANUAL_ONLY',
      },
    ],
  });

  console.log('✅ Configuraciones de notificaciones creadas.');
  console.log('   • San José: INSTANT (WhatsApp inmediato)');
  console.log('   • Santander: MANUAL_ONLY (botón de envío)');
  console.log('   • Bolívar: END_OF_DAY (resumen diario)');

  // ============================================================================
  // 4. CREAR USUARIOS - TODOS LOS DEL LOGIN
  // ============================================================================
  console.log('\n👥 Creando usuarios del sistema...');

  // -------------------- SUPER ADMINISTRADOR --------------------
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

  // -------------------- ADMINISTRADORES DE INSTITUCIÓN --------------------
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

  // Admin Multi-Sede (tiene acceso a múltiples instituciones)
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

  // -------------------- PROFESORES --------------------
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
  console.log('   ✅ Prof. Juan Pérez: juan.perez@sanjose.edu / Prof123!');

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
  console.log('   ✅ Prof. Laura Gómez: laura.gomez@sanjose.edu / Prof123!');

  // Profesor sin clases asignadas (para probar dashboard vacío)
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
  console.log('   ✅ Prof. Sin Clases: vacio.profe@sanjose.edu / Prof123!');

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
  console.log('   ✅ Prof. Carlos Díaz: carlos.diaz@santander.edu / Prof123!');

  // -------------------- ESTUDIANTES SAN JOSÉ --------------------
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
  console.log('   ✅ Est. Santiago Mendoza: santiago.mendoza@sanjose.edu / Est123!');

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
  console.log('   ✅ Est. Mateo Castro: mateo.castro@sanjose.edu / Est123!');

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
  console.log('   ✅ Est. Valentina Rojas: valentina.rojas@sanjose.edu / Est123!');

  const estudianteAndres = await prisma.usuario.create({
    data: {
      email: 'andres.lopez@sanjose.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Andrés',
      apellidos: 'López',
      identificacion: 'EST-AL-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  // -------------------- ESTUDIANTES SANTANDER --------------------
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
  console.log('   ✅ Est. Sofía Núñez: sofia.nunez@santander.edu / Est123!');

  const estudianteDaniel = await prisma.usuario.create({
    data: {
      email: 'daniel.ruiz@santander.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Daniel',
      apellidos: 'Ruiz',
      identificacion: 'EST-DR-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  const estudiantePaula = await prisma.usuario.create({
    data: {
      email: 'paula.mendez@santander.edu',
      passwordHash: hashPassword('Est123!'),
      nombres: 'Paula',
      apellidos: 'Méndez',
      identificacion: 'EST-PM-001',
      rol: 'estudiante',
      activo: true,
    },
  });

  console.log('✅ Todos los usuarios creados.');

  // ============================================================================
  // 5. VINCULAR USUARIOS A INSTITUCIONES
  // ============================================================================
  console.log('\n🔗 Vinculando usuarios a instituciones...');

  await prisma.usuarioInstitucion.createMany({
    data: [
      // NOTA: Super Admin NO se vincula - tiene acceso global automático

      // Admins de institución (cada uno a la suya)
      { usuarioId: adminSanJose.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminSantander.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },

      // Admin Multi-Sede (tiene acceso a MÚLTIPLES instituciones)
      { usuarioId: adminMultiSede.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminMultiSede.id, institucionId: colegioBolivar.id, rolEnInstitucion: 'admin' },

      // Profesores
      { usuarioId: profesorJuan.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profesorLaura.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profesorVacio.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profesorCarlos.id, institucionId: liceoSantander.id, rolEnInstitucion: 'profesor' },

      // Estudiantes San José
      { usuarioId: estudianteSantiago.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteMateo.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteValentina.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteAndres.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },

      // Estudiantes Santander
      { usuarioId: estudianteSofia.id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudianteDaniel.id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudiantePaula.id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },
    ],
  });

  console.log('✅ Vínculos usuario-institución creados.');
  console.log('   ℹ️  Super Admin tiene acceso global (sin vínculos explícitos)');
  console.log('   ℹ️  Admin Multi-Sede vinculado a 3 instituciones');

  // ============================================================================
  // 6. ESTRUCTURA ACADÉMICA - PERÍODOS
  // ============================================================================
  console.log('\n📚 Creando estructura académica...');

  const currentYear = new Date().getFullYear();

  const periodoSanJose = await prisma.periodoAcademico.create({
    data: {
      nombre: `Año Lectivo ${currentYear}`,
      fechaInicio: new Date(`${currentYear}-01-15`),
      fechaFin: new Date(`${currentYear}-12-15`),
      activo: true,
      institucionId: colegioSanJose.id,
    },
  });

  const periodoSantander = await prisma.periodoAcademico.create({
    data: {
      nombre: `Año Lectivo ${currentYear}`,
      fechaInicio: new Date(`${currentYear}-01-20`),
      fechaFin: new Date(`${currentYear}-12-10`),
      activo: true,
      institucionId: liceoSantander.id,
    },
  });

  const periodoBolivar = await prisma.periodoAcademico.create({
    data: {
      nombre: `Año Lectivo ${currentYear}`,
      fechaInicio: new Date(`${currentYear}-02-01`),
      fechaFin: new Date(`${currentYear}-11-30`),
      activo: true,
      institucionId: colegioBolivar.id,
    },
  });

  console.log('✅ 3 períodos académicos creados (todos activos).');

  // ============================================================================
  // 7. MATERIAS POR INSTITUCIÓN
  // ============================================================================
  console.log('\n📖 Creando materias...');

  // Materias San José
  const materiasSanJose = await Promise.all([
    prisma.materia.create({
      data: { nombre: 'Cálculo', codigo: 'MAT-101', institucionId: colegioSanJose.id },
    }),
    prisma.materia.create({
      data: { nombre: 'Física', codigo: 'FIS-101', institucionId: colegioSanJose.id },
    }),
    prisma.materia.create({
      data: { nombre: 'Español', codigo: 'ESP-101', institucionId: colegioSanJose.id },
    }),
    prisma.materia.create({
      data: { nombre: 'Inglés', codigo: 'ING-101', institucionId: colegioSanJose.id },
    }),
    prisma.materia.create({
      data: { nombre: 'Química', codigo: 'QUI-101', institucionId: colegioSanJose.id },
    }),
  ]);

  // Materias Santander
  const materiasSantander = await Promise.all([
    prisma.materia.create({
      data: { nombre: 'Ciencias Sociales', codigo: 'SOC-101', institucionId: liceoSantander.id },
    }),
    prisma.materia.create({
      data: { nombre: 'Matemáticas', codigo: 'MAT-101', institucionId: liceoSantander.id },
    }),
    prisma.materia.create({
      data: { nombre: 'Arte', codigo: 'ART-101', institucionId: liceoSantander.id },
    }),
    prisma.materia.create({
      data: { nombre: 'Educación Física', codigo: 'EFI-101', institucionId: liceoSantander.id },
    }),
  ]);

  console.log('✅ 9 materias creadas.');

  // ============================================================================
  // 8. GRUPOS POR INSTITUCIÓN
  // ============================================================================
  console.log('\n👥 Creando grupos...');

  // Grupos San José
  const grupo10A = await prisma.grupo.create({
    data: {
      nombre: 'Décimo A',
      grado: '10',
      seccion: 'A',
      periodoId: periodoSanJose.id,
      institucionId: colegioSanJose.id,
    },
  });

  const grupo11B = await prisma.grupo.create({
    data: {
      nombre: 'Once B',
      grado: '11',
      seccion: 'B',
      periodoId: periodoSanJose.id,
      institucionId: colegioSanJose.id,
    },
  });

  // Grupos Santander
  const grupo6_1 = await prisma.grupo.create({
    data: {
      nombre: 'Sexto Uno',
      grado: '6',
      seccion: '1',
      periodoId: periodoSantander.id,
      institucionId: liceoSantander.id,
    },
  });

  const grupo7_2 = await prisma.grupo.create({
    data: {
      nombre: 'Séptimo Dos',
      grado: '7',
      seccion: '2',
      periodoId: periodoSantander.id,
      institucionId: liceoSantander.id,
    },
  });

  console.log('✅ 4 grupos creados.');

  // ============================================================================
  // 9. PERFILES DE ESTUDIANTES (con códigos QR y responsables)
  // ============================================================================
  console.log('\n🎓 Creando perfiles de estudiantes...');

  const perfilSantiago = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteSantiago.id,
      identificacion: 'TI-1001234567',
      codigoQr: 'QR-SANTIAGO-001',
      nombreResponsable: 'María Mendoza',
      telefonoResponsable: TELEFONO_TEST,
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
      telefonoResponsable: TELEFONO_TEST,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilValentina = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteValentina.id,
      identificacion: 'TI-1001234569',
      codigoQr: 'QR-VALENTINA-003',
      // MISMO ACUDIENTE que Santiago (hermanos) - para probar consolidación
      nombreResponsable: 'María Mendoza',
      telefonoResponsable: TELEFONO_TEST,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilAndres = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteAndres.id,
      identificacion: 'TI-1001234570',
      codigoQr: 'QR-ANDRES-004',
      nombreResponsable: 'Carmen López',
      telefonoResponsable: TELEFONO_TEST,
      telefonoResponsableVerificado: false, // No verificado
      aceptaNotificaciones: true,
    },
  });

  const perfilSofia = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteSofia.id,
      identificacion: 'TI-2001234567',
      codigoQr: 'QR-SOFIA-005',
      nombreResponsable: 'Carlos Núñez',
      telefonoResponsable: TELEFONO_TEST,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilDaniel = await prisma.estudiante.create({
    data: {
      usuarioId: estudianteDaniel.id,
      identificacion: 'TI-2001234568',
      codigoQr: 'QR-DANIEL-006',
      nombreResponsable: 'Isabel Ruiz',
      telefonoResponsable: TELEFONO_TEST,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: true,
    },
  });

  const perfilPaula = await prisma.estudiante.create({
    data: {
      usuarioId: estudiantePaula.id,
      identificacion: 'TI-2001234569',
      codigoQr: 'QR-PAULA-007',
      nombreResponsable: 'Fernando Méndez',
      telefonoResponsable: TELEFONO_TEST,
      telefonoResponsableVerificado: true,
      aceptaNotificaciones: false, // No acepta notificaciones
    },
  });

  console.log('✅ 7 perfiles de estudiantes creados.');
  console.log(`   📱 Teléfono de prueba: ${TELEFONO_TEST}`);

  // ============================================================================
  // 10. ASIGNAR ESTUDIANTES A GRUPOS
  // ============================================================================
  console.log('\n🔗 Asignando estudiantes a grupos...');

  await prisma.estudianteGrupo.createMany({
    data: [
      // Grupo 10-A San José
      { estudianteId: perfilSantiago.id, grupoId: grupo10A.id },
      { estudianteId: perfilValentina.id, grupoId: grupo10A.id },
      { estudianteId: perfilAndres.id, grupoId: grupo10A.id },

      // Grupo 11-B San José
      { estudianteId: perfilMateo.id, grupoId: grupo11B.id },

      // Grupo 6-1 Santander
      { estudianteId: perfilSofia.id, grupoId: grupo6_1.id },
      { estudianteId: perfilDaniel.id, grupoId: grupo6_1.id },

      // Grupo 7-2 Santander
      { estudianteId: perfilPaula.id, grupoId: grupo7_2.id },
    ],
  });

  console.log('✅ Estudiantes asignados a grupos.');

  // ============================================================================
  // 11. CREAR HORARIOS COMPLETOS (TODOS LOS DÍAS DE LA SEMANA)
  // ============================================================================
  console.log('\n📅 Creando horarios semanales...');

  // Horarios para TODOS los días de la semana (1=Lunes, 5=Viernes)
  // Esto garantiza que siempre haya clases disponibles sin importar el día

  const horariosData = [];

  // Horarios Grupo 10-A San José - Prof. Juan (Cálculo) y Prof. Laura (Física)
  for (let dia = 1; dia <= 5; dia++) {
    // Clase de mañana temprano (siempre disponible)
    horariosData.push({
      diaSemana: dia,
      horaInicio: '07:00',
      horaFin: '08:00',
      materiaId: materiasSanJose[0].id, // Cálculo
      profesorId: profesorJuan.id,
      grupoId: grupo10A.id,
      periodoId: periodoSanJose.id,
      institucionId: colegioSanJose.id,
    });

    // Segunda clase
    horariosData.push({
      diaSemana: dia,
      horaInicio: '08:00',
      horaFin: '09:00',
      materiaId: materiasSanJose[1].id, // Física
      profesorId: profesorLaura.id,
      grupoId: grupo10A.id,
      periodoId: periodoSanJose.id,
      institucionId: colegioSanJose.id,
    });

    // Clase de medio día
    horariosData.push({
      diaSemana: dia,
      horaInicio: '10:00',
      horaFin: '11:00',
      materiaId: materiasSanJose[2].id, // Español
      profesorId: profesorJuan.id,
      grupoId: grupo10A.id,
      periodoId: periodoSanJose.id,
      institucionId: colegioSanJose.id,
    });

    // Clase de tarde
    horariosData.push({
      diaSemana: dia,
      horaInicio: '14:00',
      horaFin: '15:00',
      materiaId: materiasSanJose[3].id, // Inglés
      profesorId: profesorLaura.id,
      grupoId: grupo10A.id,
      periodoId: periodoSanJose.id,
      institucionId: colegioSanJose.id,
    });
  }

  // Horarios Grupo 11-B San José
  for (let dia = 1; dia <= 5; dia++) {
    horariosData.push({
      diaSemana: dia,
      horaInicio: '09:00',
      horaFin: '10:00',
      materiaId: materiasSanJose[4].id, // Química
      profesorId: profesorLaura.id,
      grupoId: grupo11B.id,
      periodoId: periodoSanJose.id,
      institucionId: colegioSanJose.id,
    });
  }

  // Horarios Grupo 6-1 Santander - Prof. Carlos
  for (let dia = 1; dia <= 5; dia++) {
    horariosData.push({
      diaSemana: dia,
      horaInicio: '07:00',
      horaFin: '08:00',
      materiaId: materiasSantander[0].id, // Ciencias Sociales
      profesorId: profesorCarlos.id,
      grupoId: grupo6_1.id,
      periodoId: periodoSantander.id,
      institucionId: liceoSantander.id,
    });

    horariosData.push({
      diaSemana: dia,
      horaInicio: '08:00',
      horaFin: '09:00',
      materiaId: materiasSantander[1].id, // Matemáticas
      profesorId: profesorCarlos.id,
      grupoId: grupo6_1.id,
      periodoId: periodoSantander.id,
      institucionId: liceoSantander.id,
    });
  }

  await prisma.horario.createMany({ data: horariosData });

  console.log(`✅ ${horariosData.length} horarios creados (clases todos los días L-V).`);

  // ============================================================================
  // 12. REGISTROS HISTÓRICOS DE ASISTENCIA
  // ============================================================================
  console.log('\n📋 Creando registros históricos de asistencia...');

  const horarios = await prisma.horario.findMany({
    where: { institucionId: colegioSanJose.id },
    take: 5,
  });

  const fechaAyer = new Date();
  fechaAyer.setDate(fechaAyer.getDate() - 1);
  fechaAyer.setHours(8, 0, 0, 0);

  const fechaHace3Dias = new Date();
  fechaHace3Dias.setDate(fechaHace3Dias.getDate() - 3);
  fechaHace3Dias.setHours(8, 0, 0, 0);

  const fechaHaceSemana = new Date();
  fechaHaceSemana.setDate(fechaHaceSemana.getDate() - 7);
  fechaHaceSemana.setHours(8, 0, 0, 0);

  if (horarios.length > 0) {
    await prisma.asistencia.createMany({
      data: [
        // Asistencias de ayer
        {
          fecha: fechaAyer,
          estado: 'PRESENTE',
          horarioId: horarios[0].id,
          estudianteId: perfilSantiago.id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'QR',
        },
        {
          fecha: fechaAyer,
          estado: 'AUSENTE',
          horarioId: horarios[0].id,
          estudianteId: perfilValentina.id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'MANUAL',
          observaciones: 'No asistió sin justificación',
        },
        {
          fecha: fechaAyer,
          estado: 'TARDANZA',
          horarioId: horarios[0].id,
          estudianteId: perfilAndres.id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'MANUAL',
          observaciones: 'Llegó 15 minutos tarde',
        },

        // Asistencias de hace 3 días
        {
          fecha: fechaHace3Dias,
          estado: 'PRESENTE',
          horarioId: horarios[1].id,
          estudianteId: perfilSantiago.id,
          profesorId: profesorLaura.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'QR',
        },
        {
          fecha: fechaHace3Dias,
          estado: 'PRESENTE',
          horarioId: horarios[1].id,
          estudianteId: perfilValentina.id,
          profesorId: profesorLaura.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'QR',
        },

        // Asistencias de hace una semana
        {
          fecha: fechaHaceSemana,
          estado: 'JUSTIFICADO',
          horarioId: horarios[0].id,
          estudianteId: perfilSantiago.id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'MANUAL',
          observaciones: 'Excusa médica presentada',
        },
        {
          fecha: fechaHaceSemana,
          estado: 'AUSENTE',
          horarioId: horarios[0].id,
          estudianteId: perfilAndres.id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'MANUAL',
        },
      ],
    });
  }

  console.log('✅ 7 registros históricos de asistencia creados.');

  // ============================================================================
  // RESUMEN FINAL
  // ============================================================================
  console.log('\n' + '='.repeat(70));
  console.log('🎉 SEED COMPLETADO EXITOSAMENTE');
  console.log('='.repeat(70));

  console.log('\n📊 RESUMEN DE DATOS CREADOS:');
  console.log('   • Instituciones: 4 (3 activas, 1 inactiva)');
  console.log('   • Configuraciones: 4 (INSTANT, MANUAL_ONLY, END_OF_DAY, NONE)');
  console.log('   • Usuarios: 14 total');
  console.log('     - 1 Super Admin');
  console.log('     - 3 Admins Institución (1 multi-sede)');
  console.log('     - 4 Profesores (1 sin clases)');
  console.log('     - 7 Estudiantes');
  console.log('   • Períodos académicos: 3');
  console.log('   • Materias: 9');
  console.log('   • Grupos: 4');
  console.log(`   • Horarios: ${horariosData.length} (clases L-V)`);
  console.log('   • Asistencias históricas: 7');

  console.log('\n🔐 CREDENCIALES DE ACCESO:');
  console.log('   ┌────────────────────────────────────────────────────────────┐');
  console.log('   │ ROL                │ EMAIL                    │ CONTRASEÑA │');
  console.log('   ├────────────────────────────────────────────────────────────┤');
  console.log('   │ 👑 Super Admin     │ superadmin@asistapp.com  │ Admin123!  │');
  console.log('   ├────────────────────────────────────────────────────────────┤');
  console.log('   │ 👨‍💼 Admin San José  │ admin@sanjose.edu        │ SanJose123!│');
  console.log('   │ 👨‍💼 Admin Santander │ admin@santander.edu      │ Santander123!│');
  console.log('   │ 👨‍💼 Admin Multi-Sede│ multiadmin@asistapp.com  │ Multi123!  │');
  console.log('   ├────────────────────────────────────────────────────────────┤');
  console.log('   │ 👨‍🏫 Juan Pérez      │ juan.perez@sanjose.edu   │ Prof123!   │');
  console.log('   │ 👨‍🏫 Laura Gómez     │ laura.gomez@sanjose.edu  │ Prof123!   │');
  console.log('   │ 👨‍🏫 Sin Clases      │ vacio.profe@sanjose.edu  │ Prof123!   │');
  console.log('   │ 👨‍🏫 Carlos Díaz     │ carlos.diaz@santander.edu│ Prof123!   │');
  console.log('   ├────────────────────────────────────────────────────────────┤');
  console.log('   │ 👨‍🎓 Santiago        │ santiago.mendoza@sanjose.edu │ Est123!│');
  console.log('   │ 👨‍🎓 Mateo           │ mateo.castro@sanjose.edu │ Est123!    │');
  console.log('   │ 👨‍🎓 Valentina       │ valentina.rojas@sanjose.edu │ Est123! │');
  console.log('   │ 👨‍🎓 Sofía           │ sofia.nunez@santander.edu│ Est123!    │');
  console.log('   └────────────────────────────────────────────────────────────┘');

  console.log('\n📱 CONFIGURACIÓN DE NOTIFICACIONES:');
  console.log('   • San José: INSTANT (WhatsApp inmediato al registrar ausencia)');
  console.log('   • Santander: MANUAL_ONLY (requiere botón para enviar)');
  console.log('   • Bolívar: END_OF_DAY (resumen a las 16:00)');
  console.log(`   • Teléfono de prueba: ${TELEFONO_TEST}`);

  console.log('\n✅ Base de datos lista para pruebas!');
  console.log('='.repeat(70) + '\n');
}

main()
  .catch((e) => {
    console.error('❌ Error durante el seed:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
