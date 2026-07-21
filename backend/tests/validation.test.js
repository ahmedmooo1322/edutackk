import test from 'node:test';
import assert from 'node:assert/strict';
import { storySchema } from '../src/validators/schemas.js';

const choice = { text: 'أكمل', outcome: 'نتيجة' };
test('story validation rejects any level without exactly three choices', () => {
  const invalid = { body: { category: 'خيانة', title: 'عنوان صالح', summary: 'ملخص صالح طويل كفاية', characters: [{ name: 'أحمد', role: 'صاحب الحكاية' }], levels: Array.from({ length: 5 }, () => ({ narrative: 'نص مستوى طويل كفاية للاختبار', choices: [choice, choice] })) }, params: {}, query: {} };
  assert.throws(() => storySchema.parse(invalid));
});
