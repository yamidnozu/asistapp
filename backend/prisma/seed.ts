import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seed de AsistApp V2...');

  // ============================================
  // 1. CREAR INSTITUCIONES
  // ============================================
  console.log('🏫 Creando instituciones...');

  const instituciones = await Promise.all([
    prisma.institucion.upsert({
      where: { codigo: 'sanjose' },
      update: {},
      create: {
        nombre: 'Colegio San José',
        codigo: 'sanjose',
        direccion: 'Calle 123 #45-67',
        email: 'admin@sanjose.edu',
        telefono: '555-0101',
        activa: true,
      },
    }),
    prisma.institucion.upsert({
      where: { codigo: 'fps' },
      update: {},
      create: {
        nombre: 'IE Francisco de Paula Santander',
        codigo: 'fps',
        direccion: 'Carrera 10 #20-30',
        email: 'admin@fps.edu',
        telefono: '555-0202',
        activa: true,
      },
    }),
  ]);

  console.log('✅ Instituciones creadas:', instituciones.length);

  // ============================================
  // 2. CREAR SUPER ADMIN
  // ============================================
  console.log('👑 Creando super admin...');

  const superAdminPassword = await bcrypt.hash('Admin123!', 10);

  const superAdmin = await prisma.usuario.upsert({
    where: { email: 'superadmin@asistapp.com' },
    update: {},
    create: {
      email: 'superadmin@asistapp.com',
      passwordHash: superAdminPassword,
      nombres: 'Super',
      apellidos: 'Admin',
      rol: 'super_admin',
      activo: true,
    },
  });

  console.log('✅ Super admin creado:', superAdmin.email);

  // ============================================
  // 3. CREAR ADMINS DE INSTITUCIÓN
  // ============================================
  console.log('👨‍💼 Creando admins de institución...');

  const adminSanJosePassword = await bcrypt.hash('SanJose123!', 10);
  const adminFpsPassword = await bcrypt.hash('Fps123!', 10);

  const adminsInstitucion = await Promise.all([
    prisma.usuario.upsert({
      where: { email: 'admin@sanjose.edu' },
      update: {},
      create: {
        institucionId: instituciones[0].id,
        email: 'admin@sanjose.edu',
        passwordHash: adminSanJosePassword,
        nombres: 'María',
        apellidos: 'González',
        rol: 'admin_institucion',
        telefono: '555-0103',
        activo: true,
      },
    }),
    prisma.usuario.upsert({
      where: { email: 'admin@fps.edu' },
      update: {},
      create: {
        institucionId: instituciones[1].id,
        email: 'admin@fps.edu',
        passwordHash: adminFpsPassword,
        nombres: 'Carlos',
        apellidos: 'Rodríguez',
        rol: 'admin_institucion',
        telefono: '555-0203',
        activo: true,
      },
    }),
  ]);

  console.log('✅ Admins de institución creados:', adminsInstitucion.length);

  // ============================================
  // 4. CREAR PROFESORES
  // ============================================
  console.log('👨‍🏫 Creando profesores...');

  const profesor1Password = await bcrypt.hash('Prof123!', 10);
  const profesor2Password = await bcrypt.hash('Prof456!', 10);

  const profesores = await Promise.all([
    prisma.usuario.upsert({
      where: { email: 'pedro.garcia@sanjose.edu' },
      update: {},
      create: {
        institucionId: instituciones[0].id,
        email: 'pedro.garcia@sanjose.edu',
        passwordHash: profesor1Password,
        nombres: 'Pedro',
        apellidos: 'García',
        rol: 'profesor',
        telefono: '555-0104',
        activo: true,
      },
    }),
    prisma.usuario.upsert({
      where: { email: 'ana.lopez@sanjose.edu' },
      update: {},
      create: {
        institucionId: instituciones[0].id,
        email: 'ana.lopez@sanjose.edu',
        passwordHash: profesor2Password,
        nombres: 'Ana',
        apellidos: 'López',
        rol: 'profesor',
        telefono: '555-0105',
        activo: true,
      },
    }),
  ]);

  console.log('✅ Profesores creados:', profesores.length);

  // ============================================
  // 5. CREAR ESTUDIANTES (USUARIOS + INFO ADICIONAL)
  // ============================================
  console.log('👨‍🎓 Creando estudiantes...');

  const estudiantesData = [
    { nombres: 'Juan', apellidos: 'Pérez', identificacion: '12345678', responsable: 'María Pérez', telResponsable: '300-111-0001' },
    { nombres: 'María', apellidos: 'García', identificacion: '12345679', responsable: 'Carlos García', telResponsable: '300-111-0002' },
    { nombres: 'Carlos', apellidos: 'López', identificacion: '12345680', responsable: 'Ana López', telResponsable: '300-111-0003' },
    { nombres: 'Laura', apellidos: 'Martínez', identificacion: '12345681', responsable: 'Pedro Martínez', telResponsable: '300-111-0004' },
    { nombres: 'Miguel', apellidos: 'Rodríguez', identificacion: '12345682', responsable: 'Sofia Rodríguez', telResponsable: '300-111-0005' },
  ];

  const estudiantes = [];
  for (const estudianteData of estudiantesData) {
    const estudiantePassword = await bcrypt.hash('Est123!', 10);

    const usuario = await prisma.usuario.upsert({
      where: { email: `${estudianteData.nombres.toLowerCase()}.${estudianteData.apellidos.toLowerCase()}@sanjose.edu` },
      update: {},
      create: {
        institucionId: instituciones[0].id,
        email: `${estudianteData.nombres.toLowerCase()}.${estudianteData.apellidos.toLowerCase()}@sanjose.edu`,
        passwordHash: estudiantePassword,
        nombres: estudianteData.nombres,
        apellidos: estudianteData.apellidos,
        rol: 'estudiante',
        activo: true,
      },
    });

    const estudiante = await prisma.estudiante.upsert({
      where: { identificacion: estudianteData.identificacion },
      update: {},
      create: {
        usuarioId: usuario.id,
        identificacion: estudianteData.identificacion,
        codigoQr: `QR-${estudianteData.identificacion}`,
        nombreResponsable: estudianteData.responsable,
        telefonoResponsable: estudianteData.telResponsable,
      },
    });

    estudiantes.push({ usuario, estudiante });
  }

  console.log('✅ Estudiantes creados:', estudiantes.length);

  // ============================================
  // 6. CREAR PERIODOS ACADÉMICOS
  // ============================================
  console.log('📅 Creando periodos académicos...');

  // const periodos = await Promise.all([
  //   prisma.periodoAcademico.upsert({
  //     where: {
  //       institucionId_activo: {
  //         institucionId: instituciones[0].id,
  //         activo: true,
  //       },
  //     },
  //     update: {},
  //     create: {
  //       institucionId: instituciones[0].id,
  //       nombre: '2025',
  //       fechaInicio: new Date('2025-01-15'),
  //       fechaFin: new Date('2025-12-15'),
  //       activo: true,
  //     },
  //   }),
  // ]);

  // console.log('✅ Periodos académicos creados:', periodos.length);

  console.log('📅 Periodos académicos saltados temporalmente');

  const periodos = [{ id: 'temp-id' }]; // Temporal

  // ============================================
  // 7. CREAR GRUPOS
  // ============================================
  console.log('👥 Creando grupos...');

  // const grupos = await Promise.all([
  //   prisma.grupo.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       periodoId: periodos[0].id,
  //       nombre: '10-A',
  //       grado: '10',
  //       seccion: 'A',
  //     },
  //   }),
  //   prisma.grupo.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       periodoId: periodos[0].id,
  //       nombre: '11-B',
  //       grado: '11',
  //       seccion: 'B',
  //     },
  //   }),
  // ]);

  // console.log('✅ Grupos creados:', grupos.length);

  console.log('👥 Grupos saltados temporalmente');

  const grupos = [{ id: 'temp-id' }]; // Temporal

  // ============================================
  // 8. CREAR MATERIAS
  // ============================================
  console.log('📚 Creando materias...');

  // const materias = await Promise.all([
  //   prisma.materia.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       nombre: 'Matemáticas',
  //       codigo: 'MAT101',
  //     },
  //   }),
  //   prisma.materia.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       nombre: 'Español',
  //       codigo: 'ESP101',
  //     },
  //   }),
  //   prisma.materia.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       nombre: 'Ciencias',
  //       codigo: 'CIE101',
  //     },
  //   }),
  // ]);

  // console.log('✅ Materias creadas:', materias.length);

  console.log('📚 Materias saltadas temporalmente');

  const materias = [{ id: 'temp-id' }]; // Temporal

  // ============================================
  // 9. CREAR HORARIOS
  // ============================================
  console.log('⏰ Creando horarios...');

  // const horarios = await Promise.all([
  //   // Matemáticas - Grupo 10-A - Lunes
  //   prisma.horario.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       periodoId: periodos[0].id,
  //       grupoId: grupos[0].id,
  //       materiaId: materias[0].id,
  //       profesorId: profesores[0].id,
  //       diaSemana: 1, // Lunes
  //       horaInicio: '07:00:00',
  //       horaFin: '08:00:00',
  //     },
  //   }),
  //   // Español - Grupo 10-A - Lunes
  //   prisma.horario.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       periodoId: periodos[0].id,
  //       grupoId: grupos[0].id,
  //       materiaId: materias[1].id,
  //       profesorId: profesores[1].id,
  //       diaSemana: 1, // Lunes
  //       horaInicio: '08:00:00',
  //       horaFin: '09:00:00',
  //     },
  //   }),
  //   // Ciencias - Grupo 10-A - Martes
  //   prisma.horario.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       periodoId: periodos[0].id,
  //       grupoId: grupos[0].id,
  //       materiaId: materias[2].id,
  //       profesorId: profesores[0].id,
  //       diaSemana: 2, // Martes
  //       horaInicio: '07:00:00',
  //       horaFin: '08:00:00',
  //     },
  //   }),
  //   // Matemáticas - Grupo 11-B - Miércoles
  //   prisma.horario.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       periodoId: periodos[0].id,
  //       grupoId: grupos[1].id,
  //       materiaId: materias[0].id,
  //       profesorId: profesores[0].id,
  //       diaSemana: 3, // Miércoles
  //       horaInicio: '07:00:00',
  //       horaFin: '08:00:00',
  //     },
  //   }),
  // ]);

  // console.log('✅ Horarios creados:', horarios.length);

  console.log('⏰ Horarios saltados temporalmente');

  // ============================================
  // 10. ASIGNAR ESTUDIANTES A GRUPOS
  // ============================================
  console.log('🔗 Asignando estudiantes a grupos...');

  // await Promise.all([
  //   // Estudiantes en 10-A
  //   prisma.estudianteGrupo.create({
  //     data: {
  //       estudianteId: estudiantes[0].estudiante.id,
  //       grupoId: grupos[0].id,
  //     },
  //   }),
  //   prisma.estudianteGrupo.create({
  //     data: {
  //       estudianteId: estudiantes[1].estudiante.id,
  //       grupoId: grupos[0].id,
  //     },
  //   }),
  //   prisma.estudianteGrupo.create({
  //     data: {
  //       estudianteId: estudiantes[2].estudiante.id,
  //       grupoId: grupos[0].id,
  //     },
  //   }),
  //   // Estudiantes en 11-B
  //   prisma.estudianteGrupo.create({
  //     data: {
  //       estudianteId: estudiantes[3].estudiante.id,
  //       grupoId: grupos[1].id,
  //     },
  //   }),
  //   prisma.estudianteGrupo.create({
  //     data: {
  //       estudianteId: estudiantes[4].estudiante.id,
  //       grupoId: grupos[1].id,
  //     },
  //   }),
  // ]);

  console.log('🔗 Estudiantes asignados a grupos (saltado)');

  // ============================================
  // 11. CREAR ASISTENCIAS DE EJEMPLO
  // ============================================
  console.log('📝 Creando asistencias de ejemplo...');

  // const fechaHoy = new Date();
  // await Promise.all([
  //   // Juan Pérez - Matemáticas (presente)
  //   prisma.asistencia.create({
  //     data: {
  //       estudianteId: estudiantes[0].estudiante.id,
  //       horarioId: 'temp-id', // Temporal, cambiar cuando se arreglen horarios
  //       profesorId: profesores[0].id,
  //       grupoId: grupos[0].id,
  //       fecha: fechaHoy,
  //       tipoRegistro: 'qr',
  //       observaciones: 'Excelente participación en clase',
  //     },
  //   }),
  //   // María García - Matemáticas (ausente)
  //   prisma.asistencia.create({
  //     data: {
  //       estudianteId: estudiantes[1].estudiante.id,
  //       horarioId: 'temp-id', // Temporal
  //       profesorId: profesores[0].id,
  //       grupoId: grupos[0].id,
  //       fecha: fechaHoy,
  //       tipoRegistro: 'manual',
  //       observaciones: 'Enfermedad',
  //     },
  //   }),
  //   // Carlos López - Español (presente)
  //   prisma.asistencia.create({
  //     data: {
  //       estudianteId: estudiantes[2].estudiante.id,
  //       horarioId: 'temp-id', // Temporal
  //       profesorId: profesores[1].id,
  //       grupoId: grupos[0].id,
  //       fecha: fechaHoy,
  //       tipoRegistro: 'qr',
  //       observaciones: 'Muy atento en clase',
  //     },
  //   }),
  // ]);

  console.log('📝 Asistencias de ejemplo creadas (saltado)');

  // ============================================
  // 12. CREAR CONFIGURACIONES
  // ============================================
  console.log('⚙️ Creando configuraciones...');

  // await Promise.all([
  //   prisma.configuracion.create({
  //     data: {
  //       institucionId: instituciones[0].id,
  //       notificacionesActivas: false,
  //       modoNotificacion: 'diaria',
  //       horaNotificacion: '18:00:00',
  //       umbralFaltas: 3,
  //       horaInicioClases: '07:00:00',
  //       horaFinClases: '15:00:00',
  //       diasLaborales: [1, 2, 3, 4, 5], // Lunes a Viernes
  //     },
  //   }),
  // ]);

  console.log('⚙️ Configuraciones creadas (saltado)');

  // ============================================
  // RESUMEN FINAL
  // ============================================
  console.log('\n🎉 Seed completado exitosamente!');
  console.log('\n📊 Resumen de datos creados:');
  console.log('🏫 Instituciones:', instituciones.length);
  console.log('👑 Super Admin:', 1);
  console.log('👨‍💼 Admins de institución:', adminsInstitucion.length);
  console.log('👨‍🏫 Profesores:', profesores.length);
  console.log('👨‍🎓 Estudiantes:', estudiantes.length);
  console.log('📅 Periodos académicos:', 0); // Temporalmente 0
  console.log('👥 Grupos:', 0); // Temporalmente 0
  console.log('📚 Materias:', 0); // Temporalmente 0
  console.log('⏰ Horarios:', 0); // Temporalmente 0
  console.log('📝 Asistencias:', 0); // Temporalmente 0
  console.log('⚙️ Configuraciones:', 0); // Temporalmente 0

  console.log('\n🔐 Credenciales de acceso:');
  console.log('Super Admin: superadmin@asistapp.com / Admin123!');
  console.log('Admin San José: admin@sanjose.edu / SanJose123!');
  console.log('Profesor Pedro: pedro.garcia@sanjose.edu / Prof123!');
  console.log('Estudiantes: [nombre].[apellido]@sanjose.edu / Est123!');
}

main()
  .catch((e) => {
    console.error('❌ Error durante el seed:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });