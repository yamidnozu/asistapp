import { prisma } from './src/config/database';

async function showStudentExample() {
  try {
    console.log('🎓 EJEMPLO: ESTUDIANTE CON SUS MATERIAS Y HORARIOS\n');
    console.log('='.repeat(80));

    // Obtener un estudiante de ejemplo
    const estudiante = await prisma.estudiante.findFirst({
      include: {
        usuario: {
          include: {
            usuarioInstituciones: {
              include: { institucion: true }
            }
          }
        }
      }
    });

    if (!estudiante) {
      console.log('❌ No se encontraron estudiantes en la base de datos');
      return;
    }

    // Mostrar información básica del estudiante
    console.log('📋 INFORMACIÓN DEL ESTUDIANTE:');
    console.log('-'.repeat(50));
    console.log(`ID: ${estudiante.id}`);
    console.log(`Nombre: ${estudiante.usuario.nombres} ${estudiante.usuario.apellidos}`);
    console.log(`Email: ${estudiante.usuario.email}`);
    console.log(`Institución: ${estudiante.usuario.usuarioInstituciones[0]?.institucion.nombre || 'N/A'}`);
    console.log(`Identificación: ${estudiante.identificacion}`);
    console.log(`Código QR: ${estudiante.codigoQr}`);
    console.log(`Responsable: ${estudiante.nombreResponsable || 'N/A'}`);
    console.log(`Teléfono Responsable: ${estudiante.telefonoResponsable || 'N/A'}`);
    console.log(`Teléfono Personal: ${estudiante.usuario.telefono || 'N/A'}`);
    console.log('');

    // Obtener grupos del estudiante
    const gruposEstudiante = await prisma.estudianteGrupo.findMany({
      where: { estudianteId: estudiante.id },
      include: {
        grupo: {
          include: {
            periodoAcademico: true,
            _count: {
              select: {
                estudiantesGrupos: true,
                horarios: true
              }
            }
          }
        }
      }
    });

    console.log('👥 GRUPOS ASIGNADOS:');
    console.log('-'.repeat(50));
    if (gruposEstudiante.length === 0) {
      console.log('No tiene grupos asignados');
    } else {
      gruposEstudiante.forEach((eg, index) => {
        const grupo = eg.grupo;
        console.log(`${index + 1}. ${grupo.nombre} (${grupo.grado}° ${grupo.seccion})`);
        console.log(`   Período: ${grupo.periodoAcademico.nombre}`);
        console.log(`   Estudiantes: ${grupo._count.estudiantesGrupos}`);
        console.log(`   Horarios: ${grupo._count.horarios}`);
        console.log('');
      });
    }

    // Obtener horario semanal completo
    console.log('📅 HORARIO SEMANAL COMPLETO:');
    console.log('-'.repeat(50));

    const diasSemana = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

    for (let dia = 1; dia <= 7; dia++) {
      const clasesDia = await prisma.horario.findMany({
        where: {
          diaSemana: dia,
          institucionId: estudiante.usuario.usuarioInstituciones[0]?.institucionId,
          grupo: {
            estudiantesGrupos: {
              some: {
                estudianteId: estudiante.id
              }
            }
          }
        },
        include: {
          materia: true,
          profesor: {
            select: {
              id: true,
              nombres: true,
              apellidos: true
            }
          },
          grupo: true
        },
        orderBy: {
          horaInicio: 'asc'
        }
      });

      console.log(`\n📆 ${diasSemana[dia]} (Día ${dia}):`);
      console.log('-'.repeat(40));

      if (clasesDia.length === 0) {
        console.log('  📝 Sin clases');
      } else {
        // Crear tabla para el día
        console.log('┌─────────┬─────────────────┬──────────────────────┬──────────────────────┐');
        console.log('│ Hora    │ Materia         │ Profesor             │ Grupo                │');
        console.log('├─────────┼─────────────────┼──────────────────────┼──────────────────────┤');

        clasesDia.forEach((clase) => {
          const hora = `${clase.horaInicio.slice(0, 5)}-${clase.horaFin.slice(0, 5)}`;
          const materia = clase.materia.nombre.length > 15
            ? clase.materia.nombre.substring(0, 12) + '...'
            : clase.materia.nombre.padEnd(15);
          const profesorNombre = clase.profesor
            ? `${clase.profesor.nombres} ${clase.profesor.apellidos}`
            : 'Sin asignar';
          const profesor = profesorNombre.length > 20
            ? profesorNombre.substring(0, 17) + '...'
            : profesorNombre.padEnd(20);
          const grupo = `${clase.grupo.nombre} (${clase.grupo.grado}°${clase.grupo.seccion})`.length > 20
            ? `${clase.grupo.nombre} (${clase.grupo.grado}°${clase.grupo.seccion})`.substring(0, 17) + '...'
            : `${clase.grupo.nombre} (${clase.grupo.grado}°${clase.grupo.seccion})`.padEnd(20);

          console.log(`│ ${hora.padEnd(7)} │ ${materia} │ ${profesor} │ ${grupo} │`);
        });

        console.log('└─────────┴─────────────────┴──────────────────────┴──────────────────────┘');
      }
    }

    // Resumen de materias
    console.log('\n📚 RESUMEN DE MATERIAS:');
    console.log('-'.repeat(50));

    const todasLasMaterias = await prisma.horario.findMany({
      where: {
        institucionId: estudiante.usuario.usuarioInstituciones[0]?.institucionId,
        grupo: {
          estudiantesGrupos: {
            some: {
              estudianteId: estudiante.id
            }
          }
        }
      },
      include: {
        materia: true,
        profesor: {
          select: {
            id: true,
            nombres: true,
            apellidos: true
          }
        }
      },
      distinct: ['materiaId']
    });

    if (todasLasMaterias.length === 0) {
      console.log('No tiene materias asignadas');
    } else {
      console.log('┌─────────────────┬──────────────────────┬─────────────┐');
      console.log('│ Materia         │ Profesor             │ Código      │');
      console.log('├─────────────────┼──────────────────────┼─────────────┤');

      todasLasMaterias.forEach((horario) => {
        const materia = horario.materia.nombre.length > 15
          ? horario.materia.nombre.substring(0, 12) + '...'
          : horario.materia.nombre.padEnd(15);
        const profesorNombre = horario.profesor
          ? `${horario.profesor.nombres} ${horario.profesor.apellidos}`
          : 'Sin asignar';
        const profesor = profesorNombre.length > 20
          ? profesorNombre.substring(0, 17) + '...'
          : profesorNombre.padEnd(20);
        const codigo = (horario.materia.codigo || 'N/A').padEnd(11);

        console.log(`│ ${materia} │ ${profesor} │ ${codigo} │`);
      });

      console.log('└─────────────────┴──────────────────────┴─────────────┘');
      console.log(`\nTotal de materias: ${todasLasMaterias.length}`);
    }

    console.log('\n🎉 ¡Ejemplo completado exitosamente!');

  } catch (error) {
    console.error('❌ Error al mostrar el ejemplo:', error);
  } finally {
    await prisma.$disconnect();
  }
}

// Ejecutar el ejemplo
showStudentExample();