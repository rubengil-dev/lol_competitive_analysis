/* 	============================================================================
		LOL COMPETITIVE ANALYTICS - Oracle's Elixir Database (2018-2025)
    ----------------------------------------------------------------------------
	The original dataset consisted of separate CSV files for each year. 
    This project focuses on cleaning, normalizing, and analyzing the data to
    find powerful insights that can help teams improve their performance.
    
    This file contains the data quality, cleaning, exploratory análisis and 
    business questions answering.
	============================================================================ */
    
-- DataBase Selection
USE lol_competitive;

/* 	============================================================================
		1. DATA QUALITY CHECK: Ensuring data insert was succesfull
	============================================================================ */
    
/*  For every null and duplicate check I expect both to be 0 due to how data was
    imported. However, I stil checked it with the rest of data quality check.    */
    
/* 	============================================================================
		1.1. TABLES: CHAMPIONS, LEAGUES, PLAYERS & TEAMS [NO DEPENDENCIES]
	============================================================================ */

-- Champions
SELECT 
	COUNT(*) AS total_rows,													-- 172
    COUNT(DISTINCT champ_name) AS unique_champs,							-- 172
    SUM(CASE WHEN champ_name IS NULL THEN 1 ELSE 0 END) AS null_names,		-- 0
    SUM(CASE WHEN champ_role IS NULL THEN 1 ELSE 0 END) AS null_role,		-- 0
    SUM(CASE WHEN champ_subrole IS NULL THEN 1 ELSE 0 END) AS null_subrole	-- 0
FROM champions;

-- Leagues
SELECT 
	COUNT(*) AS total_rows,													-- 112
    COUNT(DISTINCT league_name) AS unique_leagues,							-- 112
    SUM(CASE WHEN league_name IS NULL THEN 1 ELSE 0 END) AS null_name,		-- 0
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) AS null_region			-- 0
FROM leagues;

-- Players
SELECT 
	COUNT(*) AS total_rows,													-- 9479
    COUNT(DISTINCT player_name) AS unique_names,							-- 8974
    SUM(CASE WHEN player_name IS NULL THEN 1 ELSE 0 END) AS null_player		-- 0
FROM players;

-- Teams
SELECT 
    COUNT(*) AS total_rows,                                                 -- 1981
    COUNT(DISTINCT team_name) AS unique_teams,                              -- 1981
    SUM(CASE WHEN team_name IS NULL THEN 1 ELSE 0 END) AS null_name        -- 0
FROM teams;

/* 	============================================================================
		1.2. TABLE: GAMES INFORMATION [1 DEPENDENCY]
	============================================================================ */
SELECT 
	COUNT(*) AS total_rows,													-- 80760 -> 78173
    COUNT(DISTINCT game_id) AS unique_games,								-- 80760 -> 78173
    SUM(CASE WHEN game_date IS NULL THEN 1 ELSE 0 END) AS null_date,		-- 0
    SUM(CASE WHEN playoffs IS NULL THEN 1 ELSE 0 END) AS null_playoffs,		-- 0
    SUM(CASE WHEN duration IS NULL THEN 1 ELSE 0 END) AS null_duration,		-- 0
    SUM(CASE WHEN league_id IS NULL THEN 1 ELSE 0 END) AS null_league		-- 0
FROM games_info;

/* 	============================================================================
		1.3. TABLE: TEAM STATS [2 DEPENDENCIES]
	============================================================================ */
SELECT 
	COUNT(*) AS total_rows,													-- 161499 -> 156344
    SUM(CASE WHEN team_id IS NULL THEN 1 ELSE 0 END) AS null_team,			-- 0
    SUM(CASE WHEN side IS NULL THEN 1 ELSE 0 END) AS null_side,				-- 0
    SUM(CASE WHEN win IS NULL THEN 1 ELSE 0 END) AS null_win				-- 0
FROM team_stats;

