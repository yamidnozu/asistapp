#!/usr/bin/env ts-node

/**
 * SETUP COMPLETO PARA PRUEBAS EXHAUSTIVAS DE FLUJOS COMPLETOS - AsistApp Backend
 * Configura un universo completo de datos para testing: instituciones, usuarios, grupos, materias, horarios, etc.
 *
 * Ejecutar con: npx ts-node setup-test-data.ts
 */

import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function setupCompleteTestData() {
  console.log('🚀 Iniciando setup completo de datos de prueba...\n');

  try {
    // === FASE 1: INSTITUCIONES ===
    console.log('🏫 FASE 1: Creando instituciones...');

    const instituciones = [
      {
        nombre: 'Colegio San José',
        direccion: 'Calle 123 #45-67, Bogotá',
        email: 'admin@sanjose.edu',
        telefono: '555-0101',
        activa: true,
      },
      {
        nombre: 'Liceo Nacional',
        direccion: 'Carrera 10 #20-30, Medellín',
        email: 'admin@liceonacional.edu',
        telefono: '555-0202',
        activa: true,
      },
      {
        nombre: 'Instituto Tecnológico',
        direccion: 'Avenida Siempre Viva 742, Cali',
        email: 'admin@institutotecnologico.edu',
        telefono: '555-0303',
        activa: false, // Institución inactiva para pruebas
      },
    ];

    const institucionesCreadas: any[] = [];
    for (const instData of instituciones) {
      let institucion = await prisma.institucion.findFirst({
        where: { nombre: instData.nombre }
      });

      if (!institucion) {
        institucion = await prisma.institucion.create({ data: instData });
        console.log(`   ✅ Institución creada: ${instData.nombre}`);
      } else {
        console.log(`   ✅ Institución ya existe: ${instData.nombre}`);
      }
      institucionesCreadas.push(institucion);
    }

    // === FASE 2: PERIODOS ACADÉMICOS ===
    console.log('\n📅 FASE 2: Creando periodos académicos...');

    const periodos = [];
    for (const institucion of institucionesCreadas.filter(i => i.activa)) {
      let periodo = await prisma.periodoAcademico.findFirst({
        where: {
          institucionId: institucion.id,
          activo: true
        }
      });

      if (!periodo) {
        const fechaInicio = new Date();
        const fechaFin = new Date();
        fechaFin.setMonth(fechaFin.getMonth() + 6);

        periodo = await prisma.periodoAcademico.create({
          data: {
            nombre: `Periodo ${new Date().getFullYear()}-1`,
            fechaInicio,
            fechaFin,
            activo: true,
            institucionId: institucion.id,
          },
        });
        console.log(`   ✅ Periodo creado para ${institucion.nombre}`);
      } else {
        console.log(`   ✅ Periodo ya existe para ${institucion.nombre}`);
      }
      periodos.push({ institucion, periodo });
    }

    // === FASE 3: USUARIOS COMPLETOS ===
    console.log('\n👥 FASE 3: Creando usuarios completos...');

    // Super Admin
    const superAdminPassword = await bcrypt.hash('SuperAdmin123!', 10);
    const superAdmin = await prisma.usuario.upsert({
      where: { email: 'superadmin@asistapp.com' },
      update: { passwordHash: superAdminPassword },
      create: {
        email: 'superadmin@asistapp.com',
        passwordHash: superAdminPassword,
        nombres: 'Super',
        apellidos: 'Admin',
        rol: 'super_admin',
        activo: true,
      },
    });
    console.log('   ✅ Super Admin creado');

    // Admins de Institución
    const adminsData = [
      { email: 'admin@sanjose.edu', nombres: 'María', apellidos: 'González', institucion: institucionesCreadas[0] },
      { email: 'admin@liceonacional.edu', nombres: 'Carlos', apellidos: 'Rodríguez', institucion: institucionesCreadas[1] },
    ];

    const admins = [];
    for (const adminData of adminsData) {
      const adminPassword = await bcrypt.hash('Admin123!', 10);
      const admin = await prisma.usuario.upsert({
        where: { email: adminData.email },
        update: { passwordHash: adminPassword },
        create: {
          email: adminData.email,
          passwordHash: adminPassword,
          nombres: adminData.nombres,
          apellidos: adminData.apellidos,
          rol: 'admin_institucion',
          activo: true,
        },
      });

      await prisma.usuarioInstitucion.upsert({
        where: {
          usuarioId_institucionId: {
            usuarioId: admin.id,
            institucionId: adminData.institucion.id
          }
        },
        update: {},
        create: {
          usuarioId: admin.id,
          institucionId: adminData.institucion.id,
          rolEnInstitucion: 'admin'
        }
      });

      admins.push(admin);
      console.log(`   ✅ Admin creado: ${adminData.email}`);
    }

    // Profesores
    const profesoresData = [
      { email: 'ana.lopez@sanjose.edu', nombres: 'Ana', apellidos: 'López', institucion: institucionesCreadas[0] },
      { email: 'pedro.garcia@sanjose.edu', nombres: 'Pedro', apellidos: 'García', institucion: institucionesCreadas[0] },
      { email: 'maria.rodriguez@sanjose.edu', nombres: 'María', apellidos: 'Rodríguez', institucion: institucionesCreadas[0] },
      { email: 'juan.martinez@liceonacional.edu', nombres: 'Juan', apellidos: 'Martínez', institucion: institucionesCreadas[1] },
      { email: 'laura.sanchez@liceonacional.edu', nombres: 'Laura', apellidos: 'Sánchez', institucion: institucionesCreadas[1] },
    ];

    const profesores = [];
    for (const profData of profesoresData) {
      const profPassword = await bcrypt.hash('Prof123!', 10);
      const profesor = await prisma.usuario.upsert({
        where: { email: profData.email },
        update: { passwordHash: profPassword },
        create: {
          email: profData.email,
          passwordHash: profPassword,
          nombres: profData.nombres,
          apellidos: profData.apellidos,
          rol: 'profesor',
          activo: true,
        },
      });

      await prisma.usuarioInstitucion.upsert({
        where: {
          usuarioId_institucionId: {
            usuarioId: profesor.id,
            institucionId: profData.institucion.id
          }
        },
        update: {},
        create: {
          usuarioId: profesor.id,
          institucionId: profData.institucion.id,
          rolEnInstitucion: 'profesor'
        }
      });

      profesores.push(profesor);
      console.log(`   ✅ Profesor creado: ${profData.email}`);
    }

    // Estudiantes
    const estudiantesData = [
      // Colegio San José
      { email: 'juan.perez@sanjose.edu', nombres: 'Juan', apellidos: 'Pérez', institucion: institucionesCreadas[0] },
      { email: 'maria.gomez@sanjose.edu', nombres: 'María', apellidos: 'Gómez', institucion: institucionesCreadas[0] },
      { email: 'carlos.lopez@sanjose.edu', nombres: 'Carlos', apellidos: 'López', institucion: institucionesCreadas[0] },
      { email: 'ana.martinez@sanjose.edu', nombres: 'Ana', apellidos: 'Martínez', institucion: institucionesCreadas[0] },
      { email: 'luis.rodriguez@sanjose.edu', nombres: 'Luis', apellidos: 'Rodríguez', institucion: institucionesCreadas[0] },

      // Liceo Nacional
      { email: 'sofia.garcia@liceonacional.edu', nombres: 'Sofía', apellidos: 'García', institucion: institucionesCreadas[1] },
      { email: 'mateo.silva@liceonacional.edu', nombres: 'Mateo', apellidos: 'Silva', institucion: institucionesCreadas[1] },
      { email: 'valentina.moreno@liceonacional.edu', nombres: 'Valentina', apellidos: 'Moreno', institucion: institucionesCreadas[1] },
    ];

    const estudiantes = [];
    for (let i = 0; i < estudiantesData.length; i++) {
      const estData = estudiantesData[i];
      const estPassword = await bcrypt.hash('Est123!', 10);
      const estudianteUsuario = await prisma.usuario.upsert({
        where: { email: estData.email },
        update: { passwordHash: estPassword },
        create: {
          email: estData.email,
          passwordHash: estPassword,
          nombres: estData.nombres,
          apellidos: estData.apellidos,
          rol: 'estudiante',
          activo: true,
        },
      });

      await prisma.usuarioInstitucion.upsert({
        where: {
          usuarioId_institucionId: {
            usuarioId: estudianteUsuario.id,
            institucionId: estData.institucion.id
          }
        },
        update: {},
        create: {
          usuarioId: estudianteUsuario.id,
          institucionId: estData.institucion.id,
          rolEnInstitucion: 'estudiante'
        }
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
      console.log(`   ✅ Estudiante creado: ${estData.email}`);
    }

    // === FASE 4: MATERIAS ===
    console.log('\n📚 FASE 4: Creando materias...');

    const materiasData = [
      { nombre: 'Matemáticas', codigo: 'MAT101', institucion: institucionesCreadas[0] },
      { nombre: 'Física', codigo: 'FIS101', institucion: institucionesCreadas[0] },
      { nombre: 'Química', codigo: 'QUI101', institucion: institucionesCreadas[0] },
      { nombre: 'Biología', codigo: 'BIO101', institucion: institucionesCreadas[0] },
      { nombre: 'Historia', codigo: 'HIS101', institucion: institucionesCreadas[0] },
      { nombre: 'Español', codigo: 'ESP101', institucion: institucionesCreadas[1] },
      { nombre: 'Inglés', codigo: 'ING101', institucion: institucionesCreadas[1] },
      { nombre: 'Programación', codigo: 'PRO101', institucion: institucionesCreadas[1] },
    ];

    const materias = [];
    for (const matData of materiasData) {
      const existingMateria = await prisma.materia.findFirst({
        where: {
          nombre: matData.nombre,
          institucionId: matData.institucion.id
        }
      });

      if (!existingMateria) {
        const materia = await prisma.materia.create({
          data: {
            nombre: matData.nombre,
            codigo: matData.codigo,
            institucionId: matData.institucion.id,
          },
        });
        materias.push(materia);
        console.log(`   ✅ Materia creada: ${matData.nombre} (${matData.institucion.nombre})`);
      } else {
        materias.push(existingMateria);
        console.log(`   ✅ Materia ya existe: ${matData.nombre}`);
      }
    }

    // === FASE 5: GRUPOS ===
    console.log('\n🏫 FASE 5: Creando grupos...');

    const gruposData = [];
    for (const { institucion, periodo } of periodos) {
      const gruposInstitucion = [
        { nombre: 'Grupo A', grado: '1ro', seccion: 'A' },
        { nombre: 'Grupo B', grado: '1ro', seccion: 'B' },
        { nombre: 'Grupo C', grado: '2do', seccion: 'A' },
        { nombre: 'Grupo D', grado: '2do', seccion: 'B' },
      ];

      for (const grupoData of gruposInstitucion) {
        const existingGrupo = await prisma.grupo.findFirst({
          where: {
            nombre: grupoData.nombre,
            institucionId: institucion.id
          }
        });

        if (!existingGrupo) {
          const grupo = await prisma.grupo.create({
            data: {
              nombre: grupoData.nombre,
              grado: grupoData.grado,
              seccion: grupoData.seccion,
              periodoId: periodo.id,
              institucionId: institucion.id,
            },
          });
          gruposData.push(grupo);
          console.log(`   ✅ Grupo creado: ${grupoData.nombre} (${institucion.nombre})`);
        } else {
          gruposData.push(existingGrupo);
          console.log(`   ✅ Grupo ya existe: ${grupoData.nombre}`);
        }
      }
    }

    // === FASE 6: ASIGNAR ESTUDIANTES A GRUPOS ===
    console.log('\n👨‍🎓 FASE 6: Asignando estudiantes a grupos...');

    // Colegio San José - Grupo A: estudiantes 0-2
    const grupoSanJoseA = gruposData.find(g => g.nombre === 'Grupo A' && g.institucionId === institucionesCreadas[0].id);
    if (grupoSanJoseA) {
      for (let i = 0; i < 3; i++) {
        const estudiante = estudiantes[i];
        if (estudiante) {
          const existingAsignacion = await prisma.estudianteGrupo.findFirst({
            where: {
              estudianteId: estudiante.estudiante.id,
              grupoId: grupoSanJoseA.id
            }
          });

          if (!existingAsignacion) {
            await prisma.estudianteGrupo.create({
              data: {
                estudianteId: estudiante.estudiante.id,
                grupoId: grupoSanJoseA.id,
              },
            });
          }
          console.log(`   ✅ Estudiante ${estudiante.usuario.email} asignado a ${grupoSanJoseA.nombre}`);
        }
      }
    }

    // Colegio San José - Grupo B: estudiantes 3-4
    const grupoSanJoseB = gruposData.find(g => g.nombre === 'Grupo B' && g.institucionId === institucionesCreadas[0].id);
    if (grupoSanJoseB) {
      for (let i = 3; i < 5; i++) {
        const estudiante = estudiantes[i];
        if (estudiante) {
          const existingAsignacion = await prisma.estudianteGrupo.findFirst({
            where: {
              estudianteId: estudiante.estudiante.id,
              grupoId: grupoSanJoseB.id
            }
          });

          if (!existingAsignacion) {
            await prisma.estudianteGrupo.create({
              data: {
                estudianteId: estudiante.estudiante.id,
                grupoId: grupoSanJoseB.id,
              },
            });
          }
          console.log(`   ✅ Estudiante ${estudiante.usuario.email} asignado a ${grupoSanJoseB.nombre}`);
        }
      }
    }

    // Liceo Nacional - Grupo A: estudiantes 5-7
    const grupoLiceoA = gruposData.find(g => g.nombre === 'Grupo A' && g.institucionId === institucionesCreadas[1].id);
    if (grupoLiceoA) {
      for (let i = 5; i < 8; i++) {
        const estudiante = estudiantes[i];
        if (estudiante) {
          const existingAsignacion = await prisma.estudianteGrupo.findFirst({
            where: {
              estudianteId: estudiante.estudiante.id,
              grupoId: grupoLiceoA.id
            }
          });

          if (!existingAsignacion) {
            await prisma.estudianteGrupo.create({
              data: {
                estudianteId: estudiante.estudiante.id,
                grupoId: grupoLiceoA.id,
              },
            });
          }
          console.log(`   ✅ Estudiante ${estudiante.usuario.email} asignado a ${grupoLiceoA.nombre}`);
        }
      }
    }

    // === FASE 7: HORARIOS COMPLETOS ===
    console.log('\n📅 FASE 7: Creando horarios completos...');

    // Horarios para Colegio San José
    const horariosSanJose = [
      // Lunes
      { grupo: grupoSanJoseA, materia: materias[0], profesor: profesores[0], diaSemana: 1, horaInicio: '08:00', horaFin: '09:00' },
      { grupo: grupoSanJoseA, materia: materias[1], profesor: profesores[1], diaSemana: 1, horaInicio: '09:00', horaFin: '10:00' },
      { grupo: grupoSanJoseB, materia: materias[2], profesor: profesores[2], diaSemana: 1, horaInicio: '08:00', horaFin: '09:00' },

      // Martes
      { grupo: grupoSanJoseA, materia: materias[3], profesor: profesores[0], diaSemana: 2, horaInicio: '08:00', horaFin: '09:00' },
      { grupo: grupoSanJoseA, materia: materias[4], profesor: profesores[1], diaSemana: 2, horaInicio: '09:00', horaFin: '10:00' },
      { grupo: grupoSanJoseB, materia: materias[0], profesor: profesores[2], diaSemana: 2, horaInicio: '08:00', horaFin: '09:00' },

      // Miércoles
      { grupo: grupoSanJoseA, materia: materias[1], profesor: profesores[0], diaSemana: 3, horaInicio: '08:00', horaFin: '09:00' },
      { grupo: grupoSanJoseB, materia: materias[3], profesor: profesores[1], diaSemana: 3, horaInicio: '08:00', horaFin: '09:00' },
    ];

    for (const horarioData of horariosSanJose) {
      if (horarioData.grupo && horarioData.materia && horarioData.profesor) {
        const existingHorario = await prisma.horario.findFirst({
          where: {
            grupoId: horarioData.grupo.id,
            materiaId: horarioData.materia.id,
            diaSemana: horarioData.diaSemana,
            horaInicio: horarioData.horaInicio,
          }
        });

        if (!existingHorario) {
          await prisma.horario.create({
            data: {
              periodoId: horarioData.grupo.periodoId,
              grupoId: horarioData.grupo.id,
              materiaId: horarioData.materia.id,
              profesorId: horarioData.profesor.id,
              diaSemana: horarioData.diaSemana,
              horaInicio: horarioData.horaInicio,
              horaFin: horarioData.horaFin,
              institucionId: horarioData.grupo.institucionId,
            },
          });
          console.log(`   ✅ Horario creado: ${horarioData.materia.nombre} - ${horarioData.grupo.nombre} (${horarioData.profesor.email})`);
        } else {
          console.log(`   ✅ Horario ya existe: ${horarioData.materia.nombre} - ${horarioData.grupo.nombre}`);
        }
      }
    }

    // Horarios para Liceo Nacional
    const horariosLiceo = [
      { grupo: grupoLiceoA, materia: materias[5], profesor: profesores[3], diaSemana: 1, horaInicio: '08:00', horaFin: '09:00' },
      { grupo: grupoLiceoA, materia: materias[6], profesor: profesores[4], diaSemana: 1, horaInicio: '09:00', horaFin: '10:00' },
      { grupo: grupoLiceoA, materia: materias[7], profesor: profesores[3], diaSemana: 2, horaInicio: '08:00', horaFin: '09:00' },
    ];

    for (const horarioData of horariosLiceo) {
      if (horarioData.grupo && horarioData.materia && horarioData.profesor) {
        const existingHorario = await prisma.horario.findFirst({
          where: {
            grupoId: horarioData.grupo.id,
            materiaId: horarioData.materia.id,
            diaSemana: horarioData.diaSemana,
            horaInicio: horarioData.horaInicio,
          }
        });

        if (!existingHorario) {
          await prisma.horario.create({
            data: {
              periodoId: horarioData.grupo.periodoId,
              grupoId: horarioData.grupo.id,
              materiaId: horarioData.materia.id,
              profesorId: horarioData.profesor.id,
              diaSemana: horarioData.diaSemana,
              horaInicio: horarioData.horaInicio,
              horaFin: horarioData.horaFin,
              institucionId: horarioData.grupo.institucionId,
            },
          });
          console.log(`   ✅ Horario creado: ${horarioData.materia.nombre} - ${horarioData.grupo.nombre} (${horarioData.profesor.email})`);
        } else {
          console.log(`   ✅ Horario ya existe: ${horarioData.materia.nombre} - ${horarioData.grupo.nombre}`);
        }
      }
    }

    // === FASE 8: VERIFICACIÓN FINAL ===
    console.log('\n✅ FASE 8: Verificación final...');

    const stats = {
      instituciones: await prisma.institucion.count(),
      usuarios: await prisma.usuario.count(),
      periodos: await prisma.periodoAcademico.count(),
      profesores: await prisma.usuario.count({ where: { rol: 'profesor' } }),
      estudiantes: await prisma.estudiante.count(),
      materias: await prisma.materia.count(),
      grupos: await prisma.grupo.count(),
      horarios: await prisma.horario.count(),
      asignaciones: await prisma.estudianteGrupo.count(),
    };

    console.log('📊 Estadísticas del universo de pruebas:');
    console.log(`   🏫 Instituciones: ${stats.instituciones}`);
    console.log(`   👥 Usuarios totales: ${stats.usuarios}`);
    console.log(`   📅 Periodos académicos: ${stats.periodos}`);
    console.log(`   👨‍🏫 Profesores: ${stats.profesores}`);
    console.log(`   👨‍🎓 Estudiantes: ${stats.estudiantes}`);
    console.log(`   📚 Materias: ${stats.materias}`);
    console.log(`   🏫 Grupos: ${stats.grupos}`);
    console.log(`   📅 Horarios: ${stats.horarios}`);
    console.log(`   🔗 Asignaciones estudiante-grupo: ${stats.asignaciones}`);

    console.log('\n🎉 Setup completo exitosamente!');
    console.log('\n📋 CREDENCIALES DE PRUEBA:');
    console.log('\n🔑 SUPER ADMIN:');
    console.log('   superadmin@asistapp.com / SuperAdmin123!');

    console.log('\n👨‍💼 ADMINS DE INSTITUCIÓN:');
    console.log('   admin@sanjose.edu / Admin123!');
    console.log('   admin@liceonacional.edu / Admin123!');

    console.log('\n👨‍🏫 PROFESORES:');
    console.log('   ana.lopez@sanjose.edu / Prof123!');
    console.log('   pedro.garcia@sanjose.edu / Prof123!');
    console.log('   maria.rodriguez@sanjose.edu / Prof123!');
    console.log('   juan.martinez@liceonacional.edu / Prof123!');
    console.log('   laura.sanchez@liceonacional.edu / Prof123!');

    console.log('\n👨‍🎓 ESTUDIANTES:');
    console.log('   juan.perez@sanjose.edu / Est123!');
    console.log('   maria.gomez@sanjose.edu / Est123!');
    console.log('   carlos.lopez@sanjose.edu / Est123!');
    console.log('   ana.martinez@sanjose.edu / Est123!');
    console.log('   luis.rodriguez@sanjose.edu / Est123!');
    console.log('   sofia.garcia@liceonacional.edu / Est123!');
    console.log('   mateo.silva@liceonacional.edu / Est123!');
    console.log('   valentina.moreno@liceonacional.edu / Est123!');

    console.log('\n🏫 INSTITUCIONES Y GRUPOS:');
    console.log('   📚 Colegio San José: Grupos A, B, C, D');
    console.log('   📚 Liceo Nacional: Grupos A, B, C, D');
    console.log('   📅 Horarios completos para identificar clases en tiempo real');

  } catch (error) {
    console.error('❌ Error durante el setup:', error);
    throw error;
  } finally {
    await prisma.$disconnect();
  }
}

// Ejecutar setup
setupCompleteTestData().catch(console.error);