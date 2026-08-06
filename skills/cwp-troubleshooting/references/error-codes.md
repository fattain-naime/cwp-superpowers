# Error Codes Reference

## HTTP Status Codes

### 2xx Success

| Code | Meaning          | Description                          |
|------|------------------|--------------------------------------|
| 200  | OK               | Request succeeded                    |
| 201  | Created          | Resource created successfully        |
| 204  | No Content       | Request succeeded, no content to return|

### 3xx Redirection

| Code | Meaning          | Description                          |
|------|------------------|--------------------------------------|
| 301  | Moved Permanently| Resource permanently moved           |
| 302  | Found            | Temporary redirect                   |
| 304  | Not Modified     | Resource not modified since last request|

### 4xx Client Errors

| Code | Meaning           | Common Causes                        |
|------|-------------------|--------------------------------------|
| 400  | Bad Request       | Malformed request syntax             |
| 401  | Unauthorized      | Authentication required              |
| 403  | Forbidden         | Permission denied, IP blocked        |
| 404  | Not Found         | File doesn't exist, wrong URL        |
| 405  | Method Not Allowed| HTTP method not supported            |
| 408  | Request Timeout   | Client took too long                 |
| 413  | Payload Too Large | Upload exceeds limit                 |
| 429  | Too Many Requests | Rate limit exceeded                  |

### 5xx Server Errors

| Code | Meaning              | Common Causes                     |
|------|----------------------|------------------------------------|
| 500  | Internal Server Error| PHP error, misconfiguration        |
| 502  | Bad Gateway          | Backend (PHP-FPM) not responding   |
| 503  | Service Unavailable  | Server overloaded, maintenance     |
| 504  | Gateway Timeout      | Backend took too long              |

---

## CWP API Error Codes

### Authentication Errors

| Code | Error                      | Description                              |
|------|----------------------------|------------------------------------------|
| 401  | Unauthorized               | Invalid or missing API key               |
| 403  | Forbidden                  | API key lacks required permissions       |
| 429  | Too Many Requests          | Rate limit exceeded                      |

### Account Errors

| Code | Error                      | Description                              |
|------|----------------------------|------------------------------------------|
| 1001 | User already exists        | Username is taken                        |
| 1002 | User not found             | Username doesn't exist                   |
| 1003 | Invalid username           | Username format invalid                  |
| 1004 | Invalid password           | Password doesn't meet requirements       |
| 1005 | Invalid email              | Email format invalid                     |
| 1006 | Account suspended          | User account is suspended                |
| 1007 | Quota exceeded             | Disk or bandwidth quota reached          |
| 1008 | Invalid plan               | Hosting plan doesn't exist               |

### Domain Errors

| Code | Error                      | Description                              |
|------|----------------------------|------------------------------------------|
| 2001 | Domain already exists      | Domain is already configured             |
| 2002 | Domain not found           | Domain doesn't exist                     |
| 2003 | Invalid domain format      | Domain name format invalid               |
| 2004 | DNS zone error             | Failed to create/update DNS zone         |
| 2005 | SSL error                  | SSL certificate issue                    |

### Database Errors

| Code | Error                      | Description                              |
|------|----------------------------|------------------------------------------|
| 3001 | Database already exists    | Database name is taken                   |
| 3002 | Database not found         | Database doesn't exist                   |
| 3003 | User already exists        | Database user is taken                   |
| 3004 | User not found             | Database user doesn't exist              |
| 3005 | Connection failed          | MySQL connection error                   |
| 3006 | Access denied              | Insufficient database privileges         |
| 3007 | Import failed              | SQL import error                         |

### Email Errors

| Code | Error                      | Description                              |
|------|----------------------------|------------------------------------------|
| 4001 | Mailbox already exists     | Email address is taken                   |
| 4002 | Mailbox not found          | Email address doesn't exist              |
| 4003 | Invalid email format       | Email format invalid                     |
| 4004 | Forwarder error            | Failed to create forwarder               |
| 4005 | DNS error                  | MX record issue                          |
| 4006 | Authentication failed      | SMTP authentication error                |
| 4007 | Delivery failed            | Email delivery error                     |

### DNS Errors

| Code | Error                      | Description                              |
|------|----------------------------|------------------------------------------|
| 5001 | Zone already exists        | DNS zone already configured              |
| 5002 | Zone not found             | DNS zone doesn't exist                   |
| 5003 | Record error               | Failed to add/edit DNS record            |
| 5004 | Invalid record type        | Unsupported DNS record type              |
| 5005 | Transfer failed            | Zone transfer error                      |

---

## Service Error Codes

### Apache Errors

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| AH00558: httpd: Could not reliably | ServerName not set              | Set ServerName in httpd.conf  |
| AH00072: make_sock: could not bind | Port in use                     | Check which process uses port |
| AH01630: client denied by config   | Access control                  | Check Directory directives    |
| AH01071: Got error 'PHP message'   | PHP error                       | Check PHP error log           |

### Nginx Errors

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| bind() to 0.0.0.0:80 failed       | Port in use                     | Stop conflicting service      |
| upstream timed out                 | Backend timeout                 | Increase proxy timeout        |
| no live upstreams                  | Backend down                    | Check PHP-FPM status          |
| connect() failed                   | Connection refused              | Check backend socket/port     |