-- Duplicates check based on Game_id-Team_id
WITH Counter AS (
    SELECT game_id, team_id, COUNT(*) AS times
    FROM team_stats
    GROUP BY game_id, team_id
    HAVING COUNT(*) > 1
)
SELECT COUNT(*) AS duplicates FROM Counter;									-- 0

/* 	============================================================================
		1.4. TABLE: BANS [2+ DEPENDENCIES]
	============================================================================ */
SELECT 
	COUNT(*) AS total_rows,													-- 788010 -> 763045
    SUM(CASE WHEN game_id IS NULL THEN 1 ELSE 0 END) AS null_game,			-- 0
    SUM(CASE WHEN team_id IS NULL THEN 1 ELSE 0 END) AS null_team,			-- 0
    SUM(CASE WHEN champ_id IS NULL THEN 1 ELSE 0 END) AS null_champ,		-- 0
    SUM(CASE WHEN ban_order IS NULL THEN 1 ELSE 0 END) AS null_order		-- 0
FROM bans;

-- Duplicates check based on Game_id-Team_id-Ban_order
WITH Counter AS (
    SELECT game_id, team_id, ban_order, COUNT(*) AS times
    FROM bans
    GROUP BY game_id, team_id, ban_order
    HAVING COUNT(*) > 1			
) 
SELECT COUNT(*) AS duplicates FROM Counter;									-- 0

/* 	============================================================================
		1.5. TABLE: PLAYER STATS [2+ DEPENDENCIES]
	============================================================================ */
SELECT 
	COUNT(*) AS total_rows,													-- 801318 -> 781570
    SUM(CASE WHEN player_id IS NULL THEN 1 ELSE 0 END) AS null_player,		-- 0
    SUM(CASE WHEN game_id IS NULL THEN 1 ELSE 0 END) AS null_game,			-- 0
    SUM(CASE WHEN team_id IS NULL THEN 1 ELSE 0 END) AS null_team,			-- 0
    SUM(CASE WHEN champ_id IS NULL THEN 1 ELSE 0 END) AS null_champ,		-- 0
    SUM(CASE WHEN position IS NULL THEN 1 ELSE 0 END) AS null_rol,			-- 0
    SUM(CASE WHEN side IS NULL THEN 1 ELSE 0 END) AS null_side,				-- 0
    SUM(CASE WHEN win IS NULL THEN 1 ELSE 0 END) AS null_win				-- 0
FROM player_stats;

-- Duplicates check based on Game_id-Player_id
WITH Counter AS (
    SELECT game_id, player_id, COUNT(*) AS times
    FROM player_stats
    GROUP BY game_id, player_id
    HAVING COUNT(*) > 1			
) 
SELECT COUNT(*) AS duplicates FROM Counter;									-- 0

/* 	============================================================================
		1.6. CROSS-TABLE CONSISTENCY CHECKS
	============================================================================ */

-- Every game must have exactly 2 teams in team_stats (Blue & Red)
SELECT COUNT(*) AS games_without_2_teams
FROM (
    SELECT game_id
    FROM team_stats
    GROUP BY game_id
    HAVING COUNT(*) != 2
) AS check_table;															-- 19 -> 0

-- Every game must have exactly 10 players in player_stats
SELECT COUNT(*) AS games_without_10_players
FROM (
    SELECT game_id
    FROM player_stats
    GROUP BY game_id
    HAVING COUNT(*) != 10
) AS check_table;															-- 2587 -> 0

/* 	============================================================================
		1.7. CLEANING WRONG DATA
	============================================================================ */

-- Delete or not delete, but not half deletes
START TRANSACTION;

-- Identify problematic game_ids
CREATE TEMPORARY TABLE games_to_delete AS
    SELECT game_id FROM team_stats
    GROUP BY game_id
    HAVING COUNT(*) != 2													-- Games with no exactly 2 teams
    
    UNION
    
    SELECT game_id FROM player_stats
    GROUP BY game_id
    HAVING COUNT(*) != 10;													-- Games with no exactly 10 players

