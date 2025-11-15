const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function checkMartesSchedules() {
  try {
    console.log('=== VERIFICANDO HORARIOS DEL MARTES ===');
    
    const grupoId = "83869904-db41-4a0c-a147-cc80b279b8bf";
    const diaSemana = 2; // Martes
    
    console.log('Buscando horarios para grupo:', grupoId, 'día:', diaSemana);
    
    const schedules = await prisma.horario.findMany({
      where: {
        grupoId: grupoId,
        diaSemana: diaSemana
      },
      include: {
        materia: { select: { nombre: true } },
        profesor: { select: { nombres: true, apellidos: true } }
      },
      orderBy: { horaInicio: 'asc' }
    });
    
    console.log('Horarios encontrados:', schedules.length);
    
    schedules.forEach((schedule, index) => {
      console.log(`${index + 1}. ${schedule.materia.nombre}`);
      console.log(`   Horario: ${schedule.horaInicio} - ${schedule.horaFin}`);
      if (schedule.profesor) {
        console.log(`   Profesor: ${schedule.profesor.nombres} ${schedule.profesor.apellidos}`);
      } else {
        console.log('   Sin profesor');
      }
      console.log(`   ID: ${schedule.id}`);
      console.log('');
    });
    
    // Verificar conflicto con 10:00-11:00
    const conflicting = schedules.filter(s => {
      const newStart = "10:00";
      const newEnd = "11:00";
      const existingStart = s.horaInicio;
      const existingEnd = s.horaFin;
      
      return (
        (existingStart <= newStart && existingEnd > newStart) ||
        (existingStart < newEnd && existingEnd >= newEnd) ||
        (existingStart >= newStart && existingEnd <= newEnd)
      );
    });
    
    console.log('Horarios que entran en conflicto con 10:00-11:00:', conflicting.length);
    
  } catch (error) {
    console.error('❌ ERROR:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

checkMartesSchedules();
