# CS121_final_project
This is the repository for Caltech CS 121 final project
## Packages
We used the `prettytable` to format our output, the `mysql-connection-python` to connect the Mysql to Python, therefore you must install them before using.
```bash
pip install prettytable
pip install mysql-connector-python
```
## Data
The data we used comes from [NBA Games Dataset](https://www.kaggle.com/nathanlauga/nba-games).
We modified the original data and produced the following 5 csv files.
1. teams.csv
2. games.csv
3. players.csv
4. games_details.csv
5. ranking.csv

## Usage
```bash
$ cd your-files
$ mysql
mysql> source setup.sql;
mysql> source load-data.sql;
mysql> source setup-passwords.sql;
mysql> source setup-routines.sql;
mysql> source grant-permissions.sql;
mysql> source queries.sql;
mysql> quit;
$ python3 app.py
```

