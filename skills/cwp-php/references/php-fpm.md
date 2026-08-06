# PHP-FPM Selector Reference

## Overview

PHP-FPM (FastCGI Process Manager) is the recommended PHP handler for CWP. The PHP-FPM Selector (CWP Pro feature) allows per-domain PHP-FPM pools with individual PHP versions, providing isolation between users.

---

## PHP-FPM Architecture

```
Client -> Web Server (Apache/Nginx)
  -> FastCGI -> PHP-FPM Pool (per user/domain)
    -> PHP Process -> Response
```

Each user gets an isolated FPM pool with:
- Dedicated socket file
- Separate process limits
- Individual php.ini settings
- Own error log

---

## Installation and Setup

### CWP Pro Feature

PHP-FPM Selector requires CWP Pro. Enable via:
**Admin Panel > PHP Settings > PHP-FPM Selector**

### PHP-FPM Binary Locations

| Source         | FPM Binary Path                                          |
|----------------|----------------------------------------------------------|
| PHP Switcher   | `/usr/local/php{version}/sbin/php-fpm`                   |
| PHP Selector   | `/opt/alt/php{version}/usr/sbin/php-fpm`                 |
| System PHP     | `/usr/sbin/php-fpm`                                      |

---

## Per-Domain Pool Configuration

### Pool Config Location

```
/opt/alt/php{version}/etc/php-fpm.d/{username}.conf
```

Or for PHP Switcher:
```
/usr/local/php{version}/etc/php-fpm.d/{username}.conf
```

### Example Pool Configuration

```ini
[{username}]
; User isolation
user = {username}
group = {username}

; Socket configuration
listen = /opt/alt/php{version}/usr/var/running/{username}.sock
listen.owner = {username}
listen.group = nobody
listen.mode = 0660

; Process management
pm = dynamic
pm.max_children = 25
pm.start_servers = 3
pm.min_spare_servers = 2
pm.max_spare_servers = 10
pm.max_requests = 500
pm.process_idle_timeout = 10s

; Resource limits
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[max_input_time] = 60
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[max_file_uploads] = 20

; Security
php_admin_value[open_basedir] = /home/{username}:/tmp:/usr/share/php
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen
php_admin_flag[allow_url_fopen] = on
php_admin_flag[display_errors] = off

; Logging
php_admin_value[error_log] = /home/{username}/logs/php_error.log
php_admin_flag[log_errors] = on

; Session
php_value[session.save_path] = /home/{username}/tmp
```

---

## Socket Configuration

### Socket File Paths

| Mode               | Socket Path                                              |
|--------------------|----------------------------------------------------------|
| PHP-FPM Selector   | `/opt/alt/php{version}/usr/var/running/{username}.sock`  |
| PHP Switcher FPM   | `/usr/local/php{version}/var/run/php-fpm.sock`           |
| System FPM         | `/var/run/php-fpm/php-fpm.sock`                          |

### Socket Permissions

```ini
listen.owner = {username}    # Socket file owner
listen.group = nobody        # Socket file group
listen.mode = 0660           # Socket permissions
```

The web server user (nobody, nginx, or apache) must have access to the socket.

### Verifying Sockets

```bash
# List all FPM sockets
ls -la /opt/alt/php*/usr/var/running/*.sock

# Check if socket is active
ss -xlnp | grep {username}.sock

# Test PHP-FPM connectivity
SCRIPT_FILENAME=/usr/share/php/info.php REQUEST_METHOD=GET \
    cgi-fcgi -bind -connect /opt/alt/php{version}/usr/var/running/{username}.sock
```

---

## Process Management Modes

### pm = dynamic (Recommended)

```ini
pm = dynamic
pm.max_children = 25         ; Maximum total processes
pm.start_servers = 3         ; Processes at startup
pm.min_spare_servers = 2     ; Minimum idle processes
pm.max_spare_servers = 10    ; Maximum idle processes
pm.max_requests = 500        ; Recycle after N requests (prevents memory leaks)
pm.process_idle_timeout = 10s ; Kill idle processes after timeout
```

### pm = static

```ini
pm = static
pm.max_children = 25         ; Always run this many processes
```

All processes are always running. Predictable memory usage but higher baseline.

### pm = ondemand

```ini
pm = ondemand
pm.max_children = 25         ; Maximum processes
pm.process_idle_timeout = 10s ; Spawn on demand, kill when idle
```

