# Log Analysis Reference

## Log File Locations

### Web Server Logs

| Log Type        | Path                                                     |
|-----------------|----------------------------------------------------------|
| Apache error    | `/usr/local/apache/logs/error_log`                       |
| Apache access   | `/usr/local/apache/logs/access_log`                      |
| Per-user Apache | `/usr/local/apache/logs/{username}_error.log`            |
| Nginx error     | `/usr/local/nginx/logs/error.log`                        |
| Nginx access    | `/usr/local/nginx/logs/access.log`                       |
| Per-domain Nginx| `/var/log/nginx/domains/{domain}.error.log`              |
| Nginx access    | `/var/log/nginx/domains/{domain}.access.log`             |

### PHP Logs

| Log Type              | Path                                                     |
|-----------------------|----------------------------------------------------------|
| PHP-FPM error         | `/var/log/php-fpm/error.log`                             |
| PHP-FPM slow log      | `/var/log/php-fpm/slow.log`                              |
| Alt-PHP error         | `/opt/alt/php{version}/var/log/php_errors.log`           |
| Per-user PHP error    | `/home/{username}/logs/php_error.log`                    |
| CWP internal PHP      | `/usr/local/cwp/php/var/log/php_errors.log`              |

### Mail Logs

| Log Type        | Path                                                     |
|-----------------|----------------------------------------------------------|
| Postfix         | `/var/log/maillog`                                       |
| Dovecot         | `/var/log/maillog` (shared with Postfix)                 |
| Rspamd          | `/var/log/rspamd/rspamd.log`                             |
| ClamAV          | `/var/log/clamd.scan`                                    |

### Database Logs

| Log Type        | Path                                                     |
|-----------------|----------------------------------------------------------|
| MySQL error     | `/var/log/mariadb/mariadb.log`                           |
| MySQL slow      | `/var/log/mariadb/slow.log`                              |
| MySQL general   | `/var/log/mariadb/general.log`                           |

### System Logs

| Log Type        | Path                                                     |
|-----------------|----------------------------------------------------------|
| System messages | `/var/log/messages`                                      |
| Authentication  | `/var/log/secure`                                        |
| Cron            | `/var/log/cron`                                          |
| Boot            | `/var/log/boot.log`                                      |
| dmesg           | `/var/log/dmesg`                                         |

### CWP Logs

| Log Type        | Path                                                     |
|-----------------|----------------------------------------------------------|
| CWP panel       | `/usr/local/cwpsrv/logs/error.log`                       |
| CWP access      | `/usr/local/cwpsrv/logs/access.log`                      |
| CWP API         | `/usr/local/cwpsrv/logs/api.log`                         |
| Backup          | `/backup/logs/backup_{date}.log`                         |
| CSF/LFD         | `/var/log/lfd.log`                                       |

---

## Common Log Patterns

### Apache Error Log Patterns

```bash
# PHP fatal errors
grep "PHP Fatal error" /usr/local/apache/logs/error_log

# File not found
grep "File does not exist" /usr/local/apache/logs/error_log

# Permission denied
grep "Permission denied" /usr/local/apache/logs/error_log

# ModSecurity blocks
grep "ModSecurity" /usr/local/apache/logs/error_log

# Segmentation faults
grep "Segmentation fault" /usr/local/apache/logs/error_log

# Connection timeout
grep "Timeout" /usr/local/apache/logs/error_log
```

### Nginx Error Log Patterns

```bash
# Connection refused (backend down)
grep "Connection refused" /usr/local/nginx/logs/error.log

# Upstream timeout
grep "upstream timed out" /usr/local/nginx/logs/error.log

# No such file
grep "No such file" /usr/local/nginx/logs/error.log

# Permission denied
grep "Permission denied" /usr/local/nginx/logs/error.log

# Too many open files
grep "Too many open files" /usr/local/nginx/logs/error.log
```

### Mail Log Patterns

```bash
# Successful delivery
grep "status=sent" /var/log/maillog

# Bounced messages
grep "status=bounced" /var/log/maillog

# Deferred messages
grep "status=deferred" /var/log/maillog

# Rejected messages
grep "reject:" /var/log/maillog

# Authentication failures
grep "authentication failed" /var/log/maillog

# SPF failures
grep "spf=fail" /var/log/maillog

# DKIM verification
grep "dkim=" /var/log/maillog
```

### MySQL Log Patterns

```bash
# Connection errors
grep "Can't connect" /var/log/mariadb/mariadb.log

# Access denied
grep "Access denied" /var/log/mariadb/mariadb.log

# Table corruption
grep "is marked as crashed" /var/log/mariadb/mariadb.log

# Slow queries
grep "Query_time" /var/log/mariadb/slow.log

# Out of memory
grep "Out of memory" /var/log/mariadb/mariadb.log
```

---

## Log Analysis Commands

### Count Occurrences

```bash
# Count errors per hour
grep "error" /usr/local/apache/logs/error_log | awk '{print $1, $2}' | cut -d: -f1,2 | sort | uniq -c

# Count 500 errors per domain
grep " 500 " /var/log/nginx/domains/*.access.log | awk '{print $1}' | sort | uniq -c | sort -rn

# Count failed login attempts
grep "Failed password" /var/log/secure | awk '{print $11}' | sort | uniq -c | sort -rn | head -20
```

### Find Specific Time Range

