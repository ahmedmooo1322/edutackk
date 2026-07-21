import { AppError } from '../utils/errors.js';

function slugify(value) { return value.trim().toLowerCase().replace(/[^a-z0-9\u0600-\u06ff]+/g, '-').replace(/^-|-$/g, '').slice(0, 80); }
export async function createStory(db, input, authorId = null) {
  const timeoutCount = input.levels.flatMap((level) => level.choices).filter((choice) => choice.timeoutDefault).length;
  if (timeoutCount !== 1) throw new AppError(422, 'INVALID_STORY', 'Exactly one timeout default choice is required across the story');
  const categorySlug = slugify(input.category);
  await db.query('INSERT INTO story_categories (name_ar,slug) VALUES (?,?) ON DUPLICATE KEY UPDATE name_ar=VALUES(name_ar)', [input.category, categorySlug]);
  const category = (await db.query('SELECT id FROM story_categories WHERE slug=?', [categorySlug]))[0];
  const story = await db.query('INSERT INTO stories (category_id,title_ar,summary_ar,characters_json,status,created_by) VALUES (?,?,?,?,?,?)', [category.id, input.title, input.summary, JSON.stringify(input.characters), 'draft', authorId]);
  for (let levelIndex = 0; levelIndex < input.levels.length; levelIndex += 1) {
    const level = input.levels[levelIndex];
    const levelResult = await db.query('INSERT INTO story_levels (story_id,level_number,narrative_ar) VALUES (?,?,?)', [story.insertId, levelIndex + 1, level.narrative]);
    for (let choiceIndex = 0; choiceIndex < level.choices.length; choiceIndex += 1) {
      const choice = level.choices[choiceIndex];
      await db.query('INSERT INTO level_choices (level_id,choice_number,text_ar,outcome_ar,score_delta,is_timeout_default) VALUES (?,?,?,?,?,?)', [levelResult.insertId, choiceIndex + 1, choice.text, choice.outcome, choice.scoreDelta, choice.timeoutDefault]);
    }
  }
  if (input.status !== 'draft') await db.query('UPDATE stories SET status=?,published_at=CASE WHEN ?=\'published\' THEN NOW(3) ELSE NULL END WHERE id=?', [input.status, input.status, story.insertId]);
  return story.insertId;
}
