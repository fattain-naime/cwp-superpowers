---
name: cwp-database
description: This skill should be used when the user asks to "create MySQL database", "manage MariaDB", "install PostgreSQL", "configure MongoDB", "reset MySQL password", "tune database performance", "upgrade MariaDB", "fix database crash", "set up remote MySQL", "import database", "repair tables", "optimize database", or needs to manage any database service on a CWP server.
version: 1.0.0
---

# CWP Database Management

Manage MySQL/MariaDB, PostgreSQL, and MongoDB databases on CWP servers. Handle database creation, user management, performance tuning, upgrades, and recovery.

## Database Services Overview

| Database | Default | Management Tool |
|---|---|---|
| MariaDB | Installed by default | phpMyAdmin included |
| MySQL | Alternative to MariaDB | phpMyAdmin included |
| PostgreSQL | Optional install | phpPgAdmin |
| MongoDB | Optional install | MongoDB Manager |

## Service Detection

Detect which database services are installed:

```bash
# MariaDB (installed by default)
systemctl is-active mariadb 2>/dev/null && echo "MariaDB: active" || echo "MariaDB: not running"

# PostgreSQL (optional)
systemctl is-active postgresql 2>/dev/null && echo "PostgreSQL: active" || echo "PostgreSQL: not installed"

# MongoDB (optional)
systemctl is-active mongod 2>/dev/null && echo "MongoDB: active" || echo "MongoDB: not installed"
```

## MariaDB/MySQL

### Configuration Files

| File | Purpose |
|---|---|
| `/etc/my.cnf.d/server.cnf` | MariaDB main configuration |
| `/root/.my.cnf` | MySQL root credentials |
| `/etc/yum.repos.d/mariadb.repo` | MariaDB repository |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php` | CWP database connection |

### Access phpMyAdmin

- URL: `https://SERVER_IP:2030/phpMyAdmin/`
- Credentials: Use root password from `/root/.my.cnf`

### Common Database Operations

```bash
# Access MySQL CLI
mysql -u root -p

# Access with stored credentials
mysql

# Show databases
mysql -e "SHOW DATABASES;"

# Create database
mysql -e "CREATE DATABASE dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Create user
mysql -e "CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';"

# Grant privileges
mysql -e "GRANT ALL PRIVILEGES ON dbname.* TO 'username'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Import database
mysql -u username -p dbname < dump.sql

# Export database
mysqldump -u root -p dbname > dump.sql

# Export all databases
mysqldump -u root -p --all-databases > all_databases.sql
```

### Database Management via API

```bash
# Create database via CWP API
/scripts/cwp_api databasemysql add USERNAME DBNAME

# Delete database
/scripts/cwp_api databasemysql delete USERNAME DBNAME

# List databases
/scripts/cwp_api databasemysql list USERNAME
```

## Performance Tuning

Edit `/etc/my.cnf.d/server.cnf` under `[mysqld]`:

```ini
# Connection settings
max_connections = 500           # Default is 151
max_user_connections = 45       # Per-user for shared hosting
wait_timeout = 600              # Close idle connections

# Buffer settings
innodb_buffer_pool_size = 1G    # 50-70% of available RAM
innodb_log_file_size = 256M     # InnoDB log size
max_allowed_packet = 256M       # For large imports/exports
tmp_table_size = 64M            # Temporary table size
max_heap_table_size = 64M       # Memory table size

# Query cache (MariaDB 10.1 and earlier)
query_cache_type = 1
query_cache_size = 64M

# Logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
```

After changes, restart MariaDB:

```bash
systemctl restart mariadb
```

### Repair and Optimize Tables

```bash
# Repair MyISAM tables
/scripts/mysql_fix_myisam_tables

# Check all databases
mysqlcheck -u root -p --all-databases --check

# Optimize all databases
mysqlcheck -u root -p --all-databases --optimize

# Analyze all tables
mysqlcheck -u root -p --all-databases --analyze
```

## MariaDB Upgrade

Upgrade between MariaDB versions following the official path:

```bash
# Example: MariaDB 10.2 to 10.6
# Step 1: Update repository
sed -i 's/10.2/10.6/g' /etc/yum.repos.d/mariadb.repo

# Step 2: Stop MariaDB
systemctl stop mariadb mysql mysqld

# Step 3: Remove old packages
systemctl disable mariadb
rpm --nodeps -ev MariaDB-server

# Step 4: Install new version
yum clean all
yum -y update "MariaDB-*"
yum -y install MariaDB-server

# Step 5: Start and upgrade
systemctl enable mariadb
systemctl start mariadb
mysql_upgrade --force
```

**Warning:** Always back up all databases before upgrading. Test on a staging server first.

### MariaDB Upgrade Paths

| From | To | Notes |
|---|---|---|
| 10.2 | 10.3 -> 10.4 -> 10.5 -> 10.6 | Step-by-step recommended |
| 10.3 | 10.4 -> 10.5 -> 10.6 | Step-by-step recommended |
| 10.4 | 10.5 -> 10.6 | Direct may work |
| 10.5 | 10.6 | Direct upgrade |

## Remote MySQL Access

