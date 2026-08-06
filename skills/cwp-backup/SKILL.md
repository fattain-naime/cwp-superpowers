---
name: cwp-backup
description: This skill should be used when the user asks to "configure backups", "set up automatic backups", "restore from backup", "configure remote backup", "set up S3 backup", "configure Google Drive backup", "set up SSH remote backup", "fix backup issues", "schedule backups", "create manual backup", "restore database from backup", or needs to manage any backup-related configuration on a CWP server.
version: 1.0.0
---

# CWP Backup Management

Manage local, remote, and cloud backups on CWP servers. Configure backup schedules, destinations, and restoration procedures.

## Backup Overview

Use built-in backup functionality with multiple storage backends and scheduling options.

**Important:** The CWP backup system has been in "perpetual beta" for over 4 years. Known issues include temporary files not being cleaned up, S3 files not auto-deleting, unreliable email notifications, and restore operations stalling. Always verify backups independently.

## Backup Schedules

| Schedule | Frequency | Default |
|---|---|---|
| Daily | Every day | Enabled |
| Weekly | Every week | Enabled |
| Monthly | Every month | Enabled |

## Backup Modes

| Mode | Description |
|---|---|
| Full | Complete backup of all user data |
| Incremental | Only changed files since last backup |
| Overwrite | Replace previous backup entirely |

## Storage Backends

| Backend | Protocol | Notes |
|---|---|---|
| Local | Disk | Default: `/backup` |
| SMB/CIFS | Network share | Windows-compatible |
| NFS | Network filesystem | Linux-native |
| Amazon S3 | Cloud storage | Requires AWS credentials |
| Google Drive | Cloud storage | Requires gdrive tool |
| SSH Remote | SCP/SFTP | Remote server backup |

## Default Locations

### Backup Directory Structure

CWP backup structure varies by version. Check which structure exists:

```bash
# Detect backup structure
if [ -d "/backup/daily" ]; then
    echo "Structure: /backup/{daily,weekly,monthly}/{username}/"
    BACKUP_BASE="/backup/daily"
elif [ -d "/backup/$(ls /backup 2>/dev/null | head -1)" ]; then
    echo "Structure: /backup/{username}/"
    BACKUP_BASE="/backup"
fi
```

| Path | Contents |
|---|---|
| `/backup` | Backup root directory |
| `/backup/daily/` | Daily backups (per-user subdirectories) |
| `/backup/weekly/` | Weekly backups (per-user subdirectories) |
| `/backup/monthly/` | Monthly backups (per-user subdirectories) |
| `/backup/mysql/` | Database backups |
| `/var/vmail` | Email storage |

## Backup Configuration

### Via CWP Admin Panel

Navigate to Backup -> Backup Configuration to configure:

1. Backup schedule (daily/weekly/monthly)
2. Backup mode (full/incremental/overwrite)
3. Storage destination
4. Retention period
5. Email notifications

## Manual Backup

### Create User Backup

Script name varies by CWP version:

```bash
# Try user_backup first (newer CWP), fallback to backup_user
if [ -f /scripts/user_backup ]; then
    sh /scripts/user_backup USERNAME
elif [ -f /scripts/backup_user ]; then
    sh /scripts/backup_user USERNAME
else
    echo "Backup script not found"
fi
```

### Via API

```bash
/scripts/cwp_api account backup_user USERNAME
```

## Google Drive Backup

### Installation

```bash
# Download gdrive tool
wget -O gdrive https://drive.google.com/uc?id=FILE_ID&export=download
mv gdrive /usr/sbin/gdrive
chmod 755 /usr/sbin/gdrive
```

### Upload Backup to Google Drive

```bash
# Create compressed backup
tar -czf "/tmp/backup-$(date '+%d-%m-%Y').tar.gz" /backup/daily/user

# Upload to Google Drive folder
gdrive upload --parent FOLDER_TOKEN /tmp/backup.tar.gz --delete
```

### Automate Google Drive Upload

Create a cron job to automate uploads:

```bash
# Add to crontab
0 2 * * * /path/to/backup_script.sh
```

## Amazon S3 Backup

