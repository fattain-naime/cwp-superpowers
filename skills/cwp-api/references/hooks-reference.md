# Action Hooks Reference

## Overview

CWP supports action hooks that trigger custom scripts at specific points during operations. These hooks allow automation and integration with external systems.

---

## Hook System Architecture

```
CWP Operation (e.g., add_user)
  |
  +-- Pre-hook (before operation)
  |
  +-- Execute operation
  |
  +-- Post-hook (after operation)
  |
  +-- Return result
```

---

## Hook Directories

```
/usr/local/cwp/hooks/
  pre/                           # Pre-execution hooks
    add_user.sh
    delete_user.sh
    add_domain.sh
    ...
  post/                          # Post-execution hooks
    add_user.sh
    delete_user.sh
    add_domain.sh
    ...
  error/                         # Error hooks (on failure)
    add_user.sh
    delete_user.sh
    ...
```

---

## Account Hooks

### add_user

Triggered when a new user account is created.

**Hook File:** `/usr/local/cwp/hooks/post/add_user.sh`

**Environment Variables:**
```bash
$HOOK_USERNAME    # New username
$HOOK_DOMAIN      # Primary domain
$HOOK_EMAIL       # Contact email
$HOOK_PACKAGE     # Hosting plan
$HOOK_PASSWORD    # Password (post-hook only)
$HOOK_IP          # Assigned IP address
```

**Example Hook:**
```bash
#!/bin/bash
# /usr/local/cwp/hooks/post/add_user.sh

# Log new user creation
echo "$(date): New user created: ${HOOK_USERNAME} (${HOOK_DOMAIN})" >> /var/log/cwp_hooks.log

# Send notification email
echo "New user ${HOOK_USERNAME} created on ${HOOK_DOMAIN}" | \
    mail -s "New Account Created" admin@example.com

# Custom provisioning
/usr/local/bin/custom_provision.sh ${HOOK_USERNAME} ${HOOK_DOMAIN}
```

### delete_user

Triggered when a user account is deleted.

**Hook File:** `/usr/local/cwp/hooks/pre/delete_user.sh`

**Environment Variables:**
```bash
$HOOK_USERNAME    # Username being deleted
$HOOK_DOMAIN      # Primary domain
```

**Example Hook:**
```bash
#!/bin/bash
# /usr/local/cwp/hooks/pre/delete_user.sh

# Backup before deletion (script name varies by CWP version)
if [ -f /scripts/user_backup ]; then
    /scripts/user_backup ${HOOK_USERNAME}
elif [ -f /scripts/backup_user ]; then
    /scripts/backup_user ${HOOK_USERNAME}
fi

# Log deletion
echo "$(date): User deleted: ${HOOK_USERNAME}" >> /var/log/cwp_hooks.log
```

### suspend_user

Triggered when a user account is suspended.

**Hook File:** `/usr/local/cwp/hooks/post/suspend_user.sh`

**Environment Variables:**
```bash
$HOOK_USERNAME    # Suspended username
$HOOK_REASON      # Suspension reason
```

### unsuspend_user

Triggered when a user account is unsuspended.

**Hook File:** `/usr/local/cwp/hooks/post/unsuspend_user.sh`

### modify_user

Triggered when user account properties are modified.

**Hook File:** `/usr/local/cwp/hooks/post/modify_user.sh`

---

## Domain Hooks

### add_domain

Triggered when a domain is added to an account.

**Hook File:** `/usr/local/cwp/hooks/post/add_domain.sh`

**Environment Variables:**
```bash
$HOOK_USERNAME    # Account username
$HOOK_DOMAIN      # Domain name
$HOOK_IP          # Server IP
$HOOK_DOCROOT     # Document root path
```

**Example Hook:**
```bash
#!/bin/bash
# /usr/local/cwp/hooks/post/add_domain.sh

# Install SSL automatically
/scripts/install_acme ${HOOK_DOMAIN}

# Log domain addition
echo "$(date): Domain added: ${HOOK_DOMAIN} for user ${HOOK_USERNAME}" >> /var/log/cwp_hooks.log
```

### delete_domain

Triggered when a domain is removed.

**Hook File:** `/usr/local/cwp/hooks/pre/delete_domain.sh`

---

## DNS Hooks

### add_dns_zone

Triggered when a DNS zone is created.

**Hook File:** `/usr/local/cwp/hooks/post/add_dns_zone.sh`

**Environment Variables:**
```bash
$HOOK_DOMAIN      # Domain name
$HOOK_IP          # IP address
```

### add_dns_record

Triggered when a DNS record is added.

**Hook File:** `/usr/local/cwp/hooks/post/add_dns_record.sh`

**Environment Variables:**
```bash
$HOOK_DOMAIN      # Domain name
$HOOK_TYPE        # Record type (A, CNAME, MX, etc.)
$HOOK_NAME        # Record name
$HOOK_VALUE       # Record value
$HOOK_TTL         # TTL value
$HOOK_PRIORITY    # MX priority (if applicable)
```

**Example Hook (DNS Cluster Sync):**
```bash
#!/bin/bash
# /usr/local/cwp/hooks/post/add_dns_record.sh

# Sync DNS to slave servers
for slave in 192.168.1.11 192.168.1.12; do
    ssh root@${slave} "rndc reload ${HOOK_DOMAIN}" &
done
wait
```

---

## Email Hooks

### add_mailbox

Triggered when an email mailbox is created.

**Hook File:** `/usr/local/cwp/hooks/post/add_mailbox.sh`

**Environment Variables:**
```bash
$HOOK_EMAIL       # Full email address
$HOOK_DOMAIN      # Domain name
$HOOK_USERNAME    # Email username
$HOOK_QUOTA       # Mailbox quota
```

