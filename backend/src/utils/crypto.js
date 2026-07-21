import { createHash, randomUUID } from 'node:crypto';

export const id = () => randomUUID();
export const digest = (value) => createHash('sha256').update(value).digest('hex');