Lowest memory usage but slight latency on first request.

---

## Calculating max_children

```
max_children = Total RAM for PHP / Average PHP process size
```

| Memory per Process | 256M RAM | 512M RAM | 1G RAM | 2G RAM |
|--------------------|----------|----------|--------|--------|
| 32M                | 8        | 16       | 32     | 64     |
| 64M                | 4        | 8        | 16     | 32     |
| 128M               | 2        | 4        | 8      | 16     |

Check actual usage:
```bash
ps aux | grep php-fpm | awk '{sum+=$6} END {print sum/NR/1024 " MB per process"}'
```

---

## Apache Integration

### mod_proxy_fcgi

```apache
# Per-user PHP-FPM handler
<FilesMatch \.php$>
    SetHandler "proxy:unix:/opt/alt/php{version}/usr/var/running/{username}.sock|fcgi://localhost"
</FilesMatch>
```

### Global FPM Configuration

In `/usr/local/apache/conf/httpd.conf`:
```apache
# Load proxy modules
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
```

---

## Nginx Integration

### fastcgi_pass to socket

```nginx
location ~ \.php$ {
    fastcgi_pass unix:/opt/alt/php{version}/usr/var/running/{username}.sock;
    fastcgi_index index.php;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;

    # Timeouts
    fastcgi_connect_timeout 60s;
    fastcgi_send_timeout 300s;
    fastcgi_read_timeout 300s;

    # Buffers
    fastcgi_buffer_size 32k;
    fastcgi_buffers 16 16k;
    fastcgi_busy_buffers_size 64k;
}
```

---

## PHP-FPM Status Page

Enable the status page for monitoring:

```ini
; In pool config
pm.status_path = /fpm-status
ping.path = /fpm-ping
ping.response = pong
```

Nginx access:
```nginx
location ~ ^/(fpm-status|fpm-ping)$ {
    access_log off;
    allow 127.0.0.1;
    deny all;
    fastcgi_pass unix:/opt/alt/php{version}/usr/var/running/{username}.sock;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    include fastcgi_params;
}
```

```bash
curl http://localhost/fpm-status
# Output: pool, process manager, active/idle/total processes, etc.
```

---

## Rebuilding FPM Pools

CWP generates FPM pool configs automatically. To rebuild:

```bash
# Rebuild all pools
/scripts/rebuild_php_fpm

# Restart PHP-FPM (service name varies by version)
# Try common service names until one succeeds:
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    if systemctl is-active "$svc" 2>/dev/null; then
        systemctl restart "$svc"
        echo "Restarted $svc"
        break
    fi
done
```

> **Note:** PHP-FPM service naming varies between CWP versions. Common names include
> `php-fpm`, `php83-php-fpm`, `php-fpm83`, `php-fpm81`, `php-fpm74`. Use the
> detection loop above or check with `systemctl list-units --type=service | grep php-fpm`.

Or via CWP: **PHP Settings > PHP-FPM Selector > Rebuild Configs**

---

## Slow Log

Enable slow request logging for debugging:

```ini
slowlog = /home/{username}/logs/php-fpm-slow.log
request_slowlog_timeout = 5s
request_terminate_timeout = 300s
```

---

## Troubleshooting

### 502 Bad Gateway
```bash
# Check if FPM is running
systemctl status php-fpm

# Check socket exists
ls -la /opt/alt/php{version}/usr/var/running/{username}.sock

# Check FPM error log
tail -50 /opt/alt/php{version}/var/log/php-fpm-error.log

# Restart FPM (service name varies by version)
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    if systemctl is-active "$svc" 2>/dev/null; then
        systemctl restart "$svc"
        echo "Restarted $svc"
        break
    fi
done
```

### 504 Gateway Timeout
```bash
# Increase timeouts in FPM pool
request_terminate_timeout = 600

# Increase web server timeouts
# Nginx: fastcgi_read_timeout 600s;
# Apache: ProxyTimeout 600
```

### High memory usage
```bash
# Check process count
ps aux | grep php-fpm | wc -l

# Reduce max_children
# Reduce pm.max_requests to recycle processes more often
```

### Permission denied on socket
```bash
# Fix socket permissions
chown {username}:nobody /opt/alt/php{version}/usr/var/running/{username}.sock
chmod 660 /opt/alt/php{version}/usr/var/running/{username}.sock

# Verify web server user is in correct group
usermod -aG {username} nobody
```
