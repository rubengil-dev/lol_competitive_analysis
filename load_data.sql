/* ============================================================================
		LOL COMPETITIVE ANALYTICS - Oracle's Elixir Database (2018-2025)
    ----------------------------------------------------------------------------
	The original dataset consisted of separate CSV files for each year. 
    This project focuses on cleaning, normalizing, and analyzing the data to
    find powerful insights that can help teams improve their performance.
    
    This file contains de data load from raw_data, a table created via python
    using a unique csv created by merging the yearly csv's.
	============================================================================ */
    
-- DataBase Selection
USE lol_competitive;

/* ============================================================================
        CLEANING PATCH
    =========================================================================== */
-- This idx's objective is accelerate the delete (initially lasted +2h)
-- Specifications are given due to raw_data data_types
CREATE INDEX idx_cleaning_raw ON raw_data (gameid(50), `position`(20), side(20));

/* 
Uncoment and execute the lane below if there is a problem with the index.
Then, comment it back for execute it all.
MySQL doesn't support if exists for index
*/
-- DROP INDEX idx_cleaning_raw ON raw_data

-- Delete itself
DELETE FROM raw_data 
WHERE gameid IN (
    SELECT gameid FROM (
        SELECT r.gameid 
        FROM raw_data r
        JOIN raw_data r_rival ON r_rival.gameid = r.gameid
            AND r_rival.position = 'team'
            AND r_rival.side != r.side
        WHERE r.position = 'team'
          AND TRIM(r.teamname) = TRIM(r_rival.teamname)
    ) AS tabla_temporal
);
  
/* 
	After executing the script for the first time, an error happened because 
    in raw_data there are some match in which a team is in both sides of the game.
    Like, that team is playing against himself. This first block was added 
    afterwards in order to delete those games.
*/
    
/* ============================================================================
		1. LEAGUES DATA
    =========================================================================== */
INSERT INTO leagues (league_name, region)
SELECT DISTINCT
    TRIM(league),
    CASE league
        WHEN 'LCK'    THEN 'Korea'
        WHEN 'LPL'    THEN 'China'
        WHEN 'LEC'    THEN 'Europe'
        WHEN 'EU LCS' THEN 'Europe'
        WHEN 'LCS'    THEN 'North America'
        WHEN 'NA LCS' THEN 'North America'
        WHEN 'PCS'    THEN 'Southeast Asia'
        WHEN 'LMS'    THEN 'Southeast Asia'
        WHEN 'CBLOL'  THEN 'Brazil'
        WHEN 'WLDs'   THEN 'International'
        WHEN 'MSI'    THEN 'International'
        WHEN 'EWC'	  THEN 'International'
        ELSE              'Regional League'
    END AS region
FROM raw_data
WHERE league IS NOT NULL;

/* ============================================================================
        2. TEAMS DATA
    =========================================================================== */
INSERT INTO teams (team_name)
SELECT DISTINCT TRIM(teamname)
FROM raw_data
WHERE teamname IS NOT NULL
    AND position = 'team';					-- Included for optimization
    
/* ============================================================================
        3. PLAYERS DATA
    =========================================================================== */
INSERT INTO players (player_id, player_name)
SELECT playerid, MAX(playername)			-- This selects his last name
FROM raw_data 
WHERE playername IS NOT NULL
    AND position != 'team'
    AND playerid IS NOT NULL
GROUP BY playerid;							-- Made to manage name changes

/* ============================================================================
		4. CHAMPIONS DATA
    =========================================================================== */
