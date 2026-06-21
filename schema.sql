/* 	============================================================================
		LOL COMPETITIVE ANALYTICS - Oracle's Elixir Database (2018-2025)
    ----------------------------------------------------------------------------
	The original dataset consisted of separate CSV files for each year. 
    This project focuses on cleaning, normalizing, and analyzing the data to
    find powerful insights that can help teams improve their performance.
    
    This file contains the schema design.
	============================================================================ */
    
/* 	============================================================================
		1. SET UP - DATABASE CREATION AND DROPS FOR END-TO-END RUN
    =========================================================================== */

-- DataBase Creation
CREATE DATABASE IF NOT EXISTS lol_competitive
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

-- DataBase Selection    
USE lol_competitive;

-- Drops for end-to-end run
DROP VIEW IF EXISTS top10_teams;
DROP VIEW IF EXISTS top10_toplaners;
DROP FUNCTION IF EXISTS calcKDA;
DROP TABLE IF EXISTS player_stats;
DROP TABLE IF EXISTS bans;
DROP TABLE IF EXISTS team_stats;
DROP TABLE IF EXISTS games_info;
DROP TABLE IF EXISTS champions;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS teams;
DROP TABLE IF EXISTS leagues;

/* 	============================================================================
		2. TABLES CREATION
    =========================================================================== */

/* 	============================================================================
		2.1 FIRST TABLE [DIMENSION] - LEAGUES
    =========================================================================== */
CREATE TABLE IF NOT EXISTS leagues (
    league_id   INT AUTO_INCREMENT PRIMARY KEY,
    league_name VARCHAR(50) UNIQUE NOT NULL,
    region      VARCHAR(50) NOT NULL
);

/* 	============================================================================
		2.2 SECOND TABLE [DIMENSION] - TEAMS
    =========================================================================== */
CREATE TABLE IF NOT EXISTS teams (
    team_id      INT AUTO_INCREMENT PRIMARY KEY,
    team_name    VARCHAR(100) NOT NULL UNIQUE
);

/* 	============================================================================
		2.3 THIRD TABLE [DIMENSION] - PLAYERS
    =========================================================================== */
CREATE TABLE IF NOT EXISTS players (
    player_id   VARCHAR(200) PRIMARY KEY,
    player_name VARCHAR(75) NOT NULL
);

/* 	============================================================================
		2.4 FOURTH TABLE [DIMENSION] - CHAMPIONS
    =========================================================================== */
CREATE TABLE IF NOT EXISTS champions (
    champ_id     	INT AUTO_INCREMENT PRIMARY KEY,
    champ_name   	VARCHAR(50) UNIQUE NOT NULL,
    champ_role		VARCHAR(25) NOT NULL,
    champ_subrole	VARCHAR(25) NOT NULL
);

/* 	============================================================================
		2.5 FIFTH TABLE [DIMENSION] - GAMES
    =========================================================================== */
CREATE TABLE IF NOT EXISTS games_info (
    game_id     VARCHAR(50) PRIMARY KEY,
    game_date   DATETIME,
    patch       VARCHAR(10),
    split       VARCHAR(25),
    playoffs    BOOLEAN NOT NULL,
    duration    INT NOT NULL,		    -- in seconds
    league_id   INT NOT NULL
);

/* 	============================================================================
		2.6 SIXTH TABLE [DIMENSION] - TEAM STATS PER GAME
    =========================================================================== */
CREATE TABLE IF NOT EXISTS team_stats (
    team_stats_id   INT AUTO_INCREMENT PRIMARY KEY,
    game_id         VARCHAR(50) NOT NULL,
    team_id         INT NOT NULL,
    side            ENUM('Blue', 'Red') NOT NULL,
    win          	BOOLEAN NOT NULL,
    firstblood      BOOLEAN,
    firstdragon     BOOLEAN,
    firstherald     BOOLEAN,
    firstbaron      BOOLEAN,
    firsttower      BOOLEAN,
    dragons         INT,
    infernals       INT,
    mountains       INT,
    clouds          INT,
    oceans          INT,
    chemtechs       INT,
    hextechs        INT,
    elders          INT,
    barons          INT,
    heralds         INT,
    void_grubs      INT,
    towers          INT,
    inhibitors      INT,
    
    CONSTRAINT uq_game_team UNIQUE (game_id, team_id)
);