-- Delete in order (child tables first)
DELETE FROM player_stats WHERE game_id IN (SELECT game_id FROM games_to_delete);
DELETE FROM bans         WHERE game_id IN (SELECT game_id FROM games_to_delete);
DELETE FROM team_stats   WHERE game_id IN (SELECT game_id FROM games_to_delete);
DELETE FROM games_info   WHERE game_id IN (SELECT game_id FROM games_to_delete);

DROP TEMPORARY TABLE games_to_delete;

COMMIT;

-- There is no NULL UPDATE because no NULL were introduced during data loading

/* 	============================================================================
		1.8. "OUTLIER" DETECTION [nonsense data]
	============================================================================ */

-- Most of these checks are redundant because it was managed on data loading.

-- Games with invalid duration (0 or negative)
SELECT COUNT(*) AS WrongGames
FROM games_info
WHERE duration <= 0;														-- 0

-- Players with negative kills, deaths or assists
SELECT COUNT(*) AS WrongGames
FROM player_stats
WHERE kills < 0 OR deaths < 0 OR assists < 0;								-- 0

-- Games with future dates
SELECT COUNT(*) AS WrongGames
FROM games_info
WHERE game_date > NOW();													-- 0

-- Invalid win values in team_stats
SELECT COUNT(*) AS WrongGames
FROM team_stats
WHERE win NOT IN (0, 1);													-- 0

-- Invalid win values in player_stats
SELECT COUNT(*) AS WrongGames
FROM player_stats
WHERE win NOT IN (0, 1);													-- 0

-- Invalid side values
SELECT COUNT(*) AS WrongGames
FROM team_stats
WHERE side NOT IN ('Blue', 'Red');

-- Invalid position values
SELECT COUNT(*) AS WrongGames
FROM player_stats
WHERE position NOT IN ('Top', 'Jng', 'Mid', 'Bot', 'Sup');					-- 0

/* ============================================================================
   2. EXPLORATORY DATA ANALYSIS
   ============================================================================ */

/* ============================================================================
   2.1. GENERAL DATASET OVERVIEW
   ============================================================================ */

-- Data Scope: Nº games, players & teams
SELECT
    (SELECT COUNT(*) FROM games_info) AS TotalGames,						-- 78173
    (SELECT COUNT(*) FROM teams)      AS TotalTeams,						-- 1981
    (SELECT COUNT(*) FROM players)    AS TotalPlayers,						-- 9479
    (SELECT COUNT(DISTINCT ps.player_id) 
     FROM player_stats ps
     JOIN games_info g ON ps.game_id = g.game_id
     JOIN leagues l ON g.league_id = l.league_id
     WHERE l.region != 'Regional League') AS MajorLeaguePlayers;			-- 1583

-- Champ Info
SELECT
	(SELECT COUNT(*) FROM champions) AS TotalChamps,						-- 172
    (SELECT COUNT(DISTINCT champ_role) FROM champions) AS TotalRoles,		-- 6
    (SELECT COUNT(DISTINCT champ_subrole) FROM champions) AS TotalSubRoles,	-- 12
    (SELECT GROUP_CONCAT(DISTINCT champ_role ORDER BY champ_role)
		FROM champions) AS RolesNames,										-- Assassin, Fighter, Mage, Marksman, Support, Tank
    (SELECT GROUP_CONCAT(DISTINCT champ_subrole ORDER BY champ_subrole)
		FROM champions) AS SubrolesNames;									-- Artillery, Assassin, Battlemage, Catcher, Diver, Enchanter,
																			-- Juggernaut, Marksman, Skirmisher, Specialist, Vanguard, Warden

/* ============================================================================
   2.2. GAME DATA OVERVIEW
   ============================================================================ */

-- Average Game Duration
SELECT 
    CONCAT(
		FLOOR(AVG(duration) / 60), 
		"' ",
        LPAD(ROUND(MOD(AVG(duration), 60)), 2, '0'),
        "''") AS GlobalDuration
