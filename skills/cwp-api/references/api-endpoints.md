# CWP API Endpoints Reference

## Overview

CWP provides a REST-like API on port 2304 for server management automation. All API calls require an API key for authentication.

---

## API Base URL

```
https://server:2304/v1/
```

## Authentication

All API calls require the `apikey` parameter:

```
https://server:2304/api/?action=endpoint&apikey=YOUR_API_KEY
```

### Generate API Key

**Admin Panel > CWP Settings > API Manager**

This is the recommended method. There is no reliable CLI script for generating
API keys -- always use the admin panel.

---

## Account Management Endpoints

### list_users
List all user accounts.

```
GET /api/?action=list_users&apikey=KEY
```

**Response:**
```json
{
    "status": "success",
    "users": ["user1", "user2", "user3"]
}
```

### add_user
Create a new user account.

```
POST /api/?action=add_user&apikey=KEY
```

**Parameters:**
| Parameter   | Required | Description              |
|-------------|----------|--------------------------|
| username    | Yes      | Account username         |
| password    | Yes      | Account password         |
| domain      | Yes      | Primary domain           |
| email       | Yes      | Contact email            |
| package     | Yes      | Hosting plan name        |
| server_ips  | No       | Dedicated IP (if any)    |

### delete_user
Delete a user account.

```
POST /api/?action=delete_user&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| username  | Yes      | Username to delete|

### modify_user
Modify user account properties.

```
POST /api/?action=modify_user&apikey=KEY
```

**Parameters:**
| Parameter   | Required | Description              |
|-------------|----------|--------------------------|
| username    | Yes      | Username                 |
| password    | No       | New password             |
| email       | No       | New email                |
| package     | No       | New hosting plan         |
| disk_quota  | No       | Disk quota in MB         |
| bandwidth   | No       | Bandwidth limit in MB    |

### suspend_user
Suspend a user account.

```
POST /api/?action=suspend_user&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description            |
|-----------|----------|------------------------|
| username  | Yes      | Username to suspend    |
| reason    | No       | Suspension reason      |

### unsuspend_user
Unsuspend a user account.

```
POST /api/?action=unsuspend_user&apikey=KEY
```

---

## Domain Management Endpoints

### add_domain
Add a domain to a user account.

```
POST /api/?action=add_domain&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description              |
|-----------|----------|--------------------------|
| username  | Yes      | Account username         |
| domain    | Yes      | Domain name              |
| path      | No       | Document root path       |

### delete_domain
Remove a domain from a user account.

```
POST /api/?action=delete_domain&apikey=KEY
```

### list_domains
List all domains for a user.

```
GET /api/?action=list_domains&username=user1&apikey=KEY
```

### add_subdomain
Add a subdomain.

```
POST /api/?action=add_subdomain&apikey=KEY
```

**Parameters:**
| Parameter  | Required | Description      |
|------------|----------|------------------|
| username   | Yes      | Account username |
| subdomain  | Yes      | Subdomain name   |
| domain     | Yes      | Parent domain    |

### add_parked_domain
Add a parked (alias) domain.

```
POST /api/?action=add_parked_domain&apikey=KEY
```

---

## DNS Endpoints

### list_dns_zones
List all DNS zones.

```
GET /api/?action=list_dns_zones&apikey=KEY
```

### add_dns_zone
Add a DNS zone.

```
POST /api/?action=add_dns_zone&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| domain    | Yes      | Domain name      |
| ip        | Yes      | IP address       |

### delete_dns_zone
Delete a DNS zone.

```
POST /api/?action=delete_dns_zone&apikey=KEY
```

### add_dns_record
Add a DNS record to a zone.

```
POST /api/?action=add_dns_record&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description          |
|-----------|----------|----------------------|
| domain    | Yes      | Domain name          |
| type      | Yes      | Record type (A, CNAME, MX, TXT, etc.) |
| name      | Yes      | Record name          |
| value     | Yes      | Record value         |
| ttl       | No       | TTL (default 14400)  |
| priority  | No       | MX priority          |

### delete_dns_record
Delete a DNS record.

```
POST /api/?action=delete_dns_record&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| domain    | Yes      | Domain name      |
| record_id | Yes      | Record ID        |

### edit_dns_record
Edit an existing DNS record.

```
POST /api/?action=edit_dns_record&apikey=KEY
```

---

## Database Endpoints

### add_database
Create a MySQL database.