/* 	============================================================================
		2.7 SEVENTH TABLE [DIMENSION] - BANS
    =========================================================================== */
CREATE TABLE IF NOT EXISTS bans (
    ban_id      INT AUTO_INCREMENT PRIMARY KEY,
    game_id     VARCHAR(50) NOT NULL,
    team_id     INT NOT NULL,
    champ_id    INT NOT NULL,
    ban_order   INT NOT NULL,
    
    CONSTRAINT uq_game_team_ban UNIQUE (game_id, team_id, ban_order)
);

/* 	============================================================================
		2.8 EIGHTH TABLE [FACT] - PLAYER STATS PER GAME
    =========================================================================== */
CREATE TABLE IF NOT EXISTS player_stats (
    stat_id             INT AUTO_INCREMENT PRIMARY KEY,
    game_id             VARCHAR(50) NOT NULL,
    player_id           VARCHAR(200) NOT NULL,
    team_id        		INT NOT NULL,
    champ_id            INT NOT NULL,
    position            ENUM('Top', 'Jng', 'Mid', 'Bot', 'Sup') NOT NULL,
    side                ENUM('Blue', 'Red') NOT NULL,
    win	                BOOLEAN NOT NULL,
    kills               INT,
    deaths              INT,
    assists             INT,
    dpm                 FLOAT,
    damageshare         FLOAT,
    damagetakenpermin   FLOAT,
    wardsplaced         INT,
    wardskilled         INT,
    controlwardsbought  INT,
    visionscore         INT,
    totalgold           INT,
    earnedgold          INT,
    goldspent           INT,
    total_cs            INT,
    cspm                FLOAT,
    golddiffat10        INT,  
    golddiffat15        INT,
    golddiffat20        INT,
    golddiffat25        INT,
	csdiffat10  	  	INT,
	csdiffat15   	 	INT,
    csdiffat20   	 	INT,
	csdiffat25   	 	INT,
    xpdiffat10    		INT,
    xpdiffat15  	  	INT,
    xpdiffat20   	 	INT,
    xpdiffat25   	 	INT,
    
    CONSTRAINT uq_game_player UNIQUE (game_id, player_id)
);

/* 	============================================================================
		3. FOREIGN KEYS
    =========================================================================== */

/* ============================================================================
	3.1 GAMES_INFO ~ LEAGUES
    ============================================================================ */
ALTER TABLE games_info
    ADD CONSTRAINT fk_league_game
        FOREIGN KEY (league_id) REFERENCES leagues(league_id);

/* ============================================================================
	3.2 TEAM_STATS ~ GAMES_INFO & TEAMS
    ============================================================================ */
ALTER TABLE team_stats
    ADD CONSTRAINT fk_game_teamstats
        FOREIGN KEY (game_id) REFERENCES games_info(game_id),
    ADD CONSTRAINT fk_team_teamstats
        FOREIGN KEY (team_id) REFERENCES teams(team_id);

/* ============================================================================
	3.3 BANS ~ GAMES_INFO & TEAMS & CHAMPIONS 
    ============================================================================ */
ALTER TABLE bans
    ADD CONSTRAINT fk_game_bans
        FOREIGN KEY (game_id) REFERENCES games_info(game_id),
    ADD CONSTRAINT fk_team_bans
        FOREIGN KEY (team_id) REFERENCES teams(team_id),
    ADD CONSTRAINT fk_champ_bans
        FOREIGN KEY (champ_id) REFERENCES champions(champ_id);

/* ============================================================================
	3.4 PLAYER_STATS ~ GAMES_INFO & PLAYERS & TEAMS & CHAMPIONS
    ============================================================================ */
ALTER TABLE player_stats
    ADD CONSTRAINT fk_game_playerstats
        FOREIGN KEY (game_id) REFERENCES games_info(game_id),
    ADD CONSTRAINT fk_player_playerstats
        FOREIGN KEY (player_id) REFERENCES players(player_id),
    ADD CONSTRAINT fk_team_playerstats
        FOREIGN KEY (team_id) REFERENCES teams(team_id),
    ADD CONSTRAINT fk_champ_playerstats
        FOREIGN KEY (champ_id) REFERENCES champions(champ_id);