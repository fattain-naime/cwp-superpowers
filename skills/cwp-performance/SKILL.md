---
name: cwp-performance
description: This skill should be used when the user asks to "optimize server performance", "enable caching", "configure Varnish", "set up Redis", "configure Memcached", "enable OPcache", "enable Brotli compression", "tune PHP-FPM", "optimize database", "reduce server load", "improve page speed", "tune MySQL performance", or needs to optimize any aspect of CWP server performance.
version: 1.0.0
---

# CWP Performance Optimization

If the user provides specific details via "$ARGUMENTS", focus the optimization on that component. For example: `/cwp-pro-centos:cwp-performance optimize MySQL` will focus on database tuning.

Optimize server performance on CWP servers through caching, compression, PHP-FPM tuning, database optimization, and web server configuration.

## Performance Stack Overview

Use multiple caching and optimization layers:

| Layer | Options |
|---|---|
| Web Server | Apache, Nginx, Varnish |
| PHP Caching | OPcache, APC |
| Object Cache | Memcached, Redis |
| Compression | Brotli, gzip |
| Application | LiteSpeed Cache, WordPress caching plugins |

## Service Detection

Detect which caching services are installed:

```bash
# Redis
systemctl is-active redis 2>/dev/null && echo "Redis: active" || echo "Redis: not running"

# Memcached
systemctl is-active memcached 2>/dev/null && echo "Memcached: active" || echo "Memcached: not installed"

# Varnish
systemctl is-active varnish 2>/dev/null && echo "Varnish: active" || echo "Varnish: not running"

# OPcache (check PHP)
php -m 2>/dev/null | grep -i opcache && echo "OPcache: loaded" || echo "OPcache: not loaded"
```

## Caching Compatibility

| Cache | suPHP | PHP-FPM |
|---|---|---|
| Varnish | Yes | Yes |
| Memcached | Yes | Yes |
| Redis | Yes | Yes |
| OPcache | No | Yes |
| APC | No | Yes |

**Note:** OPcache and APC require PHP-FPM mode, not suPHP.

## Varnish Cache

### Configuration

| File | Purpose |
|---|---|
| `/etc/varnish/varnish.params` | Varnish parameters |
| `/etc/varnish/default.vcl` | VCL configuration |

### Stack Setup

Use Nginx -> Varnish -> Apache for maximum performance:

- Nginx (port 80/443): Handles SSL termination and static files
- Varnish (port 82 or 80): Caches dynamic content
- Apache (port 8181 or 8080): Processes PHP via mod_php or proxy

Detect actual Varnish port:

```bash
VARNISH_PORT=$(ss -tlnp | grep varnish | grep -oP ':\K\d+' | head -1)
echo "Varnish port: ${VARNISH_PORT:-unknown}"
```

### Clear Varnish Cache

```bash
/scripts/varnish_clear_cache
```

### Monitor Varnish

```bash
varnishstat
varnishlog
```

## Redis

### Installation

Install via CWP Admin -> Software -> Redis Manager or:

```bash
# Install Redis
yum install redis

# Start and enable
systemctl start redis
systemctl enable redis
```

### PHP Redis Extension

```bash
# Install PHP Redis extension
yum install php-redis

# Or via PECL
pecl install redis
```

### Redis Configuration

`/etc/redis/redis.conf`:

```
maxmemory 256mb
maxmemory-policy allkeys-lru
```

## Memcached

### Installation

```bash
# Install Memcached
yum install memcached

# Start and enable
systemctl start memcached
systemctl enable memcached
```

### PHP Memcached Extension

```bash
yum install php-memcached
```

### Memcached Configuration

`/etc/sysconfig/memcached`:

```
CACHESIZE="256"
OPTIONS="-l 127.0.0.1"
```

## OPcache

OPcache caches compiled PHP bytecode. Requires PHP-FPM mode.

### Configuration

Add to PHP configuration:

```ini
opcache.enable=1
opcache.memory_consumption=256
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
```

## Brotli Compression

Brotli provides better compression ratios than gzip.

### Nginx Brotli

```bash
cd /etc/nginx/modules
wget http://dl1.centos-webpanel.com/files/nginx/modules/nginx-brotli-modules.zip
unzip nginx-brotli-modules.zip
```

