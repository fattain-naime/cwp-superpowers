# cPanel to CWP Migration Reference

## Overview

CWP provides a 5-script migration process to import accounts from cPanel/WHM servers. This supports both single account and full server migrations.

---

## Migration Methods

### Method 1: CWP Built-in Migration Module

**Admin Panel > Account Migration > cPanel Migration**

### Method 2: CLI Scripts

5 dedicated scripts in `/scripts/` for granular migration control.

### Method 3: Backup File Import

Import cPanel backup files (.tar.gz) directly into CWP.

---

## Prerequisites

### On cPanel Server

1. Root SSH access (or reseller with full access)
2. Generate backups in cPanel format
3. Ensure backups are accessible via SSH or HTTP

### On CWP Server

1. CWP installed and configured
2. Sufficient disk space for all accounts
3. Network connectivity to cPanel server
4. Matching PHP version (or plan to adjust)

### Disk Space Check

```bash
# Check available space on CWP server
df -h /home

# Estimate required space (add 20% buffer)
# Total cPanel backup size * 1.2
```

---

## The 5-Script Migration Process

> **Note:** The migration scripts below (1-cpanel-data-export.sh, etc.) are external
> community/provided scripts, not CWP built-in commands. They must be obtained and
> placed on the server before running.

### Script 1: cpanel_prepare

Prepares the CWP server for migration.

```bash
/scripts/cpanel_prepare --source=cpanel_server_ip --user=root
```

What it does:
- Creates necessary directories
- Sets up temporary storage
- Validates connectivity
- Checks prerequisites

### Script 2: cpanel_fetch

Downloads cPanel backups to the CWP server.

```bash
/scripts/cpanel_fetch --source=cpanel_server_ip --user=root --password=ssh_pass
```

Options:
- `--account=username` - Single account
- `--all` - All accounts
- `--backup-path=/path` - Custom backup location on source

### Script 3: cpanel_extract

Extracts cPanel backup archives.

```bash
/scripts/cpanel_extract --file=/path/to/backup.tar.gz
```

What it extracts:
- Website files
- Database dumps
- Email accounts and forwarders
- DNS zones
- Cron jobs
- SSL certificates

### Script 4: cpanel_import

Imports extracted data into CWP.

```bash
/scripts/cpanel_import --user=username
```

What it imports:
- Creates user account
- Restores website files
- Imports databases
- Configures email accounts
- Sets up DNS zones
- Applies cron jobs

### Script 5: cpanel_cleanup

Cleans up temporary migration files.

```bash
/scripts/cpanel_cleanup --user=username
```

Removes:
- Temporary extraction directories
- Downloaded backup files
- Migration logs (optional)

---

## Single Account Migration

### Via CWP Panel

1. Go to **Account Migration > cPanel Migration**
2. Enter cPanel server details:
   - Server IP
   - SSH port (default 22)
   - Root username
   - Root password (or SSH key)
3. Select account to migrate
4. Click "Migrate"

### Via CLI

```bash
# Step 1: Prepare
/scripts/cpanel_prepare

# Step 2: Fetch single account
/scripts/cpanel_fetch --source=192.168.1.100 --user=root --password=pass --account=client1

# Step 3: Extract
/scripts/cpanel_extract --file=/tmp/cpanel_backup/client1.tar.gz

# Step 4: Import
/scripts/cpanel_import --user=client1

# Step 5: Cleanup
/scripts/cpanel_cleanup --user=client1
```

---

## Full Server Migration

### Via CWP Panel

1. Go to **Account Migration > cPanel Migration**
2. Enter server credentials
3. Select "Migrate All Accounts"
4. Set concurrency (number of simultaneous migrations)
5. Click "Start Migration"

### Via CLI (Batch)

```bash
# Prepare
/scripts/cpanel_prepare

# Fetch all accounts
/scripts/cpanel_fetch --source=192.168.1.100 --user=root --password=pass --all

# Process each account
for backup in /tmp/cpanel_backup/*.tar.gz; do
    username=$(basename ${backup} .tar.gz)
    /scripts/cpanel_extract --file=${backup}
    /scripts/cpanel_import --user=${username}
    /scripts/cpanel_cleanup --user=${username}
done
```

### Batch Migration Script

