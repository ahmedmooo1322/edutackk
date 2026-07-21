import { createApp } from './app.js';
import { env } from './config/env.js';
import { pool } from './config/database.js';

const app = createApp();
const server = app.listen(env.PORT, () => { process.stdout.write(`The Wiretap API listening on ${env.PORT}\n`); });
async function shutdown(signal) { process.stdout.write(`${signal} received, closing\n`); server.close(async () => { await pool.end(); process.exit(0); }); }
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
