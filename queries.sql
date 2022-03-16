-- query 1
-- Search for a given player’s stats for a given year.
-- The purpose of this query is that fans of a basketball star 
-- may want to know how this player performed. 
SELECT player_id, player_name, AVG(PTS) AS avg_points, 
       AVG(OREB+DREB) AS avg_rebounds, AVG(AST) AS avg_assists, 
       AVG(STL) AS avg_steals, AVG(BLK) AS avg_blocks, 
       AVG(turnover) AS avg_turnovers, AVG(PF)AS avg_personal_fouls 
FROM game_details NATURAL INNER JOIN players NATURAL INNER JOIN games
WHERE player_name='Andrew Bogut' AND date_to_season(game_date_EST) = 2005
GROUP BY player_id, player_name;


-- query 2
-- Show the leading player of each team ordered by average points 
-- per game in the given year.
-- The purpose of this is to show the fans the leading player 
-- of his supporting team.
WITH 
    cte1 AS (SELECT player_id, team_id, AVG(PTS) AS avg_pts 
             FROM game_details NATURAL INNER JOIN games 
             WHERE date_to_season(game_date_EST) = 2012 
             GROUP BY player_id, team_id) 
SELECT DISTINCT team_abbreviation, player_name, leading_pts
FROM teams 
     NATURAL INNER JOIN players 
     NATURAL INNER JOIN cte1 
     NATURAL INNER JOIN (SELECT team_id, MAX(avg_pts) AS leading_pts 
                         FROM cte1 
                         GROUP BY team_id) AS leading_pts_count 
WHERE leading_pts = avg_pts 
ORDER BY team_abbreviation ASC;

-- query 3
-- Show the team stats in the given match. The purpose of this query is 
-- to allow fans of a certain team to know how it performed in that match.
SELECT DISTINCT home_team_id AS team,
                team_abbreviation,
                PTS_home AS pts,
                FG_PCT_home AS fg_pct,
                FG_PCT_home AS ft_pct,
                AST_home AS ast,
                REB_home AS reb 
FROM games NATURAL INNER JOIN game_details NATURAL INNER JOIN teams 
WHERE game_date_EST = '2003-10-05' 
      AND team_abbreviation = 'UTA' 
      AND home_team_id = team_id
    UNION
SELECT DISTINCT visitor_team_id AS team,
                team_abbreviation,
                PTS_away AS pts,
                FG_PCT_away AS fg_pct,
                FG_PCT_away AS ft_pct,
                AST_away AS ast,
                REB_away AS reb 
FROM games NATURAL INNER JOIN game_details NATURAL INNER JOIN teams
WHERE game_date_EST = '2003-10-05' 
      AND team_abbreviation = 'UTA'
      AND visitor_team_id = team_id;

-- query 4
-- Show the team rankings of a certain conference on a given date.
-- Rankings are sorted by win_rate DESC.
SELECT team_id, 
       team_abbreviation, 
       number_of_wins / (number_of_wins + number_of_losses) AS win_pct, 
       conference 
FROM rankings NATURAL INNER JOIN teams 
WHERE standings_date = '2012-11-26' AND conference = 'West' 
ORDER BY win_pct DESC;

-- query 5
-- Show the 10 players with highest points per game this season.
-- The purpose of this is to report the players 
-- who are the leading scorers in the league. 
SELECT player_name, AVG(PTS) AS avg_pts 
FROM game_details 
     NATURAL INNER JOIN games 
     NATURAL INNER JOIN players 
WHERE YEAR(game_date_EST) = 2012 
GROUP BY player_name 
ORDER BY avg_pts DESC 
LIMIT 10;
