import axios from 'axios';

async function testRegistroManual() {
  try {
    // 1. Primero hacer login como profesor
    console.log('🔐 Haciendo login como profesor Juan Pérez...');
    const loginResponse = await axios.post('http://localhost:3001/auth/login', {
      email: 'juan.perez@sanjose.edu',
      password: 'Prof123!',
    });

    const token = loginResponse.data.data.accessToken;
    console.log('✅ Login exitoso, token obtenido\n');

    // 2. Obtener horarios del profesor
    console.log('📅 Obteniendo horarios del profesor...');
    const horariosResponse = await axios.get('http://localhost:3001/horarios', {
      headers: { Authorization: `Bearer ${token}` },
    });

    const horarios = horariosResponse.data.data;
    console.log(`✅ ${horarios.length} horarios encontrados`);
    
    if (horarios.length > 0) {
      const primerHorario = horarios[0];
      console.log(`\n📚 Primer horario:`);
      console.log(`   ID: ${primerHorario.id}`);
      console.log(`   Materia: ${primerHorario.materia.nombre}`);
      console.log(`   Grupo: ${primerHorario.grupo.nombre}`);
      console.log(`   Día: ${primerHorario.diaSemana} (${getDiaNombre(primerHorario.diaSemana)})`);
      console.log(`   Hora: ${primerHorario.horaInicio} - ${primerHorario.horaFin}`);

      // 3. Obtener estudiantes de ese horario
      console.log(`\n👨‍🎓 Obteniendo estudiantes del horario...`);
      const asistenciasResponse = await axios.get(
        `http://localhost:3001/horarios/${primerHorario.id}/asistencias`,
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      const estudiantes = asistenciasResponse.data.data;
      console.log(`✅ ${estudiantes.length} estudiantes encontrados\n`);

      if (estudiantes.length > 0) {
        // Buscar un estudiante sin registro
        const estudianteSinRegistro = estudiantes.find((e: any) => !e.estado);
        
        if (estudianteSinRegistro) {
          console.log(`📝 Estudiante sin registro encontrado:`);
          console.log(`   ID: ${estudianteSinRegistro.estudiante.id}`);
          console.log(`   Nombre: ${estudianteSinRegistro.estudiante.nombres} ${estudianteSinRegistro.estudiante.apellidos}`);
          console.log(`   Estado: ${estudianteSinRegistro.estado || 'SIN REGISTRAR'}`);

          // 4. Intentar registrar asistencia manual
          console.log(`\n✍️  Intentando registrar asistencia manual...`);
          const registroResponse = await axios.post(
            'http://localhost:3001/asistencias/registrar-manual',
            {
              horarioId: primerHorario.id,
              estudianteId: estudianteSinRegistro.estudiante.id,
            },
            {
              headers: { Authorization: `Bearer ${token}` },
            }
          );

          console.log('✅ ¡Asistencia registrada exitosamente!');
          console.log('📄 Respuesta:', JSON.stringify(registroResponse.data, null, 2));
        } else {
          console.log('⚠️  Todos los estudiantes ya tienen registro de asistencia');
          console.log('\nEstudiantes:');
          estudiantes.forEach((e: any, i: number) => {
            console.log(`   ${i + 1}. ${e.estudiante.nombres} ${e.estudiante.apellidos} - Estado: ${e.estado || 'SIN REGISTRAR'}`);
            console.log(`      ID: ${e.estudiante.id}`);
          });
        }
      }
    }
  } catch (error: any) {
    console.error('\n❌ Error:', error.response?.data || error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', JSON.stringify(error.response.data, null, 2));
    }
  }
}

function getDiaNombre(dia: number): string {
  const dias = ['', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  return dias[dia] || 'Desconocido';
}

testRegistroManual();
