import test from 'node:test';
import assert from 'node:assert/strict';
import request from 'supertest';

Object.assign(process.env, {
  JWT_SECRET: 'test-secret-that-is-long-enough-for-the-required-validation-value', DB_HOST: 'localhost', DB_PORT: '3306', DB_NAME: 'the_wiretap', DB_USER: 'wiretap', DB_PASSWORD: 'test', ADMIN_EMAIL: 'admin@example.test', ADMIN_PASSWORD: 'AdministratorPassword123!', SMTP_HOST: 'mail.example.test', SMTP_PORT: '587', SMTP_USER: 'wiretap@example.test', SMTP_PASSWORD: 'test', SMTP_FROM: 'wiretap@example.test'
});
const { createApp } = await import('../src/app.js');
const app = createApp();
test('health endpoint responds without database access', async () => { const response = await request(app).get('/health').expect(200); assert.deepEqual(response.body, { success: true, data: { status: 'ok' } }); });
test('unknown endpoint has standard error envelope', async () => { const response = await request(app).get('/missing').expect(404); assert.equal(response.body.success, false); assert.equal(response.body.error.code, 'NOT_FOUND'); });
