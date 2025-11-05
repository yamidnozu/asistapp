// Script para verificar que todas las tablas académicas existen
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function verifySchema() {
  console.log('🔍 Verificando estructura académica en la base de datos...\n');

  try {
    // Verificar PeriodoAcademico
    console.log('✓ Verificando tabla: periodos_academicos');
    const periodos = await prisma.periodoAcademico.findMany();
    console.log(`  → ${periodos.length} periodos académicos encontrados\n`);

    // Verificar Grupos
    console.log('✓ Verificando tabla: grupos');
    const grupos = await prisma.grupo.findMany();
    console.log(`  → ${grupos.length} grupos encontrados\n`);

    // Verificar Materias
    console.log('✓ Verificando tabla: materias');
    const materias = await prisma.materia.findMany();
    console.log(`  → ${materias.length} materias encontradas\n`);

    // Verificar Horarios
    console.log('✓ Verificando tabla: horarios');
    const horarios = await prisma.horario.findMany();
    console.log(`  → ${horarios.length} horarios encontrados\n`);

    // Verificar Instituciones
    console.log('✓ Verificando tabla: instituciones');
    const instituciones = await prisma.institucion.findMany();
    console.log(`  → ${instituciones.length} instituciones encontradas\n`);

    console.log('✅ TODAS LAS TABLAS ACADÉMICAS ESTÁN CORRECTAMENTE CREADAS\n');
    console.log('📊 Resumen de la estructura:');
    console.log('   - PeriodoAcademico ✓ (id, nombre, fechaInicio, fechaFin, activo, institucionId)');
    console.log('   - Grupo ✓ (id, nombre, grado, seccion, institucionId, periodoId)');
    console.log('   - Materia ✓ (id, nombre, codigo, institucionId)');
    console.log('   - Horario ✓ (id, diaSemana, horaInicio, horaFin, periodoId, grupoId, materiaId, profesorId)');
    console.log('\n🎉 Sub-fase 2.1 COMPLETADA con éxito!\n');

  } catch (error) {
    console.error('❌ Error al verificar la estructura:', error.message);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

verifySchema();
