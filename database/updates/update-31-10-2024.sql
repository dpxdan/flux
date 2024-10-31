CREATE TABLE `git_version` (
  `id` int NOT NULL AUTO_INCREMENT,
  `commit_hash` varchar(40) NOT NULL,
  `description` text,
  `tittle` text,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `is_current` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id`)
);

---  

CREATE  OR REPLACE 
    ALGORITHM = UNDEFINED 
    DEFINER = `fluxuser`@`localhost` 
    SQL SECURITY INVOKER
VIEW `view_git_version` AS
    SELECT 
        `git_version`.`id` AS `id`,
        `git_version`.`commit_hash` AS `commit_hash`,
        `git_version`.`tittle` AS `tittle`,
        `git_version`.`description` AS `description`,
        `git_version`.`updated_at` AS `updated_at`,
        (CASE
            WHEN (`git_version`.`is_current` = 0) THEN CONCAT('Ativo/Atual')
            ELSE CONCAT('Inativo')
        END) AS `is_current`
    FROM
        `git_version`;


