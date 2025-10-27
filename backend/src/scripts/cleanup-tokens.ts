import { databaseService } from '../config/database';

/**
 * Script para limpiar refresh tokens expirados
 * Se puede ejecutar periódicamente (ej: CRON job diario)
 */
async function cleanupExpiredRefreshTokens() {
  try {
    console.log('🧹 Iniciando limpieza de refresh tokens expirados...');

    const prisma = databaseService.getClient();
    const result = await prisma.refreshToken.deleteMany({
      where: {
        OR: [
          { expiresAt: { lt: new Date() } }, // Expirados
          { revoked: true }, // Revocados
        ],
      },
    });

    console.log(`✅ Eliminados ${result.count} refresh tokens expirados/revocados`);
    const remainingTokens = await prisma.refreshToken.count();
    console.log(`📊 Tokens restantes en DB: ${remainingTokens}`);

  } catch (error) {
    console.error('❌ Error durante la limpieza:', error);
    process.exit(1);
  } finally {
    await databaseService.disconnect();
  }
}
if (require.main === module) {
  cleanupExpiredRefreshTokens();
}

export default cleanupExpiredRefreshTokens;