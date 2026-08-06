#!/bin/bash
# CWP Performance Optimization Script
# Applies common performance optimizations to CWP servers

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== CWP Performance Optimization ==="
echo "Date: $(date)"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} Please run as root"
    exit 1
fi

# Function to backup config file
backup_config() {
    local file="$1"
    if [ -f "$file" ]; then
        cp "$file" "${file}.bak.$(date +%Y%m%d%H%M%S)"
        echo "  Backed up: $file"
    fi
}

# Step 1: Optimize MariaDB
echo -e "${GREEN}[1/6]${NC} Optimizing MariaDB..."
if [ -f /etc/my.cnf.d/server.cnf ]; then
    backup_config /etc/my.cnf.d/server.cnf
    
    # Calculate innodb_buffer_pool_size (50% of RAM)
    TOTAL_RAM=$(free -m | awk '/^Mem:/ {print $2}')
    BUFFER_POOL=$((TOTAL_RAM / 2))
    
    cat > /etc/my.cnf.d/server.cnf << EOF
[mysqld]
# Performance optimizations
innodb_buffer_pool_size = ${BUFFER_POOL}M
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
innodb_flush_method = O_DIRECT
query_cache_type = 1
query_cache_size = 64M
tmp_table_size = 64M
max_heap_table_size = 64M
max_connections = 500
thread_cache_size = 16
table_open_cache = 4096

# Slow query logging
slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 2
EOF
    
    echo "  MariaDB optimized (buffer pool: ${BUFFER_POOL}M)"
fi

# Step 2: Optimize PHP-FPM
echo -e "${GREEN}[2/6]${NC} Optimizing PHP-FPM..."
for fpm_conf in /opt/alt/php-fpm*/usr/etc/php-fpm.d/users/*.conf; do
    if [ -f "$fpm_conf" ]; then
        backup_config "$fpm_conf"
        
        # Update PM settings
        sed -i 's/^pm = .*/pm = dynamic/' "$fpm_conf"
        sed -i 's/^pm.max_children = .*/pm.max_children = 10/' "$fpm_conf"
        sed -i 's/^pm.start_servers = .*/pm.start_servers = 3/' "$fpm_conf"
        sed -i 's/^pm.min_spare_servers = .*/pm.min_spare_servers = 2/' "$fpm_conf"
        sed -i 's/^pm.max_spare_servers = .*/pm.max_spare_servers = 5/' "$fpm_conf"
        sed -i 's/^pm.max_requests = .*/pm.max_requests = 500/' "$fpm_conf"
    fi
done
echo "  PHP-FPM pools optimized"

# Step 3: Enable OPcache
echo -e "${GREEN}[3/6]${NC} Enabling OPcache..."
for php_ini in /opt/alt/php*/usr/php/php.ini; do
    if [ -f "$php_ini" ]; then
        backup_config "$php_ini"
        
        # Enable OPcache
        sed -i 's/^;opcache.enable=.*/opcache.enable=1/' "$php_ini"
        sed -i 's/^;opcache.memory_consumption=.*/opcache.memory_consumption=256/' "$php_ini"
        sed -i 's/^;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=16/' "$php_ini"
        sed -i 's/^;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/' "$php_ini"
        sed -i 's/^;opcache.revalidate_freq=.*/opcache.revalidate_freq=2/' "$php_ini"
        sed -i 's/^;opcache.fast_shutdown=.*/opcache.fast_shutdown=1/' "$php_ini"
    fi
done
echo "  OPcache enabled"

# Step 4: Optimize Apache
echo -e "${GREEN}[4/6]${NC} Optimizing Apache..."
if [ -f /usr/local/apache/conf/httpd.conf ]; then
    backup_config /usr/local/apache/conf/httpd.conf
    echo "  Apache config backed up (manual tuning recommended)"
fi

# Step 5: Optimize Nginx
echo -e "${GREEN}[5/6]${NC} Optimizing Nginx..."
if [ -f /etc/nginx/nginx.conf ]; then
    backup_config /etc/nginx/nginx.conf
    echo "  Nginx config backed up (manual tuning recommended)"
fi

# Step 6: Enable gzip compression
echo -e "${GREEN}[6/6]${NC} Enabling gzip compression..."
if [ -f /etc/nginx/nginx.conf ]; then
    # Check if gzip is already configured
    if ! grep -q "gzip on" /etc/nginx/nginx.conf; then
        cat >> /etc/nginx/nginx.conf << 'EOF'

# gzip compression
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_comp_level 6;
gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
EOF
        echo "  gzip compression enabled in Nginx"
    else
        echo "  gzip already configured"
    fi
fi

# Restart services
echo ""
echo "=== Restarting Services ==="
systemctl restart mariadb 2>/dev/null && echo "  MariaDB restarted" || echo "  MariaDB restart failed"
systemctl restart nginx 2>/dev/null && echo "  Nginx restarted" || echo "  Nginx restart failed"
systemctl restart httpd 2>/dev/null && echo "  Apache restarted" || echo "  Apache restart failed"

# Restart PHP-FPM
for fpm in php-fpm*; do
    service "$fpm" restart 2>/dev/null && echo "  $fpm restarted"
done

echo ""
echo "=== Optimization Complete ==="
echo "Backups saved with .bak.TIMESTAMP extension"
echo ""
echo "Recommended follow-up:"
echo "1. Monitor server load: uptime"
echo "2. Check MariaDB slow queries: tail -f /var/log/mysql/slow.log"
echo "3. Verify OPcache: php -i | grep opcache.enable"
echo "4. Test website performance"
