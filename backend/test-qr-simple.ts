// test-qr-simple.ts
// Test automatizado para verificar registro de asistencia con QR

import axios from 'axios';
import { PrismaClient } from '@prisma/client';

const BASE_URL = 'http://localhost:3001';
const prisma = new PrismaClient();

async function login(email: string, password: string) {
  const response = await axios.post(`${BASE_URL}/auth/login`, {
    email,
    password,
  });
  return response.data.data.accessToken;
}

async function test() {
  console.log('\n🧪 === TEST: Registro de Asistencia con QR ===\n');

  try {
    // Login como profesor Juan Pérez
    const token = await login('juan.perez@sanjose.edu', 'Prof123!');
    console.log('✅ Login exitoso\n');

    // Obtener el ID del profesor desde la BD
    const profesor = await prisma.usuario.findUnique({
      where: { email: 'juan.perez@sanjose.edu' },
    });

    if (!profesor) {
      console.error('❌ No se encontró el profesor en la base de datos');
      return;
    }

    // Buscar un horario asignado a este profesor
    const horario = await prisma.horario.findFirst({
      where: {
        profesorId: profesor.id,
      },
      include: {
        grupo: true,
        materia: true,
        periodoAcademico: true,
      },
    });

    if (!horario) {
      console.error('❌ No se encontró ningún horario asignado al profesor');
      console.log('   Verifica que existan horarios en la base de datos para este profesor\n');
      return;
    }

    console.log('📅 Horario encontrado:');
    console.log(`   ID: ${horario.id}`);
    console.log(`   Grupo: ${horario.grupo.nombre}`);
    console.log(`   Materia: ${horario.materia.nombre}`);
    console.log(`   Periodo: ${horario.periodoAcademico.nombre}\n`);

    // Buscar un estudiante del grupo
    const estudianteGrupo = await prisma.estudianteGrupo.findFirst({
      where: {
        grupoId: horario.grupoId,
      },
      include: {
        estudiante: {
          include: {
            usuario: true,
          },
        },
      },
    });

    if (!estudianteGrupo) {
      console.error('❌ No se encontró ningún estudiante en el grupo');
      console.log('   Verifica que existan estudiantes asignados a este grupo\n');
      return;
    }

    const estudiante = estudianteGrupo.estudiante;
    console.log('👨‍🎓 Estudiante encontrado:');
    console.log(`   Nombre: ${estudiante.usuario.nombres} ${estudiante.usuario.apellidos}`);
    console.log(`   Código QR: ${estudiante.codigoQr}\n`);

    // Intentar registrar asistencia
    console.log('📝 Registrando asistencia...\n');

    const response = await axios.post(
      `${BASE_URL}/asistencias/registrar`,
      {
        horarioId: horario.id,
        codigoQr: estudiante.codigoQr,
      },
      {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      }
    );

    if (response.data.success) {
      console.log('✅ Asistencia registrada exitosamente!');
      console.log(`   ID de asistencia: ${response.data.data.id}`);
      console.log(`   Estado: ${response.data.data.estado}`);
      console.log(`   Fecha: ${response.data.data.fecha}\n`);
    } else {
      console.error('❌ Error al registrar asistencia:', response.data.message);
    }
  } catch (error: any) {
    if (error.response) {
      console.error('❌ Error HTTP:', error.response.status);
      console.error('   Mensaje:', error.response.data.message || error.response.data);
    } else {
      console.error('❌ Error:', error.message);
    }
  } finally {
    await prisma.$disconnect();
  }
}

test().catch(console.error);
