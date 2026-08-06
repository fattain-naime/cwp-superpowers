# Caching Reference

## Overview

CWP supports multiple caching layers: Varnish (HTTP reverse proxy), Redis (object cache), Memcached (memory cache), OPcache (PHP bytecode), and APC (legacy PHP cache).

---

## Caching Layers

```
Client Request
  |
  +-- Varnish (HTTP cache, port 82)
  |     |
  |     +-- Nginx (static files)
  |           |
  |           +-- Apache/PHP-FPM (dynamic)
  |                 |
  |                 +-- OPcache (PHP bytecode)
  |                 +-- Redis/Memcached (object cache)
  |                       |
  |                       +-- MySQL (query cache)
```

> **Note:** The Varnish port varies by CWP version. Current CWP defaults to port 82; older configurations may use port 80. Detect the actual port: `VARNISH_PORT=$(ss -tlnp | grep varnish | grep -oP ':\K\d+' | head -1)`

---

## Varnish Cache

### Installation/Enablement

**Admin Panel > WebServer Settings > Varnish Cache**

### Configuration

**Path:** `/etc/varnish/default.vcl`

See `varnish.md` in cwp-webserver references for full VCL configuration.

### Key Settings

```vcl
# Cache TTL
sub vcl_backend_response {
    # Static files: 30 days
    if (bereq.url ~ "\.(css|js|jpg|png|gif|ico)$") {
        set beresp.ttl = 30d;
    }
    # HTML: 10 minutes
    if (beresp.http.Content-Type ~ "text/html") {
        set beresp.ttl = 10m;
    }
}
```

### Varnish Statistics

```bash
varnishstat
varnishtop -i URL
varnishlog -g request
```

### Cache Purge

```bash
# Purge all
varnishadm "ban req.url ~ ."

# Purge specific URL
varnishadm "ban req.url == /page"

# Purge by domain
varnishadm "ban req.http.host == domain.com"
```

---

## Redis

### Installation

```bash
# Install Redis
yum install redis

# Start and enable
systemctl start redis
systemctl enable redis
```

### Configuration

**Path:** `/etc/redis/redis.conf`

```ini
# Network
bind 127.0.0.1
port 6379
protected-mode yes

# Memory
maxmemory 256mb
maxmemory-policy allkeys-lru

# Persistence
save 900 1
save 300 10
save 60 10000

# Logging
loglevel notice
logfile /var/log/redis/redis.log

# Security
requirepass your_redis_password
```

### PHP Redis Extension

```bash
# Install via PECL
pecl install redis

# Add to php.ini
echo "extension=redis.so" >> /usr/local/php81/lib/php.ini
```

### WordPress Redis Object Cache

```php
// wp-config.php
define('WP_REDIS_HOST', '127.0.0.1');
define('WP_REDIS_PORT', 6379);
define('WP_REDIS_PASSWORD', 'your_redis_password');
define('WP_REDIS_DATABASE', 0);
define('WP_REDIS_PREFIX', 'wp_');
```

### Redis Commands

```bash
# Connect
redis-cli

# Auth
AUTH your_redis_password

# Info
INFO
INFO memory
INFO stats

# Monitor commands
MONITOR

# Check keys
KEYS *

# Flush cache
FLUSHALL
FLUSHDB

# Check memory usage
INFO memory | grep used_memory_human
```

---

## Memcached

### Installation

```bash
# Install Memcached
yum install memcached

# Start and enable
systemctl start memcached
systemctl enable memcached
```

### Configuration

**Path:** `/etc/sysconfig/memcached`

```bash
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="256"
OPTIONS="-l 127.0.0.1"
```

### PHP Memcached Extension

```bash
# Install via PECL
pecl install memcached

# Add to php.ini
echo "extension=memcached.so" >> /usr/local/php81/lib/php.ini
```

### Memcached Commands

```bash
# Connect
telnet localhost 11211

# Stats
stats

# Flush
flush_all

# Check slabs
stats slabs

# Check items
stats items
```

---

## OPcache

OPcache is the recommended PHP bytecode cache, built into PHP 5.5+.

### Configuration

**Path:** `/usr/local/php{version}/lib/php.ini`

```ini
[opcache]
opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=128
opcache.interned_strings_buffer=8
opcache.max_accelerated_files=10000
opcache.revalidate_freq=2
opcache.fast_shutdown=1
opcache.save_comments=1
opcache.validate_timestamps=1
opcache.enable_file_override=0

# For production (disable timestamp checking)
opcache.validate_timestamps=0
opcache.revalidate_freq=0

# JIT (PHP 8.0+)
opcache.jit=1255
opcache.jit_buffer_size=128M
```

