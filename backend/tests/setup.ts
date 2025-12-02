import { afterAll, beforeAll } from '@jest/globals';
import { testDatabaseService } from './test-database';

beforeAll(async () => {

  process.env.NODE_ENV = 'test';
  // Allow overriding from environment (useful for CI or local docker runs).
  // If not provided, default to the DB service used in docker-compose when running inside containers.
  process.env.DATABASE_URL = process.env.DATABASE_URL || 'postgresql://postgres:postgres@db:5432/asistapp_test?schema=public';

  await testDatabaseService.connect();
});

afterAll(async () => {
  await testDatabaseService.disconnect();
});