FROM games_info;															-- 31' 57''
     
-- Kills x Game
WITH KillsPerGame AS (
    SELECT game_id, SUM(kills) AS TotalKills
    FROM player_stats
    WHERE kills IS NOT NULL
    GROUP BY game_id
)
SELECT ROUND(AVG(TotalKills), 2) AS GlobalAvgKills
FROM KillsPerGame;															-- ~28.66

-- Objectives x Game
WITH ObjectivesPerGame AS (
    SELECT
        game_id,
        SUM(CASE WHEN side = 'Blue' THEN dragons ELSE 0 END) AS BlueDragons,
        SUM(CASE WHEN side = 'Red' THEN dragons ELSE 0 END) AS RedDragons,
        SUM(CASE WHEN side = 'Blue' THEN heralds ELSE 0 END) AS BlueHeralds,
        SUM(CASE WHEN side = 'Red' THEN heralds ELSE 0 END) AS RedHeralds,
        SUM(CASE WHEN side = 'Blue' THEN barons ELSE 0 END) AS BlueBarons,
        SUM(CASE WHEN side = 'Red' THEN barons ELSE 0 END) AS RedBarons
    FROM team_stats
    GROUP BY game_id
)
SELECT
    ROUND(AVG(BlueDragons + RedDragons), 2) AS AvgDragons,					-- 4.36
    ROUND(AVG(BlueDragons), 2) AS AvgBlueDragons,							-- 2.10
    ROUND(AVG(RedDragons), 2) AS AvgRedDragons,								-- 2.26
    ROUND(AVG(BlueHeralds + RedHeralds), 2) AS AvgHeralds,					-- 1.39
    ROUND(AVG(BlueHeralds), 2) AS AvgBlueHeralds,							-- 0.82
    ROUND(AVG(RedHeralds), 2) AS AvgRedHeralds,								-- 0.57
    ROUND(AVG(BlueBarons + RedBarons), 2) AS AvgBarons,						-- 1.34
    ROUND(AVG(BlueBarons), 2) AS AvgBlueBarons,								-- 0.68
    ROUND(AVG(RedBarons), 2) AS AvgRedBarons								-- 0.66
FROM ObjectivesPerGame;

-- Champions never banned in top competitives games
SELECT c.champ_name
FROM champions c
LEFT JOIN (
    SELECT DISTINCT b.champ_id
    FROM bans b
    JOIN games_info g ON b.game_id = g.game_id
    JOIN leagues l ON g.league_id = l.league_id
    WHERE l.region != 'Regional League'
) AS major_bans ON c.champ_id = major_bans.champ_id
WHERE major_bans.champ_id IS NULL;											-- Briar, Katarina, Zaahen

-- Champions never picked in top competitives games
SELECT c.champ_name
FROM champions c
LEFT JOIN (
    SELECT DISTINCT ps.champ_id
    FROM player_stats ps
    JOIN games_info g ON ps.game_id = g.game_id
    JOIN leagues l ON g.league_id = l.league_id
    WHERE l.region != 'Regional League'
) AS major_picks ON c.champ_id = major_picks.champ_id
WHERE major_picks.champ_id IS NULL;											-- Briar, Zaahen

/* ============================================================================
   2.3. YEAR EVOLUTION OVERVIEW
   ============================================================================ */

-- Nº Games x Year
SELECT 
    YEAR(g.game_date) AS Year,
    COUNT(*) AS TotalGames,
    COUNT(CASE WHEN l.region != 'Regional League' THEN 1 END) AS MajorGames,
    COUNT(CASE WHEN l.region = 'Regional League' THEN 1 END) AS MinorGames
FROM games_info g
JOIN leagues l ON g.league_id = l.league_id
GROUP BY YEAR(g.game_date)
ORDER BY Year;

-- Game duration x Year
SELECT 
    YEAR(g.game_date) AS Year,
    CONCAT(FLOOR(AVG(g.duration) / 60), "' ",
        LPAD(ROUND(MOD(AVG(g.duration), 60)), 2, '0'), "''") AS AvgDuration
