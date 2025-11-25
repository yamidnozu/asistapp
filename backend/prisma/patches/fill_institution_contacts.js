const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  console.log('🛠️  Patching institutions with missing contact info...');

  const institutions = await prisma.institucion.findMany({
    where: { OR: [{ email: null }, { telefono: null }, { direccion: null }] },
  });

  console.log(`Found ${institutions.length} institutions with missing contact fields.`);

  for (const inst of institutions) {
    const adminRel = await prisma.usuarioInstitucion.findFirst({
      where: { institucionId: inst.id, rolEnInstitucion: 'admin', activo: true },
      include: { usuario: true },
    });

    const updatedData = {};
    if (!inst.email && adminRel?.usuario?.email) updatedData.email = adminRel.usuario.email;
    if (!inst.telefono && adminRel?.usuario?.telefono) updatedData.telefono = adminRel.usuario.telefono;
    if (!inst.direccion) updatedData.direccion = inst.direccion || null; // leave null since users don't have direccion

    if (Object.keys(updatedData).length > 0) {
      try {
        await prisma.institucion.update({ where: { id: inst.id }, data: updatedData });
        console.log(`Updated institution ${inst.nombre} (${inst.id}) with: ${JSON.stringify(updatedData)}`);
      } catch (err) {
        console.error(`Failed to update institution ${inst.id}`, err);
      }
    } else {
      console.log(`No admin fallback available for institution ${inst.nombre} (${inst.id}); skipping.`);
    }
  }

  console.log('✅ Patch complete.');
}

main()
  .catch((e) => {
    console.error('❌ Error during patch:', e);
    throw e;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

