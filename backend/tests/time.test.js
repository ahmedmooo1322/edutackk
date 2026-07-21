import test from 'node:test';
import assert from 'node:assert/strict';
import { remainingSeconds } from '../src/utils/time.js';

test('remainingSeconds rounds up until server deadline', () => {
  const started = '2026-01-01T00:00:00.000Z';
  assert.equal(remainingSeconds(started, 30, Date.parse('2026-01-01T00:00:00.001Z')), 30);
  assert.equal(remainingSeconds(started, 30, Date.parse('2026-01-01T00:00:29.001Z')), 1);
  assert.equal(remainingSeconds(started, 30, Date.parse('2026-01-01T00:00:30.000Z')), 0);
});

