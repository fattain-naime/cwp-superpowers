---
description: Manage MySQL/MariaDB databases on CWP (create, delete, list, backup, restore, optimize)
argument-hint: "<action> [options]"
allowed-tools: Bash, Read, Write
---

# CWP Database Management Command

You are managing databases on a CWP server. Determine the action from `$1` and execute accordingly.

## Arguments

- `$1` — Action: `create`, `delete`, `list`, `backup`, `restore`, `optimize`
- `$2` — Database name or target (varies by action)
- `$3` — Additional options (e.g., username for create, file path for restore)

## Step 1: Validate MySQL Access

- Confirm MariaDB/MySQL is running: `systemctl is-active mariadb`.
- Test root access: `mysql -e "SELECT 1"`. If it fails, try with credentials from `/root/.my.cnf`.

## Step 2: Validate Action

Confirm `$1` is one of the supported actions. If not, display usage and stop.

## Step 3: Execute Action

### create
- Require database name in `$2`. Validate: lowercase alphanumeric plus underscores, max 64 chars.
- Require username in `$3`. Validate: max 16 chars.
- Generate a random password for the database user.
- Run: `CREATE DATABASE $2; CREATE USER '$3'@'localhost' IDENTIFIED BY '<password>'; GRANT ALL PRIVILEGES ON $2.* TO '$3'@'localhost'; FLUSH PRIVILEGES;`
- Display the database name, username, and password.

### delete
- Require database name in `$2`.
- Confirm the database exists: `mysql -e "SHOW DATABASES LIKE '$2'"`.
- Warn and ask for confirmation.
- Run: `DROP DATABASE $2; DROP USER IF EXISTS '$3'@'localhost'; FLUSH PRIVILEGES;`

### list
- Run `mysql -e "SHOW DATABASES"` to list all databases.
- Filter out system databases (`information_schema`, `performance_schema`, `mysql`, `test`).
- For each user database, show size: `SELECT table_schema, ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS size_mb FROM information_schema.tables GROUP BY table_schema;`

### backup
- Require database name in `$2` (or `all` for all databases).
- Set backup path: `/var/backups/mysql/`.
- For single DB: `mysqldump $2 | gzip > /var/backups/mysql/$2_$(date +%Y%m%d_%H%M%S).sql.gz`
- For all DBs: `mysqldump --all-databases | gzip > /var/backups/mysql/all_$(date +%Y%m%d_%H%M%S).sql.gz`
- Verify the backup file exists and is non-empty.

### restore
- Require database name in `$2` and backup file path in `$3`.
- Confirm the backup file exists.
- Warn that this will overwrite the existing database.
- Run: `gunzip < $3 | mysql $2` (or `mysql < $3` for full backups).
- Verify restoration by checking table count.

### optimize
- Require database name in `$2` (or `all`).
- For single DB: Run `OPTIMIZE TABLE` on all tables: `mysql -e "SELECT CONCAT('OPTIMIZE TABLE ', table_name, ';') FROM information_schema.tables WHERE table_schema='$2'" | mysql $2`
- For all DBs: Iterate through all user databases.
- Report space reclaimed.

## Step 4: Log Action

Log all actions to `/var/log/cwp/database-actions.log` with timestamp, action, database name, and result.
