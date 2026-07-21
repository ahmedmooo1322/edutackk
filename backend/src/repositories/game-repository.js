export function createGameRepository(db) {
  return {
    findActive: async (userId) => (await db.query("SELECT * FROM games WHERE user_id=? AND status='active' ORDER BY created_at DESC LIMIT 1", [userId]))[0],
    lockGame: async (gameId) => (await db.query('SELECT * FROM games WHERE id=? FOR UPDATE', [gameId]))[0],
    findEligibleStory: async (userId) => (await db.query(`SELECT s.id FROM stories s JOIN story_categories c ON c.id=s.category_id
      WHERE s.status='published' AND c.is_active=TRUE AND NOT EXISTS (SELECT 1 FROM story_assignments a WHERE a.user_id=? AND a.story_id=s.id)
      ORDER BY RAND() LIMIT 1`, [userId]))[0],
    insertGame: (game) => db.query('INSERT INTO games (id,user_id,story_id,stake) VALUES (?,?,?,?)', [game.id, game.userId, game.storyId, game.stake]),
    insertAssignment: (userId, storyId, gameId) => db.query('INSERT INTO story_assignments (user_id,story_id,game_id) VALUES (?,?,?)', [userId, storyId, gameId]),
    loadStory: async (storyId) => {
      const story = (await db.query('SELECT s.id,s.title_ar,s.summary_ar,s.characters_json,c.name_ar category FROM stories s JOIN story_categories c ON c.id=s.category_id WHERE s.id=?', [storyId]))[0];
      if (!story) return null;
      const levels = await db.query(`SELECT l.id,l.level_number,l.narrative_ar,c.id choice_id,c.choice_number,c.text_ar,c.outcome_ar
        FROM story_levels l JOIN level_choices c ON c.level_id=l.id WHERE l.story_id=? ORDER BY l.level_number,c.choice_number`, [storyId]);
      const indexed = new Map();
      for (const row of levels) {
        if (!indexed.has(row.level_number)) indexed.set(row.level_number, { number: row.level_number, narrative: row.narrative_ar, choices: [] });
        indexed.get(row.level_number).choices.push({ id: row.choice_id, number: row.choice_number, text: row.text_ar, outcome: row.outcome_ar });
      }
      return { id: story.id, title: story.title_ar, summary: story.summary_ar, category: story.category, characters: JSON.parse(story.characters_json), levels: [...indexed.values()] };
    },
    choiceForLevel: async (storyId, levelNumber, choiceNumber) => (await db.query(`SELECT c.* FROM story_levels l JOIN level_choices c ON c.level_id=l.id
      WHERE l.story_id=? AND l.level_number=? AND c.choice_number=?`, [storyId, levelNumber, choiceNumber]))[0],
    defaultChoice: async (storyId, levelNumber, index) => (await db.query(`SELECT c.* FROM story_levels l JOIN level_choices c ON c.level_id=l.id
      WHERE l.story_id=? AND l.level_number=? AND c.choice_number=?`, [storyId, levelNumber, index + 1]))[0],
    recordDecision: (gameId, level, choiceId, wasTimeout) => db.query('INSERT INTO game_decisions (game_id,level_number,choice_id,was_timeout) VALUES (?,?,?,?)', [gameId, level, choiceId, wasTimeout]),
    advance: (game, nextLevel, score) => db.query('UPDATE games SET current_level=?,score=?,level_started_at=NOW(3) WHERE id=?', [nextLevel, score, game.id]),
    complete: (game, score, status = 'completed') => db.query('UPDATE games SET status=?,score=?,completed_at=NOW(3) WHERE id=?', [status, score, game.id]),
    setAssignmentStatus: (gameId, status) => db.query('UPDATE story_assignments SET final_status=? WHERE game_id=?', [status, gameId]),
    decisions: (gameId) => db.query('SELECT d.level_number,d.was_timeout,d.selected_at,c.choice_number,c.text_ar,c.outcome_ar FROM game_decisions d JOIN level_choices c ON c.id=d.choice_id WHERE d.game_id=? ORDER BY d.level_number', [gameId]),
    history: (userId, limit, offset) => db.query('SELECT g.id,g.stake,g.status,g.score,g.current_level,g.created_at,g.completed_at,s.title_ar FROM games g JOIN stories s ON s.id=g.story_id WHERE g.user_id=? ORDER BY g.created_at DESC LIMIT ? OFFSET ?', [userId, limit, offset]),
    abandon: (game) => db.query("UPDATE games SET status='abandoned',completed_at=NOW(3) WHERE id=?", [game.id])
  };
}

