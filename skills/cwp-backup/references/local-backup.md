# Local Backup Reference

## Overview

CWP provides built-in local backup functionality that creates compressed archives of user accounts, databases, and configurations in the `/backup` directory.

---

## Directory Structure

Modern CWP (0.9.8.1244+) uses date-based subdirectories under `/backup`:

```
/backup/                              # Default backup directory
  daily/                              # Daily backup cycle
    {username}/                       # Per-user backup folder
      {username}.tar.gz               # User files backup
      {username}_mysql.tar.gz         # Database backup
      {username}_email.tar.gz         # Email backup
  weekly/                             # Weekly backup cycle
    {username}/                       # Per-user backup folder
  monthly/                            # Monthly backup cycle
    {username}/                       # Per-user backup folder
  mysql/                              # Standalone database backups
  system/                             # System configuration backup
    etc_configs.tar.gz                # Configuration files
    cron_backup.tar.gz                # Cron jobs
    dns_zones.tar.gz                  # DNS zones
  logs/                               # Backup logs
    backup_{date}.log                 # Daily backup log
```

> **Note:** Some older CWP installations use a flat layout with `/backup/{username}/` directly (no `daily/`, `weekly/`, `monthly/` subdirectories). Check both patterns when locating backups.

---

## Backup Configuration

### Via CWP Admin Panel

Navigate to: **Backup > Backup Configuration**

### Configuration Options

| Setting            | Default         | Description                              |
|--------------------|-----------------|------------------------------------------|
| Backup enabled     | yes             | Enable/disable backups                   |
| Backup directory   | /backup         | Where backups are stored                 |
| Backup count       | 3               | Number of backups to retain              |
| Backup frequency   | daily           | daily, weekly, monthly                   |
| Backup time        | 02:00           | Time to run backup                       |
| Compress backups   | yes             | Gzip compression                         |
| Include databases  | yes             | Backup MySQL databases                   |
| Include email      | yes             | Backup email accounts                    |
| Include cron       | yes             | Backup cron jobs                         |
| Include DNS        | yes             | Backup DNS zones                         |
| Exclude dirs       | (empty)         | Directories to exclude                   |

### Configuration File

**Path:** `/usr/local/cwp/.conf/backup.conf`

```ini
enabled=yes
backup_dir=/backup
backup_count=3
backup_frequency=daily
backup_time=02:00
compress=yes
include_databases=yes
include_email=yes
include_cron=yes
include_dns=yes
exclude_dirs=cache,tmp,.cache,node_modules
```

---

## Backup Scripts

### Full Server Backup

```bash
# Backup all users
/scripts/backup_all

# Or via CWP panel
# Backup > Backup All Users
```

### Single User Backup

```bash
# Backup specific user (dual-path: script name varies by CWP version)
if [ -f /scripts/user_backup ]; then
    sh /scripts/user_backup {username}
elif [ -f /scripts/backup_user ]; then
    sh /scripts/backup_user {username}
fi

# Via CWP API
/scripts/cwp_api account backup_user {username}

# Via CWP panel
# Backup > List Users > Select User > Backup
```

### What Gets Backed Up

#### User Files Backup (`{username}.tar.gz`)
- `/home/{username}/` (entire home directory)
- `.htaccess` files
- Public HTML directory
- User-specific configs

#### Database Backup (`{username}_mysql.tar.gz`)
- All MySQL databases owned by user
- Database users and permissions
- SQL dump format

#### Email Backup (`{username}_email.tar.gz`)
- Email accounts list
- Mailbox contents (Maildir format)
- Forwarders
- Autoresponders

---

## Manual Backup Commands

### Tar-Based Backup

```bash
# Backup user home directory
tar -czf /backup/user_backup.tar.gz /home/username/

# Backup databases
mysqldump -u root -p --all-databases | gzip > /backup/all_databases.sql.gz

# Backup specific database
mysqldump -u root -p database_name | gzip > /backup/database_name.sql.gz

# Backup configuration files
tar -czf /backup/etc_configs.tar.gz /etc/postfix/ /etc/dovecot/ /etc/named.conf /etc/my.cnf
```

### Incremental Backup

```bash
# Create incremental backup using rsync
rsync -avz --delete /home/username/ /backup/incremental/username/

# Using tar with snapshot
tar -czf /backup/username_incremental.tar.gz \
    --newer-mtime="2024-01-01" /home/username/
```

---

## Backup Schedule (Cron)

### CWP Cron Jobs

**Path:** `/etc/cron.d/cwp_backup`

```cron
# CWP backup schedule
0 2 * * * root /scripts/backup_all >> /backup/logs/backup_$(date +\%Y\%m\%d).log 2>&1
```

### Custom Cron Schedule