```bash
#!/bin/bash
# /scripts/migrate_all_cpanel

SOURCE_IP="192.168.1.100"
SSH_USER="root"
SSH_PASS="password"
LOG_FILE="/var/log/cpanel_migration.log"

echo "Starting migration from ${SOURCE_IP}" | tee -a ${LOG_FILE}

# Get list of accounts from cPanel
ssh ${SSH_USER}@${SOURCE_IP} "ls /backup/cpmove-*" | while read -r backup; do
    username=$(echo ${backup} | sed 's/.*cpmove-//' | sed 's/\.tar\.gz//')

    echo "Migrating: ${username}" | tee -a ${LOG_FILE}

    # Fetch
    /scripts/cpanel_fetch --source=${SOURCE_IP} --user=${SSH_USER} --password=${SSH_PASS} --account=${username} 2>&1 | tee -a ${LOG_FILE}

    # Extract and import
    /scripts/cpanel_extract --file=/tmp/cpanel_backup/${username}.tar.gz 2>&1 | tee -a ${LOG_FILE}
    /scripts/cpanel_import --user=${username} 2>&1 | tee -a ${LOG_FILE}
    /scripts/cpanel_cleanup --user=${username} 2>&1 | tee -a ${LOG_FILE}

    echo "Completed: ${username}" | tee -a ${LOG_FILE}
done

echo "Migration complete" | tee -a ${LOG_FILE}
```

---

## What Gets Migrated

### Automatically Migrated

| Component       | Status   | Notes                              |
|-----------------|----------|------------------------------------|
| Website files   | Full     | Including .htaccess                |
| MySQL databases | Full     | Users and permissions included     |
| Email accounts  | Full     | Passwords preserved                |
| Email forwarders| Full     |                                    |
| DNS zones       | Full     | All record types                   |
| Cron jobs       | Full     | User crontabs                      |
| FTP accounts    | Partial  | May need password reset            |
| SSL certificates| Partial  | May need reissuance                |
| Subdomains      | Full     |                                    |
| Parked domains  | Full     |                                    |
| Addon domains   | Full     |                                    |

### Requires Manual Attention

| Component         | Action Required                        |
|-------------------|----------------------------------------|
| PHP version       | Verify/adjust via PHP Switcher         |
| Custom php.ini    | Migrate to PHP-FPM pool config         |
| SSL certificates  | Reissue via AutoSSL if needed          |
| SSH keys          | Regenerate for users                   |
| Custom scripts    | Verify paths and dependencies          |
| .htaccess rules   | Test and adjust if using Nginx         |

---

## Post-Migration Verification

### Checklist

```bash
# 1. Verify user exists
/scripts/list_users

# 2. Check website
curl -I http://domain.com

# 3. Verify database
mysql -u root -p -e "SHOW DATABASES;"

# 4. Test email
swaks --to user@domain.com --server localhost

# 5. Check DNS
dig domain.com @localhost

# 6. Verify cron jobs
crontab -u username -l

# 7. Check file permissions
ls -la /home/username/public_html/
```

### Verification Script

```bash
#!/bin/bash
# /scripts/verify_migration

USERNAME=$1
DOMAIN=$(mysql -u root -p -N -e "SELECT domain FROM postfix.mailbox WHERE username LIKE '%${USERNAME}%' LIMIT 1;")

echo "=== Migration Verification: ${USERNAME} ==="

# Check user directory
echo "Files:"
ls -la /home/${USERNAME}/public_html/ | head -10

# Check database
echo "Databases:"
mysql -u root -p -e "SHOW DATABASES LIKE '%${USERNAME}%';"

# Check email
echo "Email accounts:"
mysql -u root -p postfix -e "SELECT username FROM mailbox WHERE domain='${DOMAIN}';"

# Check DNS
echo "DNS zone:"
rndc zonestatus ${DOMAIN}

# Check website
echo "Website response:"
curl -s -o /dev/null -w "%{http_code}" http://${DOMAIN}
```

---

## Common Issues

### Migration fails with SSH error

```bash
# Test SSH connection
ssh root@cpanel_server_ip "echo OK"

# Check SSH key authentication
ssh -i /root/.ssh/id_rsa root@cpanel_server_ip

# Verify SSH port
telnet cpanel_server_ip 22
```

### Database import fails

```bash
# Check MySQL credentials
cat /root/.my.cnf

# Check disk space
df -h /var/lib/mysql/

# Check MySQL error log
tail -50 /var/log/mariadb/mariadb.log

# Try manual import
gunzip -c /tmp/backup/user_mysql.sql.gz | mysql -u root -p
```

### Email passwords not working

```bash
# cPanel uses different password hashing
# CWP should handle conversion automatically

# If not, reset password
/scripts/change_password user@domain.com new_password
```

### PHP version mismatch

```bash
# Check current PHP version
php -v

# Switch to matching version via CWP Admin panel:
# PHP Settings > PHP Version Switcher > Select version > Click "Select"

# Or use PHP Selector per-user
/scripts/php_select username 8.1
```

### Disk space issues during migration

```bash
# Check available space
df -h

# Clean up after each account
/scripts/cpanel_cleanup --user=username

# Or process in batches
# Migrate 5 accounts at a time
```
