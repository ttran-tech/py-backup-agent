@echo off
mariadb -u root -p < ".\\BackupAgent_MariaDB_100MB.sql"
mariadb -u root -p < ".\\BackupAgent_MariaDB_500MB.sql"
mariadb -u root -p < ".\\BackupAgent_MariaDB_PatientManagement_500MB.sql"