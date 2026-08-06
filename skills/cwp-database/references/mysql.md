# MySQL/MariaDB Reference

## Overview

CWP supports both MySQL and MariaDB as the database server. MariaDB is the default on modern CWP installations (CentOS 7+, AlmaLinux 8/9).

---

## Installation Paths

| Item              | Path                                    |
|-------------------|-----------------------------------------|
| Binary            | `/usr/bin/mysql`, `/usr/bin/mariadb`    |
| Data directory    | `/var/lib/mysql/`                       |
| Config            | `/etc/my.cnf` -> `/etc/my.cnf.d/`      |
| Error log         | `/var/log/mariadb/mariadb.log`          |
| Slow query log    | `/var/log/mariadb/slow.log`             |
| Socket            | `/var/lib/mysql/mysql.sock`             |
| PID file          | `/var/run/mariadb/mariadb.pid`          |

---

## Configuration Files

### Main Config

**Path:** `/etc/my.cnf`

```ini
!includedir /etc/my.cnf.d/
```

### Server Config

**Path:** `/etc/my.cnf.d/server.cnf`

```ini
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

# Character set
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# InnoDB
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_file_per_table=1
innodb_flush_log_at_trx_commit=1
innodb_flush_method=O_DIRECT
innodb_io_capacity=200

# Connections
max_connections=151
max_connect_errors=100000
wait_timeout=600
interactive_timeout=600

# Query cache (disabled in MySQL 8+ and MariaDB 10.1.7+)
query_cache_type=0
query_cache_size=0

# Logging
slow_query_log=1
slow_query_log_file=/var/log/mariadb/slow.log
long_query_time=2
log_queries_not_using_indexes=1

# Security
local_infile=0
symbolic-links=0
skip-name-resolve

# Temporary tables
tmp_table_size=64M
max_heap_table_size=64M

# Thread cache
thread_cache_size=16

# Table cache
table_open_cache=400
table_definition_cache=400

# Buffer sizes
sort_buffer_size=2M
read_buffer_size=1M
read_rnd_buffer_size=1M
join_buffer_size=2M
```

### Client Config

**Path:** `/etc/my.cnf.d/client.cnf`

```ini
[client]
socket=/var/lib/mysql/mysql.sock
default-character-set=utf8mb4
```

---

## Performance Tuning

### Memory-Based Tuning

| Server RAM | innodb_buffer_pool_size | max_connections | key_buffer_size |
|------------|-------------------------|-----------------|-----------------|
| 1GB        | 256M                    | 50              | 32M             |
| 2GB        | 512M                    | 100             | 64M             |
| 4GB        | 1G                      | 200             | 128M            |
| 8GB        | 2G                      | 400             | 256M            |
| 16GB       | 4G                      | 500             | 256M            |
| 32GB       | 8G                      | 800             | 256M            |

### InnoDB Tuning

```ini
# Buffer pool (set to 50-70% of available RAM)
innodb_buffer_pool_size=2G
innodb_buffer_pool_instances=4  # One per GB of buffer pool

# Log file size (25% of buffer pool, max 2G)
innodb_log_file_size=512M
innodb_log_buffer_size=64M

# Flush settings
innodb_flush_log_at_trx_commit=1  # 1=ACID, 2=performance
innodb_flush_method=O_DIRECT       # Avoid double buffering

# IO settings
innodb_io_capacity=400       # SSD: 200-2000, HDD: 200
innodb_io_capacity_max=800
innodb_read_io_threads=4
innodb_write_io_threads=4
```

### Query Cache

Query cache is deprecated in MySQL 8+ and MariaDB 10.1.7+. For older versions:

```ini
# Small workloads
query_cache_type=1
query_cache_size=64M
query_cache_limit=1M

# High-write environments (disable)
query_cache_type=0
```

---

## Root Password Management

### Reset Root Password

```bash
# Via CWP script
/scripts/mysql_pwd_reset <new_password>

# Manual reset
systemctl stop mariadb
mysqld_safe --skip-grant-tables &
mysql -u root
# In MySQL:
# ALTER USER 'root'@'localhost' IDENTIFIED BY 'new_password';
# FLUSH PRIVILEGES;
systemctl restart mariadb
```

### Root Credentials File

**Path:** `/root/.my.cnf`

```ini
[client]
user=root
password=MySQLRootPassword
host=localhost
```

### CWP Database Credentials

**Path:** `/usr/local/cwp/.conf/db_conn.php`

