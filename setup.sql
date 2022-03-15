
-- DROP TABLE commands:
DROP TABLE IF EXISTS game_details;
DROP TABLE IF EXISTS rankings;
DROP TABLE IF EXISTS players;
DROP TABLE IF EXISTS games;
DROP TABLE IF EXISTS teams;

-- create table for teams
CREATE TABLE teams(
  team_id           CHAR(10),
  team_abbreviation CHAR(3) NOT NULL,
  team_nickname     VARCHAR(40) NOT NULL,
  founded           YEAR NOT NULL,
  team_city         VARCHAR(20) NOT NULL,
  arena             VARCHAR(40) NOT NULL,
  -- capacity of the stadium
  capacity          INTEGER NOT NULL,
  -- last owner of the team
  owner             VARCHAR(40) NOT NULL,
  manager           VARCHAR(40) NOT NULL,
  coach             VARCHAR(40) NOT NULL,
  -- league affiliation, can be NULL
  affiliation       VARCHAR(40),
  PRIMARY KEY (team_id)
);

-- create table for games
CREATE TABLE games(
  game_id            CHAR(8),
  game_date_EST      DATE NOT NULL,
  -- e.g. 'Final', '2nd Qtr'
  game_status        VARCHAR(20) NOT NULL,
  home_team_id       CHAR(10) NOT NULL,
  visitor_team_id    CHAR(10) NOT NULL,
  -- points got by the home team
  PTS_home           INTEGER,
  -- field goal percentage of the home team
  FG_PCT_home        NUMERIC(4, 3),
  -- free throw percentage of the home team
  FT_PCT_home        NUMERIC(4, 3),
  -- 3 pointer field goal percentage of the home team
  FG3_PCT_home       NUMERIC(4, 3),
  -- assists of the home team
  AST_home           INTEGER,
  -- rebounds of the home team
  REB_home           INTEGER,
  -- points got by the away team
  PTS_away           INTEGER,
  -- field goal percentage of the away team
  FG_PCT_away        NUMERIC(4, 3),
  -- free throw percentage of the away team
  FT_PCT_away        NUMERIC(4, 3),
  -- 3 pointer field goal percentage of the away team
  FG3_PCT_away       NUMERIC(4, 3),
  -- assists of the away team
  AST_away           INTEGER,
  -- rebounds of the away team
  REB_away           INTEGER,
  PRIMARY KEY (game_id),
  FOREIGN KEY (home_team_id) REFERENCES teams(team_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (visitor_team_id) REFERENCES teams(team_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- create table for players
CREATE TABLE players(
  player_id          VARCHAR(20),
  team_id            CHAR(10),
  season             YEAR,
  player_name        VARCHAR(40) NOT NULL,
  PRIMARY KEY (player_id, team_id, season),
  FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- create table for rankings
CREATE TABLE rankings(
  team_id            CHAR(10),
  standings_date     DATE,
  season             YEAR NOT NULL,
  -- conferene('East' of 'West')
  conference         CHAR(4) NOT NULL,
  number_of_wins     INTEGER NOT NULL,
  number_of_losses   INTEGER NOT NULL,
  PRIMARY KEY (team_id, standings_date),
  FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CHECK (conference IN ('West', 'East')) 
);

-- create talbe for game_details
CREATE TABLE game_details(
  game_id            CHAR(8),
  team_id            CHAR(10),
  player_id          VARCHAR(20),
  -- NULL for bench players
  start_position     CHAR(1),
  -- comments on the player, can be NULL
  comments           TEXT(100),
  -- minutes played
  played_min         VARCHAR(20),
  -- field goal made
  FGM                INTEGER,
  -- field goal attempted
  FGA                INTEGER,
  -- 3 pointer field goal made
  FG3M               INTEGER,
  -- 3 pointer field goal attempted
  FG3A               INTEGER,
  -- free throw made
  FTM                INTEGER,
  -- free throw attempted
  FTA                INTEGER,
  -- offensive rebounds
  OREB               INTEGER,
  -- defensive rebounds
  DREB               INTEGER,
  -- assists
  AST                INTEGER,
  -- steals
  STL                INTEGER,
  -- blocks
  BLK                INTEGER,
  -- turnovers
  turnover           INTEGER,
  -- personal fouls
  PF                 INTEGER,
  -- points
  PTS                INTEGER,
  -- plus/minus value
  PLUS_MINUS         INTEGER,
  PRIMARY KEY (game_id, team_id, player_id),
  FOREIGN KEY (game_id) REFERENCES games(game_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (team_id) REFERENCES teams(team_id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (player_id) REFERENCES players(player_id) ON DELETE CASCADE ON UPDATE CASCADE
);
