# CWP to CWP Migration Reference

## Overview

CWP provides built-in migration tools for transferring accounts between CWP servers, supporting both the CWP Migration Module and API-based transfers.

---

## Migration Methods

### Method 1: CWP Migration Module (Recommended)

**Admin Panel > Account Migration > CWP Migration**

### Method 2: API-Based Transfer

Using CWP API for automated/scripted migrations.

### Method 3: Manual Backup/Restore

Using CWP backup and restore scripts.

---

## CWP Migration Module

### Architecture

```
Source CWP Server (Remote)
  |
  +-- SSH/API Connection
  |
Destination CWP Server (Local)
```

### Setup on Source Server

1. Enable API access:
   **Admin Panel > CWP Settings > API Manager**
2. Generate API key
3. Ensure SSH access is enabled
4. Whitelist destination server IP in CSF

### Setup on Destination Server

1. Go to **Account Migration > CWP Migration**
2. Enter source server details:
   - Server IP
   - API Key
   - SSH port (default 22)
3. Click "Connect"
4. Select accounts to migrate
5. Click "Migrate"

---

## Step-by-Step Migration

### Preparation

```bash
# On source server - verify accounts
/scripts/list_users

# Check disk space on destination
df -h /home

# Ensure services are running on destination
systemctl status httpd nginx mysql postfix dovecot named
```

### Via CWP Panel

1. **Account Migration > CWP Migration**
2. Enter source server credentials
3. Select accounts (individually or all)
4. Configure options:
   - Migrate databases
   - Migrate email
   - Migrate DNS
   - Migrate cron jobs
5. Click "Start Migration"
6. Monitor progress in migration log

### Via CLI

```bash
# Single account migration
/scripts/cwp_transfer <username> <source_ip> <source_port>

# Full server migration
/scripts/cwp_migrate <source_ip> <source_api_key>
```

---

## API-Based Transfer

### Using CWP API

```bash
# Get account list from source
curl -X GET "https://source_server:2304/api/?action=list_users&apikey=SOURCE_API_KEY"

# Backup account on source
curl -X POST "https://source_server:2304/api/?action=backup_user&username=user1&apikey=SOURCE_API_KEY"

# Download backup to destination (check both directory structures)
BACKUP_FILE=""
if [ -f "/backup/daily/user1/user1.tar.gz" ]; then
    BACKUP_FILE="/backup/daily/user1/user1.tar.gz"
elif [ -f "/backup/user1/user1.tar.gz" ]; then
    BACKUP_FILE="/backup/user1/user1.tar.gz"
else
    BACKUP_FILE=$(find /backup -name "*user1*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
fi
scp root@source_server:"$BACKUP_FILE" /backup/

# Restore on destination via CWP Admin panel:
# Admin Panel > Backup > Restore
# Or extract manually:
# mkdir -p /home/user1 && tar -xzf /backup/user1.tar.gz -C /
```

### Automated API Migration Script

```bash
#!/bin/bash
# /scripts/api_migrate

SOURCE_IP="192.168.1.100"
SOURCE_API_KEY="your_source_api_key"
DEST_API_KEY="your_dest_api_key"

# Get user list from source
USERS=$(curl -s -k "https://${SOURCE_IP}:2304/api/?action=list_users&apikey=${SOURCE_API_KEY}" | jq -r '.users[]')

for user in ${USERS}; do
    echo "Migrating: ${user}"

    # Backup on source
    curl -s -k -X POST "https://${SOURCE_IP}:2304/api/?action=backup_user&username=${user}&apikey=${SOURCE_API_KEY}"

    # Find and download backup (check both directory structures)
    BACKUP_FILE=""
    if [ -f "/backup/daily/${user}/${user}.tar.gz" ]; then
        BACKUP_FILE="/backup/daily/${user}/${user}.tar.gz"
    else
        BACKUP_FILE=$(find /backup -name "*${user}*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -n | tail -1 | cut -d' ' -f2-)
    fi
    scp root@${SOURCE_IP}:"$BACKUP_FILE" /backup/

    # Restore on destination via CWP Admin panel or manual extraction
    mkdir -p /home/${user} && tar -xzf /backup/$(basename "$BACKUP_FILE") -C /home/${user}/

    # Cleanup
    rm -f /backup/$(basename "$BACKUP_FILE")

    echo "Completed: ${user}"
done
```

---

## What Gets Transferred

### Full Transfer

| Component       | Included | Notes                          |
|-----------------|----------|--------------------------------|
| User files      | Yes      | Entire home directory          |
| Databases       | Yes      | With users and permissions     |
| Email           | Yes      | Accounts, forwarders, filters  |
| DNS zones       | Yes      | All records                    |
| Cron jobs       | Yes      | User crontabs                  |
| SSL certificates| Yes      | If present                     |
| FTP accounts    | Yes      | Passwords preserved            |
| Subdomains      | Yes      |                                |
| Parked domains  | Yes      |                                |
| Addon domains   | Yes      |                                |
| SSH keys        | Yes      | Authorized keys                |
| Custom configs  | Partial  | May need adjustment            |

