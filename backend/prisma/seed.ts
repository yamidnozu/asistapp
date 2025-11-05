import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('��� Iniciando seed maestro de AsistApp V2...');

  // --- CAPA 1: INSTITUCIONES (El Fundamento) ---
  console.log('🏫 Creando instituciones de prueba...');

  let colegioSanJose = await prisma.institucion.findFirst({
    where: { nombre: 'Colegio San José (Activo)' }
  });
  if (!colegioSanJose) {
    colegioSanJose = await prisma.institucion.create({
      data: {
        nombre: 'Colegio San José (Activo)',
        direccion: 'Calle 123 #45-67, Bogotá',
        email: 'admin@sanjose.edu',
        telefono: '555-0101',
        activa: true,
      },
    });
  }

  let ieSantander = await prisma.institucion.findFirst({
    where: { nombre: 'IE Santander (Activa)' }
  });
  if (!ieSantander) {
    ieSantander = await prisma.institucion.create({
      data: {
        nombre: 'IE Santander (Activa)',
        direccion: 'Carrera 10 #20-30, Bucaramanga',
        email: 'admin@santander.edu',
        telefono: '555-0202',
        activa: true,
      },
    });
  }

  let liceoInactivo = await prisma.institucion.findFirst({
    where: { nombre: 'Liceo del Pasado (Inactivo)' }
  });
  if (!liceoInactivo) {
    liceoInactivo = await prisma.institucion.create({
      data: {
        nombre: 'Liceo del Pasado (Inactivo)',
        direccion: 'Avenida Siempre Viva 742, Ciudad Antigua',
        email: 'admin@inactivo.edu',
        telefono: '555-0303',
        activa: false,
      },
    });
  }

  console.log('✅ Instituciones creadas/verificados.');

  // --- CAPA 2: USUARIOS ADMINISTRATIVOS (Los Pilares) ---
  console.log('��� Creando usuarios administrativos...');

  // Super Admins
  const superAdmin = await prisma.usuario.upsert({
    where: { email: 'superadmin@asistapp.com' },
    update: {},
    create: {
      email: 'superadmin@asistapp.com',
      passwordHash: await bcrypt.hash('Admin123!', 10),
      nombres: 'Super',
      apellidos: 'Admin (Activo)',
      rol: 'super_admin',
      activo: true,
    },
  });

  const superAdminInactivo = await prisma.usuario.upsert({
    where: { email: 'inactive.super@asistapp.com' },
    update: {},
    create: {
      email: 'inactive.super@asistapp.com',
      passwordHash: await bcrypt.hash('InactiveSuper123!', 10),
      nombres: 'Super',
      apellidos: 'Admin (Inactivo)',
      rol: 'super_admin',
      activo: false,
    },
  });

  // Admins de Institución - Casos diversos
  const adminSanJose = await prisma.usuario.upsert({
    where: { email: 'admin@sanjose.edu' },
    update: {},
    create: {
      email: 'admin@sanjose.edu',
      passwordHash: await bcrypt.hash('SanJose123!', 10),
      nombres: 'María',
      apellidos: 'González (Admin Activo)',
      rol: 'admin_institucion',
      telefono: '555-0103',
      activo: true,
    },
  });
  await prisma.usuarioInstitucion.upsert({
    where: { usuarioId_institucionId: { usuarioId: adminSanJose.id, institucionId: colegioSanJose.id } },
    update: {},
    create: { usuarioId: adminSanJose.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' }
  });

  const adminInstitucionInactivo = await prisma.usuario.upsert({
    where: { email: 'inactive.admin@sanjose.edu' },
    update: {},
    create: {
      email: 'inactive.admin@sanjose.edu',
      passwordHash: await bcrypt.hash('InactiveAdmin123!', 10),
      nombres: 'Carlos',
      apellidos: 'Rodríguez (Admin Inactivo)',
      rol: 'admin_institucion',
      telefono: '555-0104',
      activo: false,
    },
  });
  await prisma.usuarioInstitucion.upsert({
    where: { usuarioId_institucionId: { usuarioId: adminInstitucionInactivo.id, institucionId: colegioSanJose.id } },
    update: {},
    create: { usuarioId: adminInstitucionInactivo.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' }
  });

  const adminDeInstitucionInactiva = await prisma.usuario.upsert({
    where: { email: 'admin@inactiva.edu' },
    update: {},
    create: {
      email: 'admin@inactiva.edu',
      passwordHash: await bcrypt.hash('AdminInactiva123!', 10),
      nombres: 'Ana',
      apellidos: 'López (Institución Inactiva)',
      rol: 'admin_institucion',
      telefono: '555-0304',
      activo: true,
    },
  });
  await prisma.usuarioInstitucion.upsert({
    where: { usuarioId_institucionId: { usuarioId: adminDeInstitucionInactiva.id, institucionId: liceoInactivo.id } },
    update: {},
    create: { usuarioId: adminDeInstitucionInactiva.id, institucionId: liceoInactivo.id, rolEnInstitucion: 'admin' }
  });

  const adminMulti = await prisma.usuario.upsert({
    where: { email: 'multi@asistapp.com' },
    update: {},
    create: {
      email: 'multi@asistapp.com',
      passwordHash: await bcrypt.hash('Multi123!', 10),
      nombres: 'Pedro',
      apellidos: 'Martínez (Multi-Institución)',
      rol: 'admin_institucion',
      telefono: '555-0505',
      activo: true,
    },
  });
  await prisma.usuarioInstitucion.upsert({
    where: { usuarioId_institucionId: { usuarioId: adminMulti.id, institucionId: colegioSanJose.id } },
    update: {},
    create: { usuarioId: adminMulti.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' }
  });
  await prisma.usuarioInstitucion.upsert({
    where: { usuarioId_institucionId: { usuarioId: adminMulti.id, institucionId: ieSantander.id } },
    update: {},
    create: { usuarioId: adminMulti.id, institucionId: ieSantander.id, rolEnInstitucion: 'admin' }
  });

  const adminMixto = await prisma.usuario.upsert({
    where: { email: 'admin.mixto@asistapp.com' },
    update: {},
    create: {
      email: 'admin.mixto@asistapp.com',
      passwordHash: await bcrypt.hash('AdminMixto123!', 10),
      nombres: 'Laura',
      apellidos: 'Sánchez (Admin Mixto)',
      rol: 'admin_institucion',
      telefono: '555-0606',
      activo: true,
    },
  });
  await prisma.usuarioInstitucion.upsert({
    where: { usuarioId_institucionId: { usuarioId: adminMixto.id, institucionId: colegioSanJose.id } },
    update: {},
    create: { usuarioId: adminMixto.id, institucionId: colegioSanJose.id, rolEnInstitucion: 'admin' }
  });
  await prisma.usuarioInstitucion.upsert({
    where: { usuarioId_institucionId: { usuarioId: adminMixto.id, institucionId: liceoInactivo.id } },
    update: {},
    create: { usuarioId: adminMixto.id, institucionId: liceoInactivo.id, rolEnInstitucion: 'admin' }
  });

  console.log('✅ Usuarios administrativos creados/verificados.');

  // --- CAPA 3: PROFESORES (El Personal Docente) ---
  console.log('���‍��� Creando profesores...');

  const profesoresData = [
    { email: 'juan.perez@sanjose.edu', nombres: 'Juan', apellidos: 'Pérez', activo: true, institucion: colegioSanJose },
    { email: 'maria.garcia@sanjose.edu', nombres: 'María', apellidos: 'García', activo: true, institucion: colegioSanJose },
    { email: 'carlos.lopez@sanjose.edu', nombres: 'Carlos', apellidos: 'López', activo: true, institucion: colegioSanJose },
    { email: 'profesor.inactivo@sanjose.edu', nombres: 'Miguel', apellidos: 'Torres (Inactivo)', activo: false, institucion: colegioSanJose },
    { email: 'sofia.ramirez@santander.edu', nombres: 'Sofía', apellidos: 'Ramírez', activo: true, institucion: ieSantander },
    { email: 'diego.morales@santander.edu', nombres: 'Diego', apellidos: 'Morales', activo: true, institucion: ieSantander },
  ];

  const profesores = [];
  for (const profData of profesoresData) {
    const profesor = await prisma.usuario.upsert({
      where: { email: profData.email },
      update: {},
      create: {
        email: profData.email,
        passwordHash: await bcrypt.hash('Prof123!', 10),
        nombres: profData.nombres,
        apellidos: profData.apellidos,
        rol: 'profesor',
        activo: profData.activo,
      },
    });

    await prisma.usuarioInstitucion.upsert({
      where: { usuarioId_institucionId: { usuarioId: profesor.id, institucionId: profData.institucion.id } },
      update: {},
      create: { usuarioId: profesor.id, institucionId: profData.institucion.id, rolEnInstitucion: 'profesor' }
    });

    profesores.push(profesor);
  }

  console.log('✅ Profesores creados:', profesores.length);

  // --- CAPA 4: ESTUDIANTES (El Alumnado) ---
  console.log('���‍��� Creando estudiantes...');

  const estudiantesData = [
    // Colegio San José (10 estudiantes, 1 inactivo)
    { email: 'santiago.gomez@sanjose.edu', nombres: 'Santiago', apellidos: 'Gómez', activo: true, institucion: colegioSanJose },
    { email: 'valeria.fernandez@sanjose.edu', nombres: 'Valeria', apellidos: 'Fernández', activo: true, institucion: colegioSanJose },
    { email: 'mateo.silva@sanjose.edu', nombres: 'Mateo', apellidos: 'Silva', activo: true, institucion: colegioSanJose },
    { email: 'isabella.ruiz@sanjose.edu', nombres: 'Isabella', apellidos: 'Ruiz', activo: true, institucion: colegioSanJose },
    { email: 'lucas.moreno@sanjose.edu', nombres: 'Lucas', apellidos: 'Moreno', activo: true, institucion: colegioSanJose },
    { email: 'mariana.jimenez@sanjose.edu', nombres: 'Mariana', apellidos: 'Jiménez', activo: true, institucion: colegioSanJose },
    { email: 'daniel.herrera@sanjose.edu', nombres: 'Daniel', apellidos: 'Herrera', activo: true, institucion: colegioSanJose },
    { email: 'gabriela.medina@sanjose.edu', nombres: 'Gabriela', apellidos: 'Medina', activo: true, institucion: colegioSanJose },
    { email: 'alejandro.castro@sanjose.edu', nombres: 'Alejandro', apellidos: 'Castro', activo: true, institucion: colegioSanJose },
    { email: 'estudiante.inactivo@sanjose.edu', nombres: 'Miguel', apellidos: 'Torres (Inactivo)', activo: false, institucion: colegioSanJose },

    // IE Santander (8 estudiantes)
    { email: 'leonardo.ramos@santander.edu', nombres: 'Leonardo', apellidos: 'Ramos', activo: true, institucion: ieSantander },
    { email: 'sara.torres@santander.edu', nombres: 'Sara', apellidos: 'Torres', activo: true, institucion: ieSantander },
    { email: 'emiliano.flores@santander.edu', nombres: 'Emiliano', apellidos: 'Flores', activo: true, institucion: ieSantander },
    { email: 'valentina.rivera@santander.edu', nombres: 'Valentina', apellidos: 'Rivera', activo: true, institucion: ieSantander },
    { email: 'diego.gutierrez@santander.edu', nombres: 'Diego', apellidos: 'Gutiérrez', activo: true, institucion: ieSantander },
    { email: 'camila.sanchez@santander.edu', nombres: 'Camila', apellidos: 'Sánchez', activo: true, institucion: ieSantander },
    { email: 'sebastian.romero@santander.edu', nombres: 'Sebastián', apellidos: 'Romero', activo: true, institucion: ieSantander },
    { email: 'lucia.diaz@santander.edu', nombres: 'Lucía', apellidos: 'Díaz', activo: true, institucion: ieSantander },
  ];

  const estudiantes = [];
  for (let i = 0; i < estudiantesData.length; i++) {
    const estData = estudiantesData[i];
    const estudianteUsuario = await prisma.usuario.upsert({
      where: { email: estData.email },
      update: {},
      create: {
        email: estData.email,
        passwordHash: await bcrypt.hash('Est123!', 10),
        nombres: estData.nombres,
        apellidos: estData.apellidos,
        rol: 'estudiante',
        activo: estData.activo,
      },
    });

    await prisma.usuarioInstitucion.upsert({
      where: { usuarioId_institucionId: { usuarioId: estudianteUsuario.id, institucionId: estData.institucion.id } },
      update: {},
      create: { usuarioId: estudianteUsuario.id, institucionId: estData.institucion.id, rolEnInstitucion: 'estudiante' }
    });

    const estudiante = await prisma.estudiante.upsert({
      where: { usuarioId: estudianteUsuario.id },
      update: {},
      create: {
        usuarioId: estudianteUsuario.id,
        identificacion: `ID${String(i + 1).padStart(3, '0')}`,
        codigoQr: `QR${String(i + 1).padStart(3, '0')}`,
        nombreResponsable: `Responsable ${estData.apellidos.split(' ')[0]}`,
        telefonoResponsable: `300-111-${String(i + 1).padStart(4, '0')}`,
      },
    });

    estudiantes.push({ usuario: estudianteUsuario, estudiante });
  }

  console.log('✅ Estudiantes creados:', estudiantes.length);

  // --- CAPA 5: PERIODOS ACADÉMICOS (El Tiempo Educativo) ---
  console.log('📅 Creando periodos académicos...');

  let periodoActual = await prisma.periodoAcademico.findFirst({
    where: { nombre: 'Periodo 2025-1', institucionId: colegioSanJose.id }
  });
  if (!periodoActual) {
    periodoActual = await prisma.periodoAcademico.create({
      data: {
        nombre: 'Periodo 2025-1',
        institucionId: colegioSanJose.id,
        fechaInicio: new Date('2025-01-15'),
        fechaFin: new Date('2025-06-15'),
        activo: true,
      },
    });
  }

  let periodoSantander = await prisma.periodoAcademico.findFirst({
    where: { nombre: 'Periodo 2025-1', institucionId: ieSantander.id }
  });
  if (!periodoSantander) {
    periodoSantander = await prisma.periodoAcademico.create({
      data: {
        nombre: 'Periodo 2025-1',
        institucionId: ieSantander.id,
        fechaInicio: new Date('2025-01-15'),
        fechaFin: new Date('2025-06-15'),
        activo: true,
      },
    });
  }

  console.log('✅ Periodos académicos creados.');

  // --- CAPA 6: GRUPOS (Las Clases) ---
  console.log('👥 Creando grupos...');

  let grupoA = await prisma.grupo.findFirst({
    where: { nombre: 'Grupo A', institucionId: colegioSanJose.id }
  });
  if (!grupoA) {
    grupoA = await prisma.grupo.create({
      data: {
        nombre: 'Grupo A',
        grado: '1ro',
        seccion: 'A',
        institucionId: colegioSanJose.id,
        periodoId: periodoActual.id,
      },
    });
  }

  let grupoB = await prisma.grupo.findFirst({
    where: { nombre: 'Grupo B', institucionId: colegioSanJose.id }
  });
  if (!grupoB) {
    grupoB = await prisma.grupo.create({
      data: {
        nombre: 'Grupo B',
        grado: '2do',
        seccion: 'B',
        institucionId: colegioSanJose.id,
        periodoId: periodoActual.id,
      },
    });
  }

  console.log('✅ Grupos creados.');

  // --- CAPA 7: ASIGNACIÓN DE ESTUDIANTES A GRUPOS ---
  console.log('🔗 Asignando estudiantes a grupos...');

  // Grupo A - primeros 5 estudiantes
  for (let i = 0; i < 5; i++) {
    const existing = await prisma.estudianteGrupo.findFirst({
      where: {
        estudianteId: estudiantes[i].estudiante.id,
        grupoId: grupoA.id
      }
    });
    if (!existing) {
      await prisma.estudianteGrupo.create({
        data: {
          estudianteId: estudiantes[i].estudiante.id,
          grupoId: grupoA.id,
        },
      });
    }
  }

  // Grupo B - siguientes 4 estudiantes
  for (let i = 5; i < 9; i++) {
    const existing = await prisma.estudianteGrupo.findFirst({
      where: {
        estudianteId: estudiantes[i].estudiante.id,
        grupoId: grupoB.id
      }
    });
    if (!existing) {
      await prisma.estudianteGrupo.create({
        data: {
          estudianteId: estudiantes[i].estudiante.id,
          grupoId: grupoB.id,
        },
      });
    }
  }

  console.log('✅ Estudiantes asignados a grupos.');

  // --- CAPA 8: MATERIAS (Las Asignaturas) ---
  console.log('📚 Creando materias...');

  const materiasData = [
    { nombre: 'Matemáticas', codigo: 'MAT101', institucion: colegioSanJose },
    { nombre: 'Física', codigo: 'FIS101', institucion: colegioSanJose },
    { nombre: 'Biología', codigo: 'BIO101', institucion: colegioSanJose },
    { nombre: 'Historia', codigo: 'HIS101', institucion: colegioSanJose },
    { nombre: 'Química', codigo: 'QUI101', institucion: colegioSanJose },
  ];

  const materias = [];
  for (const matData of materiasData) {
    let materia = await prisma.materia.findFirst({
      where: {
        nombre: matData.nombre,
        institucionId: matData.institucion.id
      }
    });
    if (!materia) {
      materia = await prisma.materia.create({
        data: {
          nombre: matData.nombre,
          codigo: matData.codigo,
          institucionId: matData.institucion.id,
        },
      });
    }
    materias.push(materia);
  }

  console.log('✅ Materias creadas:', materias.length);

  // --- CAPA 9: HORARIOS (El Calendario) ---
  console.log('📅 Creando horarios...');

  const horariosData = [
    // Lunes - Grupo A
    { diaSemana: 1, horaInicio: '08:00', horaFin: '09:00', materia: materias[0], profesor: profesores[0], grupo: grupoA }, // Matemáticas - Juan Pérez
    { diaSemana: 1, horaInicio: '09:00', horaFin: '10:00', materia: materias[1], profesor: profesores[1], grupo: grupoA }, // Física - María García

    // Martes - Grupo A
    { diaSemana: 2, horaInicio: '08:00', horaFin: '09:00', materia: materias[2], profesor: profesores[1], grupo: grupoA }, // Biología - María García
    { diaSemana: 2, horaInicio: '09:00', horaFin: '10:00', materia: materias[3], profesor: profesores[2], grupo: grupoA }, // Historia - Carlos López

    // Miércoles - Grupo A
    { diaSemana: 3, horaInicio: '08:00', horaFin: '09:00', materia: materias[1], profesor: profesores[1], grupo: grupoA }, // Física - María García

    // Viernes - Grupo A
    { diaSemana: 5, horaInicio: '14:00', horaFin: '15:00', materia: materias[2], profesor: profesores[2], grupo: grupoA }, // Biología - Carlos López

    // Sábado - Grupo A
    { diaSemana: 6, horaInicio: '16:00', horaFin: '17:00', materia: materias[2], profesor: profesores[2], grupo: grupoA }, // Biología - Carlos López

    // Lunes - Grupo B
    { diaSemana: 1, horaInicio: '10:00', horaFin: '11:00', materia: materias[0], profesor: profesores[0], grupo: grupoB }, // Matemáticas - Juan Pérez
    { diaSemana: 1, horaInicio: '11:00', horaFin: '12:00', materia: materias[4], profesor: profesores[1], grupo: grupoB }, // Química - María García
  ];

  const horarios = [];
  for (const horData of horariosData) {
    const existing = await prisma.horario.findFirst({
      where: {
        grupoId: horData.grupo.id,
        materiaId: horData.materia.id,
        diaSemana: horData.diaSemana,
        horaInicio: horData.horaInicio,
      }
    });
    if (!existing) {
      const horario = await prisma.horario.create({
        data: {
          institucionId: horData.grupo.institucionId,
          periodoId: horData.grupo.periodoId,
          grupoId: horData.grupo.id,
          materiaId: horData.materia.id,
          profesorId: horData.profesor.id,
          diaSemana: horData.diaSemana,
          horaInicio: horData.horaInicio,
          horaFin: horData.horaFin,
        },
      });
      horarios.push(horario);
    }
  }

  console.log('✅ Horarios creados:', horarios.length);

  console.log('\n��� Seed maestro completado exitosamente!');
  console.log('\n��� Resumen del universo de pruebas creado:');
  console.log('��� Instituciones:', 3, '(2 activas, 1 inactiva)');
  console.log('��� Super Admins:', 2, '(1 activo, 1 inactivo)');
  console.log('���‍��� Admins de Institución:', 5, '(casos diversos de actividad y multi-institución)');
  console.log('���‍��� Profesores:', profesores.length, '(distribuidos en instituciones activas)');
  console.log('���‍��� Estudiantes:', estudiantes.length, '(18 estudiantes en instituciones activas)');
  console.log('📅 Periodos Académicos:', 2, '(1 por institución activa)');
  console.log('👥 Grupos:', 2, '(Grupo A y Grupo B en San José)');
  console.log('📚 Materias:', materias.length, '(5 materias básicas)');
  console.log('📅 Horarios:', horarios.length, '(horarios de ejemplo creados)');

  console.log('\n��� Credenciales de acceso de prueba:');
  console.log('\n��� SUPER ADMINS:');
  console.log('Super Admin (Activo): superadmin@asistapp.com / Admin123!');
  console.log('Super Admin (Inactivo): inactive.super@asistapp.com / InactiveSuper123!');

  console.log('\n���‍��� ADMINS DE INSTITUCIÓN:');
  console.log('Admin Simple (Activo): admin@sanjose.edu / SanJose123!');
  console.log('Admin Usuario Inactivo: inactive.admin@sanjose.edu / InactiveAdmin123!');
  console.log('Admin Institución Inactiva: admin@inactiva.edu / AdminInactiva123!');
  console.log('Admin Multi-Institución: multi@asistapp.com / Multi123!');
  console.log('Admin Mixto: admin.mixto@asistapp.com / AdminMixto123!');

  console.log('\n���‍��� PROFESORES:');
  console.log('Profesores Activos: [nombre].[apellido]@sanjose.edu / Prof123!');
  console.log('Profesor Inactivo: profesor.inactivo@sanjose.edu / Prof123!');

  console.log('\n���‍��� ESTUDIANTES:');
  console.log('Estudiantes Activos: [nombre].[apellido]@sanjose.edu / Est123!');
  console.log('Estudiante Inactivo: estudiante.inactivo@sanjose.edu / Est123!');
}

main()
  .catch((e) => {
    console.error('❌ Error durante el seed:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
