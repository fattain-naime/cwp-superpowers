---
description: View and analyze CWP server logs with filtering and tailing options
argument-hint: "[service] [--tail] [--lines N]"
allowed-tools: Bash, Read, Grep
---

# CWP Logs Command

You are viewing and analyzing logs for a CWP server. Parse the arguments to determine which logs to show and how to display them.

## Parse Arguments

Parse `$ARGUMENTS` to determine:
- **service**: Which service log to view (apache, nginx, mariadb, postfix, dovecot, php, csf, cwp, system, auth, cron, all)
- **--tail**: Follow the log in real-time (like `tail -f`)
- **--lines N**: Number of lines to show (default: 50)

If no service is specified, show a summary of recent errors across all services.

## Log File Locations

| Service | Log Path |
|---------|----------|
| Apache error | `/usr/local/apache/logs/error_log` |
| Apache access | `/usr/local/apache/domlogs/DOMAIN.log` |
| Nginx error | `/var/log/nginx/error.log` |
| Nginx access | `/var/log/nginx/access.log` |
| MariaDB | `/var/log/mysql/error.log` or `/var/log/mariadb/mariadb.log` |
| Postfix | `/var/log/maillog` |
| Dovecot | `/var/log/maillog` |
| PHP-FPM | `/opt/alt/php-fpm{VER}/var/log/php-fpm-error.log` |
| PHP compile | `/var/log/php-rebuild.log` |
| CSF/LFD | `/var/log/lfd.log` |
| CWP panel | `/var/log/cwp/` |
| System | `/var/log/messages` |
| Auth | `/var/log/secure` |
| Cron | `/var/log/cron` |
| Varnish | `/var/log/varnish/varnish.log` |

## Display Modes

### Single Service (--tail)
If `--tail` is specified, follow the log in real-time:
```bash
tail -f /path/to/logfile
```
Run for 30 seconds max, then show the output.

### Single Service (static)
Show the last N lines:
```bash
tail -N /path/to/logfile
```

### All Services (summary)
If service is "all" or not specified, grep for errors across all logs:
```bash
echo "=== Apache Errors ===" && tail -10 /usr/local/apache/logs/error_log 2>/dev/null
echo "=== Nginx Errors ===" && tail -10 /var/log/nginx/error.log 2>/dev/null
echo "=== MariaDB Errors ===" && tail -10 /var/log/mysql/error.log 2>/dev/null
echo "=== Mail Errors ===" && grep -i 'error\|warning' /var/log/maillog 2>/dev/null | tail -10
echo "=== System Errors ===" && grep -i 'error\|critical\|fatal' /var/log/messages 2>/dev/null | tail -10
```

## Filtering

If the user provides additional context (e.g., "show apache errors for example.com"), filter the output:
- For Apache access logs, use the domain-specific log: `/usr/local/apache/domlogs/DOMAIN.log`
- For error patterns, grep for specific keywords: `grep -i 'error\|warn\|fail'`

## Output Format

Present logs in a clear, readable format:

```
=== [Service] Log ===
[timestamp] [level] [message]
[timestamp] [level] [message]
...

Summary: X errors, Y warnings found in last N lines
```

If errors are found, provide brief analysis of the most common issues and suggest follow-up actions.