### OPcache Status Script

```php
<?php
// /home/user/public_html/opcache-status.php
// Remove after checking!

if (function_exists('opcache_get_status')) {
    $status = opcache_get_status();
    echo "OPcache enabled: " . ($status['opcache_enabled'] ? 'Yes' : 'No') . "\n";
    echo "Memory used: " . round($status['memory_usage']['used_memory']/1024/1024, 2) . " MB\n";
    echo "Memory free: " . round($status['memory_usage']['free_memory']/1024/1024, 2) . " MB\n";
    echo "Cached scripts: " . $status['opcache_statistics']['num_cached_scripts'] . "\n";
    echo "Hits: " . $status['opcache_statistics']['hits'] . "\n";
    echo "Misses: " . $status['opcache_statistics']['misses'] . "\n";
    echo "Hit rate: " . round($status['opcache_statistics']['opcache_hit_rate'], 2) . "%\n";
}
```

### OPcache Reset

```php
<?php
// Reset OPcache for specific file
opcache_invalidate('/path/to/file.php', true);

// Reset all OPcache
opcache_reset();
```

---

## APC (Alternative PHP Cache)

APCu is the user-cache portion of APC, compatible with PHP 7+/8+.

### Installation

```bash
# Install APCu
pecl install apcu

# Add to php.ini
echo "extension=apcu.so" >> /usr/local/php81/lib/php.ini
echo "apc.enabled=1" >> /usr/local/php81/lib/php.ini
echo "apc.shm_size=128M" >> /usr/local/php81/lib/php.ini
```

### Configuration

```ini
[apcu]
apc.enabled=1
apc.shm_size=128M
apc.ttl=7200
apc.enable_cli=0
apc.gc_ttl=3600
apc.entries_hint=4096
apc.slam_defense=1
```

---

## Application-Level Caching

### WordPress Caching

**Recommended plugins:**
- LiteSpeed Cache (if using LiteSpeed)
- WP Super Cache
- W3 Total Cache
- Redis Object Cache

### W3 Total Cache Configuration

```php
// wp-config.php
define('W3TC_EDGE_MODE', 1);

// Enable object cache
define('W3TC_OBJECT_CACHE', true);
define('W3TC_OBJECT_CACHE_ENGINE', 'redis');
```

---

## Caching Best Practices

### Layer Your Caches

1. **Varnish** - Cache full HTTP responses
2. **OPcache** - Cache PHP bytecode
3. **Redis/Memcached** - Cache database queries and objects
4. **Browser cache** - Static assets with long TTL

### TTL Recommendations

| Content Type        | TTL                  |
|---------------------|----------------------|
| Static assets       | 1 year               |
| CSS/JS              | 1 month              |
| HTML pages          | 10 minutes           |
| API responses       | 5 minutes            |
| Database queries    | 1-5 minutes          |
| Session data        | 24 hours             |

### Cache Invalidation

- Invalidate on content update
- Use versioned filenames for static assets
- Set appropriate cache-control headers
- Implement cache purging hooks

---

## Monitoring Cache Performance

### Varnish

```bash
varnishstat -1 | grep -E "MAIN.cache_hit|MAIN.cache_miss"
```

### Redis

```bash
redis-cli INFO stats | grep -E "keyspace_hits|keyspace_misses"
```

### OPcache

```bash
php -r "var_dump(opcache_get_status()['opcache_statistics']['opcache_hit_rate']);"
```

### Memcached

```bash
echo "stats" | nc localhost 11211 | grep -E "get_hits|get_misses"
```

---

## Troubleshooting

### Varnish not caching

```bash
# Check VCL for pass conditions
grep "return (pass)" /etc/varnish/default.vcl

# Check for cookies
varnishlog -g request -i RxHeader | grep Cookie

# Verify backend is healthy
varnishlog -g raw -i Backend_health
```

### Redis high memory usage

```bash
redis-cli INFO memory
redis-cli --bigkeys
```

### OPcache not working

```bash
php -i | grep opcache
php -m | grep opcache
```

### Cache stampede

Implement locking:
```php
// Redis lock example
$lock = $redis->set('lock:key', 1, ['NX', 'EX' => 300]);
if ($lock) {
    // Generate cache
    $redis->del('lock:key');
}
```
