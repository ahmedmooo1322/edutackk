import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import pino from 'pino';
import pinoHttp from 'pino-http';
import { env } from './config/env.js';
import { authRouter } from './routes/auth-routes.js';
import { gameRouter } from './routes/game-routes.js';
import { walletRouter } from './routes/wallet-routes.js';
import { adminRouter } from './routes/admin-routes.js';
import { systemRouter } from './routes/system-routes.js';
import { notificationRouter } from './routes/notification-routes.js';
import { errorHandler, notFoundHandler } from './middleware/error-handler.js';

export function createApp() {
  const app = express();
  const logger = pino({ level: env.LOG_LEVEL, redact: ['req.headers.authorization', 'req.body.password', 'req.body.refreshToken'] });
  app.disable('x-powered-by');
  app.use(pinoHttp({ logger }));
  app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
  app.use(cors({ origin: env.APP_ORIGIN, methods: ['GET', 'POST', 'PATCH'], allowedHeaders: ['Authorization', 'Content-Type'] }));
  app.use(express.json({ limit: '100kb', strict: true }));
  app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 300, standardHeaders: 'draft-8', legacyHeaders: false }));
  app.use('/api/v1/auth', rateLimit({ windowMs: 15 * 60 * 1000, limit: 20, standardHeaders: 'draft-8', legacyHeaders: false }), authRouter);
  app.get('/health', (_req, res) => res.status(200).json({ success: true, data: { status: 'ok' } }));
  app.use('/api/v1/config', systemRouter);
  app.use('/api/v1/games', gameRouter);
  app.use('/api/v1/wallet', walletRouter);
  app.use('/api/v1/notifications', notificationRouter);
  app.use('/api/v1/admin', adminRouter);
  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
