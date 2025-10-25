import { afterAll, beforeAll, beforeEach } from '@jest/globals';
import { testDatabaseService } from './test-database';

// Configurar base de datos para pruebas
beforeAll(async () => {
  // Usar SQLite para pruebas
  process.env.NODE_ENV = 'test';
  process.env.DATABASE_URL = 'file:./test.db';

  await testDatabaseService.connect();
});

afterAll(async () => {
  await testDatabaseService.disconnect();
});

beforeEach(async () => {
  // Limpiar la base de datos antes de cada test
  await testDatabaseService.reset();
});

