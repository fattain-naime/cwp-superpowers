# Migration from Other Panels Reference

## Overview

CWP supports migration from various hosting panels including Webuzo, Plesk, DirectAdmin, and others. Each requires a slightly different approach.

---

## Webuzo to CWP

### Webuzo Overview

Webuzo is a single-user panel by Softaculous. Migration involves manual backup and restore.

### Migration Steps

#### 1. Backup Webuzo Accounts

```bash
# On Webuzo server
# Backup user files
tar -czf /tmp/user_backup.tar.gz /home/username/

# Backup databases
mysqldump -u root -p --all-databases > /tmp/all_databases.sql

# Backup email (if using Webuzo email)
tar -czf /tmp/email_backup.tar.gz /var/mail/
```

#### 2. Transfer to CWP Server

```bash
# Transfer files
scp /tmp/user_backup.tar.gz root@cwp_server:/backup/
scp /tmp/all_databases.sql root@cwp_server:/backup/
scp /tmp/email_backup.tar.gz root@cwp_server:/backup/
```

#### 3. Create User on CWP

```bash
/scripts/cwp_api account add USERNAME DOMAIN PASSWORD EMAIL IP PACKAGE
```

#### 4. Restore Data

```bash
# Restore files
tar -xzf /backup/user_backup.tar.gz -C /

# Restore databases
mysql -u root -p < /backup/all_databases.sql

# Restore email (if applicable)
tar -xzf /backup/email_backup.tar.gz -C /
```

#### 5. Configure Services

```bash
# Rebuild web server config
/scripts/cwp_api webservers rebuild_all

# Rebuild DNS
/scripts/cwp_api account rebuild_etc_named_conf

# Fix permissions
/scripts/cwp_api account fix_perms USERNAME
```

### Webuzo-Specific Considerations

| Component    | Webuzo Path                | CWP Path                    |
|--------------|----------------------------|-----------------------------|
| Web files    | `/home/user/public_html/`  | `/home/user/public_html/`   |
| Databases    | MySQL (same)               | MySQL/MariaDB (same)        |
| Email        | `/var/mail/` or Dovecot    | `/var/vmail/` (Dovecot)     |
| DNS          | BIND (same)                | BIND (same)                 |
| PHP          | `/usr/local/webuzo/php/`   | `/usr/local/php/`           |

---

## Plesk to CWP

### Plesk Overview

Plesk uses a different directory structure and database management approach.

### Migration Steps

#### 1. Backup Plesk Accounts

```bash
# On Plesk server
# Use Plesk backup utility
plesk bin pleskbackup all /tmp/plesk_backup_full.xml

# Or backup individual domains
plesk bin pleskbackup domains -domain-name example.com /tmp/example.com.xml
```

#### 2. Extract Plesk Backup

```bash
# Plesk backups are XML-based archives
# Extract to temporary directory
mkdir -p /tmp/plesk_extract
tar -xzf /tmp/plesk_backup_full.tar.gz -C /tmp/plesk_extract/
```

#### 3. Migrate Web Files

```bash
# Plesk stores files differently
# Source: /var/www/vhosts/domain.com/httpdocs/
# Target: /home/username/public_html/

# Copy files
mkdir -p /home/username/public_html/
rsync -avz /var/www/vhosts/domain.com/httpdocs/ /home/username/public_html/
```

#### 4. Migrate Databases

```bash
# Export from Plesk
plesk bin dbdump -database-name dbname > /tmp/dbname.sql

# Import to CWP
mysql -u root -p < /tmp/dbname.sql
```

#### 5. Migrate Email

```bash
# Plesk stores email in /var/qmail/ or /var/spool/postfix/
# CWP uses /var/vmail/

# Export email accounts from Plesk database
# Import to CWP postfix database
```

### Plesk Directory Mapping

| Plesk Path                              | CWP Path                       |
|-----------------------------------------|--------------------------------|
| `/var/www/vhosts/domain/httpdocs/`      | `/home/user/public_html/`      |
| `/var/www/vhosts/domain/conf/`          | `/usr/local/apache/conf/users/`|
| `/var/qmail/mailnames/domain/user/`     | `/var/vmail/domain/user/`      |
| `/var/named/run-root/var/domain.db`     | `/var/named/domain.db`         |

### Plesk Email Migration

```bash
# Export from Plesk
plesk bin mail --export-domain domain.com > /tmp/email_export.xml

# Parse and import to CWP postfix database
# This typically requires a custom script

# Or use imapsync for mailboxes
imapsync --host1 plesk_server --user1 user@domain.com --password1 pass1 \
         --host2 cwp_server --user2 user@domain.com --password2 pass2
```

---

## DirectAdmin to CWP

### DirectAdmin Overview

DirectAdmin uses a similar structure to cPanel but with different paths.

### Migration Steps

#### 1. Backup DirectAdmin Accounts

```bash
# On DirectAdmin server
# Backup all users
for user in $(ls /usr/local/directadmin/data/users/); do
    /usr/local/directadmin/dataskq user_backup ${user}
done

# Or use DA backup feature
# Admin Backup/Transfer > Create Backup
```

#### 2. Transfer Backups

