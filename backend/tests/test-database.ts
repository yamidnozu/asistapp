import { PrismaClient } from '@prisma/client';

class TestDatabaseService {
  private static instance: TestDatabaseService;
  private prisma: PrismaClient | null = null;

  private constructor() {}

  public static getInstance(): TestDatabaseService {
    if (!TestDatabaseService.instance) {
      TestDatabaseService.instance = new TestDatabaseService();
    }
    return TestDatabaseService.instance;
  }

  public getClient(): PrismaClient {
    if (!this.prisma) {
      this.prisma = new PrismaClient({
        datasourceUrl: 'file:./test.db',
      });
    }
    return this.prisma;
  }

  public async disconnect(): Promise<void> {
    if (this.prisma) {
      await this.prisma.$disconnect();
      this.prisma = null;
    }
  }

  public async connect(): Promise<void> {
    const client = this.getClient();
    await client.$connect();
  }

  public async reset(): Promise<void> {
    const client = this.getClient();

    // Eliminar en orden correcto respetando las dependencias de clave foránea
    // Primero las tablas que tienen dependencias (hijas), luego las padre

    // Tablas con dependencias (hijas)
    await client.logNotificacion.deleteMany();
    await client.asistencia.deleteMany();
    await client.estudianteGrupo.deleteMany();
    await client.horario.deleteMany();
    await client.materia.deleteMany();
    await client.grupo.deleteMany();
    await client.periodoAcademico.deleteMany();
    await client.configuracion.deleteMany();
    await client.usuarioInstitucion.deleteMany();
    await client.refreshToken.deleteMany();

    // Tablas padre
    await client.estudiante.deleteMany();
    await client.usuario.deleteMany();
    await client.institucion.deleteMany();
  }
}

export const testDatabaseService = TestDatabaseService.getInstance();
export const testPrisma = testDatabaseService.getClient();