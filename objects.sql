/* 	============================================================================
		LOL COMPETITIVE ANALYTICS - Oracle's Elixir Database (2018-2025)
    ----------------------------------------------------------------------------
	The original dataset consisted of separate CSV files for each year. 
    This project focuses on cleaning, normalizing, and analyzing the data to
    find powerful insights that can help teams improve their performance.
    
    This file contains the functions and view creations.
	============================================================================ */
    
-- DataBase Selection
USE lol_competitive;

/* 	============================================================================
		1. NEW METRICS
	============================================================================ */

-- Enables updates without using PK
SET SQL_SAFE_UPDATES = 0;

/* 	============================================================================
		1.1 KDA FUNCTION: (Kills + Assists)/Deaths
	============================================================================ */
DELIMITER $$
CREATE FUNCTION calcKDA(kills INT, assists INT, deaths INT)
RETURNS FLOAT
DETERMINISTIC														-- Same input, same output -> Warning management
BEGIN
    IF deaths = 0 THEN
        RETURN CAST(kills + assists AS FLOAT);  					-- DivisionByZero error management
    END IF;
    RETURN CAST((kills + assists) / deaths AS FLOAT);
END$$
DELIMITER ;

/* 	============================================================================
		2. BUSSINES VIEWS
	============================================================================ */
    
/* 	============================================================================
		2.1 TOP 10 TEAMS (international winrate based)
	============================================================================ */
CREATE OR REPLACE VIEW top10_teams AS
SELECT 
    t.team_name                                     AS Team,
    COUNT(*)                                        AS Games,
    SUM(ts.win)                                     AS Wins,
    ROUND(SUM(ts.win) / COUNT(*) * 100, 2)          AS WinRate,
    ROUND(AVG(g.duration) / 60, 2)                  AS Duration,
    ROUND(AVG(ts.firstblood) * 100, 2)              AS FirstBlood_Rate
FROM team_stats ts
JOIN teams t      ON ts.team_id  = t.team_id
JOIN games_info g ON ts.game_id  = g.game_id
JOIN leagues l    ON g.league_id = l.league_id
WHERE l.region = 'International'
GROUP BY t.team_id, t.team_name
HAVING Games >= 50
ORDER BY WinRate DESC
LIMIT 10;

SELECT * FROM top10_teams;

/* 					IMPORTANT DISCLAIMER
Normally, you would use Team_ID for this queries, but in this case,
original Team_ID didn't managed team rebranding, so that is why
T1 and SK Telecom T1 are both in top 10 despite of being the same team.

It is a data limitation and that's why team_id wasn't imported 
in loading phase. 												*/

/* 	============================================================================
		2.2 TOP 10 TOPLANERS
	============================================================================ */
    
/* 								METRIC DETAIL
The metric used for the TOP10 ranking uses a Z-score normalization for each metric.
This decision was based on negatives values for metrics like golddiffat15. 
So, each stat is normalized against the mean and standard deviation of all qualifying toplaners. 

This produces a Z-score per metric, where 0 is average, positive is above average, and negative 
is below. 

The final score is a weighted sum of four Z-scores: xpdiffat15 carries 
the most weight (1.0) as it best reflects laning dominance, followed by golddiffat15 
and KDA (0.5 each), and CSPM (0.25) as a secondary farming indicator. 

The sum is divided by 2.25 (the total weight) to make the score comparable across players. */
    
CREATE OR REPLACE VIEW top10_toplaners AS

-- Avg calculation (only toplaners with +200 games in major leagues)
WITH stats AS (
    SELECT
        ps.player_id	 	 							AS Player,
        AVG(calcKDA(ps.kills, ps.assists, ps.deaths)) 	AS KDA,
        AVG(ps.cspm)         							AS CSPM,
        AVG(ps.golddiffat15) 							AS GoldDiff15,
        AVG(ps.xpdiffat15)   							AS XpDiff15,
        COUNT(*)             							AS Games
    FROM player_stats ps
    JOIN games_info g  ON ps.game_id = g.game_id
    JOIN leagues l     ON g.league_id = l.league_id
    WHERE ps.position  = 'Top'
      AND l.region    != 'Regional League'
    GROUP BY ps.player_id
    HAVING Games >= 200
),

-- Mean and Std deviation caculation
global_stats AS (
    SELECT
        AVG(KDA)        	AS Avg_KDA,
        STDDEV(KDA)     	AS Std_KDA,
        AVG(CSPM)       	AS Avg_CSPM,
        STDDEV(CSPM)    	AS Std_CSPM,
        AVG(GoldDiff15)   	AS Avg_GoldDiff15,
        STDDEV(GoldDiff15)	AS Std_GoldDiff15,
        AVG(XpDiff15)     	AS Avg_XpDiff15,
        STDDEV(XpDiff15)    AS Std_XpDiff15
    FROM stats
),

-- Z-score (Z = (player_value - mean) / stddev) calculation for each stat per player
zscores AS (
    SELECT
        s.Player 														AS Player,
        s.Games 														AS Games,
		(s.KDA        - g.Avg_KDA)        / NULLIF(g.Std_KDA,      	 0) AS Z_KDA,
        (s.CSPM       - g.Avg_CSPM)       / NULLIF(g.Std_CSPM,     	 0) AS Z_CSPM,
        (s.GoldDiff15 - g.Avg_GoldDiff15) / NULLIF(g.Std_GoldDiff15, 0) AS Z_GoldDiff15,
        (s.XpDiff15   - g.Avg_XpDiff15)   / NULLIF(g.Std_XpDiff15,   0) AS Z_XpDiff15

    FROM stats s
    CROSS JOIN global_stats g   -- global_stats is added to every player row
)

-- Final weighted score and rank calculation
SELECT
    p.player_name                       AS Player,
    z.Games                             AS Games,
    ROUND(s.KDA, 2)                     AS KDA,
    ROUND(s.CSPM, 2)                    AS CSPM,
    ROUND(s.GoldDiff15, 2)              AS GoldDiff15,
    ROUND(s.XpDiff15, 2)                AS XpDiff15,
    ROUND(
        (z.Z_XpDiff15   * 1.0 +
         z.Z_GoldDiff15 * 0.5 + 
         z.Z_KDA        * 0.5 + 
         z.Z_CSPM       * 0.25
        ) / 2.25, 4)                    AS Score
FROM zscores z
JOIN players p ON z.Player = p.player_id
JOIN stats s   ON z.Player = s.Player
ORDER BY Score DESC
LIMIT 10;

SELECT * FROM top10_toplaners;

-- Restart config
SET SQL_SAFE_UPDATES = 1;