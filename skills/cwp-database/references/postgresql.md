# PostgreSQL Reference

## Overview

PostgreSQL is available as an optional database server in CWP. It can be installed alongside MySQL/MariaDB for applications that require it.

---

## Installation

### Via CWP Admin Panel

Navigate to: **SQL Services > PostgreSQL > Install**

### Manual Installation

```bash
# Install PostgreSQL repository
yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# Install PostgreSQL
yum install postgresql-server postgresql-contrib

# Initialize database
postgresql-setup --initdb

# Start and enable
systemctl start postgresql
systemctl enable postgresql
```

---

## Directory Structure

| Item               | Path                                              |
|--------------------|---------------------------------------------------|
| Binary             | `/usr/bin/psql`, `/usr/bin/pg_dump`               |
| Data directory     | `/var/lib/pgsql/data/`                            |
| Config             | `/var/lib/pgsql/data/postgresql.conf`             |
| Auth config        | `/var/lib/pgsql/data/pg_hba.conf`                 |
| Log directory      | `/var/lib/pgsql/data/log/`                        |
| Service            | systemd: `postgresql.service`                     |

---

## Configuration

### postgresql.conf

**Path:** `/var/lib/pgsql/data/postgresql.conf`

```ini
# Connection settings
listen_addresses = '*'
port = 5432
max_connections = 100

# Memory settings
shared_buffers = 256MB
effective_cache_size = 768MB
work_mem = 4MB
maintenance_work_mem = 64MB

# WAL settings
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB
checkpoint_completion_target = 0.9

# Logging
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d.log'
log_rotation_age = 1d
log_rotation_size = 10MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d '

# Performance
random_page_cost = 1.1        # SSD: 1.1, HDD: 4.0
effective_io_concurrency = 200 # SSD: 200, HDD: 2
default_statistics_target = 100

# Autovacuum
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
```

### pg_hba.conf

**Path:** `/var/lib/pgsql/data/pg_hba.conf`

Controls client authentication:

```ini
# TYPE  DATABASE    USER        ADDRESS         METHOD
local   all         all                         peer
host    all         all         127.0.0.1/32    md5
host    all         all         ::1/128         md5
host    all         all         0.0.0.0/0       md5

# Allow specific network
host    all         all         192.168.1.0/24  md5

# Trust local connections (development only)
local   all         postgres                    trust
```

**Authentication Methods:**
- `trust` - Allow without password (dangerous)
- `md5` - Password-based (standard)
- `scram-sha-256` - Stronger password (PostgreSQL 10+)
- `peer` - OS user match (local only)
- `reject` - Deny connection

After modifying pg_hba.conf:
```bash
systemctl reload postgresql
```

---

## User Management

### Create Superuser

```bash
sudo -u postgres createuser --superuser dbadmin
sudo -u postgres psql -c "ALTER USER dbadmin WITH PASSWORD 'secure_password';"
```

### Create Regular User

```bash
sudo -u postgres createuser --pwprompt appuser
```

### Create Database

```bash
sudo -u postgres createdb -O appuser appdb
```

### SQL Commands

```sql
-- Create user
CREATE USER appuser WITH PASSWORD 'secure_password';

-- Create database
CREATE DATABASE appdb OWNER appuser;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;

-- Grant specific schema privileges
GRANT USAGE ON SCHEMA public TO appuser;
GRANT CREATE ON SCHEMA public TO appuser;

-- Alter user
ALTER USER appuser WITH PASSWORD 'new_password';
ALTER USER appuser CREATEDB;

-- Drop user
DROP USER appuser;

-- Drop database
DROP DATABASE appdb;
```

---

## Common psql Commands

```bash
# Connect as postgres user
sudo -u postgres psql

# Connect to specific database
psql -U appuser -d appdb -h localhost

# List databases
\l

# Connect to database
\c appdb

# List tables
\dt

# Describe table
\d table_name

# List users
\du

# Show current database
\conninfo

# Execute SQL file
\i /path/to/file.sql

# Quit
\q
```

---

## Backup and Restore

### pg_dump

