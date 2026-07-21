import 'dotenv/config';
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  JWT_SECRET: z.string().min(32),
  JWT_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('30d'),
  DB_HOST: z.string().min(1),
  DB_PORT: z.coerce.number().int().default(3306),
  DB_NAME: z.string().regex(/^[A-Za-z0-9_]+$/),
  DB_USER: z.string().min(1),
  DB_PASSWORD: z.string(),
  COIN_NAME: z.string().min(1).max(50).default('Encrypted Tokens'),
  LEVEL_COUNTDOWN_SECONDS: z.coerce.number().int().min(10).max(600).default(30),
  MIN_GAME_ENTRY: z.coerce.number().int().min(50).max(1000).default(50),
  MAX_GAME_ENTRY: z.coerce.number().int().min(50).max(1000).default(1000),
  TIMEOUT_POLICY: z.enum(['auto_choice', 'abandon']).default('auto_choice'),
  AUTO_CHOICE_INDEX: z.coerce.number().int().min(0).max(2).default(0),
  APP_ORIGIN: z.string().url().default('http://localhost:8080'),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  ADMIN_EMAIL: z.string().email(),
  ADMIN_PASSWORD: z.string().min(12),
  SMTP_HOST: z.string().min(1),
  SMTP_PORT: z.coerce.number().int().min(1).max(65535).default(587),
  SMTP_USER: z.string().min(1),
  SMTP_PASSWORD: z.string().min(1),
  SMTP_FROM: z.string().min(3).max(254)
}).superRefine((value, ctx) => {
  if (value.MIN_GAME_ENTRY > value.MAX_GAME_ENTRY) ctx.addIssue({ code: 'custom', message: 'MIN_GAME_ENTRY cannot exceed MAX_GAME_ENTRY', path: ['MIN_GAME_ENTRY'] });
});

export const env = schema.parse(process.env);