INSERT INTO champions (champ_name, champ_role, champ_subrole) VALUES 
    ('Aatrox', 'Fighter', 'Juggernaut'),
    ('Ahri', 'Mage', 'Assassin'),
    ('Akali', 'Assassin', 'Assassin'),
    ('Akshan', 'Marksman', 'Marksman'),
    ('Alistar', 'Tank', 'Vanguard'),
    ('Ambessa', 'Fighter', 'Diver'),
    ('Amumu', 'Tank', 'Vanguard'),
    ('Anivia', 'Mage', 'Battlemage'),
    ('Annie', 'Mage', 'Assassin'),
    ('Aphelios', 'Marksman', 'Marksman'),
    ('Ashe', 'Marksman', 'Marksman'),
    ('Aurelion Sol', 'Mage', 'Battlemage'),
    ('Aurora', 'Mage', 'Skirmisher'),
    ('Azir', 'Mage', 'Specialist'),
    ('Bard', 'Support', 'Catcher'),
    ('Bel''Veth', 'Fighter', 'Skirmisher'),
    ('Blitzcrank', 'Tank', 'Catcher'),
    ('Brand', 'Mage', 'Battlemage'),
    ('Braum', 'Support', 'Warden'),
    ('Briar', 'Fighter', 'Diver'),
    ('Caitlyn', 'Marksman', 'Marksman'),
    ('Camille', 'Fighter', 'Diver'),
    ('Cassiopeia', 'Mage', 'Battlemage'),
    ('Cho''Gath', 'Tank', 'Specialist'),
    ('Corki', 'Marksman', 'Marksman'),
    ('Darius', 'Fighter', 'Juggernaut'),
    ('Diana', 'Fighter', 'Diver'),
    ('Dr. Mundo', 'Fighter', 'Juggernaut'),
    ('Draven', 'Marksman', 'Marksman'),
    ('Ekko', 'Assassin', 'Assassin'),
    ('Elise', 'Mage', 'Diver'),
    ('Evelynn', 'Assassin', 'Assassin'),
    ('Ezreal', 'Marksman', 'Marksman'),
    ('Fiddlesticks', 'Mage', 'Specialist'),
    ('Fiora', 'Fighter', 'Skirmisher'),
    ('Fizz', 'Assassin', 'Assassin'),
    ('Galio', 'Tank', 'Warden'),
    ('Gangplank', 'Fighter', 'Specialist'),
    ('Garen', 'Fighter', 'Juggernaut'),
    ('Gnar', 'Fighter', 'Specialist'),
    ('Gragas', 'Fighter', 'Vanguard'),
    ('Graves', 'Marksman', 'Specialist'),
    ('Gwen', 'Fighter', 'Skirmisher'),
    ('Hecarim', 'Fighter', 'Diver'),
    ('Heimerdinger', 'Mage', 'Specialist'),
    ('Hwei', 'Mage', 'Artillery'),
    ('Illaoi', 'Fighter', 'Juggernaut'),
    ('Irelia', 'Fighter', 'Diver'),
    ('Ivern', 'Support', 'Catcher'),
    ('Janna', 'Support', 'Enchanter'),
    ('Jarvan IV', 'Fighter', 'Diver'),
    ('Jax', 'Fighter', 'Skirmisher'),
    ('Jayce', 'Fighter', 'Artillery'),
    ('Jhin', 'Marksman', 'Marksman'),
    ('Jinx', 'Marksman', 'Marksman'),
    ('K''Sante', 'Tank', 'Warden'),
    ('Kai''Sa', 'Marksman', 'Marksman'),
    ('Kalista', 'Marksman', 'Marksman'),
    ('Karma', 'Mage', 'Assassin'),
    ('Karthus', 'Mage', 'Battlemage'),
    ('Kassadin', 'Assassin', 'Assassin'),
    ('Katarina', 'Assassin', 'Assassin'),
    ('Kayle', 'Fighter', 'Specialist'),
    ('Kayn', 'Fighter', 'Skirmisher'),
    ('Kennen', 'Mage', 'Specialist'),
    ('Kha''Zix', 'Assassin', 'Assassin'),
    ('Kindred', 'Marksman', 'Marksman'),
    ('Kled', 'Fighter', 'Skirmisher'),
    ('Kog''Maw', 'Marksman', 'Marksman'),
    ('Leblanc', 'Assassin', 'Assassin'),
    ('Lee Sin', 'Fighter', 'Diver'),
    ('Leona', 'Tank', 'Vanguard'),
    ('Lillia', 'Fighter', 'Skirmisher'),
    ('Lissandra', 'Mage', 'Assassin'),
    ('Lucian', 'Marksman', 'Marksman'),
    ('Lulu', 'Support', 'Enchanter'),
    ('Lux', 'Mage', 'Assassin'),
    ('Malphite', 'Tank', 'Vanguard'),
    ('Malzahar', 'Mage', 'Battlemage'),
    ('Maokai', 'Tank', 'Vanguard'),
    ('Master Yi', 'Assassin', 'Skirmisher'),
    ('Mel', 'Mage', 'Assassin'),
    ('Milio', 'Support', 'Enchanter'),
    ('Miss Fortune', 'Marksman', 'Marksman'),
    ('Mordekaiser', 'Fighter', 'Juggernaut'),
    ('Morgana', 'Mage', 'Catcher'),
    ('Naafiri', 'Assassin', 'Assassin'),
    ('Nami', 'Support', 'Enchanter'),
    ('Nasus', 'Fighter', 'Juggernaut'),
    ('Nautilus', 'Tank', 'Vanguard'),
    ('Neeko', 'Mage', 'Assassin'),
    ('Nidalee', 'Assassin', 'Specialist'),
    ('Nilah', 'Marksman', 'Skirmisher'),
    ('Nocturne', 'Assassin', 'Assassin'),
    ('Nunu & Willump', 'Tank', 'Vanguard'),
    ('Olaf', 'Fighter', 'Diver'),
    ('Orianna', 'Mage', 'Assassin'),
    ('Ornn', 'Tank', 'Vanguard'),
    ('Pantheon', 'Fighter', 'Diver'),
    ('Poppy', 'Tank', 'Warden'),
    ('Pyke', 'Assassin', 'Assassin'),
    ('Qiyana', 'Assassin', 'Assassin'),
    ('Quinn', 'Marksman', 'Marksman'),
    ('Rakan', 'Support', 'Catcher'),
    ('Rammus', 'Tank', 'Vanguard'),
    ('Rek''Sai', 'Fighter', 'Diver'),
    ('Rell', 'Tank', 'Vanguard'),
    ('Renata Glasc', 'Support', 'Enchanter'),
    ('Renekton', 'Fighter', 'Diver'),
    ('Rengar', 'Assassin', 'Assassin'),
    ('Riven', 'Fighter', 'Skirmisher'),
    ('Rumble', 'Fighter', 'Battlemage'),
    ('Ryze', 'Mage', 'Battlemage'),
    ('Samira', 'Marksman', 'Marksman'),
    ('Sejuani', 'Tank', 'Vanguard'),
    ('Senna', 'Marksman', 'Marksman'),
    ('Seraphine', 'Mage', 'Enchanter'),
    ('Sett', 'Fighter', 'Juggernaut'),
    ('Shaco', 'Assassin', 'Assassin'),
    ('Shen', 'Tank', 'Warden'),
    ('Shyvana', 'Fighter', 'Juggernaut'),
    ('Singed', 'Tank', 'Specialist'),
    ('Sion', 'Tank', 'Vanguard'),
    ('Sivir', 'Marksman', 'Marksman'),
    ('Skarner', 'Tank', 'Vanguard'),
    ('Smolder', 'Marksman', 'Marksman'),
    ('Sona', 'Support', 'Enchanter'),
    ('Soraka', 'Support', 'Enchanter'),
    ('Swain', 'Mage', 'Battlemage'),
    ('Sylas', 'Mage', 'Skirmisher'),
    ('Syndra', 'Mage', 'Assassin'),
    ('Tahm Kench', 'Tank', 'Warden'),
    ('Taliyah', 'Mage', 'Battlemage'),
    ('Talon', 'Assassin', 'Assassin'),
    ('Taric', 'Support', 'Warden'),
    ('Teemo', 'Marksman', 'Specialist'),
    ('Thresh', 'Support', 'Catcher'),
    ('Tristana', 'Marksman', 'Marksman'),
    ('Trundle', 'Fighter', 'Juggernaut'),
    ('Tryndamere', 'Fighter', 'Skirmisher'),
    ('Twisted Fate', 'Mage', 'Assassin'),
    ('Twitch', 'Marksman', 'Marksman'),
    ('Udyr', 'Fighter', 'Juggernaut'),
    ('Urgot', 'Fighter', 'Juggernaut'),
    ('Varus', 'Marksman', 'Marksman'),
    ('Vayne', 'Marksman', 'Marksman'),
    ('Veigar', 'Mage', 'Assassin'),
    ('Vel''Koz', 'Mage', 'Artillery'),
    ('Vex', 'Mage', 'Assassin'),
    ('Vi', 'Fighter', 'Diver'),
    ('Viego', 'Fighter', 'Skirmisher'),
    ('Viktor', 'Mage', 'Battlemage'),
    ('Vladimir', 'Mage', 'Battlemage'),
    ('Volibear', 'Fighter', 'Juggernaut'),
    ('Warwick', 'Fighter', 'Diver'),
    ('Wukong', 'Fighter', 'Diver'),
    ('Xayah', 'Marksman', 'Marksman'),
    ('Xerath', 'Mage', 'Artillery'),
    ('Xin Zhao', 'Fighter', 'Diver'),
    ('Yasuo', 'Fighter', 'Skirmisher'),
    ('Yone', 'Assassin', 'Assassin'),
    ('Yorick', 'Fighter', 'Juggernaut'),
    ('Yunara', 'Marksman', 'Marksman'),
    ('Yuumi', 'Support', 'Enchanter'),
    ('Zaahen', 'Fighter', 'Juggernaut'),
    ('Zac', 'Tank', 'Vanguard'),
    ('Zed', 'Assassin', 'Assassin'),
    ('Zeri', 'Marksman', 'Marksman'),
    ('Ziggs', 'Mage', 'Artillery'),
    ('Zilean', 'Support', 'Specialist'),
    ('Zoe', 'Mage', 'Assassin'),
    ('Zyra', 'Mage', 'Catcher');
    
