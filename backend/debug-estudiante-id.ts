import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function debugEstudianteId() {
  const estudianteIdBuscado = '6ffe8d15-6d6d-49d0-a869-98968d1a2e34';
  
  console.log(`\n🔍 Buscando estudiante con ID: ${estudianteIdBuscado}`);
  
  // Buscar en tabla estudiantes
  const estudiante = await prisma.estudiante.findUnique({
    where: { id: estudianteIdBuscado },
    include: {
      usuario: true,
      estudiantesGrupos: {
        include: {
          grupo: true,
        },
      },
    },
  });
  
  if (estudiante) {
    console.log('✅ Estudiante encontrado:');
    console.log(`   Nombre: ${estudiante.usuario.nombres} ${estudiante.usuario.apellidos}`);
    console.log(`   Identificación: ${estudiante.identificacion}`);
    console.log(`   Usuario ID: ${estudiante.usuarioId}`);
    console.log(`   Grupos: ${estudiante.estudiantesGrupos.map(eg => eg.grupo.nombre).join(', ')}`);
  } else {
    console.log('❌ Estudiante NO encontrado en tabla estudiantes');
    
    // Buscar si es un usuario
    const usuario = await prisma.usuario.findUnique({
      where: { id: estudianteIdBuscado },
    });
    
    if (usuario) {
      console.log('⚠️  PERO es un usuario:');
      console.log(`   Nombre: ${usuario.nombres} ${usuario.apellidos}`);
      console.log(`   Email: ${usuario.email}`);
      console.log(`   Rol: ${usuario.rol}`);
      
      // Buscar el estudiante asociado
      const estudianteAsociado = await prisma.estudiante.findUnique({
        where: { usuarioId: usuario.id },
      });
      
      if (estudianteAsociado) {
        console.log(`   ✓ ID correcto del estudiante: ${estudianteAsociado.id}`);
      }
    }
  }
  
  // Listar todos los estudiantes para debug
  console.log('\n📋 Todos los estudiantes en la base de datos:');
  const todosEstudiantes = await prisma.estudiante.findMany({
    include: {
      usuario: true,
    },
    take: 5,
  });
  
  todosEstudiantes.forEach(est => {
    console.log(`   - ID: ${est.id}`);
    console.log(`     Usuario ID: ${est.usuarioId}`);
    console.log(`     Nombre: ${est.usuario.nombres} ${est.usuario.apellidos}`);
    console.log(`     Identificación: ${est.identificacion}`);
    console.log('');
  });
}

debugEstudianteId()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