### MySQL Errors

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| ERROR 1045 (28000)                 | Access denied                   | Check credentials             |
| ERROR 2002 (HY000)                 | Can't connect to socket         | Check MySQL is running        |
| ERROR 1040 (08004)                 | Too many connections            | Increase max_connections      |
| ERROR 1114 (HY000)                | Table full                      | Check disk space              |
| ERROR 1213 (40001)                | Deadlock detected               | Retry operation               |
| ERROR 2006 (HY000)                | MySQL server has gone away      | Increase max_allowed_packet   |

### Postfix Errors

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| Connection refused                 | Service not running             | Start Postfix                 |
| Relay access denied                | Not authenticated               | Enable SASL authentication    |
| Mailbox full                       | Quota exceeded                  | Increase quota or clean up    |
| Domain not found                   | DNS issue                       | Check MX records              |
| Client host rejected               | IP blocked                      | Check RBL lists               |

### PHP-FPM Errors

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| Connection refused                 | FPM not running                 | Start PHP-FPM                 |
| No such file or directory          | Socket missing                  | Check socket path             |
| Permission denied                  | Socket permissions              | Fix socket ownership          |
| Max children reached               | Too many processes              | Increase pm.max_children      |
| Server reached pm.max_children     | Process limit hit               | Increase or optimize          |

---

## CSF/LFD Error Codes

### LFD Alert Types

| Alert Type              | Description                              |
|-------------------------|------------------------------------------|
| LF_SSHD                | SSH login failure                        |
| LF_FTPD                | FTP login failure                        |
| LF_SMTPAUTH            | SMTP authentication failure              |
| LF_POP3D               | POP3 login failure                       |
| LF_IMAPD               | IMAP login failure                       |
| LF_HTACCESS            | HTTP authentication failure              |
| LF_CPANEL              | cPanel/CWP login failure                 |
| LF_MODSEC              | ModSecurity trigger                      |
| PT_LIMIT               | Process limit exceeded                   |
| PT_USERMEM             | User memory limit exceeded               |
| PT_USERTIME            | User CPU time exceeded                   |
| ET_SYNFLOOD            | SYN flood detected                       |
| PS_INTERVAL             | Port scan detected                       |

### CSF Actions

| Action                 | Description                              |
|------------------------|------------------------------------------|
| Blocked                | IP temporarily blocked                   |
| Permanent block        | IP permanently blocked                   |
| Deny                   | IP added to deny list                    |
| Allow                  | IP added to allow list                   |
| Ignore                 | IP excluded from monitoring              |

---

## Backup Error Codes

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| Backup failed: disk full           | No disk space                   | Free space or change location |
| Backup failed: permission denied   | File permission issue           | Check backup directory perms  |
| Backup failed: MySQL error         | Database backup failed          | Check MySQL credentials       |
| Backup failed: tar error           | Archive creation failed         | Check source files            |
| Backup failed: quota exceeded      | User quota reached              | Increase quota                |
| Restore failed: user exists        | Account already exists          | Delete account first          |
| Restore failed: invalid archive    | Corrupt backup file             | Verify backup integrity       |
| Restore failed: version mismatch   | CWP version difference          | Update CWP first              |

---

## Migration Error Codes

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| Connection refused                 | SSH/API not accessible          | Check firewall and service    |
| Authentication failed              | Wrong credentials               | Verify SSH/API key            |
| Timeout                            | Network or server slow          | Increase timeout settings     |
| Insufficient disk space            | Not enough space on destination | Free up or add storage        |
| Database import failed             | SQL syntax or compatibility     | Check MySQL version           |
| DNS conflict                       | Zone already exists             | Remove existing zone first    |
| User already exists                | Account name taken              | Use different name or delete  |

---

## SSL/TLS Error Codes

| Error                              | Cause                           | Solution                      |
|------------------------------------|---------------------------------|-------------------------------|
| Certificate expired                | Cert past expiration date       | Renew certificate             |
| Certificate not yet valid          | Cert start date in future       | Check system time             |
| Certificate name mismatch         | Domain doesn't match cert       | Use correct certificate       |
| Self-signed certificate           | Not signed by CA                | Install CA-signed cert        |
| Certificate chain incomplete       | Missing intermediate cert       | Add CA bundle                 |
| Private key mismatch              | Key doesn't match cert          | Use matching key/cert pair    |
| OCSP stapling error               | OCSP responder issue            | Disable stapling or fix       |

---

## Quick Error Resolution

### Check Service Status

```bash
systemctl status httpd nginx mysql postfix dovecot named php-fpm cwpsrv
```

### Check Recent Errors

```bash
# System
tail -20 /var/log/messages

# Web
tail -20 /usr/local/apache/logs/error_log

# Mail
tail -20 /var/log/maillog

# Database
tail -20 /var/log/mariadb/mariadb.log
```

### Check Disk Space

```bash
df -h
```

### Check Memory

```bash
free -m
```

### Check Processes

```bash
ps aux | head -20
top -bn1 | head -20
```