/* ============================================================================
		5. GAMES INFO DATA
    =========================================================================== */
INSERT INTO games_info (game_id, game_date, patch, split, playoffs, duration, league_id)
SELECT DISTINCT
    r.gameid,
    STR_TO_DATE(r.date, '%Y-%m-%d %H:%i:%s'),
    r.patch,
    r.split,
    r.playoffs,
    r.gamelength,
    l.league_id
FROM raw_data r
JOIN leagues l ON r.league = l.league_name
WHERE r.gameid IS NOT NULL
    AND r.position = 'team';				-- Included for optimization
    
/* ============================================================================
		6. TEAM STATS DATA
    =========================================================================== */
INSERT INTO team_stats (game_id, team_id, side, win, firstblood, firstdragon, 
    firstherald, firstbaron, firsttower, dragons, infernals, mountains, clouds, 
    oceans, chemtechs, hextechs, elders, barons, heralds, void_grubs, towers, inhibitors)
SELECT DISTINCT
    r.gameid,
    t.team_id,
    TRIM(r.side),
    r.result,
    r.firstblood,
    r.firstdragon,
    r.firstherald,
    r.firstbaron,
    r.firsttower,
    r.dragons,
    r.infernals,
    r.mountains,
    r.clouds,
    r.oceans,
    r.chemtechs,
    r.hextechs,
    r.elders,
    r.barons,
    r.heralds,
    r.void_grubs,
    r.towers,
    r.inhibitors