FROM games_info g
GROUP BY YEAR(g.game_date)
ORDER BY Year;

-- Farm performance [CSPM] x Year
SELECT
    YEAR(g.game_date) AS Year,
    ROUND(AVG(CASE WHEN ps.position = 'Top' THEN ps.cspm END), 2) AS Top,
    ROUND(AVG(CASE WHEN ps.position = 'Jng' THEN ps.cspm END), 2) AS Jng,
    ROUND(AVG(CASE WHEN ps.position = 'Mid' THEN ps.cspm END), 2) AS Mid,
    ROUND(AVG(CASE WHEN ps.position = 'Bot' THEN ps.cspm END), 2) AS Bot
FROM player_stats ps
JOIN games_info g ON ps.game_id = g.game_id
GROUP BY YEAR(g.game_date)
ORDER BY Year;

-- Vision performance x Year [As Team]
WITH TeamVisionPerGame AS (
    SELECT
        g.game_id,
        YEAR(g.game_date) AS Year,
        SUM(ps.wardsplaced) AS TeamWards,
        SUM(ps.controlwardsbought) AS TeamControlWards,
        SUM(ps.visionscore) AS TeamVisionScore
    FROM player_stats ps
    JOIN games_info g ON ps.game_id = g.game_id
    GROUP BY g.game_id
)
SELECT
    Year,
    ROUND(AVG(TeamWards), 1) AS AvgTeamWards,
    ROUND(AVG(TeamControlWards), 1) AS AvgTeamControlWards,
    ROUND(AVG(TeamVisionScore), 1) AS AvgTeamVisionScore
FROM TeamVisionPerGame
GROUP BY Year
ORDER BY Year;

/* ============================================================================
   3. BUSINESS QUESTION ANALYSIS
   ============================================================================ */

/* ============================================================================
   3.1. FIRST INSIGHT: WHAT'S THE BIGGEST DIFFERENCE BETWEEN TOP TEAMS AND THE REST
   ============================================================================ */

-- Average Game Duration: Who end's faster?
SELECT 
    CONCAT(
		FLOOR(AVG(CASE WHEN l.region != 'Regional League' THEN g.duration END) / 60),
        "' ",
        LPAD(ROUND(MOD(AVG(CASE WHEN l.region != 'Regional League' THEN g.duration END), 60)), 2, '0'),
		"''") AS MajorDuration,												-- 32' 43''
		
    CONCAT(
		FLOOR(AVG(CASE WHEN l.region = 'Regional League' THEN g.duration END) / 60),
        "' ",
        LPAD(ROUND(MOD(AVG(CASE WHEN l.region = 'Regional League' THEN g.duration END), 60)), 2, '0'),
        "''") AS MinorDuration												-- 31' 42''
FROM games_info g
JOIN leagues l ON g.league_id = l.league_id;

-- Average Kills x Game: Who kill more on average?
WITH KillsPerGame AS (
    SELECT g.game_id, l.region, SUM(ps.kills) AS TotalKills
    FROM player_stats ps
    JOIN games_info g ON ps.game_id = g.game_id
    JOIN leagues l ON g.league_id = l.league_id
    WHERE ps.kills IS NOT NULL
    GROUP BY g.game_id, l.region
)
SELECT
    ROUND(AVG(CASE WHEN region != 'Regional League' THEN TotalKills END), 2)
		AS MajorAvgKills,													-- 25.61
    ROUND(AVG(CASE WHEN region = 'Regional League' THEN TotalKills END), 2) 
		AS MinorAvgKills													-- 29.64
FROM KillsPerGame;