```bash
# Backup single database
pg_dump -U postgres appdb > appdb_backup.sql

# Backup with compression
pg_dump -U postgres appdb | gzip > appdb_backup.sql.gz

# Backup custom format (allows selective restore)
pg_dump -U postgres -Fc appdb > appdb_backup.dump

# Backup specific tables
pg_dump -U postgres -t table_name appdb > table_backup.sql

# Backup structure only
pg_dump -U postgres --schema-only appdb > schema.sql

# Backup data only
pg_dump -U postgres --data-only appdb > data.sql
```

### pg_dumpall

```bash
# Backup all databases
pg_dumpall -U postgres > all_databases.sql

# Backup roles only
pg_dumpall -U postgres --roles-only > roles.sql
```

### Restore

```bash
# Restore from SQL file
psql -U postgres appdb < appdb_backup.sql

# Restore from custom format
pg_restore -U postgres -d appdb appdb_backup.dump

# Restore compressed
gunzip < appdb_backup.sql.gz | psql -U postgres appdb

# Restore specific table
pg_restore -U postgres -d appdb -t table_name appdb_backup.dump
```

---

## phpPgAdmin

### Installation

```bash
# phpPgAdmin is available in CWP
# Install via CWP panel or:
yum install phpPgAdmin
```

### Configuration

**Path:** `/etc/phpPgAdmin/config.inc.php`

```php
<?php
$conf['servers'][0]['desc'] = 'PostgreSQL';
$conf['servers'][0]['host'] = 'localhost';
$conf['servers'][0]['port'] = 5432;
$conf['servers'][0]['sslmode'] = 'allow';
$conf['servers'][0]['default_db'] = 'postgres';

// Security
$conf['extra_login_security'] = true;
$conf['owned_only'] = false;
$conf['show_comments'] = true;
$conf['show_advanced'] = false;
$conf['show_system'] = false;
```

### Access

- URL: `https://server:2031/phppgadmin/`
- Or via CWP: **SQL Services > phpPgAdmin**

---

## Performance Tuning

### Memory Tuning

| Setting               | 1GB RAM | 2GB RAM | 4GB RAM | 8GB RAM |
|-----------------------|---------|---------|---------|---------|
| shared_buffers        | 128MB   | 256MB   | 1GB     | 2GB     |
| effective_cache_size  | 384MB   | 768MB   | 3GB     | 6GB     |
| work_mem              | 2MB     | 4MB     | 8MB     | 16MB    |
| maintenance_work_mem  | 32MB    | 64MB    | 128MB   | 256MB   |

### Query Analysis

```sql
-- Enable query logging
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();

-- Analyze specific query
EXPLAIN ANALYZE SELECT * FROM table WHERE condition;

-- Check table bloat
SELECT schemaname, relname, n_dead_tup, n_live_tup
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC;

-- Vacuum a table
VACUUM ANALYZE table_name;
```

---

## Security

### SSL Configuration

```ini
# In postgresql.conf
ssl = on
ssl_cert_file = '/var/lib/pgsql/data/server.crt'
ssl_key_file = '/var/lib/pgsql/data/server.key'
ssl_ca_file = '/var/lib/pgsql/data/root.crt'
```

### Restrict Remote Access

```ini
# In pg_hba.conf - only allow specific IPs
host    all    all    192.168.1.100/32    md5
host    all    all    10.0.0.0/8          reject
```

---

## Troubleshooting

### Connection refused
```bash
# Check if running
systemctl status postgresql

# Check listen_addresses
grep listen_addresses /var/lib/pgsql/data/postgresql.conf

# Check port
ss -tlnp | grep 5432

# Check pg_hba.conf for allowed connections
cat /var/lib/pgsql/data/pg_hba.conf
```

### Too many connections
```sql
-- Check current connections
SELECT count(*) FROM pg_stat_activity;

-- Increase max_connections
ALTER SYSTEM SET max_connections = 200;
-- Requires restart
systemctl restart postgresql
```

### Database size
```sql
SELECT pg_database.datname,
    pg_size_pretty(pg_database_size(pg_database.datname))
FROM pg_database
ORDER BY pg_database_size(pg_database.datname) DESC;
```
