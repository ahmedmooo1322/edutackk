import { readFile } from 'node:fs/promises';
import { inTransaction, pool } from '../src/config/database.js';
import { createStory } from '../src/services/story-service.js';
import { storySchema } from '../src/validators/schemas.js';

const filename = process.argv[2];
if (!filename) throw new Error('Usage: npm run import:stories -- /absolute/or/relative/stories.json');
const document = JSON.parse(await readFile(filename, 'utf8'));
const source = Array.isArray(document) ? document : document.stories;
if (!Array.isArray(source) || source.length === 0) throw new Error('The JSON document must be an array or contain a non-empty stories array');
let imported = 0;
try {
  for (const raw of source) {
    const normalized = {
      category: raw.category, title: raw.title, summary: raw.summary, characters: raw.characters,
      status: raw.status || (raw.published === true ? 'published' : 'draft'),
      levels: raw.levels.map((level, levelIndex) => ({
        narrative: level.narrative || level.story,
        choices: level.choices.map((choice, choiceIndex) => ({
          text: choice.text, outcome: choice.outcome || choice.result,
          scoreDelta: choice.scoreDelta || 0,
          timeoutDefault: Boolean(choice.timeoutDefault) || (levelIndex === 0 && choiceIndex === 0 && !raw.levels.some((item) => item.choices.some((entry) => entry.timeoutDefault)))
        }))
      }))
    };
    const parsed = storySchema.parse({ body: normalized, params: {}, query: {} }).body;
    await inTransaction((db) => createStory(db, parsed));
    imported += 1;
  }
  process.stdout.write(`Imported ${imported} stories.\n`);
} finally { await pool.end(); }

