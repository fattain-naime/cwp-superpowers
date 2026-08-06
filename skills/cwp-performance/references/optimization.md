# General Optimization Reference

## MySQL/MariaDB Optimization

### InnoDB Buffer Pool

The most important MySQL setting for performance.

```ini
[mysqld]
# Set to 50-70% of available RAM
innodb_buffer_pool_size = 2G

# One instance per GB of buffer pool (max 64)
innodb_buffer_pool_instances = 2

# Load data at startup
innodb_buffer_pool_load_at_startup = ON
innodb_buffer_pool_dump_at_shutdown = ON
```

### InnoDB Log Settings

```ini
[mysqld]
# Log file size (25% of buffer pool)
innodb_log_file_size = 512M

# Log buffer
innodb_log_buffer_size = 64M

# Flush method (O_DIRECT for Linux)
innodb_flush_method = O_DIRECT

# Flush log at commit (1=ACID, 2=performance)
innodb_flush_log_at_trx_commit = 1
```

### Connection Settings

```ini
[mysqld]
# Max connections
max_connections = 200

# Wait timeout (close idle connections)
wait_timeout = 600
interactive_timeout = 600

# Thread cache
thread_cache_size = 16

# Max allowed packet
max_allowed_packet = 64M
```

### Table and Query Cache

```ini
[mysqld]
# Table cache
table_open_cache = 400
table_definition_cache = 400

# Temporary tables
tmp_table_size = 64M
max_heap_table_size = 64M

# Sort and join buffers
sort_buffer_size = 2M
read_buffer_size = 1M
read_rnd_buffer_size = 1M
join_buffer_size = 2M
```

### Slow Query Log

```ini
[mysqld]
slow_query_log = 1
slow_query_log_file = /var/log/mariadb/slow.log
long_query_time = 2
log_queries_not_using_indexes = 1
```

### Analyze Slow Queries

```bash
# View slow queries
mysqldumpslow -s t /var/log/mariadb/slow.log

# Top slow queries by count
mysqldumpslow -s c /var/log/mariadb/slow.log

# Show query plan
mysql -u root -p -e "EXPLAIN SELECT * FROM table WHERE condition;"
```

---

## PHP Optimization

### OPcache Settings

```ini
[opcache]
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.fast_shutdown = 1

# Production mode (disable timestamp checking)
opcache.validate_timestamps = 0
opcache.revalidate_freq = 0

# JIT (PHP 8.0+)
opcache.jit = 1255
opcache.jit_buffer_size = 128M
```

### PHP-FPM Optimization

```ini
[www]
; Process management
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500

; Timeouts
request_terminate_timeout = 300
request_slowlog_timeout = 5s
slowlog = /var/log/php-fpm/slow.log
```

### Memory Optimization

```ini
[PHP]
memory_limit = 256M

; Realpath cache
realpath_cache_size = 4096K
realpath_cache_ttl = 600
```

### Session Optimization

```ini
[PHP]
session.save_handler = redis
session.save_path = "tcp://127.0.0.1:6379?auth=password"

; Or files
session.save_handler = files
session.gc_maxlifetime = 1440
session.gc_probability = 1
session.gc_divisor = 100
```

---

## Nginx Optimization

### Worker Processes

```nginx
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}
```

### Connection Optimization

```nginx
http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    keepalive_requests 1000;

    # Buffers
    client_body_buffer_size 128k;
    client_max_body_size 128m;
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
}
```

### Static File Serving

```nginx
# Cache static files
location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    access_log off;
    log_not_found off;
}

# Disable access log for static files
location ~* \.(css|js|jpg|jpeg|png|gif|ico)$ {
    access_log off;
}
```

---

## Apache Optimization

### MPM Settings

```apache
# mpm_event (recommended with PHP-FPM)
<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadsPerChild         25
    MaxRequestWorkers      400
    MaxConnectionsPerChild 10000
</IfModule>
```

### KeepAlive

```apache
KeepAlive On
MaxKeepAliveRequests 1000
KeepAliveTimeout 5
```

### Compression

```apache
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml
    AddOutputFilterByType DEFLATE text/css text/javascript
    AddOutputFilterByType DEFLATE application/javascript application/json
</IfModule>
```

---

## File System Optimization

### Mount Options

```bash
# In /etc/fstab
/dev/sda1 / ext4 defaults,noatime,nodiratime 0 1

# noatime - Don't update access time
# nodiratime - Don't update directory access time
```

### I/O Scheduler

```bash
# Check current scheduler
cat /sys/block/sda/queue/scheduler

# Set to deadline for SSD
echo deadline > /sys/block/sda/queue/scheduler

# Set to noop for virtual machines
echo noop > /sys/block/sda/queue/scheduler
```

### Disk Cleanup

```bash
# Remove old logs
find /var/log -name "*.gz" -delete
journalctl --vacuum-time=7d

# Remove temp files
find /tmp -type f -mtime +7 -delete

# Remove old kernels
package-cleanup --oldkernels --count=2
```

---

## Kernel Optimization

### sysctl.conf

**Path:** `/etc/sysctl.conf`

```bash
# Network tuning
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

# File descriptors
fs.file-max = 2097152
fs.nr_open = 2097152

# Memory
vm.swappiness = 10
vm.overcommit_memory = 0
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Apply
sysctl -p
```

### File Descriptor Limits

```bash
# In /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535

# For nginx user
nginx soft nofile 65535
nginx hard nofile 65535
```

---

## Monitoring Performance

### Server Load

```bash
# Current load
uptime

# CPU usage
top -bn1 | head -20

# Per-CPU usage
mpstat -P ALL 1

# Process list by CPU
ps aux --sort=-%cpu | head -20
```

### Memory

```bash
# Memory overview
free -m

# Per-process memory
ps aux --sort=-%mem | head -20

# Detailed memory
vmstat 1 10
```

### Disk I/O

```bash
# I/O statistics
iostat -x 1

# Disk usage
df -h

# Inode usage
df -i
```

### Network

```bash
# Active connections
ss -s

# Network traffic
iftop

# Connection count by state
ss -ant | awk '{print $1}' | sort | uniq -c
```

---

## Performance Benchmarking

### Apache Bench

```bash
# Basic benchmark
ab -n 1000 -c 10 https://domain.com/

# With keep-alive
ab -n 1000 -c 10 -k https://domain.com/
```

### wrk

```bash
# Install
yum install wrk

# Benchmark
wrk -t12 -c400 -d30s https://domain.com/
```

### MySQL Benchmark

```bash
# Install sysbench
yum install sysbench

# Run benchmark
sysbench --test=oltp_read_write --mysql-user=root --mysql-password=pass prepare
sysbench --test=oltp_read_write --mysql-user=root --mysql-password=pass run
```

---

## Quick Optimization Checklist

### MySQL
- [ ] innodb_buffer_pool_size set to 50-70% of RAM
- [ ] Slow query log enabled
- [ ] Unused indexes identified and removed
- [ ] Connection pooling if needed

### PHP
- [ ] OPcache enabled
- [ ] JIT enabled (PHP 8+)
- [ ] Memory limit appropriate
- [ ] PHP-FPM tuned for workload

### Nginx/Apache
- [ ] Worker processes/connections optimized
- [ ] Keep-alive enabled
- [ ] Compression enabled
- [ ] Static file caching configured

### System
- [ ] sysctl optimized
- [ ] File descriptors increased
- [ ] Swap usage minimized
- [ ] Disk I/O scheduler optimized
