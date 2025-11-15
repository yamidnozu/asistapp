const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkExistingSchedules() {
  try {
    console.log('=== VERIFICANDO HORARIOS EXISTENTES ===');
    
    const grupoId = "83869904-db41-4a0c-a147-cc80b279b8bf";
    const diaSemana = 1; // Lunes
    
    console.log('Buscando horarios existentes para grupo:', grupoId);
    console.log('Día de la semana:', diaSemana);
    
    const existingSchedules = await prisma.horario.findMany({
      where: {
        grupoId: grupoId,
        diaSemana: diaSemana
      },
      include: {
        materia: { select: { nombre: true } },
        profesor: { select: { nombres: true, apellidos: true } }
      }
    });
    
    console.log('Horarios encontrados:', existingSchedules.length);
    
    existingSchedules.forEach((schedule, index) => {
      console.log(`${index + 1}. ${schedule.materia.nombre} - ${schedule.horaInicio} a ${schedule.horaFin}`);
      if (schedule.profesor) {
        console.log(`   Profesor: ${schedule.profesor.nombres} ${schedule.profesor.apellidos}`);
      } else {
        console.log('   Sin profesor asignado');
      }
    });
    
    // Verificar si hay conflicto con 08:00-09:00
    const conflictingSchedules = existingSchedules.filter(schedule => {
      const newStart = "08:00";
      const newEnd = "09:00";
      const existingStart = schedule.horaInicio;
      const existingEnd = schedule.horaFin;
      
      // Verificar solapamiento
      return (
        (existingStart <= newStart && existingEnd > newStart) ||
        (existingStart < newEnd && existingEnd >= newEnd) ||
        (existingStart >= newStart && existingEnd <= newEnd)
      );
    });
    
    console.log('\nHorarios que entran en conflicto con 08:00-09:00:');
    if (conflictingSchedules.length > 0) {
      conflictingSchedules.forEach((schedule, index) => {
        console.log(`${index + 1}. ${schedule.materia.nombre} - ${schedule.horaInicio} a ${schedule.horaFin}`);
      });
    } else {
      console.log('Ninguno');
    }
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

checkExistingSchedules();
