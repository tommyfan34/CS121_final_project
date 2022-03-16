-- The function to map a given date to a NBA season
-- The minimal season is 2002 and the max season is 2021
DROP FUNCTION IF EXISTS date_to_season;

DELIMITER !
CREATE FUNCTION date_to_season(game_date DATE) 
RETURNS YEAR DETERMINISTIC
BEGIN
    IF game_date < '2003-10-05' THEN
		RETURN YEAR('2002-01-01');
    ELSEIF game_date < '2004-10-12' THEN
		RETURN YEAR('2003-01-01');
    ELSEIF game_date < '2005-10-10' THEN
		RETURN YEAR('2004-01-01');
	ELSEIF game_date < '2006-10-05' THEN
		RETURN YEAR('2005-01-01');
	ELSEIF game_date < '2007-10-06' THEN
		RETURN YEAR('2006-01-01');
	ELSEIF game_date < '2008-10-05' THEN
		RETURN YEAR('2007-01-01');
	ELSEIF game_date < '2009-10-01' THEN
		RETURN YEAR('2008-01-01');
	ELSEIF game_date < '2010-10-03' THEN
		RETURN YEAR('2009-01-01');
	ELSEIF game_date < '2011-12-16' THEN
		RETURN YEAR('2010-01-01');
	ELSEIF game_date < '2012-10-05' THEN
		RETURN YEAR('2011-01-01');
	ELSEIF game_date < '2013-10-05' THEN
		RETURN YEAR('2012-01-01');
	ELSEIF game_date < '2014-10-04' THEN
		RETURN YEAR('2013-01-01');
	ELSEIF game_date < '2015-10-02' THEN
		RETURN YEAR('2014-01-01');
	ELSEIF game_date < '2016-10-01' THEN
		RETURN YEAR('2015-01-01');
	ELSEIF game_date < '2017-09-30' THEN
		RETURN YEAR('2016-01-01');
	ELSEIF game_date < '2018-09-28' THEN
		RETURN YEAR('2017-01-01');
	ELSEIF game_date < '2019-09-30' THEN
		RETURN YEAR('2018-01-01');
	ELSEIF game_date < '2020-12-11' THEN
		RETURN YEAR('2019-01-01');
	ELSEIF game_date < '2021-10-03' THEN
		RETURN YEAR('2020-01-01');
	ELSE
		RETURN YEAR('2021-01-01');
    END IF;
END !
DELIMITER ;

-- Return a player's career points, including regular season and playoffs.
-- Note that the stats are from the season 2002 to season 2021
DROP FUNCTION IF EXISTS player_career_pts;

DELIMITER !
CREATE FUNCTION player_career_pts(player_id VARCHAR(20)) 
RETURNS INTEGER DETERMINISTIC
BEGIN
DECLARE total_pts INTEGER;

SELECT SUM(PTS) FROM game_details WHERE game_details.player_id = player_id
INTO total_pts;

RETURN total_pts;
END !
DELIMITER ;

-- The procedure to retrieve the game stats for a team_id given a game_id. This
-- procedure is useful because the game relation has stats seperated for 
-- home and guest team and we cannot directly retrieve the stats.
DROP PROCEDURE IF EXISTS sp_game_stats;

DELIMITER !
CREATE PROCEDURE sp_game_stats(
	IN team_id CHAR(10),
    IN game_id CHAR(8),
    OUT PTS INT,
    OUT FG_PCT NUMERIC(4, 3),
    OUT FT_PCT NUMERIC(4, 3),
    OUT FG3_PCT NUMERIC(4, 3),
    OUT AST INT,
    OUT REB INT
)
proc_label: BEGIN
DECLARE IS_HOME TINYINT(1);

IF (SELECT home_team_id FROM games WHERE games.game_id = game_id) = team_id THEN
	SELECT 1 INTO IS_HOME;
ELSEIF (SELECT visitor_team_id FROM games WHERE games.game_id = game_id) = team_id THEN
	SELECT 0 INTO IS_HOME;
ELSE LEAVE proc_label;
END IF;
IF IS_HOME = 1 THEN
	SELECT (SELECT PTS_home FROM games WHERE games.game_id = game_id) INTO PTS;
    SELECT (SELECT FG_PCT_home FROM games WHERE games.game_id = game_id) INTO FG_PCT;
    SELECT (SELECT FT_PCT_home FROM games WHERE games.game_id = game_id) INTO FT_PCT;
    SELECT (SELECT FG3_PCT_home FROM games WHERE games.game_id = game_id) INTO FG3_PCT;
    SELECT (SELECT AST_home FROM games WHERE games.game_id = game_id) INTO AST;
    SELECT (SELECT REB_home FROM games WHERE games.game_id = game_id) INTO REB;
ELSE 
	SELECT (SELECT PTS_away FROM games WHERE games.game_id = game_id) INTO PTS;
    SELECT (SELECT FG_PCT_away FROM games WHERE games.game_id = game_id) INTO FG_PCT;
    SELECT (SELECT FT_PCT_away FROM games WHERE games.game_id = game_id) INTO FT_PCT;
    SELECT (SELECT FG3_PCT_home FROM games WHERE games.game_id = game_id) INTO FG3_PCT;
    SELECT (SELECT AST_away FROM games WHERE games.game_id = game_id) INTO AST;
    SELECT (SELECT REB_away FROM games WHERE games.game_id = game_id) INTO REB;
END IF;
END !
DELIMITER ;

-- Sample usage for the sp_games_stats
-- CALL sp_game_stats('1610612764', '22100213', @pts, @fg_pct, @ft_pct, @fg3_pct, @ast, @reb);
-- SELECT @pts, @fg_pct, @ft_pct, @fg3_pct, @ast, @reb;


-- Trigger for checking the data legitmacy when inserting into the game_details relation. 
-- The FGM * 2 + FG3M + FTM should be equal to PTS, if not, simply change the primary keys to 
-- NULL to prevent insertion. The FG3M should also be less than FGM, and each
-- of the attempted goal should be more or equal to the made goals
DROP TRIGGER IF EXISTS tr_add_detail;

DELIMITER !
CREATE TRIGGER tr_add_detail BEFORE INSERT ON game_details FOR EACH ROW
BEGIN
	IF NEW.FGM * 2 + NEW.FG3M + NEW.FTM <> NEW.PTS OR NEW.FGA < NEW.FGM OR NEW.FG3A < NEW.FG3M OR NEW.FTA < NEW.FTM
    OR NEW.FGM < NEW.FG3M OR NEW.FGA < NEW.FG3A THEN
		SET NEW.game_id = NULL;
    END IF;
END!
DELIMITER ;

-- Sample usage for the tr_add_detail
-- INSERT INTO game_details VALUES('22100213','1610612764','201950','G','','27:41:00',3,6,2,5,1,1,1,5,2,1,0,1,0,4,2);