---
name: cwp-migration
description: This skill should be used when the user asks to "migrate from cPanel", "migrate to CWP", "transfer accounts", "cPanel to CWP migration", "CWP to CWP migration", "migrate single account", "migrate from Webuzo", "import cPanel backup", "export cPanel data", "set up migration scripts", or needs to migrate websites, accounts, or data between hosting panels.
version: 1.0.0
---

# CWP Migration Management

Migrate accounts and data from cPanel, other CWP servers, or alternative control panels to CWP. Handle full server migrations, single account transfers, and data import procedures.

## Migration Paths

| Source | Destination | Method |
|---|---|---|
| cPanel (full server) | CWP | Automated scripts |
| cPanel (single account) | CWP | Admin panel import |
| CWP | CWP | Built-in migration tool |
| Webuzo | CWP | Manual process |
| Other panels | CWP | Manual export/import |

## cPanel to CWP (Full Server Migration)

Full server migration requires running a series of scripts in order on a fresh CWP installation.

### Prerequisites

- Fresh CWP installation on target server
- cPanel data exported from source server
- Sufficient disk space for migration
- Root SSH access to both servers

### Migration Steps

```bash
# Step 1: Export cPanel data from source server
# Copy the migration scripts to the cPanel server first
sh 1-cpanel-data-export.sh

# Step 2: Uninstall cPanel from source server
# Only if reusing the same server
sh 2-cpanel-uninstall.sh

# Step 3: Install CWP on target server
cd /usr/local/src
wget http://centos-webpanel.com/cwp-el8-latest && sh cwp-el8-latest

# Step 4: Import data into CWP
sh 4-import-into-cwp.sh

# Step 5: Generate mail SNI certificates
sh 5-mail-sni.sh
```

### Migration Scripts

| Script | Purpose |
|---|---|
| `1-cpanel-data-export.sh` | Export all cPanel accounts, databases, emails |
| `2-cpanel-uninstall.sh` | Remove cPanel (same-server migration) |
| `4-import-into-cwp.sh` | Import all data into CWP |
| `5-mail-sni.sh` | Generate mail SSL certificates |

## cPanel to CWP (Single Account)

### Via CWP Admin Panel

1. Navigate to User Account -> cPanel Migration
2. Enter cPanel server details:
   - Server IP or hostname
   - cPanel username
   - cPanel password
3. Click Migrate

### What Gets Migrated

| Data | Status |
|---|---|
| Website files | Migrated |
| Databases | Migrated |
| Email accounts | Migrated |
| DNS zones | Migrated |
| Cron jobs | Migrated |
| FTP accounts | Migrated |
| SSL certificates | May need reissuing |

## CWP to CWP Migration

### Via CWP Admin Panel

1. Navigate to User Accounts -> CWP->CWP Migration
2. Enter source CWP server details:
   - Server IP
   - Root SSH credentials
3. Select accounts to migrate
4. Click Migrate

### Manual CWP to CWP

```bash
# On source server: create backup (script name varies by CWP version)
if [ -f /scripts/user_backup ]; then
    sh /scripts/user_backup USERNAME
elif [ -f /scripts/backup_user ]; then
    sh /scripts/backup_user USERNAME
fi

# Find backup file (check both directory structures)
BACKUP_FILE=""
if [ -f "/backup/daily/USERNAME/backup.tar.gz" ]; then
    BACKUP_FILE="/backup/daily/USERNAME/backup.tar.gz"
elif [ -f "/backup/USERNAME/backup.tar.gz" ]; then
    BACKUP_FILE="/backup/USERNAME/backup.tar.gz"
else
    BACKUP_FILE=$(find /backup -name "*USERNAME*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
fi

# Transfer backup to destination
scp "$BACKUP_FILE" root@DEST_IP:/backup/

# On destination: restore
# CWP Admin -> Backup -> Restore
```

## Webuzo to CWP

Webuzo migration requires manual process:

```bash
# Step 1: Export from Webuzo
# Download website files and database dumps

# Step 2: Create account on CWP
# Via CWP Admin or API

# Step 3: Upload website files
rsync -avz /source/public_html/ /home/USER/public_html/

# Step 4: Create database on CWP
# Via phpMyAdmin or MySQL CLI

# Step 5: Import database
mysql -u username -p dbname < database_dump.sql

# Step 6: Fix permissions
/scripts/cwp_api account fix_perms USERNAME

# Step 7: Configure DNS
# Update DNS records to point to new server
```

## Migration Checklist

### Pre-Migration

- [ ] Back up all data on source server
- [ ] Verify disk space on destination
- [ ] Document all accounts and configurations
- [ ] Note DNS TTL values (lower them before migration)
- [ ] Test migration on staging if possible
- [ ] Notify users of migration window

### During Migration

- [ ] Run migration scripts or transfer data
- [ ] Verify each account transferred completely
- [ ] Check database integrity
- [ ] Verify email accounts and forwarders
- [ ] Test website functionality

### Post-Migration

- [ ] Update DNS records to new server IP
- [ ] Verify SSL certificates (reissue if needed)
- [ ] Test email sending/receiving
- [ ] Verify cron jobs are running
- [ ] Check file permissions
- [ ] Monitor error logs
- [ ] Confirm all services are running

## DNS During Migration

### Lower TTL Before Migration

```bash
# Reduce TTL to 300 (5 minutes) 24-48 hours before migration
# This ensures faster DNS propagation
```

### Update DNS After Migration

```bash
# Update A records to new server IP
# Update MX records if mail server changed
# Update nameservers if changing DNS provider
```

## Email Migration Considerations

- Email stored in `/var/vmail/DOMAIN/USER/`
- Verify DKIM, SPF, and DMARC records after migration
- Test email delivery in both directions
- Check spam filtering is working

## Database Migration

### Large Database Import

```bash
# Increase MariaDB limits for large imports
mysql -e "SET GLOBAL max_allowed_packet=256*1024*1024;"
mysql -e "SET GLOBAL wait_timeout=86400;"

# Import
mysql -u root -p dbname < large_dump.sql
```

### Verify Database Integrity

```bash
# Check tables
mysqlcheck -u root -p dbname

# Repair if needed
mysqlcheck -u root -p --repair dbname
```

## Troubleshooting

| Issue | Solution |
|---|---|
| Migration script fails | Check SSH connectivity and credentials |
| Databases not importing | Increase `max_allowed_packet` |
| Email not working after migration | Verify Postfix/Dovecot running, check DNS |
| Websites showing errors | Check PHP version compatibility |
| SSL certificates invalid | Reissue via AutoSSL or ACME |
| DNS not propagating | Wait for TTL, verify records |
| Permission denied errors | Run `/scripts/cwp_api account fix_perms USERNAME` |
| Disk space insufficient | Clean up before migration, expand storage |

### Diagnostic Commands

```bash
# Check disk space
df -h

# Verify user accounts
/scripts/list_users

# Check databases
/scripts/checkdb

# Test website
curl -I http://domain.com

# Check DNS
dig domain.com @localhost

# Verify email
telnet localhost 25

# Check services
systemctl status httpd nginx mariadb postfix dovecot
```

## Additional Resources

- `references/cpanel-to-cwp.md` -- Detailed cPanel to CWP migration guide
- `references/cwp-to-cwp.md` -- CWP to CWP migration procedures
- `references/other-panels.md` -- Migration from Webuzo and other panels
