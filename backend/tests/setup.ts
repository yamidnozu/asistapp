import { afterAll, beforeAll } from '@jest/globals';
import { testDatabaseService } from './test-database';

beforeAll(async () => {

  process.env.NODE_ENV = 'test';
  process.env.DATABASE_URL = 'file:./test.db';

  await testDatabaseService.connect();
});

afterAll(async () => {
  await testDatabaseService.disconnect();
});

