# Common Issues Reference

## HTTP Error Codes

### 502 Bad Gateway

**Cause:** Web server cannot reach the backend (PHP-FPM, Apache, or application).

**Diagnosis:**
```bash
# Check PHP-FPM status
systemctl status php-fpm

# Check socket exists
ls -la /opt/alt/php*/usr/var/running/*.sock

# Check PHP-FPM error log
tail -50 /var/log/php-fpm/error.log

# Check Nginx error log
tail -50 /usr/local/nginx/logs/error.log
```

**Solutions:**
```bash
# Restart PHP-FPM
systemctl restart php-fpm

# Restart Nginx
systemctl restart nginx

# Rebuild PHP-FPM pools
/scripts/rebuild_php_fpm

# Check max_children
grep "max_children" /opt/alt/php*/etc/php-fpm.d/*.conf

# Increase if needed
# Edit pool config: pm.max_children = 50
```

---

### 503 Service Unavailable

**Cause:** Server overloaded, application crashed, or resource limits reached.

**Diagnosis:**
```bash
# Check server load
top
uptime

# Check memory
free -m

# Check disk space
df -h

# Check Apache/Nginx status
systemctl status httpd nginx

# Check error logs
tail -50 /usr/local/apache/logs/error_log
```

**Solutions:**
```bash
# Restart web server
systemctl restart httpd
systemctl restart nginx

# Kill runaway processes
ps aux | grep php | wc -l
pkill -u username php

# Increase PHP memory limit
# Edit php.ini: memory_limit = 512M

# Check .htaccess for errors
cat /home/user/public_html/.htaccess
```

---

### 504 Gateway Timeout

**Cause:** Backend took too long to respond.

**Diagnosis:**
```bash
# Check PHP execution time
php -i | grep max_execution_time

# Check slow queries
tail -50 /var/log/mariadb/slow.log

# Check Apache timeout
grep Timeout /usr/local/apache/conf/httpd.conf
```

**Solutions:**
```bash
# Increase PHP timeout
# Edit php.ini: max_execution_time = 300

# Increase Nginx timeout
# fastcgi_read_timeout 300s;

# Increase Apache timeout
# Timeout 300

# Optimize slow queries
mysql -u root -p -e "SHOW PROCESSLIST;"
```

---

### 403 Forbidden

**Cause:** Permission denied or IP blocked.

**Diagnosis:**
```bash
# Check file permissions
ls -la /home/user/public_html/

# Check .htaccess rules
cat /home/user/public_html/.htaccess

# Check CSF firewall
csf -g client_ip

# Check ModSecurity
grep "403" /var/log/httpd/modsec_audit.log
```

**Solutions:**
```bash
# Fix permissions
chmod 755 /home/user/public_html/
chmod 644 /home/user/public_html/index.html
chown -R user:user /home/user/public_html/

# Check directory listing
# In .htaccess: Options -Indexes

# Whitelist IP in CSF
csf -a client_ip "Whitelisted"

# Disable ModSecurity temporarily
# In httpd.conf: SecRuleEngine Off
```

---

### 404 Not Found

**Cause:** File does not exist or wrong document root.

**Diagnosis:**
```bash
# Check if file exists
ls -la /home/user/public_html/path/to/file

# Check document root in vhost
grep DocumentRoot /usr/local/apache/conf/users/user.conf

# Check DNS resolution
dig domain.com
```

**Solutions:**
```bash
# Upload missing file
# Or check if URL rewrite is correct
cat /home/user/public_html/.htaccess

# Verify domain points to correct directory
# Rebuild vhost
/scripts/rebuild_vhosts
```

---

## PHP Errors

### PHP Fatal Error: Allowed Memory Size Exhausted

```bash
# Check current memory limit
php -i | grep memory_limit

# Increase in php.ini
memory_limit = 512M

# Or in .htaccess
php_value memory_limit 512M

# Or in .user.ini
memory_limit = 512M
```

### PHP Warning: POST Content-Length Exceeds Limit

```bash
# Check limits
php -i | grep -E "upload_max_filesize|post_max_size"

# Increase in php.ini
upload_max_filesize = 128M
post_max_size = 128M
```

### PHP Fatal Error: Maximum Execution Time Exceeded

```bash
# Increase timeout
max_execution_time = 300

# Or in .htaccess
php_value max_execution_time 300
```

### PHP Parse Error: Syntax Error

```bash
# Check PHP version compatibility
php -v

# Test file syntax
php -l /home/user/public_html/script.php

# Check for short tags
grep "<?" /home/user/public_html/script.php
```

---

## Email Issues

### Emails Not Sending

```bash
# Check Postfix status
systemctl status postfix

# Check mail queue
postqueue -p

# Check mail log
tail -50 /var/log/maillog

# Check DNS MX records
dig MX domain.com

# Check IP blacklist
# https://mxtoolbox.com/blacklists.aspx
```

### Emails Not Receiving

