import { z } from 'zod';

const email = z.string().trim().toLowerCase().email().max(254);
const password = z.string().min(12).max(128);
const page = z.coerce.number().int().min(1).default(1);
const limit = z.coerce.number().int().min(1).max(100).default(20);
export const registerSchema = z.object({ body: z.object({ email, displayName: z.string().trim().min(2).max(80), password }), params: z.object({}), query: z.object({}) });
export const loginSchema = z.object({ body: z.object({ email, password }), params: z.object({}), query: z.object({}) });
export const refreshSchema = z.object({ body: z.object({ refreshToken: z.string().min(40).max(200) }), params: z.object({}), query: z.object({}) });
export const forgotPasswordSchema = z.object({ body: z.object({ email }), params: z.object({}), query: z.object({}) });
export const resetPasswordSchema = z.object({ body: z.object({ token: z.string().min(40).max(200), password }), params: z.object({}), query: z.object({}) });
export const startGameSchema = z.object({ body: z.object({ stake: z.number().int() }), params: z.object({}), query: z.object({}) });
export const choiceSchema = z.object({ body: z.object({ choiceNumber: z.number().int().min(1).max(3) }), params: z.object({ gameId: z.string().uuid() }), query: z.object({}) });
export const gameIdSchema = z.object({ body: z.object({}), params: z.object({ gameId: z.string().uuid() }), query: z.object({}) });
export const walletRequestSchema = z.object({ body: z.object({ amount: z.number().int().positive().max(1_000_000), reference: z.string().trim().min(3).max(255) }), params: z.object({}), query: z.object({}) });
export const paginateSchema = z.object({ body: z.object({}), params: z.object({}), query: z.object({ page, limit }) });
export const adminStatusSchema = z.object({ body: z.object({ status: z.enum(['active', 'banned']) }), params: z.object({ userId: z.coerce.number().int().positive() }), query: z.object({}) });
export const adjustmentSchema = z.object({ body: z.object({ userId: z.number().int().positive(), amount: z.number().int().refine((value) => value !== 0), reason: z.string().trim().min(3).max(255) }), params: z.object({}), query: z.object({}) });
export const requestReviewSchema = z.object({ body: z.object({ action: z.enum(['approve', 'reject']), note: z.string().trim().max(255).optional() }), params: z.object({ requestId: z.string().uuid() }), query: z.object({}) });
export const storySchema = z.object({ body: z.object({
  category: z.string().trim().min(2).max(80), title: z.string().trim().min(3).max(180), summary: z.string().trim().min(10), characters: z.array(z.object({ name: z.string().min(1), role: z.string().min(1) })).min(1), status: z.enum(['draft', 'published', 'archived']).default('draft'),
  levels: z.array(z.object({ narrative: z.string().trim().min(10), choices: z.array(z.object({ text: z.string().trim().min(1), outcome: z.string().trim().min(1), scoreDelta: z.number().int().default(0), timeoutDefault: z.boolean().default(false) })).length(3) })).length(5)
}), params: z.object({}), query: z.object({}) });
