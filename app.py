"""
command-line app for CS121 final project
"""
import sys  # to print error messages to sys.stderr
import mysql.connector
# To get error codes from the connector, useful for user-friendly
# error-handling
import mysql.connector.errorcode as errorcode
from getpass import getpass
from prettytable import PrettyTable

"""
class for the user
"""
class user:
    def __init__(self, username, is_admin):
        self.username = username
        self.is_admin = is_admin

"""
class for the app
"""
class app:
    def __init__(self, DBG=False):
        self.DEBUG = DBG
        self.logged_in = False
        self.logged_user = None

    def get_conn(self):
        """"
        Returns a connected MySQL connector instance, if connection is successful.
        If unsuccessful, exits.
        """
        try:
            conn = mysql.connector.connect(
            host='localhost',
            user='nbaadmin',
            # Find port in MAMP or MySQL Workbench GUI or with
            # SHOW VARIABLES WHERE variable_name LIKE 'port';
            port='3306',
            password='adminpw',
            database='nba'
            )
            print('Successfully connected.')
            return conn
        except mysql.connector.Error as err:
            # Remember that this is specific to _database_ users, not
            # application users. So is probably irrelevant to a client in your
            # simulated program. Their user information would be in a users table
            # specific to your database.
            if err.errno == errorcode.ER_ACCESS_DENIED_ERROR and self.DEBUG:
                sys.stderr('Incorrect username or password when connecting to DB.')
            elif err.errno == errorcode.ER_BAD_DB_ERROR and self.DEBUG:
                sys.stderr('Database does not exist.')
            elif self.DEBUG:
                sys.stderr(err)
            else:
                sys.stderr('An error occurred, please contact the administrator.')
            sys.exit(1)


    def show_options(self):
        """
        show the option functions for users
        """
        print("Select an option:")
        if not self.logged_in:
            print("  (l) - Log in")
        else:
            print("  (p) - Look up a player's stats for a given year")
            print("  (s) - Get the score leader for each team for a given year")
            print("  (g) - Show the game stats of a team on a given date")
            if self.logged_user.is_admin:
                print("  (t) - Change the information of a team")
            print("  (c) - Change password")
            print("  (o) - Log out")
        print("  (q) - Exit program")

        print()

    def get_input(self):
        """
        get the input from the user and call the corresponding function
        """
        input_val = input("You choose: ")
        if not self.logged_in and input_val == 'l':
            self.log_in()
        elif input_val == 'q':
            exit(0)
        elif self.logged_in and input_val == 'o':
            self.log_out()
        elif self.logged_in and input_val == 'c':
            self.change_password()
        elif self.logged_in and input_val == 'p':
            self.get_player_stats()
        elif self.logged_in and input_val == 's':
            self.get_score_leader()
        elif self.logged_in and input_val == 't':
            self.update_teams()
        elif self.logged_in and input_val == 'g':
            self.show_game()

    def get_player_stats(self):
        """
        get the player's stats for a given year
        """
        player = input("Type the player's name (e.g. Kobe Bryant):\n")
        year = input("Type the year of the stats you want to look up, if does not specify, all year's stats will be given:\n")
        t = PrettyTable(['Year', 'Player', 'Avg Pts', 'Avg Reb', 'Avg Ast', 'Avg Stl', 'Avg Blk', 'Avg Turnover', 'Avg Foul'])
        if year != "":
            sql = """
            SELECT player_name, AVG(PTS) AS avg_points, 
                AVG(OREB+DREB) AS avg_rebounds, AVG(AST) AS avg_assists, 
                AVG(STL) AS avg_steals, AVG(BLK) AS avg_blocks, 
                AVG(turnover) AS avg_turnovers, AVG(PF)AS avg_personal_fouls 
            FROM game_details NATURAL INNER JOIN players NATURAL INNER JOIN games
            WHERE player_name='%s' AND date_to_season(game_date_EST) = %s
            GROUP BY player_id, player_name;
            """ % (player, year, )
            rows = self.sql_helper(sql)
            if len(rows) == 0:
                print("No results found :(")
            else:
                r = list(rows[0])
                r.insert(0, year)
                t.add_row(r)
                print(t)
        else:
            sql = """
            SELECT date_to_season(game_date_EST), player_name, AVG(PTS) AS avg_points, 
                AVG(OREB+DREB) AS avg_rebounds, AVG(AST) AS avg_assists, 
                AVG(STL) AS avg_steals, AVG(BLK) AS avg_blocks, 
                AVG(turnover) AS avg_turnovers, AVG(PF)AS avg_personal_fouls 
            FROM game_details NATURAL INNER JOIN players NATURAL INNER JOIN games
            WHERE player_name='%s' GROUP BY player_id, player_name, date_to_season(game_date_EST)
            ORDER BY date_to_season(game_date_EST);
            """ % (player, )
            rows = self.sql_helper(sql)
            if len(rows) == 0:
                print("No results found :(")
            else:
                for i in range(len(rows)):
                    t.add_row(rows[i])
                print(t)
        
    def get_score_leader(self):
        """
        get the score leader for a given year of each team
        """
        year = input("Type the year: \n")
        t = PrettyTable(['Year', 'Team', 'Player', 'Leading Pts'])
        sql = """
        WITH 
            cte1 AS (SELECT player_id, team_id, AVG(PTS) AS avg_pts 
                    FROM game_details NATURAL INNER JOIN games 
                    WHERE date_to_season(game_date_EST) = %s
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
        """ % (year, )
        rows = self.sql_helper(sql)
        if len(rows) == 0:
            print("The year is no correct")
        else:
            for r in rows:
                r = list(r)
                r.insert(0, year)
                t.add_row(r)
            print(t)

    def update_teams(self):
        """
        update the team information, including owner, manager and coach.
        can only be updated by an admin
        """
        if self.logged_user is None or not self.logged_user.is_admin:
            return
        team = input('Type the abbreviation of the team you want to change, e.g. BOS:\n')
        sql = """
        SELECT owner, manager, coach FROM teams WHERE team_abbreviation='%s';
        """ % (team, )
        rows = self.sql_helper(sql)
        if len(rows) == 0:
            print('There is no such team')
        else:
            (owner, manager, coach) = rows[0]
            print("The owner for %s is %s, the manager is %s, the coach is %s" % (team, owner, manager, coach))
            new_owner = input("Type the new owner, if you does not want to change, just ENTER \n")
            if new_owner == '':
                new_owner = owner
            new_manager = input("Type the new manager, if you does not want to change, just ENTER \n")
            if new_manager == '':
                new_manager = manager
            new_coach = input("Type the new coach, if you does not want to change, just ENTER \n")
            if new_coach == '':
                new_coach = coach
            sql = """
            CALL sp_modify_teams('%s', '%s', '%s', '%s');
            """ % (team, new_owner, new_manager, new_coach, )
            rows = self.sql_helper(sql, changed=True)
            print("Now the owner for %s is %s, the manager is %s, the coach is %s" % (team, new_owner, new_manager, new_coach))


    def show_game(self):
        """
        show the game stats of a team on the given date
        e.g. 'UTA' on '2003-10-05'
        """
        team = input('Type the team abbreviation, e.g. UTA \n')
        date = input('Type the date of the match, must be in form of YYYY-MM-DD\n')
        sql = """
        SELECT DISTINCT team_abbreviation,
                        PTS_home AS pts,
                        FG_PCT_home AS fg_pct,
                        FG_PCT_home AS ft_pct,
                        AST_home AS ast,
                        REB_home AS reb 
        FROM games NATURAL INNER JOIN game_details NATURAL INNER JOIN teams 
        WHERE game_date_EST = '%s' 
            AND team_abbreviation = '%s' 
            AND home_team_id = team_id
            UNION
        SELECT DISTINCT team_abbreviation,
                        PTS_away AS pts,
                        FG_PCT_away AS fg_pct,
                        FG_PCT_away AS ft_pct,
                        AST_away AS ast,
                        REB_away AS reb 
        FROM games NATURAL INNER JOIN game_details NATURAL INNER JOIN teams
        WHERE game_date_EST = '%s' 
            AND team_abbreviation = '%s'
            AND visitor_team_id = team_id;
        """ % (date, team, date, team, )
        rows = self.sql_helper(sql)
        if len(rows) == 0:
            print("There is no matched games")
        else:
            t = PrettyTable(["Team", "Pts", "FG_pct", "FT_pct", "Ast", "Reb"])
            for r in rows:
                t.add_row(r)
            print(t)


    def log_in(self):
        """
        log the user in
        """
        username = input("Type your username: ")
        password = getpass("Type your password: ")
        sql = """
        SELECT authenticate('%s', '%s');
        """ % (username, password, )
        rows = self.sql_helper(sql)
        if rows[0][0] == 1:
            print('Welcome,', username)
            self.logged_in = True
            sql = """
            SELECT is_admin FROM user_info WHERE username='%s';
            """ % (username)
            is_admin = self.sql_helper(sql)[0][0]
            if is_admin == 1:
                self.logged_user = user(username, True)
            else:
                self.logged_user = user(username, False)
        else:
            print('The username and password does not match')

    def log_out(self):
        """
        log the user out
        """
        print("Bye,", self.logged_user.username)
        self.logged_in = False
        self.logged_user = None

    def change_password(self):
        """
        change the user's password
        """
        new_pw = input("Type your new password: ")
        sql = """
        CALL sp_change_password('%s', '%s')
        """ % (self.logged_user.username, new_pw, )
        self.sql_helper(sql)
        
    def sql_helper(self, query, err_msg = None, changed=False):
        """
        helper function for calling sql
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute(query)
            if changed:
                self.conn.commit()
            rows = cursor.fetchall()
            return rows
        except mysql.connector.Error as err:
            if self.DEBUG:
                sys.stderr(err)
                sys.exit(1)
            else:
                if err_msg is None:
                    sys.stderr('An error occurred with the sql')
                else:
                    sys.stderr(err_msg)
                return

    def main(self):
        """
        Main function for starting things up.
        """
        self.conn = self.get_conn()
        while True:
            self.show_options()
            self.get_input()


if __name__ == '__main__':
    # This conn is a global object that other functinos can access.
    # You'll need to use cursor = conn.cursor() each time you are
    # about to execute a query with cursor.execute(<sqlquery>)
    arguments = set(sys.argv[1:])
    if '-d' in arguments:
        debug_mode = True
    else:
        debug_mode = False
    app_instance = app(debug_mode)
    app_instance.main()
