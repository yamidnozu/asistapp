#!/usr/bin/env node

/**
 * 👤 AsistApp - Script para crear usuarios de prueba
 *
 * Este script crea usuarios de prueba en la base de datos para testing
 *
 * Uso: node create-test-users.js
 */

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

const TEST_USERS = [
  {
    email: 'admin@asistapp.com',
    password: 'Admin123!',
    nombres: 'Super',
    apellidos: 'Admin',
    rol: 'super_admin',
    telefono: '3000000000',
    activo: true
  },
  {
    email: 'admin@colegio.edu',
    password: 'Admin123!',
    nombres: 'Admin',
    apellidos: 'Institución',
    rol: 'admin_institucion',
    telefono: '3001111111',
    activo: true
  },
  {
    email: 'profesor@colegio.edu',
    password: 'Profesor123!',
    nombres: 'Profesor',
    apellidos: 'Demo',
    rol: 'profesor',
    telefono: '3002222222',
    activo: true
  },
  {
    email: 'estudiante@colegio.edu',
    password: 'Estudiante123!',
    nombres: 'Estudiante',
    apellidos: 'Demo',
    rol: 'estudiante',
    telefono: '3003333333',
    activo: true
  }
];

async function createTestUsers() {
  console.log('👤 Creando usuarios de prueba para AsistApp...');
  console.log('='.repeat(50));

  try {
    // Crear institución de prueba si no existe
    let institucion = await prisma.institucion.findFirst({
      where: { codigo: 'TEST_INST' }
    });

    if (!institucion) {
      console.log('🏫 Creando institución de prueba...');
      institucion = await prisma.institucion.create({
        data: {
          nombre: 'Institución de Prueba',
          codigo: 'TEST_INST',
          direccion: 'Calle de Prueba 123',
          telefono: '3004444444',
          email: 'test@institucion.edu',
          activa: true
        }
      });
      console.log(`✅ Institución creada: ${institucion.nombre} (ID: ${institucion.id})`);
    } else {
      console.log(`✅ Institución existente: ${institucion.nombre} (ID: ${institucion.id})`);
    }

    // Crear usuarios
    for (const userData of TEST_USERS) {
      // Verificar si el usuario ya existe
      const existingUser = await prisma.usuario.findUnique({
        where: { email: userData.email }
      });

      if (existingUser) {
        console.log(`⚠️  Usuario ya existe: ${userData.email} (${userData.rol})`);
        continue;
      }

      // Crear usuario
      const hashedPassword = await bcrypt.hash(userData.password, 10);

      const newUser = await prisma.usuario.create({
        data: {
          email: userData.email,
          passwordHash: hashedPassword,
          nombres: userData.nombres,
          apellidos: userData.apellidos,
          rol: userData.rol,
          telefono: userData.telefono,
          activo: userData.activo
        }
      });

      console.log(`✅ Usuario creado: ${userData.nombres} ${userData.apellidos} (${userData.rol})`);

      // Si es admin_institucion o profesor, asignarlo a la institución
      if (userData.rol === 'admin_institucion' || userData.rol === 'profesor') {
        await prisma.usuarioInstitucion.create({
          data: {
            usuarioId: newUser.id,
            institucionId: institucion.id,
            activo: true
          }
        });
        console.log(`   📍 Asignado a institución: ${institucion.nombre}`);
      }

      // Si es estudiante, crear registro adicional
      if (userData.rol === 'estudiante') {
        const identificacion = `TEST${Date.now()}`;
        const codigoQr = `EST-${identificacion}-${newUser.id}`;

        await prisma.estudiante.create({
          data: {
            usuarioId: newUser.id,
            identificacion: identificacion,
            codigoQr: codigoQr,
            nombreResponsable: 'Padre Demo',
            telefonoResponsable: '3005555555'
          }
        });
        console.log(`   📱 Código QR generado: ${codigoQr}`);
      }
    }

    console.log('');
    console.log('🎉 Usuarios de prueba creados exitosamente!');
    console.log('');
    console.log('📋 Credenciales de acceso:');
    console.log('='.repeat(30));

    TEST_USERS.forEach(user => {
      console.log(`${user.rol.toUpperCase()}:`);
      console.log(`  Email: ${user.email}`);
      console.log(`  Password: ${user.password}`);
      console.log('');
    });

    console.log('🏫 Institución de prueba:');
    console.log(`  ID: ${institucion.id}`);
    console.log(`  Nombre: ${institucion.nombre}`);
    console.log(`  Código: ${institucion.codigo}`);

  } catch (error) {
    console.error('❌ Error creando usuarios de prueba:', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

// Ejecutar si se llama directamente
if (require.main === module) {
  createTestUsers();
}

module.exports = { createTestUsers, TEST_USERS };