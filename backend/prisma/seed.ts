// backend/prisma/seed.ts

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('🚀 Iniciando seed maestro para AsistApp...');

  // 1. Limpieza Completa
  console.log('🧹 Limpiando base de datos...');
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
  await prisma.institucion.deleteMany();
  console.log('✅ Base de datos limpia.');

  // Función para hashear contraseñas
  const hashPassword = (password: string) => bcrypt.hashSync(password, 10);

  // 2. Crear Instituciones
  console.log('🏫 Creando instituciones...');
  const colegioSanJose = await prisma.institucion.create({
    data: {
      nombre: 'Colegio San José',
      activa: true,
    },
  });

  const liceoSantander = await prisma.institucion.create({
    data: {
      nombre: 'Liceo Santander',
      activa: true,
    },
  });

  const institutoPasado = await prisma.institucion.create({
    data: {
      nombre: 'Instituto del Pasado',
      activa: false,
    },
  });
  console.log('✅ Instituciones creadas.');

  // 3. Crear Usuarios y Roles
  console.log('👥 Creando usuarios...');

  // Super Admin
  const superAdmin = await prisma.usuario.create({
    data: {
      email: 'superadmin@asistapp.com',
      passwordHash: hashPassword('Admin123!'),
      nombres: 'Super',
      apellidos: 'Admin',
      rol: 'super_admin',
      activo: true,
    },
  });

  // Admins de Institución
  const adminSanJose = await prisma.usuario.create({
    data: {
      email: 'admin@sanjose.edu',
      passwordHash: hashPassword('SanJose123!'),
      nombres: 'Admin',
      apellidos: 'San José',
      rol: 'admin_institucion',
      activo: true,
    },
  });

  const adminSantander = await prisma.usuario.create({
    data: {
      email: 'admin@santander.edu',
      passwordHash: hashPassword('Santander123!'),
      nombres: 'Admin',
      apellidos: 'Santander',
      rol: 'admin_institucion',
      activo: true,
    },
  });

  // Profesores
  const profesorJuan = await prisma.usuario.create({
    data: {
      email: 'juan.perez@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Juan',
      apellidos: 'Pérez',
      rol: 'profesor',
      activo: true,
    },
  });

  const profesorLaura = await prisma.usuario.create({
    data: {
      email: 'laura.gomez@sanjose.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Laura',
      apellidos: 'Gómez',
      rol: 'profesor',
      activo: true,
    },
  });

  const profesorCarlos = await prisma.usuario.create({
    data: {
      email: 'carlos.diaz@santander.edu',
      passwordHash: hashPassword('Prof123!'),
      nombres: 'Carlos',
      apellidos: 'Díaz',
      rol: 'profesor',
      activo: true,
    },
  });

  // Estudiantes San José
  const estudiantesSanJose = await Promise.all([
    prisma.usuario.create({
      data: {
        email: 'santiago.mendoza@sanjose.edu',
        passwordHash: hashPassword('Est123!'),
        nombres: 'Santiago',
        apellidos: 'Mendoza',
        rol: 'estudiante',
        activo: true,
      },
    }),
    prisma.usuario.create({
      data: {
        email: 'sofia.nunez@santander.edu',
        passwordHash: hashPassword('Est123!'),
        nombres: 'Sofía',
        apellidos: 'Núñez',
        rol: 'estudiante',
        activo: true,
      },
    }),
    prisma.usuario.create({
      data: {
        email: 'mateo.castro@sanjose.edu',
        passwordHash: hashPassword('Est123!'),
        nombres: 'Mateo',
        apellidos: 'Castro',
        rol: 'estudiante',
        activo: true,
      },
    }),
    prisma.usuario.create({
      data: {
        email: 'valentina.rojas@sanjose.edu',
        passwordHash: hashPassword('Est123!'),
        nombres: 'Valentina',
        apellidos: 'Rojas',
        rol: 'estudiante',
        activo: true,
      },
    }),
    prisma.usuario.create({
      data: {
        email: 'daniel.ruiz@santander.edu',
        passwordHash: hashPassword('Est123!'),
        nombres: 'Daniel',
        apellidos: 'Ruiz',
        rol: 'estudiante',
        activo: true,
      },
    }),
    prisma.usuario.create({
      data: {
        email: 'paula.mendez@santander.edu',
        passwordHash: hashPassword('Est123!'),
        nombres: 'Paula',
        apellidos: 'Méndez',
        rol: 'estudiante',
        activo: true,
      },
    }),
  ]);

  console.log('✅ Usuarios creados.');

  // 4. Vincular Usuarios a Instituciones
  console.log('🔗 Vinculando usuarios a instituciones...');
  await prisma.usuarioInstitucion.createMany({
    data: [
      // Super Admin vinculado a todas las instituciones activas
      { usuarioId: superAdmin.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: superAdmin.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },

      // Admins específicos
      { usuarioId: adminSanJose.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' },
      { usuarioId: adminSantander.id, institucionId: liceoSantander.id, rolEnInstitucion: 'admin' },

      // Profesores
      { usuarioId: profesorJuan.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profesorLaura.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'profesor' },
      { usuarioId: profesorCarlos.id, institucionId: liceoSantander.id, rolEnInstitucion: 'profesor' },

      // Estudiantes
      { usuarioId: estudiantesSanJose[0].id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudiantesSanJose[1].id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudiantesSanJose[2].id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudiantesSanJose[3].id, institucionId: colegioSanJose.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudiantesSanJose[4].id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },
      { usuarioId: estudiantesSanJose[5].id, institucionId: liceoSantander.id, rolEnInstitucion: 'estudiante' },
    ],
  });
  console.log('✅ Vínculos creados.');

  // 5. Crear Estructura Académica
  console.log('📚 Creando estructura académica...');

  // Periodos Académicos
  const periodoSanJose = await prisma.periodoAcademico.create({
    data: {
      nombre: 'Año Lectivo 2025',
      fechaInicio: new Date('2025-01-15'),
      fechaFin: new Date('2025-12-15'),
      activo: true,
      institucionId: colegioSanJose.id,
    },
  });

  const periodoSantander = await prisma.periodoAcademico.create({
    data: {
      nombre: 'Año Lectivo 2025',
      fechaInicio: new Date('2025-01-15'),
      fechaFin: new Date('2025-12-15'),
      activo: true,
      institucionId: liceoSantander.id,
    },
  });

  // Materias
  const materiasSanJose = await Promise.all([
    prisma.materia.create({
      data: {
        nombre: 'Cálculo',
        codigo: 'CAL-001',
        institucionId: colegioSanJose.id,
      },
    }),
    prisma.materia.create({
      data: {
        nombre: 'Física',
        codigo: 'FIS-001',
        institucionId: colegioSanJose.id,
      },
    }),
    prisma.materia.create({
      data: {
        nombre: 'Español',
        codigo: 'ESP-001',
        institucionId: colegioSanJose.id,
      },
    }),
    prisma.materia.create({
      data: {
        nombre: 'Inglés',
        codigo: 'ING-001',
        institucionId: colegioSanJose.id,
      },
    }),
  ]);

  const materiasSantander = await Promise.all([
    prisma.materia.create({
      data: {
        nombre: 'Sociales',
        codigo: 'SOC-001',
        institucionId: liceoSantander.id,
      },
    }),
    prisma.materia.create({
      data: {
        nombre: 'Arte',
        codigo: 'ART-001',
        institucionId: liceoSantander.id,
      },
    }),
    prisma.materia.create({
      data: {
        nombre: 'Matemáticas',
        codigo: 'MAT-001',
        institucionId: liceoSantander.id,
      },
    }),
  ]);

  // Grupos
  const gruposSanJose = await Promise.all([
    prisma.grupo.create({
      data: {
        nombre: 'Grupo 10-A',
        grado: '10',
        seccion: 'A',
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },
    }),
    prisma.grupo.create({
      data: {
        nombre: 'Grupo 11-B',
        grado: '11',
        seccion: 'B',
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },
    }),
  ]);

  const gruposSantander = await Promise.all([
    prisma.grupo.create({
      data: {
        nombre: 'Grupo 9-A',
        grado: '9',
        seccion: 'A',
        periodoId: periodoSantander.id,
        institucionId: liceoSantander.id,
      },
    }),
  ]);

  console.log('✅ Estructura académica creada.');

  // 6. Poblar Grupos
  console.log('👨‍🎓 Asignando estudiantes a grupos...');

  // Crear perfiles de estudiantes primero
  const estudiantes = await Promise.all([
    prisma.estudiante.create({
      data: {
        usuarioId: estudiantesSanJose[0].id,
        identificacion: '1001',
        codigoQr: 'QR-SANTIAGO-1001',
        nombreResponsable: 'Ana Mendoza',
        telefonoResponsable: '+573001234567',
      },
    }),
    prisma.estudiante.create({
      data: {
        usuarioId: estudiantesSanJose[1].id,
        identificacion: '2001',
        codigoQr: 'QR-SOFIA-2001',
        nombreResponsable: 'Carlos Núñez',
        telefonoResponsable: '+573002345678',
      },
    }),
    prisma.estudiante.create({
      data: {
        usuarioId: estudiantesSanJose[2].id,
        identificacion: '1002',
        codigoQr: 'QR-MATEO-1002',
        nombreResponsable: 'Patricia Castro',
        telefonoResponsable: '+573001234568',
      },
    }),
    prisma.estudiante.create({
      data: {
        usuarioId: estudiantesSanJose[3].id,
        identificacion: '1003',
        codigoQr: 'QR-VALENTINA-1003',
        nombreResponsable: 'Roberto Rojas',
        telefonoResponsable: '+573001234569',
      },
    }),
    prisma.estudiante.create({
      data: {
        usuarioId: estudiantesSanJose[4].id,
        identificacion: '2002',
        codigoQr: 'QR-DANIEL-2002',
        nombreResponsable: 'Isabel Ruiz',
        telefonoResponsable: '+573002345679',
      },
    }),
    prisma.estudiante.create({
      data: {
        usuarioId: estudiantesSanJose[5].id,
        identificacion: '2003',
        codigoQr: 'QR-PAULA-2003',
        nombreResponsable: 'Fernando Méndez',
        telefonoResponsable: '+573002345680',
      },
    }),
  ]);

  // Asignar estudiantes a grupos (dejando algunos sin asignar)
  await prisma.estudianteGrupo.createMany({
    data: [
      // Grupo 10-A
      { estudianteId: estudiantes[0].id, grupoId: gruposSanJose[0].id },
      { estudianteId: estudiantes[2].id, grupoId: gruposSanJose[0].id },
      { estudianteId: estudiantes[3].id, grupoId: gruposSanJose[0].id },

      // Grupo 11-B
      { estudianteId: estudiantes[1].id, grupoId: gruposSanJose[1].id },

      // Grupo 9-A Santander
      { estudianteId: estudiantes[4].id, grupoId: gruposSantander[0].id },
      { estudianteId: estudiantes[5].id, grupoId: gruposSantander[0].id },

      // estudiantes[1] queda sin asignar para probar ese caso
    ],
  });

  console.log('✅ Estudiantes asignados a grupos.');

  // 7. Crear Horarios
  console.log('📅 Creando horarios...');

  // Horario semanal completo para Grupo 10-A
  await prisma.horario.createMany({
    data: [
      // Lunes
      {
        diaSemana: 1,
        horaInicio: '08:00',
        horaFin: '10:00', // Clase de 2 horas
        materiaId: materiasSanJose[0].id, // Cálculo
        profesorId: profesorJuan.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },
      {
        diaSemana: 1,
        horaInicio: '10:30',
        horaFin: '11:30',
        materiaId: materiasSanJose[1].id, // Física
        profesorId: profesorLaura.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },

      // Martes
      {
        diaSemana: 2,
        horaInicio: '08:00',
        horaFin: '09:00',
        materiaId: materiasSanJose[2].id, // Español
        profesorId: profesorJuan.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },
      {
        diaSemana: 2,
        horaInicio: '09:00',
        horaFin: '10:00',
        materiaId: materiasSanJose[3].id, // Inglés
        profesorId: profesorLaura.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },

      // Miércoles
      {
        diaSemana: 3,
        horaInicio: '08:00',
        horaFin: '10:00', // Clase de 2 horas
        materiaId: materiasSanJose[1].id, // Física
        profesorId: profesorLaura.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },

      // Jueves
      {
        diaSemana: 4,
        horaInicio: '08:00',
        horaFin: '09:00',
        materiaId: materiasSanJose[0].id, // Cálculo
        profesorId: profesorJuan.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },
      {
        diaSemana: 4,
        horaInicio: '09:00',
        horaFin: '10:00',
        materiaId: materiasSanJose[2].id, // Español
        profesorId: profesorJuan.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },

      // Viernes
      {
        diaSemana: 5,
        horaInicio: '08:00',
        horaFin: '09:00',
        materiaId: materiasSanJose[3].id, // Inglés
        profesorId: profesorLaura.id,
        grupoId: gruposSanJose[0].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },

      // Algunos horarios para otros grupos
      {
        diaSemana: 1,
        horaInicio: '08:00',
        horaFin: '09:00',
        materiaId: materiasSanJose[0].id,
        profesorId: profesorJuan.id,
        grupoId: gruposSanJose[1].id,
        periodoId: periodoSanJose.id,
        institucionId: colegioSanJose.id,
      },
      {
        diaSemana: 2,
        horaInicio: '08:00',
        horaFin: '09:00',
        materiaId: materiasSantander[0].id,
        profesorId: profesorCarlos.id,
        grupoId: gruposSantander[0].id,
        periodoId: periodoSantander.id,
        institucionId: liceoSantander.id,
      },
    ],
  });

  console.log('✅ Horarios creados.');

  // 8. Generar Datos Históricos de Asistencia
  console.log('📋 Creando registros históricos de asistencia...');

  // Obtener algunos horarios para crear asistencias
  const horarios = await prisma.horario.findMany({
    where: { institucionId: colegioSanJose.id },
    take: 3,
  });

  const fechaHaceUnaSemana = new Date();
  fechaHaceUnaSemana.setDate(fechaHaceUnaSemana.getDate() - 7);

  const fechaHaceTresDias = new Date();
  fechaHaceTresDias.setDate(fechaHaceTresDias.getDate() - 3);

  // Crear asistencias para fechas pasadas
  if (horarios.length > 0) {
    await prisma.asistencia.createMany({
      data: [
        // Asistencia para horario 1 (Cálculo Lunes)
        {
          fecha: fechaHaceUnaSemana,
          estado: 'PRESENTE',
          horarioId: horarios[0].id,
          estudianteId: estudiantes[0].id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'QR',
        },
        {
          fecha: fechaHaceUnaSemana,
          estado: 'AUSENTE',
          horarioId: horarios[0].id,
          estudianteId: estudiantes[2].id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'MANUAL',
        },
        {
          fecha: fechaHaceTresDias,
          estado: 'TARDANZA',
          horarioId: horarios[0].id,
          estudianteId: estudiantes[0].id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'QR',
        },
        {
          fecha: fechaHaceTresDias,
          estado: 'PRESENTE',
          horarioId: horarios[0].id,
          estudianteId: estudiantes[2].id,
          profesorId: profesorJuan.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'QR',
        },

        // Asistencia para horario 2 (Física Lunes)
        {
          fecha: fechaHaceUnaSemana,
          estado: 'PRESENTE',
          horarioId: horarios[1].id,
          estudianteId: estudiantes[0].id,
          profesorId: profesorLaura.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'QR',
        },
        {
          fecha: fechaHaceUnaSemana,
          estado: 'JUSTIFICADO',
          horarioId: horarios[1].id,
          estudianteId: estudiantes[2].id,
          profesorId: profesorLaura.id,
          institucionId: colegioSanJose.id,
          tipoRegistro: 'MANUAL',
          observaciones: 'Excusa médica',
        },
      ],
    });
  }

  console.log('✅ Registros históricos de asistencia creados.');

  // 9. Resumen Final
  console.log('\n🎉 Seed completado exitosamente!');
  console.log('📊 Resumen de datos creados:');
  console.log(`   • Instituciones: 3 (2 activas, 1 inactiva)`);
  console.log(`   • Usuarios: 9 (1 super admin, 2 admins institución, 3 profesores, 3 estudiantes)`);
  console.log(`   • Vínculos usuario-institución: 9`);
  console.log(`   • Períodos académicos: 2`);
  console.log(`   • Materias: 7`);
  console.log(`   • Grupos: 3`);
  console.log(`   • Estudiantes asignados: 5 (1 sin asignar)`);
  console.log(`   • Horarios: 9`);
  console.log(`   • Registros de asistencia histórica: 6`);
  console.log('\n🔐 Credenciales de acceso:');
  console.log('   Super Admin: superadmin@asistapp.com / Admin123!');
  console.log('   Admin San José: admin@sanjose.edu / SanJose123!');
  console.log('   Admin Santander: admin@santander.edu / Santander123!');
  console.log('   Profesores: [usuario]@institucion.edu / Prof123!');
  console.log('   Estudiantes: [usuario]@institucion.edu / Est123!');
}

main()
  .catch((e) => {
    console.error('❌ Error durante el seed:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
