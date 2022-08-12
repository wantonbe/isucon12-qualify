CREATE TABLE player_score_summmary (
  id VARCHAR(255) NOT NULL PRIMARY KEY,
  tenant_id BIGINT NOT NULL,
  player_id VARCHAR(255) NOT NULL,
  competition_id VARCHAR(255) NOT NULL,
  score BIGINT NOT NULL,
  row_num BIGINT NOT NULL,
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL
);

INSERT INTO player_score_summmary (id, tenant_id, player_id, competition_id, score, row_num, created_at, updated_at) SELECT id, tenant_id, player_id, competition_id, score, row_num, created_at, updated_at FROM player_score GROUP BY tenant_id, player_id, competition_id;

ALTER TABLE player_score RENAME TO player_score_org;
ALTER TABLE player_score_summmary RENAME TO player_score;