Configure S3 credentials in CWP Admin -> Backup -> Backup Configuration:

1. Enter AWS Access Key
2. Enter AWS Secret Key
3. Select S3 bucket region
4. Specify bucket name
5. Set backup path within bucket

**Known issue:** S3 backup files are not automatically deleted. Monitor and clean up manually.

## SSH Remote Backup

Configure SSH remote backup in CWP Admin:

1. Enter remote server IP
2. Enter SSH port
3. Enter SSH username
4. Upload SSH key or enter password
5. Specify remote backup path

## Backup Restoration

### Via CWP Admin Panel

Navigate to Backup -> Restore Backup:

1. Select backup source (local/remote)
2. Choose backup date
3. Select user accounts to restore
4. Click Restore

**Known issue:** Restore may stall at "Detecting files". If this occurs, try restoring individual components manually.

### Manual Restoration

```bash
# Find backup file (check both directory structures)
BACKUP_FILE=""
if [ -f "/backup/daily/USERNAME/backup.tar.gz" ]; then
    BACKUP_FILE="/backup/daily/USERNAME/backup.tar.gz"
elif [ -f "/backup/USERNAME/backup.tar.gz" ]; then
    BACKUP_FILE="/backup/USERNAME/backup.tar.gz"
fi

if [ -z "$BACKUP_FILE" ]; then
    # Find latest backup
    BACKUP_FILE=$(find /backup -name "*USERNAME*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
fi

# Extract backup
tar -xzf "$BACKUP_FILE" -C /tmp/restore/

# Restore files
cp -a /tmp/restore/home/USERNAME/* /home/USERNAME/

# Restore database
mysql -u root -p DATABASE < /tmp/restore/database.sql

# Fix permissions (use API which works on all versions)
/scripts/cwp_api account fix_perms USERNAME
```

## Email Storage Backup

Store email at `/var/vmail`. Include this path in backup configuration to ensure email data is backed up.

## Backup Monitoring

```bash
# Check backup directory size
du -sh /backup/

# List recent backups (check both structures)
if [ -d "/backup/daily" ]; then
    ls -la /backup/daily/
else
    ls -la /backup/
fi

# Check backup cron jobs
crontab -l | grep backup

# View backup logs (check multiple possible locations)
if [ -f "/var/log/cwp_backup.log" ]; then
    tail -f /var/log/cwp_backup.log
elif [ -d "/backup/logs" ]; then
    tail -f /backup/logs/backup_$(date +%Y-%m-%d).log
else
    journalctl -u cwp --since "1 hour ago"
fi
```

## Backup Best Practices

1. **Verify backups regularly** -- Do not rely solely on backup completion notifications
2. **Test restoration** -- Periodically test restoring from backups
3. **Use multiple destinations** -- Local + remote/cloud for redundancy
4. **Monitor backup sizes** -- Alert on unexpected size changes
5. **Clean up old backups** -- Implement retention policies
6. **Back up before updates** -- Always back up before CWP or system updates
7. **Include email** -- Ensure `/var/vmail` is in backup scope
8. **Document procedures** -- Maintain restoration runbooks

## Troubleshooting

| Issue | Solution |
|---|---|
| Backup not completing | Check disk space: `df -h` |
| Restore stalling | Try manual restoration method |
| S3 files not deleting | Implement manual cleanup cron |
| Email notifications not working | Check Postfix configuration |
| Temporary files filling disk | Manually clean `/tmp/backup_*` |
| Google Drive auth failing | Re-authenticate gdrive tool |
| SSH backup connection failing | Verify SSH key and permissions |

### Diagnostic Commands

```bash
# Check disk usage
df -h

# Check backup directory
ls -lah /backup/

# Check for stale temp files
find /tmp -name "backup_*" -mtime +1

# Check backup cron
crontab -l

# Check CWP logs
tail -100 /var/log/cwp/*.log
```

## Additional Resources

- `references/local-backup.md` -- Local backup configuration and scheduling
- `references/remote-backup.md` -- Remote backup via S3, SSH, and network storage
- `references/restore.md` -- Backup restoration procedures
