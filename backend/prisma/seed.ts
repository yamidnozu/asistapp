import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Iniciando seed de AsistApp V2...');
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
  console.log('👥 Creando usuario multi-institución...');

  const multiUserPassword = await bcrypt.hash('Multi123!', 10);

  const multiUser = await prisma.usuario.upsert({
    where: { email: 'multi@asistapp.com' },
    update: {},
    create: {
      email: 'multi@asistapp.com',
      passwordHash: multiUserPassword,
      nombres: 'Usuario',
      apellidos: 'Multi',
      rol: 'admin_institucion',
      activo: true,
    },
  });
  await Promise.all([
    prisma.usuarioInstitucion.upsert({
      where: {
        usuarioId_institucionId: {
          usuarioId: multiUser.id,
          institucionId: instituciones[0].id,
        },
      },
      update: {},
      create: {
        usuarioId: multiUser.id,
        institucionId: instituciones[0].id,
        rolEnInstitucion: 'admin',
        activo: true,
      },
    }),
    prisma.usuarioInstitucion.upsert({
      where: {
        usuarioId_institucionId: {
          usuarioId: multiUser.id,
          institucionId: instituciones[1].id,
        },
      },
      update: {},
      create: {
        usuarioId: multiUser.id,
        institucionId: instituciones[1].id,
        rolEnInstitucion: 'admin',
        activo: true,
      },
    }),
  ]);

  console.log('✅ Usuario multi-institución creado:', multiUser.email);
  console.log('👨‍💼 Creando admins de institución...');

  const adminSanJosePassword = await bcrypt.hash('SanJose123!', 10);
  const adminFpsPassword = await bcrypt.hash('Fps123!', 10);

  const adminsInstitucion = await Promise.all([
    prisma.usuario.upsert({
      where: { email: 'admin@sanjose.edu' },
      update: {},
      create: {
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
  await Promise.all([
    prisma.usuarioInstitucion.upsert({
      where: {
        usuarioId_institucionId: {
          usuarioId: adminsInstitucion[0].id,
          institucionId: instituciones[0].id,
        },
      },
      update: {},
      create: {
        usuarioId: adminsInstitucion[0].id,
        institucionId: instituciones[0].id,
        rolEnInstitucion: 'admin',
        activo: true,
      },
    }),
    prisma.usuarioInstitucion.upsert({
      where: {
        usuarioId_institucionId: {
          usuarioId: adminsInstitucion[1].id,
          institucionId: instituciones[1].id,
        },
      },
      update: {},
      create: {
        usuarioId: adminsInstitucion[1].id,
        institucionId: instituciones[1].id,
        rolEnInstitucion: 'admin',
        activo: true,
      },
    }),
  ]);

  console.log('✅ Admins de institución creados:', adminsInstitucion.length);
  console.log('👨‍🏫 Creando profesores...');

  const profesor1Password = await bcrypt.hash('Prof123!', 10);
  const profesor2Password = await bcrypt.hash('Prof456!', 10);

  const profesores = await Promise.all([
    prisma.usuario.upsert({
      where: { email: 'pedro.garcia@sanjose.edu' },
      update: {},
      create: {
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
  await Promise.all([
    prisma.usuarioInstitucion.upsert({
      where: {
        usuarioId_institucionId: {
          usuarioId: profesores[0].id,
          institucionId: instituciones[0].id,
        },
      },
      update: {},
      create: {
        usuarioId: profesores[0].id,
        institucionId: instituciones[0].id,
        rolEnInstitucion: 'profesor',
        activo: true,
      },
    }),
    prisma.usuarioInstitucion.upsert({
      where: {
        usuarioId_institucionId: {
          usuarioId: profesores[1].id,
          institucionId: instituciones[0].id,
        },
      },
      update: {},
      create: {
        usuarioId: profesores[1].id,
        institucionId: instituciones[0].id,
        rolEnInstitucion: 'profesor',
        activo: true,
      },
    }),
  ]);

  console.log('✅ Profesores creados:', profesores.length);
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
        email: `${estudianteData.nombres.toLowerCase()}.${estudianteData.apellidos.toLowerCase()}@sanjose.edu`,
        passwordHash: estudiantePassword,
        nombres: estudianteData.nombres,
        apellidos: estudianteData.apellidos,
        rol: 'estudiante',
        activo: true,
      },
    });
    await prisma.usuarioInstitucion.upsert({
      where: {
        usuarioId_institucionId: {
          usuarioId: usuario.id,
          institucionId: instituciones[0].id,
        },
      },
      update: {},
      create: {
        usuarioId: usuario.id,
        institucionId: instituciones[0].id,
        rolEnInstitucion: 'estudiante',
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
  console.log('📅 Creando periodos académicos...');

  console.log('📅 Periodos académicos saltados temporalmente');

  const periodos = [{ id: 'temp-id' }]; // Temporal
  console.log('👥 Creando grupos...');

  console.log('👥 Grupos saltados temporalmente');

  const grupos = [{ id: 'temp-id' }]; // Temporal
  console.log('📚 Creando materias...');

  console.log('📚 Materias saltadas temporalmente');

  const materias = [{ id: 'temp-id' }]; // Temporal
  console.log('⏰ Creando horarios...');

  console.log('⏰ Horarios saltados temporalmente');
  console.log('🔗 Asignando estudiantes a grupos...');

  console.log('🔗 Estudiantes asignados a grupos (saltado)');
  console.log('📝 Creando asistencias de ejemplo...');

  console.log('📝 Asistencias de ejemplo creadas (saltado)');
  console.log('⚙️ Creando configuraciones...');

  console.log('⚙️ Configuraciones creadas (saltado)');
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
  console.log('Admin FPS: admin@fps.edu / Fps123!');
  console.log('Usuario Multi-institución: multi@asistapp.com / Multi123!');
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