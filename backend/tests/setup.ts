import { afterAll, beforeAll } from '@jest/globals';
import { testDatabaseService } from './test-database';

beforeAll(async () => {

  process.env.NODE_ENV = 'test';
  process.env.DATABASE_URL = 'postgresql://postgres:postgres@localhost:5433/asistapp_test?schema=public';

  await testDatabaseService.connect();
});

afterAll(async () => {
  await testDatabaseService.disconnect();
});