```bash
# Whitelist IP permanently in CSF
csf -a 10.10.23.124 "mysql remote connection"

# Whitelist IP temporarily (24 hours)
csf -ta 86400 10.10.23.124 "mysql remote connection"

# Allow MySQL remote connections in my.cnf
# bind-address = 0.0.0.0

# Create remote user
mysql -e "CREATE USER 'remoteuser'@'%' IDENTIFIED BY 'password';"
mysql -e "GRANT ALL PRIVILEGES ON dbname.* TO 'remoteuser'@'%';"
mysql -e "FLUSH PRIVILEGES;"
```

## InnoDB Crash Recovery

When MariaDB fails to start due to InnoDB corruption:

```bash
# Step 1: Add to my.cnf under [mysqld]
innodb_force_recovery = 1

# Step 2: Start MariaDB
systemctl start mariadb

# Step 3: Dump all databases
mysqldump -u root -p --all-databases > /root/emergency_backup.sql

# Step 4: Stop, remove InnoDB files, restart fresh
systemctl stop mariadb
rm -f /var/lib/mysql/ib_logfile*
systemctl start mariadb

# If level 1 fails, increment: 2, 3, 4, 5, 6
# Level 4+ may cause data loss
```

## PostgreSQL

### Installation

```bash
# Install via CWP Admin panel
# SQL Services -> PostgreSQL Installer

# Or install phpPgAdmin
sh /scripts/install_phpPgAdmin
```

### Configuration Files

| File | Purpose |
|---|---|
| `/var/lib/pgsql/data/postgresql.conf` | Main PostgreSQL configuration |
| `/var/lib/pgsql/data/pg_hba.conf` | Client authentication config |
| `/var/lib/pgsql/data/pg_ident.conf` | Username mapping |

### Common Operations

```bash
# Access PostgreSQL CLI
su - postgres
psql

# Create database
createdb dbname

# Create user
createuser -P username

# Grant privileges
psql -c "GRANT ALL PRIVILEGES ON DATABASE dbname TO username;"

# Backup database
pg_dump dbname > dbname.sql

# Restore database
psql dbname < dbname.sql

# Check PostgreSQL status
systemctl status postgresql
```

### Enable PHP PostgreSQL Support

Recompile PHP with `--with-pgsql` and `--with-pdo-pgsql` flags via PHP Switcher.

### Performance Tuning

Edit `/var/lib/pgsql/data/postgresql.conf`:

```ini
shared_buffers = 256MB              # 25% of RAM
work_mem = 4MB                      # Per-operation memory
maintenance_work_mem = 64MB         # For VACUUM, CREATE INDEX
effective_cache_size = 768MB        # 75% of RAM
max_connections = 100               # Adjust based on needs
```

```bash
# Restart after changes
systemctl restart postgresql
```

## MongoDB

### Installation

```bash
# Install via CWP Admin panel
# SQL Services -> MongoDB Manager
# Select MongoDB version (2 or 3)
```

### Configuration Files

| File | Purpose |
|---|---|
| `/etc/mongod.conf` | Main MongoDB configuration |
| `/var/log/mongodb/mongod.log` | MongoDB log file |
| `/var/lib/mongo/` | Data directory |

### Common Operations

```bash
# Access MongoDB shell
mongo

# Show databases
show dbs

# Use database
use dbname

# Create collection
db.createCollection("collectionname")

# Insert document
db.collectionname.insert({key: "value"})

# Find documents
db.collectionname.find()

# Backup database
mongodump --out /backup/path

# Restore database
mongorestore /backup/path

# Check MongoDB status
systemctl status mongod
```

### Configuration

Edit `/etc/mongod.conf`:

```yaml
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true

systemLog:
  destination: file
  path: /var/log/mongodb/mongod.log
  logAppend: true

net:
  port: 27017
  bindIp: 127.0.0.1  # Change for remote access
```

```bash
# Restart after changes
systemctl restart mongod
```

## Troubleshooting

| Issue | Solution |
|---|---|
| MySQL crashed (InnoDB) | `innodb_force_recovery = 1` (increment 1-6) |
| "BAD CONFIGURATION" error | Tune my.cnf with proper buffer settings |
| MariaDB upgrade failed | Follow version-specific upgrade path |
| Too many connections | Set `max_connections = 500` in my.cnf |
| Can't connect to phpMyAdmin | Check `/root/.my.cnf` credentials |
| Database import timeout | Increase `max_allowed_packet` and `wait_timeout` |
| Slow queries | Enable slow query log, add indexes |

### Diagnostic Commands

```bash
# Check MariaDB status
systemctl status mariadb

# View MariaDB error log
tail -50 /var/log/mysql/error.log

# Check connections
mysql -e "SHOW PROCESSLIST;"

# Check variables
mysql -e "SHOW VARIABLES LIKE 'max_connections';"

# Check InnoDB status
mysql -e "SHOW ENGINE INNODB STATUS\G"

# Database sizes
mysql -e "SELECT table_schema AS 'Database', ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)' FROM information_schema.tables GROUP BY table_schema;"

# Check database
/scripts/checkdb
```

## Additional Resources

- `references/mysql.md` -- MariaDB/MySQL configuration and tuning guide
- `references/postgresql.md` -- PostgreSQL installation and configuration
- `references/mongodb.md` -- MongoDB setup and management
