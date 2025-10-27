"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
require("jest");
const database_1 = require("../src/config/database");

beforeAll(async () => {

    process.env.NODE_ENV = 'test';
    process.env.DATABASE_URL = process.env.DATABASE_URL_TEST || 'postgresql://arroz:pollo@localhost:5432/asistapp_test?schema=public';
    await database_1.databaseService.connect();
});
afterAll(async () => {
    await database_1.databaseService.disconnect();
});
