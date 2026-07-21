CREATE TABLE roles (
  id TINYINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  code VARCHAR(32) NOT NULL UNIQUE,
  name_ar VARCHAR(100) NOT NULL
) ENGINE=InnoDB;
INSERT INTO roles (id, code, name_ar) VALUES (1, 'user', 'مستخدم'), (2, 'admin', 'مدير');

CREATE TABLE users (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(254) NOT NULL UNIQUE,
  display_name VARCHAR(80) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
  status ENUM('active','banned','pending') NOT NULL DEFAULT 'active',
  balance BIGINT NOT NULL DEFAULT 0 CHECK (balance >= 0),
  password_changed_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_users_role FOREIGN KEY (role_id) REFERENCES roles(id),
  INDEX idx_users_status (status), INDEX idx_users_created_at (created_at)
) ENGINE=InnoDB;

CREATE TABLE refresh_tokens (
  id CHAR(36) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME(3) NOT NULL,
  revoked_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_refresh_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_refresh_tokens_user_active (user_id, revoked_at, expires_at)
) ENGINE=InnoDB;

CREATE TABLE password_reset_tokens (
  id CHAR(36) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  token_hash CHAR(64) NOT NULL UNIQUE,
  expires_at DATETIME(3) NOT NULL,
  used_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_reset_tokens_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_reset_tokens_user (user_id, expires_at)
) ENGINE=InnoDB;

CREATE TABLE story_categories (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  name_ar VARCHAR(80) NOT NULL UNIQUE,
  slug VARCHAR(80) NOT NULL UNIQUE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3)
) ENGINE=InnoDB;

CREATE TABLE stories (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  category_id BIGINT UNSIGNED NOT NULL,
  title_ar VARCHAR(180) NOT NULL,
  summary_ar TEXT NOT NULL,
  characters_json JSON NOT NULL,
  status ENUM('draft','published','archived') NOT NULL DEFAULT 'draft',
  version INT UNSIGNED NOT NULL DEFAULT 1,
  created_by BIGINT UNSIGNED NULL,
  published_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_stories_category FOREIGN KEY (category_id) REFERENCES story_categories(id),
  CONSTRAINT fk_stories_author FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_stories_selectable (status, category_id, id)
) ENGINE=InnoDB;

CREATE TABLE story_levels (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  story_id BIGINT UNSIGNED NOT NULL,
  level_number TINYINT UNSIGNED NOT NULL CHECK (level_number BETWEEN 1 AND 5),
  narrative_ar TEXT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_levels_story FOREIGN KEY (story_id) REFERENCES stories(id) ON DELETE CASCADE,
  CONSTRAINT uq_story_level UNIQUE (story_id, level_number)
) ENGINE=InnoDB;

CREATE TABLE level_choices (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  level_id BIGINT UNSIGNED NOT NULL,
  choice_number TINYINT UNSIGNED NOT NULL CHECK (choice_number BETWEEN 1 AND 3),
  text_ar TEXT NOT NULL,
  outcome_ar TEXT NOT NULL,
  score_delta SMALLINT NOT NULL DEFAULT 0,
  is_timeout_default BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT fk_choices_level FOREIGN KEY (level_id) REFERENCES story_levels(id) ON DELETE CASCADE,
  CONSTRAINT uq_level_choice UNIQUE (level_id, choice_number)
) ENGINE=InnoDB;

DELIMITER //
CREATE TRIGGER trg_stories_insert_draft
BEFORE INSERT ON stories
FOR EACH ROW
BEGIN
  IF NEW.status <> 'draft' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stories must be created as drafts before publishing';
  END IF;
END//
CREATE TRIGGER trg_stories_publish_structure
BEFORE UPDATE ON stories
FOR EACH ROW
BEGIN
  IF NEW.status = 'published' AND OLD.status <> 'published' THEN
    IF (SELECT COUNT(*) FROM story_levels WHERE story_id = OLD.id) <> 5 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Published stories require exactly five levels';
    END IF;
    IF (SELECT COUNT(*) FROM story_levels l JOIN level_choices c ON c.level_id = l.id WHERE l.story_id = OLD.id) <> 15 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Published stories require exactly three choices per level';
    END IF;
    IF (SELECT COUNT(*) FROM level_choices c JOIN story_levels l ON l.id = c.level_id WHERE l.story_id = OLD.id AND c.is_timeout_default = TRUE) <> 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Published stories require exactly one timeout default choice';
    END IF;
  END IF;
END//
DELIMITER ;