```bash
# Errors in last hour
awk -v d="$(date -d '1 hour ago' '+%d/%b/%Y:%H')" '$0 ~ d' /usr/local/apache/logs/error_log

# Errors between specific times
awk '/22\/Jan\/2024:10/,/22\/Jan\/2024:11/' /usr/local/apache/logs/access_log

# Today's errors
grep "$(date +%d/%b/%Y)" /usr/local/apache/logs/error_log
```

### Top IPs

```bash
# Top IPs accessing server
awk '{print $1}' /usr/local/apache/logs/access_log | sort | uniq -c | sort -rn | head -20

# Top IPs with errors
grep " 500 " /usr/local/apache/logs/access_log | awk '{print $1}' | sort | uniq -c | sort -rn | head -20

# Top IPs hitting 404
grep " 404 " /usr/local/apache/logs/access_log | awk '{print $1}' | sort | uniq -c | sort -rn | head -20
```

### Top URLs

```bash
# Most accessed URLs
awk '{print $7}' /usr/local/apache/logs/access_log | sort | uniq -c | sort -rn | head -20

# Most 404 URLs
grep " 404 " /usr/local/apache/logs/access_log | awk '{print $7}' | sort | uniq -c | sort -rn | head -20

# Most error-prone URLs
grep " 500 " /usr/local/apache/logs/access_log | awk '{print $7}' | sort | uniq -c | sort -rn | head -20
```

---

## Real-Time Log Monitoring

### Tail Multiple Logs

```bash
# Monitor Apache errors in real-time
tail -f /usr/local/apache/logs/error_log

# Monitor Nginx errors
tail -f /usr/local/nginx/logs/error.log

# Monitor mail log
tail -f /var/log/maillog

# Monitor multiple logs
tail -f /usr/local/apache/logs/error_log /var/log/maillog /var/log/messages
```

### Watch for Specific Errors

```bash
# Watch for PHP errors
tail -f /usr/local/apache/logs/error_log | grep "PHP"

# Watch for 500 errors
tail -f /usr/local/apache/logs/access_log | grep " 500 "

# Watch for failed SSH logins
tail -f /var/log/secure | grep "Failed"

# Watch for blocked IPs
tail -f /var/log/lfd.log | grep "Blocked"
```

---

## Log Rotation

### Default Logrotate Configuration

**Path:** `/etc/logrotate.d/httpd`

```
/usr/local/apache/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /usr/local/apache/bin/httpd -k graceful
    endscript
}
```

**Path:** `/etc/logrotate.d/nginx`

```
/usr/local/nginx/logs/*.log /var/log/nginx/*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 644 nginx nginx
    postrotate
        /usr/local/nginx/sbin/nginx -s reload
    endscript
}
```

### Manual Log Rotation

```bash
# Rotate Apache logs
mv /usr/local/apache/logs/error_log /usr/local/apache/logs/error_log.$(date +%Y%m%d)
kill -USR1 $(cat /var/run/httpd.pid)

# Rotate Nginx logs
mv /usr/local/nginx/logs/error.log /usr/local/nginx/logs/error.log.$(date +%Y%m%d)
/usr/local/nginx/sbin/nginx -s reopen
```

---

## CWP-Specific Log Analysis

### Backup Logs

```bash
# Check backup status
tail -50 /backup/logs/backup_$(date +%Y%m%d).log

# Find failed backups
grep -i "error\|failed" /backup/logs/*.log

# Count successful backups
grep -c "Backup complete" /backup/logs/*.log
```

### CSF/LFD Logs

```bash
# Blocked IPs
grep "Blocked" /var/log/lfd.log | tail -20

# Login failures
grep "Failed" /var/log/lfd.log | tail -20

# Process violations
grep "Excessive" /var/log/lfd.log | tail -20

# Country blocks
grep "CC_DENY" /var/log/lfd.log | tail -20
```

### CWP API Logs

```bash
# API requests
tail -50 /usr/local/cwpsrv/logs/api.log

# Failed API calls
grep "error\|fail" /usr/local/cwpsrv/logs/api.log

# API calls by endpoint
awk '{print $4}' /usr/local/cwpsrv/logs/api.log | sort | uniq -c | sort -rn
```

---

## Log Analysis Tools

### GoAccess (Real-time Web Log Analyzer)

```bash
# Install
yum install goaccess

# Analyze Apache log
goaccess /usr/local/apache/logs/access_log --log-format=COMBINED -o report.html

# Real-time dashboard
goaccess /usr/local/apache/logs/access_log --log-format=COMBINED --real-time-html
```

### AWStats

```bash
# Install
yum install awstats

# Configure for domain
vi /etc/awstats/awstats.domain.com.conf

# Generate report
/usr/share/awstats/tools/awstats_buildstaticpages.pl -config=domain.com -update
```

### Custom Analysis Script

```bash
#!/bin/bash
# /scripts/log_analysis

echo "=== Daily Log Analysis ==="
echo "Date: $(date)"
echo ""

echo "--- Top 10 IPs ---"
awk '{print $1}' /usr/local/apache/logs/access_log | sort | uniq -c | sort -rn | head -10

echo ""
echo "--- Top 10 URLs ---"
awk '{print $7}' /usr/local/apache/logs/access_log | sort | uniq -c | sort -rn | head -10

echo ""
echo "--- Error Summary ---"
grep " 500 " /usr/local/apache/logs/access_log | wc -l
echo "500 errors"
grep " 404 " /usr/local/apache/logs/access_log | wc -l
echo "404 errors"

echo ""
echo "--- Mail Summary ---"
grep "status=sent" /var/log/maillog | wc -l
echo "sent messages"
grep "status=bounced" /var/log/maillog | wc -l
echo "bounced messages"
```
