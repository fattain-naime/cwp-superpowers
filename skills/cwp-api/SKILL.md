---
name: cwp-api
description: This skill should be used when the user asks to "use CWP API", "create API key", "manage accounts via API", "automate CWP tasks", "list API endpoints", "integrate with CWP", "use cwp_api script", "configure API access", "create account via API", "manage databases via API", "set up billing integration", "configure WHMCS", or needs to interact with the CWP API or automate CWP operations.
version: 1.0.0
---

# CWP API Integration

Interact with the CWP REST API and shell-based API for automation, account management, and third-party integrations. Handle API endpoints, authentication, and common automation workflows.

If the user provides specific details via "$ARGUMENTS", focus the response on that API task. For example: `/cwp-pro-centos:cwp-api create account for example.com` will focus on the account creation API endpoint.

## API Overview

Use two API interfaces for CWP automation:

| Interface | Port | Protocol |
|---|---|---|
| REST API | 2304 | HTTPS |
| Shell API | N/A | CLI via `/scripts/cwp_api` |

## API Configuration

### Setup

1. Navigate to CWP Settings -> API Manager
2. Generate an API key
3. Whitelist allowed IP addresses
4. Note the API base URL

### Base URL

```
https://SERVER_IP:2304/v1/{function}
```

### Authentication

All API requests require the `key` parameter with your API key.

### Request Format

- Method: POST for all endpoints
- Response: JSON or XML

## REST API Endpoints

### Account Management

| Endpoint | Operations |
|---|---|
| `/v1/account` | add, update, delete, list, suspend, unsuspend |
| `/v1/accountdetail` | list |
| `/v1/accountquota` | list |
| `/v1/account_metadata` | list |
| `/v1/changepack` | update |
| `/v1/changepass` | update |

### Database Management

| Endpoint | Operations |
|---|---|
| `/v1/databasemysql` | add, delete, list |
| `/v1/usermysql` | add, delete, list |

### SSL Management

| Endpoint | Operations |
|---|---|
| `/v1/autossl` | add, list, delete, renew |

### Domain Management

| Endpoint | Operations |
|---|---|
| `/v1/admindomains` | add, delete, list |

### Email Management

| Endpoint | Operations |
|---|---|
| `/v1/emailadmin` | list |

### Cron Jobs

| Endpoint | Operations |
|---|---|
| `/v1/cronjobsusers` | add, delete, list |

### Packages

| Endpoint | Operations |
|---|---|
| `/v1/packages` | add, update, delete, list |

### Server Information

| Endpoint | Operations |
|---|---|
| `/v1/typeserver` | list |
| `/v1/quotalimit` | list |

## API Usage Examples

### Create Account

```bash
# Replace ${CWP_API_KEY} with your actual API key or set it as an environment variable
curl -X POST "https://SERVER_IP:2304/v1/account" \
  -d "key=${CWP_API_KEY}" \
  -d "action=add" \
  -d "domain=example.com" \
  -d "username=examuser" \
  -d "password=CHANGE_ME" \
  -d "email=admin@example.com" \
  -d "server_ips=1.2.3.4" \
  -d "package=default"
```

### List Accounts

```bash
curl -X POST "https://SERVER_IP:2304/v1/account" \
  -d "key=${CWP_API_KEY}" \
  -d "action=list"
```

### Suspend Account

```bash
curl -X POST "https://SERVER_IP:2304/v1/account" \
  -d "key=${CWP_API_KEY}" \
  -d "action=suspend" \
  -d "username=examuser"
```

### Create Database

```bash
curl -X POST "https://SERVER_IP:2304/v1/databasemysql" \
  -d "key=${CWP_API_KEY}" \
  -d "action=add" \
  -d "username=examuser" \
  -d "dbname=mydb"
```

## Shell API (`/scripts/cwp_api`)

The shell API provides command-line access to CWP functions.

### Account Operations

```bash
# Account management
/scripts/cwp_api account add USERNAME DOMAIN PASSWORD EMAIL IP PACKAGE
/scripts/cwp_api account remove_user USERNAME
/scripts/cwp_api account suspend_user USERNAME
/scripts/cwp_api account unsuspend_user USERNAME
/scripts/cwp_api account fix_perms USERNAME
/scripts/cwp_api account list_domains USERNAME

# Bulk operations
/scripts/cwp_api account update_diskquota_all
/scripts/cwp_api account update_limits_all
/scripts/cwp_api account mail_fix_permissions
/scripts/cwp_api account update_policyd_all
/scripts/cwp_api account rebuild_etc_named_conf
/scripts/cwp_api account rebuild_var_named_all
```

### Web Server Operations

```bash
/scripts/cwp_api webservers rebuild_all
/scripts/cwp_api webservers rebuild_user USERNAME
/scripts/cwp_api webservers restart
/scripts/cwp_api webservers reload
```

### Application Operations

```bash
/scripts/cwp_api apps install_softaculous
```

### Database Operations

```bash
/scripts/cwp_api databasemysql add USERNAME DBNAME
/scripts/cwp_api databasemysql delete USERNAME DBNAME
/scripts/cwp_api databasemysql list USERNAME
```