CREATE TABLE games (
  id CHAR(36) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  story_id BIGINT UNSIGNED NOT NULL,
  stake BIGINT NOT NULL CHECK (stake >= 50 AND stake <= 1000),
  current_level TINYINT UNSIGNED NOT NULL DEFAULT 1 CHECK (current_level BETWEEN 1 AND 5),
  status ENUM('active','completed','abandoned','expired') NOT NULL DEFAULT 'active',
  score INT NOT NULL DEFAULT 0,
  level_started_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  completed_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_games_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_games_story FOREIGN KEY (story_id) REFERENCES stories(id),
  INDEX idx_games_user_status (user_id, status, updated_at),
  INDEX idx_games_story (story_id)
) ENGINE=InnoDB;

CREATE TABLE story_assignments (
  user_id BIGINT UNSIGNED NOT NULL,
  story_id BIGINT UNSIGNED NOT NULL,
  game_id CHAR(36) NOT NULL UNIQUE,
  assigned_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  final_status ENUM('active','completed','abandoned','expired') NOT NULL DEFAULT 'active',
  PRIMARY KEY (user_id, story_id),
  CONSTRAINT fk_assignments_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_assignments_story FOREIGN KEY (story_id) REFERENCES stories(id),
  CONSTRAINT fk_assignments_game FOREIGN KEY (game_id) REFERENCES games(id),
  INDEX idx_assignments_user_status (user_id, final_status)
) ENGINE=InnoDB;

CREATE TABLE game_decisions (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  game_id CHAR(36) NOT NULL,
  level_number TINYINT UNSIGNED NOT NULL CHECK (level_number BETWEEN 1 AND 5),
  choice_id BIGINT UNSIGNED NOT NULL,
  was_timeout BOOLEAN NOT NULL DEFAULT FALSE,
  selected_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_decisions_game FOREIGN KEY (game_id) REFERENCES games(id) ON DELETE CASCADE,
  CONSTRAINT fk_decisions_choice FOREIGN KEY (choice_id) REFERENCES level_choices(id),
  CONSTRAINT uq_game_decision UNIQUE (game_id, level_number)
) ENGINE=InnoDB;

CREATE TABLE wallet_transactions (
  id CHAR(36) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  type ENUM('game_stake','game_reward','deposit_approved','withdrawal_hold','withdrawal_rejected_refund','withdrawal_approved','admin_credit','admin_debit') NOT NULL,
  amount BIGINT NOT NULL,
  balance_after BIGINT NOT NULL CHECK (balance_after >= 0),
  reference_type VARCHAR(40) NULL,
  reference_id VARCHAR(64) NULL,
  description_ar VARCHAR(255) NOT NULL,
  created_by BIGINT UNSIGNED NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_transactions_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_transactions_creator FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_transactions_user_date (user_id, created_at DESC),
  INDEX idx_transactions_reference (reference_type, reference_id)
) ENGINE=InnoDB;

CREATE TABLE deposit_requests (
  id CHAR(36) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  amount BIGINT NOT NULL CHECK (amount > 0),
  proof_reference VARCHAR(255) NOT NULL,
  status ENUM('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
  reviewed_by BIGINT UNSIGNED NULL,
  review_note_ar VARCHAR(255) NULL,
  reviewed_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_deposits_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_deposits_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id),
  INDEX idx_deposits_status (status, created_at)
) ENGINE=InnoDB;

CREATE TABLE withdrawal_requests (
  id CHAR(36) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  amount BIGINT NOT NULL CHECK (amount > 0),
  payout_reference VARCHAR(255) NOT NULL,
  status ENUM('pending','approved','rejected','cancelled') NOT NULL DEFAULT 'pending',
  reviewed_by BIGINT UNSIGNED NULL,
  review_note_ar VARCHAR(255) NULL,
  reviewed_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_withdrawals_user FOREIGN KEY (user_id) REFERENCES users(id),
  CONSTRAINT fk_withdrawals_reviewer FOREIGN KEY (reviewed_by) REFERENCES users(id),
  INDEX idx_withdrawals_status (status, created_at)
) ENGINE=InnoDB;

CREATE TABLE notifications (
  id CHAR(36) PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  title_ar VARCHAR(120) NOT NULL,
  body_ar VARCHAR(500) NOT NULL,
  type VARCHAR(40) NOT NULL,
  read_at DATETIME(3) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_notifications_user (user_id, read_at, created_at DESC)
) ENGINE=InnoDB;

CREATE TABLE audit_logs (
  id BIGINT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  actor_user_id BIGINT UNSIGNED NULL,
  action VARCHAR(80) NOT NULL,
  entity_type VARCHAR(80) NOT NULL,
  entity_id VARCHAR(64) NULL,
  metadata_json JSON NULL,
  ip_address VARCHAR(45) NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  CONSTRAINT fk_audit_actor FOREIGN KEY (actor_user_id) REFERENCES users(id) ON DELETE SET NULL,
  INDEX idx_audit_entity (entity_type, entity_id, created_at), INDEX idx_audit_actor (actor_user_id, created_at)
) ENGINE=InnoDB;
