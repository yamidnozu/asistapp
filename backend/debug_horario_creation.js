const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function debugHorarioCreation() {
  try {
    console.log('=== DEBUG HORARIO CREATION ===');
    
    // IDs de la prueba que está fallando
    const testData = {
      periodoId: "c39384d2-df80-42b2-a56b-18c0a175fce1",
      grupoId: "83869904-db41-4a0c-a147-cc80b279b8bf", 
      materiaId: "5515b5d9-2877-43cc-a057-f379edb86442",
      profesorId: null,
      diaSemana: 2,
      horaInicio: "10:00",
      horaFin: "11:00"
    };
    
    // Obtener institución del admin
    const usuarioInstitucion = await prisma.usuarioInstitucion.findFirst({
      where: { 
        usuario: { email: 'admin_sanjose@test.com' },
        activo: true 
      }
    });
    
    if (!usuarioInstitucion) {
      console.error('❌ No se encontró institución para el admin');
      return;
    }
    
    const institucionId = usuarioInstitucion.institucionId;
    console.log('Institución del admin:', institucionId);
    
    // Verificar cada entidad por separado
    console.log('\n��� VERIFICANDO ENTIDADES...');
    
    // 1. Verificar institución
    const institucion = await prisma.institucion.findUnique({
      where: { id: institucionId }
    });
    console.log('✅ Institución existe:', institucion ? institucion.nombre : 'NO');
    
    // 2. Verificar periodo
    const periodo = await prisma.periodoAcademico.findUnique({
      where: { id: testData.periodoId }
    });
    console.log('✅ Periodo existe:', periodo ? periodo.nombre : 'NO');
    if (periodo) {
      console.log('   - Institución del periodo:', periodo.institucionId);
      console.log('   - Coincide con admin:', periodo.institucionId === institucionId);
    }
    
    // 3. Verificar grupo
    const grupo = await prisma.grupo.findUnique({
      where: { id: testData.grupoId }
    });
    console.log('✅ Grupo existe:', grupo ? grupo.nombre : 'NO');
    if (grupo) {
      console.log('   - Institución del grupo:', grupo.institucionId);
      console.log('   - Periodo del grupo:', grupo.periodoId);
      console.log('   - Coincide institución:', grupo.institucionId === institucionId);
      console.log('   - Coincide periodo:', grupo.periodoId === testData.periodoId);
    }
    
    // 4. Verificar materia
    const materia = await prisma.materia.findUnique({
      where: { id: testData.materiaId }
    });
    console.log('✅ Materia existe:', materia ? materia.nombre : 'NO');
    if (materia) {
      console.log('   - Institución de la materia:', materia.institucionId);
      console.log('   - Coincide institución:', materia.institucionId === institucionId);
    }
    
    // 5. Verificar profesor (si existe)
    if (testData.profesorId) {
      const profesor = await prisma.usuario.findUnique({
        where: { id: testData.profesorId }
      });
      console.log('✅ Profesor existe:', profesor ? `${profesor.nombres} ${profesor.apellidos}` : 'NO');
      if (profesor) {
        console.log('   - Rol del profesor:', profesor.rol);
        // Verificar relación con institución
        const relacionInstitucion = await prisma.usuarioInstitucion.findFirst({
          where: {
            usuarioId: testData.profesorId,
            institucionId: institucionId,
            activo: true
          }
        });
        console.log('   - Tiene relación con institución:', relacionInstitucion ? 'SÍ' : 'NO');
      }
    } else {
      console.log('ℹ️ Sin profesor asignado');
    }
    
    // Intentar crear el horario
    console.log('\n��� INTENTANDO CREAR HORARIO...');
    const horarioData = {
      institucionId: institucionId,
      periodoId: testData.periodoId,
      grupoId: testData.grupoId,
      materiaId: testData.materiaId,
      profesorId: testData.profesorId,
      diaSemana: testData.diaSemana,
      horaInicio: testData.horaInicio,
      horaFin: testData.horaFin
    };
    
    console.log('Datos completos:', JSON.stringify(horarioData, null, 2));
    
    try {
      const horario = await prisma.horario.create({
        data: horarioData
      });
      console.log('✅ HORARIO CREADO EXITOSAMENTE:', horario.id);
    } catch (createError) {
      console.error('❌ ERROR AL CREAR HORARIO:');
      console.error('Mensaje:', createError.message);
      console.error('Código:', createError.code);
      console.error('Meta:', createError.meta);
      
      // Si es error de foreign key, identificar cuál
      if (createError.code === 'P2003') {
        console.log('\n��� ANALIZANDO ERROR DE CLAVE FORÁNEA...');
        const field = createError.meta?.field_name;
        console.log('Campo problemático:', field);
        
        if (field?.includes('institucion_id')) {
          console.log('❌ Problema con institucionId');
        } else if (field?.includes('periodo_id')) {
          console.log('❌ Problema con periodoId');
        } else if (field?.includes('grupo_id')) {
          console.log('❌ Problema con grupoId');
        } else if (field?.includes('materia_id')) {
          console.log('❌ Problema con materiaId');
        } else if (field?.includes('profesor_id')) {
          console.log('❌ Problema con profesorId');
        }
      }
    }
    
  } catch (error) {
    console.error('❌ ERROR GENERAL:', error.message);
    console.error('Stack:', error.stack);
  } finally {
    await prisma.$disconnect();
  }
}

debugHorarioCreation();
