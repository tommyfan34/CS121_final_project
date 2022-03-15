"""
command-line app for CS121 final project
"""
import sys  # to print error messages to sys.stderr
import mysql.connector
# To get error codes from the connector, useful for user-friendly
# error-handling
import mysql.connector.errorcode as errorcode
from getpass import getpass

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
        
    def sql_helper(self, query, err_msg = None):
        """
        helper function for calling sql
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute(query)
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