```bash
# DA backups location
# /home/admin/admin_backups/

# Transfer to CWP
scp /home/admin/admin_backups/*.tar.gz root@cwp_server:/backup/
```

#### 3. Import to CWP

```bash
# DA backups are similar to cPanel format
# Use CWP's import script
/scripts/cwp_import /backup/user.tar.gz
```

#### 4. Manual Migration

```bash
# Create user on CWP
/scripts/cwp_api account add USERNAME DOMAIN PASSWORD EMAIL IP PACKAGE

# Extract DA backup
tar -xzf /backup/user.tar.gz -C /tmp/da_restore/

# Copy web files
cp -r /tmp/da_restore/backup/user/domains/domain.com/public_html/* /home/username/public_html/

# Restore database
mysql -u root -p < /tmp/da_restore/backup/user/mysql/dbname.sql

    # Rebuild configs
    /scripts/cwp_api webservers rebuild_all
    /scripts/cwp_api account rebuild_etc_named_conf
```

### DirectAdmin Directory Mapping

| DirectAdmin Path                              | CWP Path                       |
|-----------------------------------------------|--------------------------------|
| `/home/user/domains/domain.com/public_html/`  | `/home/user/public_html/`      |
| `/home/user/domains/domain.com/private_html/` | N/A (use .htaccess)            |
| `/home/user/imap/domain.com/user/`            | `/var/vmail/domain.com/user/`  |
| `/var/named/domain.com.db`                     | `/var/named/domain.com.db`     |

---

## ISPConfig to CWP

### ISPConfig Overview

ISPConfig uses a different approach with separate server configurations.

### Migration Steps

#### 1. Backup ISPConfig

```bash
# Backup websites
tar -czf /tmp/websites.tar.gz /var/www/

# Backup databases
mysqldump -u root -p --all-databases > /tmp/all_databases.sql

# Backup email
tar -czf /tmp/email.tar.gz /var/vmail/

# Backup DNS
tar -czf /tmp/dns.tar.gz /etc/bind/
```

#### 2. Transfer and Restore

```bash
# Transfer to CWP server
scp /tmp/*.tar.gz root@cwp_server:/backup/

# Create users on CWP
/scripts/cwp_api account add USERNAME DOMAIN PASSWORD EMAIL IP PACKAGE

# Restore files
tar -xzf /backup/websites.tar.gz -C /

# Restore databases
mysql -u root -p < /backup/all_databases.sql

# Restore email
tar -xzf /backup/email.tar.gz -C /
```

### ISPConfig Directory Mapping

| ISPConfig Path                | CWP Path                       |
|-------------------------------|--------------------------------|
| `/var/www/clients/client/web/`| `/home/user/public_html/`      |
| `/var/vmail/domain/user/`     | `/var/vmail/domain/user/`      |
| `/etc/bind/`                  | `/var/named/`                  |

---

## imapsync for Email Migration

### Install imapsync

```bash
# Install dependencies
yum install perl-App-cpanminus
cpanm Mail::IMAPClient
cpanm JSON

# Install imapsync
cd /usr/local/src
git clone https://github.com/imapsync/imapsync.git
cd imapsync
make install
```

### Basic imapsync Usage

```bash
# Single account migration
imapsync \
    --host1 source_server --user1 user@domain.com --password1 pass1 \
    --host2 cwp_server --user2 user@domain.com --password2 pass2

# With SSL
imapsync \
    --host1 source_server --user1 user@domain.com --password1 pass1 --ssl1 \
    --host2 cwp_server --user2 user@domain.com --password2 pass2 --ssl2

# Batch migration
for user in user1 user2 user3; do
    imapsync \
        --host1 source_server --user1 ${user}@domain.com --password1 pass1 \
        --host2 cwp_server --user2 ${user}@domain.com --password2 pass2
done
```

### imapsync Batch Script

```bash
#!/bin/bash
# /scripts/migrate_email_imapsync

SOURCE="source_server"
DEST="cwp_server"

# Read user list from file
while IFS=: read -r user pass; do
    echo "Migrating: ${user}"
    imapsync \
        --host1 ${SOURCE} --user1 ${user} --password1 ${pass} \
        --host2 ${DEST} --user2 ${user} --password2 ${pass} \
        --syncinternaldates \
        --nofoldersizes
done < /tmp/email_users.txt
```

---

## General Migration Best Practices

### Pre-Migration

1. Inventory all accounts and services
2. Verify disk space on destination
3. Test migration with one account first
4. Schedule maintenance window
5. Notify users of potential downtime

### During Migration

1. Monitor migration logs
2. Verify each account after migration
3. Keep source server running until verification complete
4. Document any issues encountered

### Post-Migration

1. Update DNS records
2. Verify all websites working
3. Test email delivery
4. Confirm database connectivity
5. Monitor for 24-48 hours
6. Decommission source server

### Common Commands

```bash
# List all users
/scripts/list_users

# Verify user data
ls -la /home/username/
mysql -u root -p -e "SHOW DATABASES;"

# Check services
systemctl status httpd nginx mysql postfix dovecot named

# Rebuild all configs
/scripts/cwp_api webservers rebuild_all
/scripts/cwp_api account rebuild_etc_named_conf
```