```
POST /api/?action=add_database&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| username  | Yes      | Account username |
| database  | Yes      | Database name    |

### delete_database
Delete a MySQL database.

```
POST /api/?action=delete_database&apikey=KEY
```

### add_db_user
Create a MySQL database user.

```
POST /api/?action=add_db_user&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| username  | Yes      | Account username |
| db_user   | Yes      | Database username|
| db_pass   | Yes      | Database password|

### grant_database
Grant a user access to a database.

```
POST /api/?action=grant_database&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description          |
|-----------|----------|----------------------|
| username  | Yes      | Account username     |
| db_user   | Yes      | Database username    |
| database  | Yes      | Database name        |
| privileges| No       | Privileges (default ALL) |

---

## Email Endpoints

### add_mailbox
Create an email mailbox.

```
POST /api/?action=add_mailbox&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| domain    | Yes      | Domain name      |
| username  | Yes      | Email username   |
| password  | Yes      | Email password   |
| quota     | No       | Mailbox quota in MB |

### delete_mailbox
Delete an email mailbox.

```
POST /api/?action=delete_mailbox&apikey=KEY
```

### add_mailforward
Create an email forwarder.

```
POST /api/?action=add_mailforward&apikey=KEY
```

**Parameters:**
| Parameter   | Required | Description        |
|-------------|----------|--------------------|
| domain      | Yes      | Domain name        |
| source_user | Yes      | Source email user  |
| target_email| Yes      | Forward target     |

### list_mailboxes
List email accounts for a domain.

```
GET /api/?action=list_mailboxes&domain=example.com&apikey=KEY
```

---

## SSL/TLS Endpoints

### install_ssl
Install an SSL certificate.

```
POST /api/?action=install_ssl&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description          |
|-----------|----------|----------------------|
| domain    | Yes      | Domain name          |
| cert      | Yes      | Certificate (CRT)    |
| key       | Yes      | Private key (KEY)    |
| ca        | No       | CA bundle            |

### install_letsencrypt
Install Let's Encrypt certificate.

```
POST /api/?action=install_letsencrypt&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| domain    | Yes      | Domain name      |

### list_ssl_certificates
List installed SSL certificates.

```
GET /api/?action=list_ssl_certificates&apikey=KEY
```

---

## System Endpoints

### server_status
Get server status information.

```
GET /api/?action=server_status&apikey=KEY
```

**Response:**
```json
{
    "status": "success",
    "hostname": "server.example.com",
    "os": "AlmaLinux 9",
    "cwp_version": "0.9.8.1244",
    "uptime": "15 days, 3:42",
    "load": "0.45, 0.32, 0.28",
    "memory": {
        "total": "4096MB",
        "used": "2048MB",
        "free": "2048MB"
    }
}
```

### list_services
List running services.

```
GET /api/?action=list_services&apikey=KEY
```

### restart_service
Restart a service.

```
POST /api/?action=restart_service&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description              |
|-----------|----------|--------------------------|
| service   | Yes      | Service name (httpd, nginx, mysql, etc.) |

### backup_user
Backup a user account.

```
POST /api/?action=backup_user&apikey=KEY
```

**Parameters:**
| Parameter | Required | Description      |
|-----------|----------|------------------|
| username  | Yes      | Username to backup|

### restore_user
Restore a user from backup.

```
POST /api/?action=restore_user&apikey=KEY
```

**Parameters:**
| Parameter   | Required | Description          |
|-------------|----------|----------------------|
| username    | Yes      | Username             |
| backup_file | Yes      | Backup file path     |

---

## Response Format

### Success Response

```json
{
    "status": "success",
    "message": "Operation completed successfully",
    "data": {}
}
```

### Error Response

```json
{
    "status": "error",
    "error_code": 1001,
    "message": "User already exists"
}
```

---

## Rate Limiting

- Default: 100 requests per minute per API key
- Exceeded limit returns HTTP 429
- Contact CWP support for higher limits

---

## Error Codes

| Code | Description                      |
|------|----------------------------------|
| 401  | Unauthorized (invalid API key)   |
| 403  | Forbidden (insufficient permissions) |
| 404  | Endpoint not found               |
| 429  | Rate limit exceeded              |
| 500  | Internal server error            |
| 1001 | User already exists              |
| 1002 | User not found                   |
| 2001 | Domain already exists            |
| 2002 | Domain not found                 |
| 3001 | Database already exists          |
| 3002 | Database not found               |
| 4001 | Mailbox already exists           |
| 4002 | Mailbox not found                |
| 5001 | DNS zone already exists          |
| 5002 | DNS zone not found               |
