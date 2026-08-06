# Restoration Reference

## Overview

CWP supports full server restoration, individual user restoration, and partial restoration of specific components (databases, emails, DNS zones).

---

## Restore Methods

### Via CWP Admin Panel

Navigate to: **Backup > Restore Backup**

### Via CLI

There is no `/scripts/restore_user` on modern CWP (0.9.8.1244). Use the CWP Admin panel (**Backup > Restore Backup**) or restore manually via tar extraction (see Manual User Restore below).

---

## Full Server Restore

### Preparation

1. Install CWP on the new server
2. Ensure same CWP version as backup
3. Mount backup storage (local or remote)
4. Verify backup integrity

### Full Restore Process

```bash
# 1. Restore system configurations
tar -xzf /backup/system/etc_configs.tar.gz -C /

# 2. Restore DNS zones
tar -xzf /backup/system/dns_zones.tar.gz -C /

# 3. Restore cron jobs
tar -xzf /backup/system/cron_backup.tar.gz -C /

# 4. Restore each user (dual-path backup script detection)
for user_dir in /backup/daily/*/; do
    username=$(basename ${user_dir})
    if [ "${username}" != "system" ] && [ "${username}" != "logs" ] && [ "${username}" != "mysql" ]; then
        # Restore user files
        tar -xzf ${user_dir}/${username}.tar.gz -C /
        # Restore databases
        gunzip -c ${user_dir}/${username}_mysql.sql.gz | mysql -u root -p
        # Fix permissions via API
        /scripts/cwp_api account fix_perms ${username}
    fi
done

# 5. Rebuild configurations
/scripts/rebuild_httpd
/scripts/rebuild_dns
/scripts/rebuild_mail

# 6. Restart services
systemctl restart httpd nginx postfix dovecot named mysql
```

---

## Single User Restore

### Via CWP Panel

1. Go to **Backup > Restore Backup**
2. Select the backup file
3. Choose restore options:
   - Restore files
   - Restore databases
   - Restore email
   - Restore cron jobs
4. Click "Restore"

### Via CLI

There is no `/scripts/restore_user` on modern CWP. Use the manual restore steps below.

### Manual User Restore

```bash
# 1. Create user if not exists
/scripts/create_user username password email@example.com plan domain.com

# 2. Restore files (adjust path for daily/weekly/monthly or flat layout)
tar -xzf /backup/daily/username/username.tar.gz -C /

# 3. Restore database
gunzip -c /backup/daily/username/username_mysql.sql.gz | mysql -u root -p

# 4. Restore email accounts
tar -xzf /backup/daily/username/username_email.tar.gz -C /

# 5. Fix permissions via API
/scripts/cwp_api account fix_perms username

# 6. Rebuild user configs
/scripts/rebuild_httpd
/scripts/rebuild_dns
```

---

## Database Restore

### Restore All Databases

```bash
# From compressed backup
gunzip -c /backup/all_databases.sql.gz | mysql -u root -p

# From uncompressed backup
mysql -u root -p < /backup/all_databases.sql
```

### Restore Specific Database

```bash
# Create database if not exists
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS database_name;"

# Restore
gunzip -c /backup/database_name.sql.gz | mysql -u root -p database_name

# Or
mysql -u root -p database_name < /backup/database_name.sql
```

### Restore Specific Table

```bash
# Extract specific table from dump
gunzip -c /backup/database_name.sql.gz | sed -n '/-- Table structure for table `table_name`/,/Table structure/p' | mysql -u root -p database_name
```

### Point-in-Time Recovery (if binary logging enabled)

```bash
# Check binary logs
ls -la /var/lib/mysql/mysql-bin.*

# Restore up to specific time
mysqlbinolog --stop-datetime="2024-01-15 12:00:00" /var/lib/mysql/mysql-bin.000001 | mysql -u root -p

# Restore specific transactions
mysqlbinlog --start-position=1234 --stop-position=5678 /var/lib/mysql/mysql-bin.000001 | mysql -u root -p
```

---

## Email Restore

### Restore Email Accounts

```bash
# Restore mailbox data
tar -xzf /backup/username/username_email.tar.gz -C /

# Restore email database entries
mysql -u root -p postfix < /backup/username/email_accounts.sql
```

### Restore Specific Mailbox

```bash
# Copy mailbox files
cp -r /backup/username/mail/domain.com/user /var/vmail/domain.com/

# Fix permissions
chown -R vmail:vmail /var/vmail/domain.com/user
chmod -R 700 /var/vmail/domain.com/user
```

### Restore Email Forwarders

```bash
# Import forwarders to database
mysql -u root -p postfix -e "
INSERT INTO alias (address, goto, domain, active)
VALUES ('user@domain.com', 'forward@other.com', 'domain.com', '1');
"
```

---

## DNS Zone Restore

### Restore Single Zone

```bash
# Copy zone file
cp /backup/dns/example.com.db /var/named/

# Add zone to named.conf if not exists
rndc reload example.com
```

### Restore All Zones

