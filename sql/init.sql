DELETE FROM tenant WHERE id > 100;
DELETE FROM visit_history WHERE created_at >= '1654041600';
UPDATE id_generator SET id=2678400000 WHERE stub='a';
ALTER TABLE id_generator AUTO_INCREMENT=2678400000;

DROP TABLE IF EXISTS `visit_history_summary`;
CREATE TABLE `visit_history_summary` (
  `player_id` varchar(255) NOT NULL,
  `tenant_id` bigint unsigned NOT NULL,
  `competition_id` varchar(255) NOT NULL,
  `created_at` bigint NOT NULL
);
CREATE INDEX visit_history_summary_idx ON visit_history_summary (`tenant_id`, `competition_id`, `player_id`);

INSERT INTO visit_history_summary
SELECT player_id, tenant_id, competition_id, MIN(created_at) FROM visit_history GROUP BY player_id, tenant_id, competition_id;