```bash
# Edit crontab
crontab -e

# Add custom backup schedule
# Daily at 2 AM
0 2 * * * /scripts/backup_all

# Weekly on Sunday at 3 AM
0 3 * * 0 /scripts/backup_all

# Monthly on 1st at 4 AM
0 4 1 * * /scripts/backup_all

# Every 6 hours
0 */6 * * * /scripts/backup_all
```

---

## Retention Policy

### Backup Count

CWP retains the number of backups specified in `backup_count`:

```ini
backup_count=3
```

When a new backup is created and the count is exceeded, the oldest backup is automatically deleted.

### Manual Retention Management

```bash
# List backups
ls -la /backup/

# Check backup sizes
du -sh /backup/*

# Delete old backups (older than 30 days)
find /backup -name "*.tar.gz" -mtime +30 -delete

# Delete specific user's old backups (adjust path for your CWP version)
find /backup/daily/username -name "*.tar.gz" -mtime +7 -delete 2>/dev/null
find /backup/username -name "*.tar.gz" -mtime +7 -delete 2>/dev/null
```

### Retention Script

```bash
#!/bin/bash
# /scripts/backup_cleanup

BACKUP_DIR="/backup"
KEEP_DAYS=7

# Delete backups older than KEEP_DAYS
find ${BACKUP_DIR} -name "*.tar.gz" -mtime +${KEEP_DAYS} -delete
find ${BACKUP_DIR} -name "*.sql.gz" -mtime +${KEEP_DAYS} -delete

# Delete empty directories
find ${BACKUP_DIR} -type d -empty -delete

echo "Cleanup complete. Removed backups older than ${KEEP_DAYS} days."
```

---

## Backup Monitoring

### Check Backup Status

```bash
# View latest backup log
tail -50 /backup/logs/backup_$(date +%Y%m%d).log

# Check if backup is running
ps aux | grep backup

# Check backup disk usage
df -h /backup
```

### Backup Log Analysis

```bash
# View all backup logs
ls -la /backup/logs/

# Check for errors
grep -i "error\|failed" /backup/logs/*.log

# Count successful backups
grep -c "Backup complete" /backup/logs/*.log
```

### Email Notifications

Configure backup notifications in CWP:
**Backup > Backup Configuration > Email Notifications**

```ini
notify_email=admin@example.com
notify_on_success=no
notify_on_failure=yes
```

---

## Disk Space Management

### Check Backup Size

```bash
# Total backup size
du -sh /backup/

# Per-user backup size
du -sh /backup/*/

# Largest backups
du -sh /backup/* | sort -rh | head -20
```

### Move Backups to Separate Disk

```bash
# Mount separate disk
mount /dev/sdb1 /backup

# Add to fstab for persistence
echo "/dev/sdb1 /backup ext4 defaults 0 2" >> /etc/fstab
```

### Compress Old Backups

```bash
# Re-compress with higher compression
for f in /backup/**/*.tar.gz; do
    gzip -9 "$f"
done
```

---

## Backup Verification

### Verify Backup Integrity

```bash
# Test tar archive (adjust path for daily/weekly/monthly or flat layout)
tar -tzf /backup/daily/username/username.tar.gz > /dev/null && echo "OK" || echo "CORRUPT"

# Test gzip integrity
gzip -t /backup/daily/username/username.tar.gz && echo "OK" || echo "CORRUPT"

# Test SQL dump
gunzip -c /backup/daily/username/username_mysql.sql.gz | head -20
```

### Test Restore

```bash
# Extract to temporary directory
mkdir -p /tmp/restore_test
tar -xzf /backup/daily/username/username.tar.gz -C /tmp/restore_test

# Verify files
ls -la /tmp/restore_test/home/username/

# Cleanup
rm -rf /tmp/restore_test
```

---

## Troubleshooting

### Backup fails

```bash
# Check error log
tail -100 /backup/logs/backup_$(date +%Y%m%d).log

# Check disk space
df -h /backup

# Check permissions
ls -la /backup/

# Test backup script manually
if [ -f /scripts/user_backup ]; then
    sh /scripts/user_backup username
elif [ -f /scripts/backup_user ]; then
    sh /scripts/backup_user username
fi
```

### Backup too large

```bash
# Check what's being backed up
du -sh /home/username/*

# Exclude large directories
# In backup.conf:
# exclude_dirs=cache,tmp,.cache,node_modules,logs

# Check for large files
find /home/username -size +100M -type f
```

### Backup taking too long

```bash
# Check I/O
iostat -x 1

# Reduce compression level
# In backup.conf: compress_level=1

# Exclude unnecessary directories
# exclude_dirs=cache,tmp,.cache,node_modules
```

### Database backup fails

```bash
# Check MySQL credentials
mysql -u root -p -e "SELECT 1"

# Check /root/.my.cnf
cat /root/.my.cnf

# Manual database backup
mysqldump -u root -p --all-databases > /tmp/test.sql
```