```bash
# Extract all zone files
tar -xzf /backup/system/dns_zones.tar.gz -C /

# Rebuild DNS
/scripts/rebuild_dns

# Restart BIND
systemctl restart named
```

### Restore Zone from Backup

```bash
# Find zone in backup
find /backup -name "example.com.db" -type f

# Copy to BIND directory
cp /backup/path/example.com.db /var/named/

# Verify zone
named-checkzone example.com /var/named/example.com.db

# Reload
rndc reload example.com
```

---

## Configuration Restore

### Restore Apache Config

```bash
# Restore from backup
tar -xzf /backup/system/apache_configs.tar.gz -C /

# Verify configuration
httpd -t

# Restart Apache
systemctl restart httpd
```

### Restore Postfix Config

```bash
# Restore main.cf and master.cf
cp /backup/system/postfix/main.cf /etc/postfix/
cp /backup/system/postfix/master.cf /etc/postfix/

# Verify
postfix check

# Restart
systemctl restart postfix
```

### Restore MySQL Config

```bash
# Restore my.cnf
cp /backup/system/my.cnf /etc/my.cnf

# Restart MySQL
systemctl restart mariadb
```

### Restore Cron Jobs

```bash
# Restore root crontab
crontab /backup/system/root_crontab.txt

# Restore user crontabs
for user_file in /backup/system/crontabs/*; do
    username=$(basename ${user_file})
    crontab -u ${username} ${user_file}
done
```

---

## Backup Verification

### Before Restore

```bash
# Verify backup integrity
tar -tzf /backup/daily/username/username.tar.gz > /dev/null && echo "OK" || echo "CORRUPT"

# Check SQL dump
gunzip -c /backup/daily/username/username_mysql.sql.gz | head -20

# List backup contents
tar -tzf /backup/daily/username/username.tar.gz | head -50
```

### After Restore

```bash
# Verify files restored
ls -la /home/username/

# Check database
mysql -u root -p -e "SHOW DATABASES;"

# Test website
curl -I https://domain.com

# Test email
swaks --to user@domain.com --server localhost
```

---

## Restore Scenarios

### Scenario: Single Website Down

```bash
# Restore only web files
tar -xzf /backup/daily/username/username.tar.gz -C / home/username/public_html/

# Restore database if needed
gunzip -c /backup/daily/username/username_mysql.sql.gz | mysql -u root -p database_name

# Fix permissions via API
/scripts/cwp_api account fix_perms username
```

### Scenario: Email Migration

```bash
# Restore email accounts (extract from backup)
tar -xzf /backup/daily/username/username_email.tar.gz -C /

# Verify email accounts
mysql -u root -p postfix -e "SELECT * FROM mailbox WHERE domain='domain.com';"
```

### Scenario: Full Server Migration

```bash
# 1. Prepare new server with CWP
# 2. Transfer backup files
rsync -avz /backup/ newserver:/backup/

# 3. Run full restore (manual tar extraction, no restore_user script on modern CWP)
for user_dir in /backup/daily/*/; do
    username=$(basename ${user_dir})
    if [ "${username}" != "system" ] && [ "${username}" != "logs" ] && [ "${username}" != "mysql" ]; then
        tar -xzf ${user_dir}/${username}.tar.gz -C /
        gunzip -c ${user_dir}/${username}_mysql.sql.gz | mysql -u root -p
        /scripts/cwp_api account fix_perms ${username}
    fi
done

# 4. Rebuild configurations and restart services
/scripts/rebuild_httpd
/scripts/rebuild_dns
/scripts/rebuild_mail
systemctl restart httpd nginx postfix dovecot named mysql

# 5. Update DNS to point to new server
```

---

## Post-Restore Checklist

- [ ] All user accounts restored
- [ ] All databases restored and accessible
- [ ] Email accounts working
- [ ] DNS zones configured
- [ ] SSL certificates installed
- [ ] Cron jobs restored
- [ ] Firewall rules applied
- [ ] Services running (Apache, Nginx, MySQL, Postfix, Dovecot)
- [ ] Websites accessible
- [ ] Email sending/receiving working
- [ ] Backups configured on new server

---

## Troubleshooting

### Restore fails with permission errors

```bash
# Check file ownership
ls -la /home/username/

# Fix permissions via API
/scripts/cwp_api account fix_perms username

# Check SELinux contexts (if enabled)
restorecon -Rv /home/username/
```

### Database restore fails

```bash
# Check MySQL is running
systemctl status mariadb

# Check credentials
cat /root/.my.cnf

# Check disk space
df -h /var/lib/mysql/

# Check error log
tail -50 /var/log/mariadb/mariadb.log
```

### Email not working after restore

```bash
# Check Postfix configuration
postfix check

# Check Dovecot
doveconf -n

# Verify email accounts in database
mysql -u root -p postfix -e "SELECT * FROM mailbox;"

# Check mail log
tail -50 /var/log/maillog
```

### Website shows wrong content

```bash
# Check document root
grep DocumentRoot /usr/local/apache/conf/users/username.conf

# Check DNS resolution
dig domain.com

# Check if files are correct
ls -la /home/username/public_html/
```