```php
<?php
$db_host = 'localhost';
$db_name = 'cwp';
$db_user = 'root';
$db_pass = 'MySQLRootPassword';
```

---

## User Management

### Create User

```sql
CREATE USER 'username'@'localhost' IDENTIFIED BY 'password';
```

### Grant Privileges

```sql
GRANT ALL PRIVILEGES ON database.* TO 'username'@'localhost';
FLUSH PRIVILEGES;
```

### Grant Specific Privileges

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON database.* TO 'username'@'localhost';
FLUSH PRIVILEGES;
```

### Remote Access

```sql
CREATE USER 'username'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON database.* TO 'username'@'%';
FLUSH PRIVILEGES;
```

### Via CWP Panel

Navigate to: **SQL Services > MySQL Manager**
- Create Database
- Create User
- Grant Access
- Change Password

---

## phpMyAdmin

### Installation

CWP installs phpMyAdmin automatically. Access via:
- Admin Panel: **SQL Services > phpMyAdmin**
- Direct URL: `https://server:2031/phpmyadmin/`

### Configuration

**Path:** `/usr/local/cwpsrv/var/services/pma/config.inc.php`

```php
<?php
$cfg['blowfish_secret'] = 'RANDOM_STRING_HERE';
$cfg['Servers'][$i]['auth_type'] = 'cookie';
$cfg['Servers'][$i]['host'] = 'localhost';
$cfg['Servers'][$i]['compress'] = false;
$cfg['Servers'][$i]['AllowNoPassword'] = false;
$cfg['UploadDir'] = '/tmp';
$cfg['SaveDir'] = '/tmp';
$cfg['MaxRows'] = 50;
$cfg['SendErrorReports'] = 'never';
```

### Security

Restrict phpMyAdmin access:
```apache
# In phpMyAdmin Apache config
<Directory /usr/local/cwpsrv/var/services/pma>
    Order Deny,Allow
    Allow from YOUR_IP
    Deny from all
</Directory>
```

---

## Backup and Restore

### Command Line Backup

```bash
# Backup single database
mysqldump -u root -p database_name > backup.sql

# Backup all databases
mysqldump -u root -p --all-databases > all_backup.sql

# Backup with compression
mysqldump -u root -p database_name | gzip > backup.sql.gz

# Backup structure only
mysqldump -u root -p --no-data database_name > structure.sql

# Backup data only
mysqldump -u root -p --no-create-info database_name > data.sql
```

### Restore

```bash
# Restore from SQL file
mysql -u root -p database_name < backup.sql

# Restore compressed
gunzip < backup.sql.gz | mysql -u root -p database_name
```

---

## Monitoring

### Status Variables

```sql
SHOW GLOBAL STATUS;
SHOW GLOBAL STATUS LIKE 'Threads%';
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool%';
SHOW GLOBAL STATUS LIKE 'Slow_queries';
SHOW GLOBAL STATUS LIKE 'Connections';
```

### Process List

```sql
SHOW PROCESSLIST;
SHOW FULL PROCESSLIST;
```

### Table Sizes

```sql
SELECT table_schema AS 'Database',
    ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS 'Size (MB)'
FROM information_schema.tables
GROUP BY table_schema;
```

### InnoDB Status

```sql
SHOW ENGINE INNODB STATUS;
```

---

## Common Issues

### Too many connections
```bash
# Check current connections
mysql -e "SHOW STATUS LIKE 'Threads_connected';"

# Increase limit
# In my.cnf: max_connections=300

# Kill sleeping connections
mysql -e "SELECT CONCAT('KILL ', id, ';') FROM information_schema.processlist WHERE command='Sleep' AND time > 300;"
```

### Slow queries
```bash
# Enable slow query log
# In my.cnf:
# slow_query_log=1
# long_query_time=2

# Analyze slow queries
mysqldumpslow -s t /var/log/mariadb/slow.log
```

### Database corruption
```bash
# Check all tables
mysqlcheck -u root -p --all-databases --check

# Repair all tables
mysqlcheck -u root -p --all-databases --repair

# Optimize all tables
mysqlcheck -u root -p --all-databases --optimize
```

### Can't connect to MySQL server
```bash
# Check if MySQL is running
systemctl status mariadb

# Check socket
ls -la /var/lib/mysql/mysql.sock

# Check port
ss -tlnp | grep 3306

# Check error log
tail -50 /var/log/mariadb/mariadb.log
```
