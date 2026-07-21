import argon2 from 'argon2';
import { SignJWT, jwtVerify } from 'jose';
import { env } from '../config/env.js';
import { digest, id } from '../utils/crypto.js';
import { AppError, forbidden } from '../utils/errors.js';

const key = new TextEncoder().encode(env.JWT_SECRET);

export async function hashPassword(password) { return argon2.hash(password, { type: argon2.argon2id, memoryCost: 19456, timeCost: 2, parallelism: 1 }); }
export async function verifyPassword(hash, password) { return argon2.verify(hash, password); }
export async function signAccessToken(user) {
  return new SignJWT({ role: user.role_code, name: user.display_name })
    .setProtectedHeader({ alg: 'HS256' }).setSubject(String(user.id)).setIssuedAt().setExpirationTime(env.JWT_EXPIRES_IN).setJti(id()).sign(key);
}
export async function verifyAccessToken(token) {
  try { return await jwtVerify(token, key, { algorithms: ['HS256'] }); }
  catch { throw new AppError(401, 'UNAUTHORIZED', 'Invalid or expired access token'); }
}
export function issueRefreshToken() { const raw = `${id()}${id()}`; return { raw, tokenHash: digest(raw) }; }
export function refreshExpiry() {
  const match = /^(\d+)([dh])$/.exec(env.JWT_REFRESH_EXPIRES_IN);
  if (!match) throw new Error('JWT_REFRESH_EXPIRES_IN must use d or h, for example 30d');
  return new Date(Date.now() + Number(match[1]) * (match[2] === 'd' ? 86_400_000 : 3_600_000));
}
export function assertActive(user) { if (!user || user.status !== 'active') throw forbidden('This account is unavailable'); }

