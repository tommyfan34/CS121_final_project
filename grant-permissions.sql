CREATE USER 'nbaadmin'@'localhost' IDENTIFIED BY 'adminpw';
CREATE USER 'nbaclient'@'localhost' IDENTIFIED BY 'clientpw';
-- Can add more users or refine permissions
GRANT ALL PRIVILEGES ON shelterdb.* TO 'appadmin'@'localhost';
GRANT SELECT ON shelterdb.* TO 'appclient'@'localhost';
FLUSH PRIVILEGES;