-- Average Assists x Game: Team-kills or solo-kills?
WITH AssistsPerGame AS (
    SELECT g.game_id, l.region, SUM(ps.assists) AS TotalAssists
    FROM player_stats ps
    JOIN games_info g ON ps.game_id = g.game_id
    JOIN leagues l ON g.league_id = l.league_id
    WHERE ps.kills IS NOT NULL
    GROUP BY g.game_id, l.region
)
SELECT
    ROUND(AVG(CASE WHEN region != 'Regional League' THEN TotalAssists END), 2)
		AS MajorAvgAssists,													-- 60.47
    ROUND(AVG(CASE WHEN region = 'Regional League' THEN TotalAssists END), 2) 
		AS MinorAvgAssists													-- 66.62
FROM AssistsPerGame;

-- Farm performance [CSPM]: Who last-hit better?
SELECT
    ps.position AS Position,
    ROUND(AVG(CASE WHEN l.region != 'Regional League' THEN ps.cspm END), 2) AS MajorCSPM,
    ROUND(AVG(CASE WHEN l.region = 'Regional League' THEN ps.cspm END), 2) AS MinorCSPM
FROM player_stats ps
JOIN games_info g ON ps.game_id = g.game_id
JOIN leagues l ON g.league_id = l.league_id
WHERE ps.position != 'Sup'
GROUP BY ps.position
ORDER BY FIELD(ps.position, 'Top', 'Jng', 'Mid', 'Bot');

-- Vision performance: Who ward better?
WITH TeamVision AS (														-- GlobalTeamVisionScore
    SELECT 
        g.game_id,
        ps.team_id,
        l.region,
        SUM(ps.visionscore) AS TeamVisionScore
    FROM player_stats ps
    JOIN games_info g ON ps.game_id = g.game_id
    JOIN leagues l ON g.league_id = l.league_id
    GROUP BY g.game_id, ps.team_id, l.region
)
SELECT
    ROUND(AVG(CASE WHEN region != 'Regional League' THEN TeamVisionScore END), 2) 
		AS MajorTeamVision,													-- 263.93
        
    ROUND(AVG(CASE WHEN region = 'Regional League' THEN TeamVisionScore END), 2) 
		AS MinorTeamVision													-- 231.73
FROM TeamVision;

SELECT																		-- VisionScoreByPosition
    ps.position AS Position,
    ROUND(AVG(CASE WHEN l.region != 'Regional League' THEN ps.visionscore END), 2) AS MajorVisionScore,
    ROUND(AVG(CASE WHEN l.region = 'Regional League' THEN ps.visionscore END), 2) AS MinorVisionScore
FROM player_stats ps
JOIN games_info g ON ps.game_id = g.game_id
JOIN leagues l ON g.league_id = l.league_id
GROUP BY ps.position
ORDER BY FIELD(ps.position, 'Top', 'Jng', 'Mid', 'Bot', 'Sup');

/* ============================================================================
   3.2. SECOND INSIGHT: WHAT'S THE TOP3 BEST CHAMP FOR EACH ROLE DESPITE GAME-STATE?
   ============================================================================ */

-- WR calculation
WITH WinRates AS (
    SELECT
        c.champ_name                                    AS Champion,
        ps.position                                     AS Position,
        COUNT(*)                                        AS Games,
        ROUND(AVG(ps.win) * 100, 2)                     AS WinRate,
        ROW_NUMBER() OVER (
            PARTITION BY ps.position 
            ORDER BY AVG(ps.win) DESC)                  AS Ranking
    FROM player_stats ps
    JOIN champions c   ON ps.champ_id  = c.champ_id
    JOIN games_info g  ON ps.game_id   = g.game_id
    JOIN leagues l     ON g.league_id  = l.league_id
    WHERE l.region != 'Regional League'
    GROUP BY c.champ_name, ps.position
    HAVING Games >= 50
)

-- Filtering by ranking
SELECT Champion, Position, Games, WinRate, Ranking
FROM WinRates
WHERE Ranking <= 3
ORDER BY Position, Ranking;

/* ============================================================================
   3.3. THIRD INSIGHT: WHAT'S THE MOST IMPACTFULL SOUL DESPITE GAME-STATE?
   ============================================================================ */