---

## Migration Options

### Full Account Migration

Migrates everything for a user:

```bash
/scripts/cwp_transfer --full username source_ip 22
```

### Selective Migration

Migrate specific components:

```bash
# Files only
/scripts/cwp_transfer --files-only username source_ip 22

# Databases only
/scripts/cwp_transfer --databases-only username source_ip 22

# Email only
/scripts/cwp_transfer --email-only username source_ip 22

# DNS only
/scripts/cwp_transfer --dns-only username source_ip 22
```

---

## Large-Scale Migration

### Batch Migration Script

```bash
#!/bin/bash
# /scripts/batch_migrate

SOURCE_IP="192.168.1.100"
SOURCE_KEY="api_key_here"
BATCH_SIZE=5
LOG_FILE="/var/log/cwp_migration.log"

# Get user list
USERS=$(curl -s -k "https://${SOURCE_IP}:2304/api/?action=list_users&apikey=${SOURCE_KEY}" | jq -r '.users[]')
USER_COUNT=$(echo "${USERS}" | wc -l)

echo "Total accounts to migrate: ${USER_COUNT}" | tee -a ${LOG_FILE}

# Process in batches
BATCH=0
for user in ${USERS}; do
    BATCH=$((BATCH + 1))

    echo "[${BATCH}/${USER_COUNT}] Migrating: ${user}" | tee -a ${LOG_FILE}

    /scripts/cwp_transfer ${user} ${SOURCE_IP} 22 2>&1 | tee -a ${LOG_FILE}

    if [ $((BATCH % BATCH_SIZE)) -eq 0 ]; then
        echo "Batch complete. Waiting 30 seconds..." | tee -a ${LOG_FILE}
        sleep 30
    fi
done

echo "Migration complete. ${USER_COUNT} accounts processed." | tee -a ${LOG_FILE}
```

### Parallel Migration

```bash
#!/bin/bash
# /scripts/parallel_migrate

SOURCE_IP="192.168.1.100"
MAX_PARALLEL=3

migrate_user() {
    /scripts/cwp_transfer $1 ${SOURCE_IP} 22
}

export -f migrate_user

# Get user list and migrate in parallel
curl -s -k "https://${SOURCE_IP}:2304/api/?action=list_users&apikey=API_KEY" | \
    jq -r '.users[]' | \
    xargs -P ${MAX_PARALLEL} -I {} bash -c 'migrate_user {}'
```

---

## DNS Migration

### Zone Transfer Approach

```bash
# On destination server
# Add source as master for zones
rndc addzone "example.com" { type slave; masters { 192.168.1.100; }; };

# Wait for transfer
rndc zonestatus example.com

# Convert to master
rndc delzone example.com
# Then add zone via CWP panel
```

### Manual DNS Migration

```bash
# Copy zone files from source
scp root@source:/var/named/example.com.db /var/named/

# Add zone to named.conf
# Via CWP panel: DNS Functions > Add DNS Zone

# Verify
named-checkzone example.com /var/named/example.com.db
rndc reload example.com
```

---

## Post-Migration

### Verification Checklist

```bash
# 1. User accounts exist
/scripts/list_users

# 2. Websites accessible
for domain in $(mysql -u root -p -N -e "SELECT domain FROM postfix.domain"); do
    curl -s -o /dev/null -w "${domain}: %{http_code}\n" http://${domain}
done

# 3. Databases intact
mysql -u root -p -e "SHOW DATABASES;"

# 4. Email working
for domain in $(mysql -u root -p -N -e "SELECT domain FROM postfix.domain"); do
    swaks --to test@${domain} --server localhost
done

# 5. DNS resolving
dig @localhost example.com
```

### Update DNS at Registrar

Point domains to new server IP:
```
ns1.newserver.com -> New IP
ns2.newserver.com -> New IP
```

### Run on Source (After Migration Complete)

```bash
# Remove accounts from source
for user in $(/scripts/list_users); do
    /scripts/cwp_api account remove_user ${user}
done
```

---

## Troubleshooting

### Connection refused

```bash
# Check CSF on source
csf -g destination_ip

# Add destination to allow
csf -a destination_ip "CWP Migration"

# Check API is enabled
curl -k "https://source_ip:2304/api/?action=test&apikey=API_KEY"
```

### Transfer timeout

```bash
# Increase SSH timeout
ssh -o ConnectTimeout=60 -o ServerAliveInterval=30 root@source_ip

# Check network connectivity
ping source_ip
traceroute source_ip
```

### Database import fails

```bash
# Check MySQL on destination
systemctl status mariadb

# Check credentials
cat /root/.my.cnf

# Manual import
gunzip -c /backup/user_mysql.sql.gz | mysql -u root -p
```

### Permissions issues after migration

```bash
# Fix ownership
/scripts/cwp_api account fix_perms username

# Check SELinux (if enabled)
restorecon -Rv /home/username/
```