Add to `nginx.conf`:

```nginx
brotli on;
brotli_comp_level 6;
brotli_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
```

### Apache Brotli

```bash
yum install pcre-devel cmake -y
cd /usr/local/src
git clone https://github.com/google/brotli.git
cd brotli && git checkout v1.0
./configure-cmake && make && make install
```

## gzip Compression

### Nginx gzip

Add to `nginx.conf`:

```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
```

### Apache mod_deflate

Ensure mod_deflate is loaded and configure in `.htaccess` or Apache config.

## PHP-FPM Tuning

### Per-Pool Configuration

FPM user configs: `/opt/alt/php-fpm{VERSION}/usr/etc/php-fpm.d/users/USERNAME.conf`

Detect installed PHP-FPM version:

```bash
# Find installed PHP-FPM versions
ls /opt/alt/ | grep php-fpm

# Or check active PHP-FPM service
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    systemctl is-active "$svc" 2>/dev/null && echo "$svc is active"
done
```

Example pool configuration (replace `php-fpm83` with your installed version):

```ini
[USERNAME]
user = USERNAME
group = USERNAME
listen = /opt/alt/php-fpm83/usr/var/run/USERNAME.sock
pm = dynamic
pm.max_children = 10
pm.start_servers = 3
pm.min_spare_servers = 2
pm.max_spare_servers = 5
pm.max_requests = 500
```

### Global PHP Settings

Edit `/usr/local/php/php.ini`:

```ini
memory_limit = 256M
max_execution_time = 60
max_input_time = 60
upload_max_filesize = 64M
post_max_size = 64M
realpath_cache_size = 4096k
realpath_cache_ttl = 600
```

### Rebuild PHP-FPM

```bash
/scripts/phpfpm_rebuild_user_conf
```

## Database Optimization

For MariaDB/MySQL tuning, buffer configuration, and maintenance commands, see the **cwp-database** skill (`references/mysql.md`).

Key performance settings to configure in `/etc/my.cnf.d/server.cnf`:
- `innodb_buffer_pool_size` -- Set to 50-70% of available RAM
- `innodb_log_file_size` -- 256M recommended
- `max_connections` -- 500 for shared hosting

```bash
# Restart after changes
systemctl restart mariadb
```

## Web Server Optimization

### Apache MPM Configuration

Edit `/usr/local/apache/conf/httpd.conf` to use event MPM:

```apache
<IfModule mpm_event_module>
    StartServers 3
    MinSpareThreads 75
    MaxSpareThreads 250
    ThreadsPerChild 25
    MaxRequestWorkers 400
    MaxConnectionsPerChild 10000
</IfModule>
```

### Nginx Worker Configuration

```nginx
worker_processes auto;
worker_connections 1024;
keepalive_timeout 65;
client_max_body_size 64M;
```

## Monitoring

### Server Load Check

```bash
/scripts/cwp_monitor

# Quick checks
uptime
free -h
df -h
iostat 1 5
```

### Bandwidth Monitoring

```bash
/scripts/bandwidth_run
```

### Connection Monitoring

```bash
/scripts/net_show_connections
```

## Performance Checklist

1. Enable OPcache (requires PHP-FPM)
2. Configure Varnish for dynamic caching
3. Install Redis or Memcached for object caching
4. Enable Brotli or gzip compression
5. Tune PHP-FPM pool settings per domain
6. Optimize MariaDB buffer sizes
7. Use Nginx as front-end for static files
8. Enable HTTP/2 (via Nginx or Apache)
9. Set proper cache headers for static assets
10. Monitor and adjust based on metrics

## Troubleshooting

| Issue | Solution |
|---|---|
| High server load | Check `top`, identify resource-heavy processes |
| Slow page loads | Enable caching, check database queries |
| Memory exhaustion | Tune PHP-FPM max_children, increase swap |
| Database bottleneck | Enable slow query log, add indexes |
| Varnish not caching | Check VCL rules, verify cache headers |
| OPcache not working | Verify PHP-FPM mode, check opcache settings |

## Additional Resources

- `references/caching.md` -- Varnish, Redis, and Memcached caching setup
- `references/compression.md` -- Brotli and gzip compression configuration
- `references/optimization.md` -- PHP-FPM, MariaDB, and web server tuning