-- Soul detecting + filtering
WITH SoulPerGame AS (
    SELECT
        ts.game_id,
        ts.team_id,
        ts.win,
        CASE 
            WHEN ts.dragons = 4 AND ts.infernals >= 2 THEN 'Infernal'
            WHEN ts.dragons = 4 AND ts.mountains >= 2 THEN 'Mountain'
            WHEN ts.dragons = 4 AND ts.clouds    >= 2 THEN 'Cloud'
            WHEN ts.dragons = 4 AND ts.oceans    >= 2 THEN 'Ocean'
            WHEN ts.dragons = 4 AND ts.chemtechs >= 2 THEN 'Chemtech'
            WHEN ts.dragons = 4 AND ts.hextechs  >= 2 THEN 'Hextech'
            ELSE 'No Soul'
        END AS Soul
    FROM team_stats ts
    JOIN games_info g ON ts.game_id = g.game_id
    JOIN leagues l    ON g.league_id = l.league_id
    WHERE YEAR(g.game_date) >= 2019
      AND l.region != 'Regional League'
)

-- WR calculation
SELECT
    Soul,
    COUNT(*)                            AS Games,
    SUM(win)                            AS Wins,
    ROUND(AVG(win) * 100, 2)            AS WinRate
FROM SoulPerGame
GROUP BY Soul
ORDER BY WinRate DESC;                                                      -- Soul importance: Hextech > Cloud > Mountain > Infernal > Ocean > Chemtech

/* ============================================================================
   3.4. FOURTH INSIGHT: IN WHICH ROLE THE GOLD DIFF AT 15' IS MORE IMPORTANT?
   ============================================================================ */

-- Firstly, calculate what's the avg gold diff to set a meaningfull threshold
SELECT
    position,
    ROUND(AVG(golddiffat15), 2) AS Avg_GoldDiff15
FROM player_stats
WHERE golddiffat15 > 0
GROUP BY position
ORDER BY FIELD(position, 'Top', 'Jng', 'Mid', 'Bot', 'Sup');

-- Winrate by golddifat15 and role
SELECT
    ps.position,
    COUNT(*)                        AS Games,
    SUM(ps.win)                     AS Wins,
    ROUND(AVG(ps.win) * 100, 2)     AS WinRate
FROM player_stats ps
JOIN games_info g ON ps.game_id   = g.game_id
JOIN leagues l    ON g.league_id  = l.league_id
WHERE ps.golddiffat15 >= 1500
  AND ps.position != 'Sup'
  AND l.region != 'Regional League'
GROUP BY ps.position
ORDER BY WinRate DESC;														-- Mid > Jng > Adc > Top

/* ============================================================================
   3.5. FIFTH INSIGHT: WHICH CHAMPIONs DUO IS MORE POWERFULL? [TOP 10]
   ============================================================================ */

-- Creating champ duos
WITH Duos AS (
    SELECT
        p1.game_id,
        p1.team_id,
        p1.win,
        c1.champ_name AS Champ1,
        c2.champ_name AS Champ2
    FROM player_stats p1
    JOIN player_stats p2  ON p1.game_id  = p2.game_id
                         AND p1.team_id  = p2.team_id
                         AND p1.champ_id < p2.champ_id
    JOIN champions c1     ON p1.champ_id = c1.champ_id
    JOIN champions c2     ON p2.champ_id = c2.champ_id
    JOIN games_info g     ON p1.game_id  = g.game_id
    JOIN leagues l        ON g.league_id = l.league_id
    WHERE l.region != 'Regional League'
)

-- WR calculation
SELECT
    Champ1,
    Champ2,
    COUNT(*)                        AS Games,
    SUM(win)                        AS Wins,
    ROUND(AVG(win) * 100, 2)        AS WinRate
FROM Duos
GROUP BY Champ1, Champ2
HAVING Games >= 50
ORDER BY WinRate DESC
LIMIT 10;

