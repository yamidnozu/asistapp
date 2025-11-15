const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function simpleTest() {
  try {
    console.log('=== PRUEBA SIMPLIFICADA DE HORARIO ===');
    
    // Obtener IDs válidos
    const adminInstitucion = await prisma.usuarioInstitucion.findFirst({
      where: { 
        usuario: { email: 'admin_sanjose@test.com' },
        activo: true 
      }
    });
    
    if (!adminInstitucion) {
      console.error('❌ No se encontró institución para el admin');
      return;
    }
    
    const institucionId = adminInstitucion.institucionId;
    console.log('Institución del admin:', institucionId);
    
    // Obtener periodo activo
    const periodo = await prisma.periodoAcademico.findFirst({
      where: { 
        institucionId: institucionId,
        activo: true 
      }
    });
    
    if (!periodo) {
      console.error('❌ No se encontró periodo activo');
      return;
    }
    
    console.log('Periodo encontrado:', periodo.nombre, periodo.id);
    
    // Obtener grupo
    const grupo = await prisma.grupo.findFirst({
      where: { 
        institucionId: institucionId,
        periodoId: periodo.id
      }
    });
    
    if (!grupo) {
      console.error('❌ No se encontró grupo');
      return;
    }
    
    console.log('Grupo encontrado:', grupo.nombre, grupo.id);
    
    // Obtener materia
    const materia = await prisma.materia.findFirst({
      where: { institucionId: institucionId }
    });
    
    if (!materia) {
      console.error('❌ No se encontró materia');
      return;
    }
    
    console.log('Materia encontrada:', materia.nombre, materia.id);
    
    // Intentar crear horario directamente con Prisma
    console.log('Creando horario...');
    const horarioData = {
      institucionId: institucionId,
      periodoId: periodo.id,
      grupoId: grupo.id,
      materiaId: materia.id,
      profesorId: null,
      diaSemana: 1,
      horaInicio: '08:00',
      horaFin: '09:00'
    };
    
    console.log('Datos del horario:', JSON.stringify(horarioData, null, 2));
    
    const horario = await prisma.horario.create({
      data: horarioData
    });
    
    console.log('✅ HORARIO CREADO EXITOSAMENTE:', horario.id);
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

simpleTest();
