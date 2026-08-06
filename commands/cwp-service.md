---
description: Manage CWP server services (start, stop, restart, status, enable, disable)
argument-hint: <service> <action>
allowed-tools: Bash, Read, Grep
---

# CWP Service Management Command

You are managing services on a CWP server. Parse the arguments to determine which service to manage and what action to take.

## Parse Arguments

Parse `$ARGUMENTS` to determine:
- **service**: Which service to manage (apache/httpd, nginx, varnish, mariadb/mysql, postfix, dovecot, named/bind, php-fpm, cwpsrv, pure-ftpd, redis, memcached, csf)
- **action**: What action to perform (status, start, stop, restart, reload, enable, disable, logs)

If arguments are unclear, ask the user for clarification.

## Service Mapping

Map common names to systemd service names:

| User Says | Service Name |
|-----------|--------------|
| apache, httpd | httpd |
| nginx | nginx |
| varnish | varnish |
| mariadb, mysql, database | mariadb |
| postfix, mail, smtp | postfix |
| dovecot, imap, pop3 | dovecot |
| named, bind, dns | named |
| php, php-fpm | php-fpmXX (version-specific) |
| cwp, panel | cwpsrv |
| ftp, pure-ftpd | pure-ftpd |
| redis | redis |
| memcached | memcached |
| firewall, csf | csf |

## Actions

### Status (default)
```bash
systemctl status <service>
```
Show the service status including:
- Active state (running/stopped/failed)
- PID and memory usage
- Last few log entries

### Start
```bash
systemctl start <service>
```
Start the service and verify it started successfully.

### Stop
```bash
systemctl stop <service>
```
Stop the service. Warn if the service is critical (httpd, mariadb, postfix).

### Restart
```bash
systemctl restart <service>
```
Restart the service and verify it came back up.

### Reload
```bash
systemctl reload <service>
```
Reload configuration without stopping the service. Note: not all services support reload.

### Enable
```bash
systemctl enable <service>
```
Enable the service to start on boot.

### Disable
```bash
systemctl disable <service>
```
Disable the service from starting on boot.

### Logs
```bash
journalctl -u <service> --no-pager -n 50
```
Show the last 50 log entries for the service.

## PHP-FPM Version Handling

For PHP-FPM, determine the version:
- If user specifies a version (e.g., "php 8.1"), use `php-fpm81`
- If no version specified, show all PHP-FPM versions: `systemctl list-units | grep php-fpm`
- Service name format: `php-fpmXX` (e.g., php-fpm74, php-fpm81)

## CSF Firewall Special Handling

CSF uses its own commands:
- Start: `csf -s` or `csf -e` (enable)
- Stop: `csf -x` (disable) or `csf -f` (flush)
- Restart: `csf -r`
- Status: `csf -t` (show temporary blocks)

## Output Format

Present service information clearly:

```
=== [Service Name] ===
Status: [running/stopped/failed]
PID: [pid]
Memory: [memory usage]
Uptime: [uptime]

Recent Logs:
[timestamp] [message]
[timestamp] [message]
```

## Safety Checks

Before stopping or restarting critical services:
- **httpd/nginx**: Warn that websites will be unavailable
- **mariadb**: Warn that database connections will drop
- **postfix**: Warn that email delivery will pause
- **named**: Warn that DNS resolution may fail
- **cwpsrv**: Warn that CWP panel will be inaccessible

Always confirm with the user before stopping critical services unless the user explicitly requests it.
