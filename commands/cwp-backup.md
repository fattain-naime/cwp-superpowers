---
description: Manage CWP backups (create, restore, list, configure, verify)
argument-hint: "<action> [options]"
allowed-tools: Bash, Read, Write, Edit
---

# CWP Backup Management Command

You are managing backups on a CWP server. Determine the action from `$1` and execute accordingly.

## Arguments

- `$1` — Action: `create`, `restore`, `list`, `configure`, `verify`
- `$2` — Target or option (varies by action)

## Step 1: Validate Action

Confirm `$1` is one of the supported actions. If not, display usage and stop.

## Step 2: Determine Backup Location

- Default CWP backup directory: `/var/backups/cwp/`.
- User backups: `/var/backups/cwp/users/`.
- System backups: `/var/backups/cwp/system/`.
- Confirm the backup directory exists and has sufficient space.

## Step 3: Execute Action

### create
- If `$2` is a username, create a backup for that specific user:
  - Run `/scripts/backup_user $2` or the CWP backup script.
  - Backups include: website files, databases, email, DNS zones, cron jobs, SSL certificates.
- If `$2` is `system`, create a system-level backup:
  - Backup CWP configuration: `/usr/local/cwpsrv/htdocs/admin/conf/`.
  - Backup Apache/Nginx configs, PHP configs, MySQL configs.
  - Backup `/etc/postfix/`, `/etc/dovecot/`, DNS zones.
- If `$2` is `all`, backup all users and system configs.
- Show progress and final backup size.
- Generate a checksum: `sha256sum <backup_file>`.

### restore
- Require `$2` as the username or backup file path.
- If `$2` is a username, find the latest backup in `/var/backups/cwp/users/$2/`.
- If `$2` is a file path, confirm the file exists.
- Warn: "This will overwrite current data for the user. Are you sure?"
- After confirmation, run the restore script or extract the backup manually.
- Restore databases from SQL dumps.
- Restore files to the user's home directory.
- Restore DNS zones and email accounts.
- Verify the restoration by checking file counts and database table counts.

### list
- List all available backups:
  - System backups: `ls -lh /var/backups/cwp/system/`.
  - User backups: `ls -lhR /var/backups/cwp/users/`.
- For each backup, show: filename, size, date, type (full/incremental).
- Calculate total backup storage usage.

### configure
- Read the current CWP backup configuration from `/usr/local/cwpsrv/htdocs/admin/conf/backup.conf` or equivalent.
- If `$2` is `show`, display current settings.
- If `$2` is `local`, configure local backup: destination path, retention days, schedule.
- If `$2` is `remote`, configure remote backup: protocol (FTP/SFTP/S3), host, credentials, path.
- If `$2` is `schedule`, set the cron schedule for automated backups.
- After configuration, display the updated settings and suggest running a test backup.

### verify
- If `$2` is provided, verify that specific backup file:
  - Check file integrity: `sha256sum` against stored checksum.
  - Test extraction: extract to a temp directory and verify contents.
  - Check database dumps: verify SQL files are valid.
  - Check file completeness: ensure expected directories are present.
- If no `$2`, verify the most recent backup for each user.
- Report: integrity status, file count, database count, any corruption detected.

## Step 4: Report

Display a summary of the action taken, including sizes, file counts, and any warnings. Log all actions to `/var/log/cwp/backup-actions.log`.