FROM raw_data r
JOIN teams t ON TRIM(r.teamname) = t.team_name
WHERE r.gameid IS NOT NULL 
    AND r.teamname IS NOT NULL
    AND r.position = 'team';				-- Included for optimization
    
/* ============================================================================
		7. BANS DATA
    =========================================================================== */
INSERT INTO bans (game_id, team_id, champ_id, ban_order)
SELECT r.gameid, t.team_id, c.champ_id, 1 
FROM raw_data r 
JOIN teams t ON r.teamname = t.team_name 
JOIN champions c ON r.ban1 = c.champ_name 
WHERE r.position = 'team' AND r.ban1 IS NOT NULL

UNION ALL

SELECT r.gameid, t.team_id, c.champ_id, 2 
FROM raw_data r 
JOIN teams t ON r.teamname = t.team_name 
JOIN champions c ON r.ban2 = c.champ_name 
WHERE r.position = 'team' AND r.ban2 IS NOT NULL

UNION ALL

SELECT r.gameid, t.team_id, c.champ_id, 3 
FROM raw_data r 
JOIN teams t ON r.teamname = t.team_name 
JOIN champions c ON r.ban3 = c.champ_name 
WHERE r.position = 'team' AND r.ban3 IS NOT NULL

UNION ALL

SELECT r.gameid, t.team_id, c.champ_id, 4 
FROM raw_data r 
JOIN teams t ON r.teamname = t.team_name 
JOIN champions c ON r.ban4 = c.champ_name 
WHERE r.position = 'team' AND r.ban4 IS NOT NULL

