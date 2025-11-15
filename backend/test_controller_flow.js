const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function testControllerFlow() {
  try {
    console.log('=== PRUEBA FLUJO CONTROLADOR ===');
    
    // Simular lo que hace el controlador: obtener instituci√≥n del admin
    const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
      where: { 
        usuario: { email: 'admin_sanjose@test.com' },
        activo: true 
      }
    });
    
    if (!usuarioInstitucion) {
      console.error('‚ùå No se encontr√≥ instituci√≥n para el admin');
      return;
    }
    
    const institucionId = usuarioInstitucion.institucionId;
    console.log('Instituci√≥n del admin (como en controlador):', institucionId);
    
    // Los IDs que usa la prueba (del test-api.js)
    const testData = {
      periodoId: "c39384d2-df80-42b2-a56b-18c0a175fce1",
      grupoId: "83869904-db41-4a0c-a147-cc80b279b8bf", 
      materiaId: "5515b5d9-2877-43cc-a057-f379edb86442",
      profesorId: null,
      diaSemana: 1,
      horaInicio: "08:00",
      horaFin: "09:00"
    };
    
    // Lo que el controlador env√≠a al servicio (agregando institucionId)
    const serviceData = {
      ...testData,
      institucionId: institucionId
    };
    
    console.log('Datos que recibe el servicio:', JSON.stringify(serviceData, null, 2));
    
    // Ahora probar las validaciones del servicio paso a paso
    
    // 1. Validar periodo
    console.log('Ì¥ç Validando periodo...');
    const periodo = await prisma.periodoAcademico.findFirst({
      where: {
        id: serviceData.periodoId,
        institucionId: serviceData.institucionId,
      },
    });
    
    if (!periodo) {
      console.error('‚ùå Periodo no encontrado o no pertenece a instituci√≥n');
      return;
    }
    console.log('‚úÖ Periodo v√°lido:', periodo.nombre);
    
    // 2. Validar grupo
    console.log('Ì¥ç Validando grupo...');
    const grupo = await prisma.grupo.findFirst({
      where: {
        id: serviceData.grupoId,
        institucionId: serviceData.institucionId,
        periodoId: serviceData.periodoId,
      },
    });
    
    if (!grupo) {
      console.error('‚ùå Grupo no encontrado o no pertenece a instituci√≥n/periodo');
      return;
    }
    console.log('‚úÖ Grupo v√°lido:', grupo.nombre);
    
    // 3. Validar materia
    console.log('Ì¥ç Validando materia...');
    const materia = await prisma.materia.findFirst({
      where: {
        id: serviceData.materiaId,
        institucionId: serviceData.institucionId,
      },
    });
    
    if (!materia) {
      console.error('‚ùå Materia no encontrada o no pertenece a instituci√≥n');
      return;
    }
    console.log('‚úÖ Materia v√°lida:', materia.nombre);
    
    // 4. Validar profesor (si existe)
    if (serviceData.profesorId) {
      console.log('Ì¥ç Validando profesor...');
      const profesor = await prisma.usuario.findFirst({
        where: {
          id: serviceData.profesorId,
          rol: 'profesor',
          usuarioInstituciones: {
            some: {
              institucionId: serviceData.institucionId,
              activo: true,
            },
          },
        },
      });
      
      if (!profesor) {
        console.error('‚ùå Profesor no encontrado o no pertenece a instituci√≥n');
        return;
      }
      console.log('‚úÖ Profesor v√°lido:', profesor.nombres, profesor.apellidos);
    } else {
      console.log('‚ÑπÔ∏è No hay profesor asignado');
    }
    
    // 5. Validar conflictos de horario
    console.log('Ì¥ç Validando conflictos...');
    
    // Validar formato de hora
    const timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
    if (!timeRegex.test(serviceData.horaInicio) || !timeRegex.test(serviceData.horaFin)) {
      console.error('‚ùå Formato de hora inv√°lido');
      return;
    }
    
    if (serviceData.horaInicio >= serviceData.horaFin) {
      console.error('‚ùå Hora inicio debe ser anterior a hora fin');
      return;
    }
    
    if (serviceData.diaSemana < 1 || serviceData.diaSemana > 7) {
      console.error('‚ùå D√≠a de semana inv√°lido');
      return;
    }
    
    // Buscar conflictos para grupo
    const grupoConflicts = await prisma.horario.findMany({
      where: {
        grupoId: serviceData.grupoId,
        diaSemana: serviceData.diaSemana,
        OR: [
          {
            AND: [
              { horaInicio: { lte: serviceData.horaInicio } },
              { horaFin: { gt: serviceData.horaInicio } }
            ]
          },
          {
            AND: [
              { horaInicio: { lt: serviceData.horaFin } },
              { horaFin: { gte: serviceData.horaFin } }
            ]
          },
          {
            AND: [
              { horaInicio: { gte: serviceData.horaInicio } },
              { horaFin: { lte: serviceData.horaFin } }
            ]
          }
        ]
      },
    });
    
    if (grupoConflicts.length > 0) {
      console.error('‚ùå Conflicto de horario para grupo');
      return;
    }
    
    console.log('‚úÖ No hay conflictos de horario');
    
    // 6. Crear horario
    console.log('Ì¥ç Creando horario...');
    const horario = await prisma.horario.create({
      data: {
        periodoId: serviceData.periodoId,
        grupoId: serviceData.grupoId,
        materiaId: serviceData.materiaId,
        profesorId: serviceData.profesorId,
        diaSemana: serviceData.diaSemana,
        horaInicio: serviceData.horaInicio,
        horaFin: serviceData.horaFin,
        institucionId: serviceData.institucionId,
      }
    });
    
    console.log('‚úÖ HORARIO CREADO EXITOSAMENTE:', horario.id);
    
  } catch (error) {
    console.error('‚ùå ERROR:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

testControllerFlow();