```bash
# Check MX records
dig MX domain.com

# Check Postfix is listening
ss -tlnp | grep :25

# Check virtual domains
postconf virtual_mailbox_domains

# Check logs for specific address
grep "user@domain.com" /var/log/maillog
```

### Email Bouncing

```bash
# Check bounce message
grep "status=bounced" /var/log/maillog

# Common reasons:
# - Domain not found (DNS issue)
# - Mailbox full (quota exceeded)
# - IP blacklisted
# - SPF/DKIM/DMARC failure
```

### Email Marked as Spam

```bash
# Check SPF record
dig TXT domain.com | grep spf

# Check DKIM
dig TXT default._domainkey.domain.com

# Check DMARC
dig TXT _dmarc.domain.com

# Check IP reputation
# https://mxtoolbox.com/blacklists.aspx
```

---

## Database Issues

### Can't Connect to MySQL

```bash
# Check MySQL status
systemctl status mariadb

# Check socket
ls -la /var/lib/mysql/mysql.sock

# Check credentials
cat /root/.my.cnf

# Restart MySQL
systemctl restart mariadb
```

### Too Many Connections

```bash
# Check current connections
mysql -e "SHOW STATUS LIKE 'Threads_connected';"

# Kill sleeping connections
mysql -e "SELECT CONCAT('KILL ', id, ';') FROM information_schema.processlist WHERE command='Sleep' AND time > 300;"

# Increase max_connections
# In my.cnf: max_connections = 300
```

### Database Corruption

```bash
# Check tables
mysqlcheck -u root -p --all-databases --check

# Repair tables
mysqlcheck -u root -p --all-databases --repair

# Optimize tables
mysqlcheck -u root -p --all-databases --optimize
```

---

## DNS Issues

### Domain Not Resolving

```bash
# Check zone exists
rndc zonestatus domain.com

# Check zone file
named-checkzone domain.com /var/named/domain.com.db

# Check named is running
systemctl status named

# Test locally
dig @localhost domain.com
```

### Wrong IP Address

```bash
# Check A record
dig domain.com A

# Edit zone file
vi /var/named/domain.com.db

# Increment serial number
# Reload zone
rndc reload domain.com
```

### DNS Propagation Delay

```bash
# Check authoritative NS
dig domain.com NS

# Query each NS
dig @ns1.domain.com domain.com
dig @ns2.domain.com domain.com

# Check TTL
dig domain.com | grep -A1 "ANSWER SECTION"
```

---

## SSL Issues

### SSL Certificate Not Working

```bash
# Check certificate
openssl s_client -connect domain.com:443

# Verify certificate files
ls -la /etc/pki/tls/certs/domain.com.crt
ls -la /etc/pki/tls/private/domain.com.key

# Check certificate matches key
openssl x509 -noout -modulus -in /etc/pki/tls/certs/domain.com.crt | openssl md5
openssl rsa -noout -modulus -in /etc/pki/tls/private/domain.com.key | openssl md5
```

### AutoSSL Fails

```bash
# Check domain resolves to server
dig +short domain.com

# Check webroot accessible
curl http://domain.com/.well-known/acme-challenge/test

# Check Let's Encrypt logs
tail -50 /root/.acme.sh/acme.sh.log
```

---

## CSF Firewall Issues

### Locked Out of Server

```bash
# Via console/KVM
csf -f    # Flush all rules
csf -x    # Disable CSF

# Or edit /etc/csf/csf.conf
# TESTING = "1"
```

### Legitimate IP Blocked

```bash
# Check if blocked
csf -g IP_ADDRESS

# Remove from deny
csf -dr IP_ADDRESS

# Add to allow
csf -a IP_ADDRESS "Reason"
```

---

## Performance Issues

### High Server Load

```bash
# Check what's consuming CPU
top -c

# Check PHP processes
ps aux | grep php | wc -l

# Check MySQL queries
mysql -e "SHOW PROCESSLIST;"

# Check disk I/O
iostat -x 1
```

### Slow Website

```bash
# Check PHP OPcache
php -i | grep opcache

# Enable OPcache in php.ini
opcache.enable = 1

# Check MySQL slow queries
tail -50 /var/log/mariadb/slow.log

# Check web server configuration
# Use Nginx + PHP-FPM for better performance
```

### High Memory Usage

```bash
# Check memory usage
free -m

# Find memory-hungry processes
ps aux --sort=-%mem | head -20

# Check PHP-FPM max_children
grep "max_children" /opt/alt/php*/etc/php-fpm.d/*.conf

# Reduce if needed
# pm.max_children = 25
```

---

## Quick Diagnostic Commands

```bash
# System overview
top -bn1 | head -20
free -m
df -h
uptime

# Service status
systemctl status httpd nginx mysql postfix dovecot named php-fpm cwpsrv

# Recent errors
tail -20 /var/log/messages
tail -20 /usr/local/apache/logs/error_log
tail -20 /var/log/maillog

# Network connections
ss -tlnp
netstat -tlnp

# Process list
ps aux | head -30
```