UNION ALL

SELECT r.gameid, t.team_id, c.champ_id, 5 
FROM raw_data r 
JOIN teams t ON r.teamname = t.team_name 
JOIN champions c ON r.ban5 = c.champ_name 
WHERE r.position = 'team' AND r.ban5 IS NOT NULL;

/* ============================================================================
        8. PLAYER STATS DATA (Versión Optimizada)
    =========================================================================== */
INSERT INTO player_stats (game_id, player_id, team_id, champ_id, position, side,  
    win, kills, deaths, assists, dpm, damageshare, damagetakenpermin,  
    wardsplaced, wardskilled, controlwardsbought, visionscore, totalgold,  
    earnedgold, goldspent, total_cs, cspm, golddiffat10, golddiffat15,  
    golddiffat20, golddiffat25, csdiffat10, csdiffat15, csdiffat20, csdiffat25, 
    xpdiffat10, xpdiffat15, xpdiffat20, xpdiffat25) 
SELECT 
    r.gameid,
    r.playerid,
    MAX(t.team_id),
    MAX(c.champ_id),
    MAX(TRIM(r.position)),
    MAX(TRIM(r.side)),
    MAX(r.result),
    MAX(r.kills),
    MAX(r.deaths),
    MAX(r.assists),
    MAX(r.dpm),
    MAX(r.damageshare),
    MAX(r.damagetakenperminute),
    MAX(r.wardsplaced),
    MAX(r.wardskilled),
    MAX(r.controlwardsbought),
    MAX(r.visionscore),
    MAX(r.totalgold),
    MAX(r.earnedgold),
    MAX(r.goldspent),
    MAX(r.`total cs`),
    MAX(r.cspm),
    MAX(r.golddiffat10),
    MAX(r.golddiffat15),
    MAX(r.golddiffat20),
    MAX(r.golddiffat25),
    MAX(r.csdiffat10),
    MAX(r.csdiffat15),
    MAX(r.csdiffat20),
    MAX(r.csdiffat25),
    MAX(r.xpdiffat10),
    MAX(r.xpdiffat15),
    MAX(r.xpdiffat20),
    MAX(r.xpdiffat25)
FROM raw_data r 
JOIN teams t ON r.teamname = t.team_name 
JOIN champions c ON r.champion = c.champ_name 
WHERE r.position != 'team'  
    AND r.gameid IS NOT NULL  
    AND r.playerid IS NOT NULL
GROUP BY r.gameid, r.playerid;

/*
Initially, there where no GROUP BY neither MAXs in each column.
However, an error happened due to duplicate entries.
Original data must have duplicates registers.
The GROUP BY and MAXs forces the insert to pick only 1 row for each player.
*/