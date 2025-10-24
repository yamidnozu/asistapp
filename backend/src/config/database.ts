import { PrismaClient } from '@prisma/client';

class DatabaseService {
  private static instance: DatabaseService;
  private prisma: PrismaClient | null = null;

  private constructor() {}

  public static getInstance(): DatabaseService {
    if (!DatabaseService.instance) {
      DatabaseService.instance = new DatabaseService();
    }
    return DatabaseService.instance;
  }

  public getClient(): PrismaClient {
    if (!this.prisma) {
      console.log('🔄 Creando cliente Prisma...');
      this.prisma = new PrismaClient({
        log: process.env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
      });
      console.log('✅ Cliente Prisma creado');
    }
    return this.prisma;
  }

  public async disconnect(): Promise<void> {
    if (this.prisma) {
      await this.prisma.$disconnect();
      this.prisma = null;
      console.log('🔌 Cliente Prisma desconectado');
    }
  }

  public async connect(): Promise<void> {
    const client = this.getClient();
    await client.$connect();
    console.log('🔗 Conectado a la base de datos');
  }
}

export const databaseService = DatabaseService.getInstance();
export const prisma = databaseService.getClient();