---
description: Optimize CWP server performance for Apache, Nginx, PHP, MySQL, caching, and compression
argument-hint: <component>
allowed-tools: Bash, Read, Write, Edit, Grep
---

# CWP Performance Optimization Command

You are optimizing performance on a CWP server. Determine the component from `$1` and apply optimizations.

## Arguments

- `$1` — Component: `all`, `apache`, `nginx`, `php`, `mysql`, `caching`, `compression`

## Step 1: Baseline Measurement

Before making changes, capture baseline metrics:
- Load average: `uptime`
- Memory usage: `free -h`
- Disk I/O: `iostat -x 1 3` (if available)
- Current Apache/Nginx connections: `ss -s`
- MySQL slow queries: `mysql -e "SHOW GLOBAL STATUS LIKE 'Slow_queries'"`

## Step 2: Optimize Component

### apache
- Read the current Apache config: `httpd -V` and review `/etc/httpd/conf/httpd.conf`.
- Optimize MPM settings based on available RAM:
  - For servers with <2GB RAM: Use `mpm_prefork` with `MaxRequestWorkers 150`.
  - For servers with >2GB RAM: Switch to `mpm_event` with `MaxRequestWorkers 500`, `ThreadsPerChild 25`.
- Enable `KeepAlive` with `MaxKeepAliveRequests 100` and `KeepAliveTimeout 5`.
- Disable unnecessary modules: list loaded modules with `httpd -M` and comment out unused ones in config.
- Enable mod_deflate for compression (see compression section).
- Restart Apache and verify.

### nginx
- Read the current Nginx config: `nginx -T`.
- Optimize worker settings: `worker_processes auto`, `worker_connections 1024`.
- Enable `sendfile on`, `tcp_nopush on`, `tcp_nodelay on`.
- Tune `keepalive_timeout 65` and `keepalive_requests 1000`.
- Configure upstream buffers: `proxy_buffer_size 128k`, `proxy_buffers 4 256k`.
- Enable gzip compression (see compression section).
- Reload Nginx and verify.

### php
- Read the active `php.ini`: `php --ini`.
- Optimize settings based on available RAM:
  - `memory_limit = 256M` (adjust per server RAM)
  - `max_execution_time = 30`
  - `max_input_time = 60`
  - `post_max_size = 64M`
  - `upload_max_filesize = 64M`
  - `max_input_vars = 3000`
- Enable and tune OPcache:
  - `opcache.enable = 1`
  - `opcache.memory_consumption = 128`
  - `opcache.interned_strings_buffer = 16`
  - `opcache.max_accelerated_files = 10000`
  - `opcache.revalidate_freq = 60`
- Disable unnecessary functions in `disable_functions`.
- Restart PHP-FPM.

### mysql
- Read the current MySQL config: `cat /etc/my.cnf`.
- Tune InnoDB settings based on available RAM:
  - `innodb_buffer_pool_size = 50% of RAM` (for dedicated DB servers) or `25% of RAM` (for shared servers)
  - `innodb_log_file_size = 256M`
  - `innodb_flush_log_at_trx_commit = 2`
  - `innodb_flush_method = O_DIRECT`
- Tune query cache (if MySQL < 8.0):
  - `query_cache_type = 1`
  - `query_cache_size = 64M`
- Set `max_connections = 150` (adjust based on usage).
- Enable slow query log: `slow_query_log = 1`, `long_query_time = 2`.
- Optimize all tables: `mysqlcheck --all-databases --optimize`.
- Restart MariaDB/MySQL.

### caching
- Check if a caching solution is available: Varnish, Redis, Memcached.
- **Varnish**: Install if not present. Configure port 80 as Varnish, Apache/Nginx on backend port. Set appropriate TTLs.
- **Redis**: Install if not present. Configure for session storage and object caching. Set `maxmemory` and `maxmemory-policy`.
- **Memcached**: Install if not present. Configure with appropriate memory allocation.
- Enable OPcache (see PHP section).
- Configure browser caching in Apache/Nginx with appropriate `Cache-Control` headers.

### compression
- **Apache**: Enable `mod_deflate` and `mod_brotli`. Add compression rules for HTML, CSS, JS, JSON, XML, fonts.
- **Nginx**: Enable `gzip on`, `gzip_vary on`, `gzip_proxied any`, `gzip_comp_level 6`, and set `gzip_types` for common MIME types.
- Enable Brotli compression if the module is available.
- Verify compression is working: `curl -H "Accept-Encoding: gzip" -I <url>`.

### all
- Run all optimizations in order: apache (or nginx, whichever is active), php, mysql, caching, compression.
- Capture metrics after all changes.
- Compare before/after metrics.

## Step 3: Report

Display a summary of changes made and their impact. Include before/after metrics where applicable. Log all optimization actions to `/var/log/cwp/optimize.log`.
