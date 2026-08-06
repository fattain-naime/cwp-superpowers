---
description: Check CWP server status including services, resources, and recent errors
argument-hint: (no arguments)
allowed-tools: Bash, Read, Grep
---

# CWP Server Status Command

You are checking the overall health and status of a CWP server. Run every check below and compile a status report.

## Step 1: CWP Version and Panel Status

- Run `cat /etc/cwp/version` or `rpm -q cwp` to get the installed CWP version.
- Check if the CWP panel service is running: `systemctl status cwpsrv`.
- Note the panel URL and whether it responds: `curl -sk -o /dev/null -w "%{http_code}" https://localhost:2031`.

## Step 2: Check Core Services

Check each service and record its status (running/stopped/failed):

| Service | Command |
|---------|---------|
| Apache (httpd) | `systemctl is-active httpd` |
| Nginx | `systemctl is-active nginx` |
| MariaDB/MySQL | `systemctl is-active mariadb` or `systemctl is-active mysql` |
| Postfix | `systemctl is-active postfix` |
| Dovecot | `systemctl is-active dovecot` |
| CSF Firewall | `systemctl is-active csf` or `csf -v` |
| PHP-FPM | `systemctl is-active php-fpm` |
| Named (BIND) | `systemctl is-active named` |

For any service that is not active, check its last log entries: `journalctl -u <service> --no-pager -n 10`.

## Step 3: System Resources

- **Disk usage**: Run `df -h` and flag any partition above 85%.
- **Memory**: Run `free -h` and report total, used, and available.
- **Load average**: Run `uptime` and compare load to CPU count (`nproc`).
- **Swap**: Run `swapon --show`. If swap is missing or heavily used, flag it.
- **Inode usage**: Run `df -i` and flag any partition above 80%.

## Step 4: Recent Errors

- Check system log for errors: `grep -i 'error\|critical\|fatal' /var/log/messages 2>/dev/null | tail -20`.
- Check CWP logs: `ls /var/log/cwp/` and grep the most recent log for errors.
- Check Apache/Nginx error log: `tail -20 /var/log/httpd/error_log` or `tail -20 /var/log/nginx/error_log`.
- Check MySQL error log: `tail -20 /var/log/mariadb/mariadb.log` or `tail -20 /var/log/mysql/error.log`.

## Step 5: Generate Report

Compile all findings into a structured report:

```
=== CWP Server Status Report ===
CWP Version: ...
Panel Status: ...

--- Services ---
httpd:    [OK/FAIL]
nginx:    [OK/FAIL]
...

--- Resources ---
Disk:     X% used on /dev/...
Memory:   X used / Y total
Load:     X.XX (Y CPUs)
Swap:     X used / Y total

--- Recent Errors ---
[errors found or "None"]
```

If any critical issues are found (service down, disk full, high load), recommend specific follow-up actions.