## PHP API Client

### Installation

```bash
composer require puerari/cwp_api
```

### Usage

```php
require_once 'vendor/autoload.php';

// Use environment variable for API key: getenv('CWP_API_KEY')
$cwpApi = new Cwpapi('https://yourcwpdomain.com', getenv('CWP_API_KEY'));

// Create account - use a secure password, not a hardcoded string
$status = $cwpApi->createAccount(
    'domain.com',
    'username',
    'CHANGE_ME',  // Generate a secure password
    'email@domain.com',
    '1.2.3.4'
);

// Create database
$status = $cwpApi->createMysqlDatabase('username', 'dbname');

// List accounts
$accounts = $cwpApi->listAccounts();
```

## Action Hooks

Hooks allow executing custom code on CWP events.

### DNS Hooks

Location: `/usr/local/cwpsrv/htdocs/resources/admin/hooks/dns/`

| Hook | Trigger |
|---|---|
| `dns_serial_update` | Zone additions, subdomain changes |
| `dns_new_zone_add` | New DNS zone created |
| `dns_new_subdomain_add` | New subdomain created |
| `dns_zone_remove` | Domain deleted |
| `dns_subdomain_remove` | Subdomain deleted |

### Account Hooks

Location: `/usr/local/cwpsrv/htdocs/resources/admin/hooks/account/`

| Hook | Trigger |
|---|---|
| `account_new` | Account created |
| `account_remove` | Account deleted |
| `account_suspend` | Account suspended |
| `account_unsuspend` | Account reactivated |
| `account_new_domain` | Domain added |
| `account_remove_domain` | Domain removed |
| `account_new_subdomain` | Subdomain added |
| `account_remove_subdomain` | Subdomain removed |

### Hook Example

```php
<?php
function account_new($array){
    // $array contains: username, domain, status
    // Reseller accounts also include 'reseller' key
    $log = date('Y-m-d H:i:s') . " - New account: {$array['username']} ({$array['domain']})\n";
    file_put_contents('/var/log/cwp_hooks.log', $log, FILE_APPEND);
}
?>
```

## Billing Integration

### WHMCS Integration

```bash
# Download WHMCS module
wget http://dl1.centos-webpanel.com/files/3rdparty/whmcs/cwp7.zip

# Extract to WHMCS
unzip cwp7.zip -d /path/to/whmcs/modules/servers/cwp7/
```

**WHMCS Configuration:**
1. Setup -> Products/Services -> Servers
2. Type: Cwp7
3. Enter CWP server IP and API key

### Other Supported Systems

- WiseCP
- HostBill
- Blesta
- Clientexec

## Automation Workflows

### New Server Provisioning

```bash
#!/bin/bash
# Automate new account setup
# Set CWP_API_KEY environment variable before running: export CWP_API_KEY="your-key"

API_URL="https://SERVER_IP:2304/v1"
API_KEY="${CWP_API_KEY}"

# Create account
curl -s -X POST "$API_URL/account" \
  -d "key=$API_KEY" \
  -d "action=add" \
  -d "domain=$1" \
  -d "username=$2" \
  -d "password=$3" \
  -d "email=$4"

# Create database
curl -s -X POST "$API_URL/databasemysql" \
  -d "key=$API_KEY" \
  -d "action=add" \
  -d "username=$2" \
  -d "dbname=${2}_db"

# Enable AutoSSL
curl -s -X POST "$API_URL/autossl" \
  -d "key=$API_KEY" \
  -d "action=add" \
  -d "domain=$1"
```

### Backup Script

```bash
#!/bin/bash
# Backup all users via API
# Script name varies by CWP version

for user in $(/scripts/list_users); do
    if [ -f /scripts/user_backup ]; then
        sh /scripts/user_backup "$user"
    elif [ -f /scripts/backup_user ]; then
        sh /scripts/backup_user "$user"
    fi
done
```

## API Security

1. Whitelist only necessary IP addresses
2. Use strong API keys
3. Rotate API keys periodically
4. Monitor API access logs
5. Use HTTPS only (port 2304)
6. Never expose API key in client-side code

## Troubleshooting

| Issue | Solution |
|---|---|
| API connection refused | Verify port 2304 is open in CSF |
| Authentication failed | Verify API key and IP whitelist |
| Timeout errors | Check server load, increase timeout |
| JSON parse error | Check response format, verify endpoint |
| Hook not executing | Check file permissions, verify PHP syntax |

### Diagnostic Commands

```bash
# Test API connectivity - set CWP_API_KEY environment variable first
curl -k -s "https://SERVER_IP:2304/v1/typeserver" -d "key=${CWP_API_KEY}"

# Check API port
ss -tlnp | grep 2304

# Check CWP API service
/scripts/check_api

# View CWP logs
tail -f /usr/local/cwpsrv/logs/error_log
```

## Additional Resources

- `references/api-endpoints.md` -- Complete API endpoint reference
- `references/api-examples.md` -- API request/response examples
- `references/hooks-reference.md` -- All available action hooks
