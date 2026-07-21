import { inTransaction } from '../config/database.js';
import { env } from '../config/env.js';
import { id } from '../utils/crypto.js';
import { AppError, conflict, notFound } from '../utils/errors.js';
import { remainingSeconds } from '../utils/time.js';
import { createGameRepository } from '../repositories/game-repository.js';
import { createUserRepository } from '../repositories/user-repository.js';
import { createWalletService } from './wallet-service.js';
import { audit } from '../repositories/audit-repository.js';

function gameView(game, story, decisions = []) {
  const level = story.levels.find((entry) => entry.number === game.current_level);
  return {
    id: game.id, status: game.status, stake: game.stake, score: game.score, currentLevel: game.current_level,
    timeRemainingSeconds: game.status === 'active' ? remainingSeconds(game.level_started_at, env.LEVEL_COUNTDOWN_SECONDS) : 0,
    story: { id: story.id, title: story.title, category: story.category, characters: story.characters },
    level: level ? { number: level.number, narrative: level.narrative, choices: level.choices.map(({ id: _id, ...choice }) => choice) } : null,
    decisions
  };
}

export async function startGame(userId, stake, ip) {
  if (!Number.isInteger(stake) || stake < env.MIN_GAME_ENTRY || stake > env.MAX_GAME_ENTRY) throw new AppError(422, 'INVALID_STAKE', `Stake must be between ${env.MIN_GAME_ENTRY} and ${env.MAX_GAME_ENTRY}`);
  return inTransaction(async (db) => {
    const games = createGameRepository(db);
    const users = createUserRepository(db);
    const wallet = createWalletService(db, users);
    await users.lock(userId);
    const active = await games.findActive(userId);
    if (active) throw conflict('Resume the unfinished game before starting another one');
    const storyRef = await games.findEligibleStory(userId);
    if (!storyRef) throw new AppError(409, 'NO_NEW_STORIES', 'No new stories available');
    const game = { id: id(), userId, storyId: storyRef.id, stake };
    await wallet.changeBalance({ userId, amount: -stake, type: 'game_stake', description: 'دخول مهمة جديدة', referenceType: 'game', referenceId: game.id });
    await games.insertGame(game);
    await games.insertAssignment(userId, game.storyId, game.id);
    await audit(db, { actorUserId: userId, action: 'game.started', entityType: 'game', entityId: game.id, metadata: { storyId: game.storyId, stake }, ip });
    const story = await games.loadStory(game.storyId);
    return gameView({ ...game, status: 'active', score: 0, current_level: 1, level_started_at: new Date() }, story);
  });
}

async function applyChoice(db, game, choice, wasTimeout) {
  const games = createGameRepository(db);
  await games.recordDecision(game.id, game.current_level, choice.id, wasTimeout);
  const score = game.score + choice.score_delta;
  if (game.current_level === 5) {
    await games.complete(game, score);
    await games.setAssignmentStatus(game.id, 'completed');
    return { ...game, status: 'completed', score, completed_at: new Date() };
  }
  await games.advance(game, game.current_level + 1, score);
  return { ...game, current_level: game.current_level + 1, score, level_started_at: new Date() };
}

async function resolveExpired(db, game) {
  if (game.status !== 'active' || remainingSeconds(game.level_started_at, env.LEVEL_COUNTDOWN_SECONDS) > 0) return game;
  const games = createGameRepository(db);
  if (env.TIMEOUT_POLICY === 'abandon') {
    await games.abandon(game);
    await games.setAssignmentStatus(game.id, 'abandoned');
    return { ...game, status: 'abandoned', completed_at: new Date() };
  }
  const choice = await games.defaultChoice(game.story_id, game.current_level, env.AUTO_CHOICE_INDEX);
  if (!choice) throw new AppError(500, 'INVALID_STORY', 'Timeout choice is missing');
  return applyChoice(db, game, choice, true);
}

export async function getGame(userId, gameId) {
  return inTransaction(async (db) => {
    const games = createGameRepository(db);
    let game = await games.lockGame(gameId);
    if (!game || game.user_id !== userId) throw notFound('Game not found');
    game = await resolveExpired(db, game);
    const story = await games.loadStory(game.story_id);
    return gameView(game, story, await games.decisions(game.id));
  });
}

export async function submitChoice(userId, gameId, choiceNumber, ip) {
  return inTransaction(async (db) => {
    const games = createGameRepository(db);
    let game = await games.lockGame(gameId);
    if (!game || game.user_id !== userId) throw notFound('Game not found');
    game = await resolveExpired(db, game);
    if (game.status !== 'active') throw conflict('This game is no longer active');
    const choice = await games.choiceForLevel(game.story_id, game.current_level, choiceNumber);
    if (!choice) throw new AppError(422, 'INVALID_CHOICE', 'Choice does not exist for this level');
    game = await applyChoice(db, game, choice, false);
    await audit(db, { actorUserId: userId, action: 'game.choice_submitted', entityType: 'game', entityId: game.id, metadata: { level: game.status === 'completed' ? 5 : game.current_level - 1, choiceNumber }, ip });
    const story = await games.loadStory(game.story_id);
    return { ...gameView(game, story, await games.decisions(game.id)), outcome: choice.outcome_ar };
  });
}

export async function resumeGame(userId) {
  return inTransaction(async (db) => {
    const games = createGameRepository(db);
    let game = await games.findActive(userId);
    if (!game) throw notFound('No unfinished game');
    game = await games.lockGame(game.id);
    game = await resolveExpired(db, game);
    const story = await games.loadStory(game.story_id);
    return gameView(game, story, await games.decisions(game.id));
  });
}

export async function abandonGame(userId, gameId, ip) {
  return inTransaction(async (db) => {
    const games = createGameRepository(db);
    const game = await games.lockGame(gameId);
    if (!game || game.user_id !== userId) throw notFound('Game not found');
    if (game.status !== 'active') throw conflict('Only active games can be abandoned');
    await games.abandon(game);
    await games.setAssignmentStatus(game.id, 'abandoned');
    await audit(db, { actorUserId: userId, action: 'game.abandoned', entityType: 'game', entityId: game.id, ip });
    return { id: game.id, status: 'abandoned' };
  });
}