/* ============================================================================
   3.6 SIXTH INSIGHT: DOES THE SIDE REALLY MATTERS?
   ============================================================================ */

-- General WR by side for year
SELECT
    YEAR(g.game_date)               AS Year,
    ts.side                         AS Side,
    COUNT(*)                        AS Games,
    SUM(ts.win)                     AS Wins,
    ROUND(AVG(ts.win) * 100, 2)     AS WinRate
FROM team_stats ts
JOIN games_info g ON ts.game_id  = g.game_id
JOIN leagues l    ON g.league_id = l.league_id
WHERE l.region != 'Regional League'
GROUP BY YEAR(g.game_date), ts.side
ORDER BY Year, Side;														-- BlueSide Dominance

-- WR by side for year within the same league to avoid diff between regions
-- Game info + filtering
WITH GameLeagues AS (
    SELECT
        ts.game_id,
        ts.side,
        ts.win,
        l.league_name
    FROM team_stats ts
    JOIN games_info g ON ts.game_id  = g.game_id
    JOIN leagues l    ON g.league_id = l.league_id
    WHERE l.region != 'Regional League'
),

-- Detecting same league games
SameLeagueGames AS (
    SELECT b.game_id
    FROM GameLeagues b
    JOIN GameLeagues r ON b.game_id    = r.game_id
                      AND b.side       = 'Blue'
                      AND r.side       = 'Red'
                      AND b.league_name = r.league_name
)

-- WR calculation
SELECT
    YEAR(g.game_date)               AS Year,
    gl.side                         AS Side,
    COUNT(*)                        AS Games,
    SUM(gl.win)                     AS Wins,
    ROUND(AVG(gl.win) * 100, 2)     AS WinRate
FROM GameLeagues gl
JOIN games_info g      ON gl.game_id = g.game_id
JOIN SameLeagueGames slg ON gl.game_id = slg.game_id
GROUP BY YEAR(g.game_date), gl.side
ORDER BY Year, Side;														-- BlueSide Dominance

/* ============================================================================
   3.7. SEVENT INSIGHT: DOES THE TOP5 TEAMS PER LEAGUE IMPROVES ON PLAYOFFS?
   ============================================================================ */

-- Calculation of total playoff games
WITH PlayoffGames AS (
    SELECT
        ts.team_id,
        l.league_name,
        COUNT(*) AS PlayoffGames
    FROM team_stats ts
    JOIN games_info g ON ts.game_id  = g.game_id
    JOIN leagues l    ON g.league_id = l.league_id
    WHERE g.playoffs   = 1
      AND l.region    != 'Regional League'
    GROUP BY ts.team_id, l.league_name
    HAVING PlayoffGames >= 50
),

-- Calculation of top5 teams per league based on Nº playoff games
Top5PerLeague AS (
    SELECT
        team_id,
        league_name,
        PlayoffGames,
        ROW_NUMBER() OVER (PARTITION BY league_name ORDER BY PlayoffGames DESC) AS Ranking
    FROM PlayoffGames
)

-- Calculation of wr difs
SELECT
    t.team_name                         AS Team,
    tp.league_name                      AS League,
    ROUND(AVG(CASE WHEN g.playoffs = 0 THEN ts.win END) * 100, 2) AS RegularWR,
    ROUND(AVG(CASE WHEN g.playoffs = 1 THEN ts.win END) * 100, 2) AS PlayoffWR,
    tp.PlayoffGames
FROM Top5PerLeague tp
JOIN teams t       ON tp.team_id   = t.team_id
JOIN team_stats ts ON tp.team_id   = ts.team_id
JOIN games_info g  ON ts.game_id   = g.game_id
JOIN leagues l     ON g.league_id  = l.league_id
WHERE tp.Ranking <= 5
  AND l.region   != 'Regional League'
GROUP BY t.team_name, tp.league_name, tp.PlayoffGames
ORDER BY tp.league_name, PlayoffWR DESC;