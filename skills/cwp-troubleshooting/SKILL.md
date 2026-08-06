---
name: cwp-troubleshooting
description: This skill should be used when the user asks to "fix CWP error", "troubleshoot server issue", "check server logs", "diagnose web server problem", "fix login issue", "resolve 502 error", "fix email problem", "debug PHP issue", "check service status", "fix CWP panel", "resolve DNS issue", "check server health", or needs to diagnose and resolve any issue on a CWP server.
version: 1.0.0
---

# CWP Troubleshooting

Diagnose and resolve common issues on CWP servers. Handle web server errors, PHP problems, email delivery issues, database crashes, panel access problems, and service failures.

If the user provides specific details via "$ARGUMENTS", use that information to narrow down the diagnosis. For example: `/cwp-pro-centos:cwp-troubleshooting 502 error on example.com` will focus the troubleshooting on 502 errors for that domain.

## Diagnostic Workflow

Follow this systematic approach:

1. **Identify the symptom** -- What is failing?
2. **Check service status** -- Is the service running?
3. **Review logs** -- What do the logs say?
4. **Apply fix** -- Implement the solution
5. **Verify** -- Confirm the fix works
6. **Document** -- Record the solution

## Service Status Checks

```bash
# Web servers
systemctl status httpd nginx varnish

# Database
systemctl status mariadb

# Email
systemctl status postfix dovecot

# Firewall
csf -s

# CWP panel
systemctl status cwpsrv

# DNS
systemctl status named

# FTP
systemctl status pure-ftpd

# All services at once
systemctl status httpd nginx varnish mariadb postfix dovecot named cwpsrv
```

## Log File Locations

| Service | Log Path |
|---|---|
| Apache error | `/usr/local/apache/logs/error_log` |
| Apache access | `/usr/local/apache/domlogs/DOMAIN.log` |
| Nginx error | `/var/log/nginx/error.log` |
| Nginx access | `/var/log/nginx/access.log` |
| MariaDB | `/var/log/mysql/error.log` |
| Postfix | `/var/log/maillog` |
| Dovecot | `/var/log/maillog` |
| PHP-FPM | `/opt/alt/php-fpm{VER}/var/log/php-fpm-error.log` |
| PHP compile | `/var/log/php-rebuild.log` |
| CSF | `/var/log/lfd.log` |
| System | `/var/log/messages` |
| Auth | `/var/log/secure` |
| Cron | `/var/log/cron` |
| Varnish | `/var/log/varnish/varnish.log` |

## Web Server Errors

### ERR_TOO_MANY_REDIRECTS

Common with Nginx -> Varnish -> Apache stack.

```apache
# Add to .htaccess
SetEnvIf X-Forwarded-Proto "https" HTTPS=on
```

### 502 Bad Gateway

PHP-FPM is not responding.

```bash
# Detect and restart PHP-FPM (service name varies)
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    if systemctl is-active "$svc" 2>/dev/null; then
        systemctl restart "$svc"
        echo "Restarted $svc"
        break
    fi
done

# Check FPM socket (path varies by version)
ls -la /opt/alt/php*/usr/var/run/ 2>/dev/null

# Rebuild FPM configs
/scripts/phpfpm_rebuild_user_conf
```

### 503 Service Unavailable

Service is down or misconfigured.

```bash
# Check port redirection
ss -tlnp | grep -E ':(80|443|82|8181)\s'

# Check PHP-FPM socket exists (path varies by version)
ls -la /opt/alt/php*/usr/var/run/ 2>/dev/null

# Restart services
systemctl restart httpd nginx

# Restart PHP-FPM (detect service name)
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    if systemctl is-active "$svc" 2>/dev/null; then
        systemctl restart "$svc"
        break
    fi
done
```

### 504 Gateway Timeout

Request processing exceeded time limit.

```bash
# Increase PHP limits
# Edit /usr/local/php/php.ini
max_execution_time = 300
max_input_time = 300

# Restart PHP-FPM (detect service name)
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    if systemctl is-active "$svc" 2>/dev/null; then
        systemctl restart "$svc"
        break
    fi
done
```

### Apache Proxy Mutex Error

```bash
# Clear stuck semaphores
ipcs -s | awk -v user=nobody '$3==user {system("ipcrm -s "$2)}'
systemctl restart httpd
```

### Default Page for All Domains

```bash
# Rebuild vHosts
/scripts/cwp_api webservers rebuild_all

# Check shared IP setting in CWP Admin
```

## PHP Errors

### PHP Installation Failing

Requires 1.5-2 GB available RAM and working DNS resolver.

```bash
# Check available RAM
free -h

# Check DNS
cat /etc/resolv.conf

# Check compile log
tail -50 /var/log/php-rebuild.log
```

### "No Loader installed" (ionCube)

```bash
sh /scripts/update_ioncube
```

### intl Extension Missing

```bash
# Install from Remi repository
yum install php-intl

# Or recompile PHP with intl support
```

### suPHP 500 Internal Server Error

```bash
# Fix ownership
chown -R USER:USER /home/USER/public_html/*
```

## Email Issues

For comprehensive email troubleshooting including DKIM, SPF, spam filtering, and Roundcube, see the **cwp-email** skill.

### Quick Email Diagnostics

```bash
# Check Postfix status
systemctl status postfix

# View mail log
tail -f /var/log/maillog

# Check mail queue
mailq

# Test email delivery
echo "Test" | mail -s "Test Subject" user@example.com
```

## Database Issues

For comprehensive database troubleshooting including InnoDB crash recovery, performance tuning, and MariaDB upgrades, see the **cwp-database** skill (`references/mysql.md`).

### Quick Database Diagnostics

```bash
# Check MariaDB status
systemctl status mariadb

# View error log
tail -50 /var/log/mysql/error.log

# Check connections
mysql -e "SHOW PROCESSLIST;"

# Check database health
/scripts/checkdb
```

## Panel Access Issues

### Can't Login to CWP

```bash
# Reset admin password
passwd

# Restart CWP service
/scripts/restart_cwpsrv
```

### CWP Expired (Error 500)

```bash
# Manual update from CDN
cd /usr/local/src
wget http://static.cdn-cwp.com/files/cwp/el8/cwp-el8-latest.sh
sh cwp-el8-latest.sh
```

### 404 on User Login

```bash
/scripts/cwpsrv_rebuild_user_conf
```

### Invalid Session

Close all browser windows and re-login.

## Installation Issues

### "Could not resolve host"

```bash
sh /scripts/centos7_fix_repository
```

### Root Login Error (AlmaLinux 9)

Comment `SHA_CRYPT_MAX_ROUNDS` in `/etc/login.defs`.

### Varnish Fails on AlmaLinux 9

Manual Varnish installation required on EL9.

### MariaDB 10.4 EOL

```bash
# Update repo to newer version
sed -i 's/10.4/10.6/g' /etc/yum.repos.d/mariadb.repo
```

## Quick Diagnostic Script

```bash
# Comprehensive server health check
echo "=== Disk Usage ===" && df -h
echo "=== Memory ===" && free -h
echo "=== Load ===" && uptime
echo "=== Services ===" && systemctl status httpd nginx mariadb postfix dovecot named --no-pager
echo "=== Ports ===" && ss -tlnp
echo "=== Recent Errors ===" && tail -20 /usr/local/apache/logs/error_log
echo "=== Mail Queue ===" && mailq
```

## Additional Resources

- `references/common-issues.md` -- Common server and service issues
- `references/log-analysis.md` -- Log file locations and analysis guide
- `references/error-codes.md` -- Error code reference and solutions