### delete_mailbox

Triggered when an email mailbox is deleted.

### add_mailforward

Triggered when an email forwarder is created.

---

## Database Hooks

### add_database

Triggered when a database is created.

**Hook File:** `/usr/local/cwp/hooks/post/add_database.sh`

**Environment Variables:**
```bash
$HOOK_USERNAME    # Account username
$HOOK_DATABASE    # Database name
```

### add_db_user

Triggered when a database user is created.

---

## SSL Hooks

### install_ssl

Triggered when an SSL certificate is installed.

**Hook File:** `/usr/local/cwp/hooks/post/install_ssl.sh`

**Environment Variables:**
```bash
$HOOK_DOMAIN      # Domain name
$HOOK_SSL_TYPE    # Type (letsencrypt, custom, self-signed)
```

### renew_ssl

Triggered when an SSL certificate is renewed.

---

## Backup Hooks

### backup_start

Triggered at the start of a backup operation.

**Hook File:** `/usr/local/cwp/hooks/pre/backup_start.sh`

### backup_complete

Triggered when a backup completes.

**Hook File:** `/usr/local/cwp/hooks/post/backup_complete.sh`

**Environment Variables:**
```bash
$HOOK_USERNAME    # Backed up user
$HOOK_BACKUP_FILE # Backup file path
$HOOK_STATUS      # Success or failure
```

### restore_start

Triggered before a restore operation.

### restore_complete

Triggered after a restore completes.

---

## System Hooks

### service_restart

Triggered when a service is restarted.

**Environment Variables:**
```bash
$HOOK_SERVICE     # Service name (httpd, nginx, mysql, etc.)
```

### cwp_update

Triggered when CWP is updated.

---

## Creating Custom Hooks

### Hook File Template

```bash
#!/bin/bash
# /usr/local/cwp/hooks/post/custom_hook.sh

# Log start
echo "$(date): Hook triggered for ${HOOK_USERNAME}" >> /var/log/cwp_hooks.log

# Your custom logic here
/usr/local/bin/custom_script.sh ${HOOK_USERNAME}

# Check result
if [ $? -eq 0 ]; then
    echo "$(date): Hook completed successfully" >> /var/log/cwp_hooks.log
else
    echo "$(date): Hook failed" >> /var/log/cwp_hooks.log
fi
```

### Make Hook Executable

```bash
chmod +x /usr/local/cwp/hooks/post/custom_hook.sh
```

### Testing Hooks

```bash
# Test hook manually
export HOOK_USERNAME="testuser"
export HOOK_DOMAIN="test.com"
/usr/local/cwp/hooks/post/add_user.sh
```

---

## External Integration Hooks

### Webhook Notifications

```bash
#!/bin/bash
# /usr/local/cwp/hooks/post/add_user.sh

# Send webhook to external system
curl -X POST "https://external-system.com/webhook" \
    -H "Content-Type: application/json" \
    -d "{
        \"event\": \"user_created\",
        \"username\": \"${HOOK_USERNAME}\",
        \"domain\": \"${HOOK_DOMAIN}\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"
    }"
```

### Slack Notification

```bash
#!/bin/bash
# /usr/local/cwp/hooks/post/add_user.sh

SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

curl -X POST "${SLACK_WEBHOOK}" \
    -H "Content-Type: application/json" \
    -d "{
        \"text\": \"New CWP account created: ${HOOK_USERNAME} (${HOOK_DOMAIN})\"
    }"
```

### Auto-SSL Installation

```bash
#!/bin/bash
# /usr/local/cwp/hooks/post/add_domain.sh

# Wait for DNS propagation
sleep 30

# Install Let's Encrypt SSL
/scripts/install_acme ${HOOK_DOMAIN}

if [ $? -eq 0 ]; then
    echo "$(date): SSL installed for ${HOOK_DOMAIN}" >> /var/log/cwp_hooks.log
else
    echo "$(date): SSL installation failed for ${HOOK_DOMAIN}" >> /var/log/cwp_hooks.log
fi
```

### Database Backup Before Deletion

```bash
#!/bin/bash
# /usr/local/cwp/hooks/pre/delete_user.sh

# Backup databases before user deletion
for db in $(mysql -u root -p -N -e "SHOW DATABASES LIKE '${HOOK_USERNAME}_%'"); do
    mysqldump -u root -p ${db} | gzip > /backup/pre_delete/${db}_$(date +%Y%m%d).sql.gz
done
```

---

## Hook Logging

### Standard Logging

```bash
#!/bin/bash
LOG_FILE="/var/log/cwp_hooks.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2" >> ${LOG_FILE}
}

log "INFO" "Hook triggered: ${HOOK_ACTION} for ${HOOK_USERNAME}"
```

### Log Rotation

**Path:** `/etc/logrotate.d/cwp_hooks`

```
/var/log/cwp_hooks.log {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
```

---

## Troubleshooting Hooks

### Hook Not Executing

```bash
# Check file permissions
ls -la /usr/local/cwp/hooks/post/

# Ensure executable
chmod +x /usr/local/cwp/hooks/post/*.sh

# Check shebang line
head -1 /usr/local/cwp/hooks/post/add_user.sh
# Should be: #!/bin/bash
```

### Hook Errors

```bash
# Check hook logs
tail -50 /var/log/cwp_hooks.log

# Test hook manually
bash -x /usr/local/cwp/hooks/post/add_user.sh

# Check system logs
tail -50 /var/log/messages
```

### Environment Variables Not Set

```bash
# Verify CWP passes variables
# Add debug to hook:
echo "Username: ${HOOK_USERNAME}" >> /tmp/hook_debug.log
echo "Domain: ${HOOK_DOMAIN}" >> /tmp/hook_debug.log
```
