-- query 1
-- Search for a given player’s stats for a given year.
-- The purpose of this query is that fans of a basketball star 
-- may want to know how this player performed. 
SELECT player_id, player_name, AVG(PTS) AS avg_points, 
       AVG(OREB+DREB) AS avg_rebounds, AVG(AST) AS avg_assists, 
       AVG(STL) AS avg_steals, AVG(BLK) AS avg_blocks, 
       AVG(turnover) AS avg_turnovers, AVG(PF)AS avg_personal_fouls 
FROM game_details NATURAL INNER JOIN players NATURAL INNER JOIN games
WHERE player_name='Andrew Bogut' AND YEAR(game_date_EST) = 2005
GROUP BY player_id, player_name;

-- query 2
-- Show the leading player of each team ordered by average points 
-- per game in the given year.
-- The purpose of this is to show the fans the leading player 
-- of his supporting team.
WITH 
    cte1 AS (SELECT player_id, team_id, AVG(PTS) AS avg_pts 
             FROM game_details NATURAL INNER JOIN games 
             WHERE YEAR(game_date_EST) = 2012 
             GROUP BY player_id, team_id) 
SELECT DISTINCT team_id, team_abbreviation, player_id, player_name, leading_pts
FROM teams 
     NATURAL INNER JOIN players 
     NATURAL INNER JOIN cte1 
     NATURAL INNER JOIN (SELECT team_id, MAX(avg_pts) AS leading_pts 
                         FROM cte1 
                         GROUP BY team_id) AS leading_pts_count 
WHERE leading_pts = avg_pts 
ORDER BY team_id ASC;
