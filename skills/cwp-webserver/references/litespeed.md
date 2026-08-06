# LiteSpeed Web Server Reference

## Overview

LiteSpeed Web Server (LSWS) is a high-performance, commercial web server available as a CWP add-on. It is a drop-in replacement for Apache with full `.htaccess` compatibility.

**Note:** LiteSpeed requires a license (free OpenLiteSpeed or paid LiteSpeed Enterprise).

---

## Installation in CWP

### Via CWP Admin Panel

Navigate to: **WebServer Settings > LiteSpeed > Install**

### Manual Installation

```bash
# Download and install
cd /usr/local/src
wget https://www.litespeedtech.com/packages/6.0/lsws-6.1.2-ent-x86_64-linux.tar.gz
tar -xzf lsws-6.1.2-ent-x86_64-linux.tar.gz
cd lsws-6.1.2
./install.sh
```

### OpenLiteSpeed (Free Alternative)

```bash
rpm -ivh http://rpms.litespeedtech.com/centos/litespeed-release.rpm
yum install openlitespeed
```

---

## Directory Structure

```
/usr/local/lsws/                    # LiteSpeed root
  bin/                              # Binaries
    lswsctrl                       # Control script
    lshttpd                        # Main binary
  conf/                             # Configuration
    httpd.conf                     # Main config (Apache-compatible)
    httpd-litespeed.conf           # LSWS native config
    vhosts/                        # Virtual host configs
    templates/                     # Config templates
  logs/                             # Log files
    error.log
    access.log
  admin/                            # WebAdmin console
    conf/                          # Admin config
  modules/                          # Loadable modules
  php/                              # Built-in PHP (if used)
```

---

## Configuration Files

### Main Configuration

**Path:** `/usr/local/lsws/conf/httpd.conf`

When integrated with CWP, LSWS reads Apache-format configuration files. The main config is similar to Apache's httpd.conf.

### LiteSpeed Native Config

**Path:** `/usr/local/lsws/conf/httpd-litespeed.conf`

```xml
serverName server.example.com
user nobody
group nobody
priority 0
enableLVE 0

listener Default {
    address *:80
    secure 0
}

listener SSL {
    address *:443
    secure 1
    keyFile /etc/pki/tls/private/server.key
    certFile /etc/pki/tls/certs/server.crt
}

virtualHost Template_cwp {
    vhRoot /home/$VH_NAME/public_html
    configFile /usr/local/apache/conf/users/$VH_NAME.conf
    allowSymbolLink 1
    enableScript 1
    restrained 0
}
```

---

## CWP Integration

### Switching to LiteSpeed

1. Install LiteSpeed via CWP panel
2. Go to **WebServer Settings > Select WebServer**
3. Choose "LiteSpeed"
4. CWP will stop Apache/Nginx and start LSWS

### Switching Away from LiteSpeed

1. Go to **WebServer Settings > Select WebServer**
2. Choose desired server (Apache, Nginx, etc.)
3. CWP will stop LSWS and start the selected server

---

## .htaccess Compatibility

LiteSpeed provides full Apache `.htaccess` compatibility, supporting:

### Supported Modules
- `mod_rewrite` - URL rewriting
- `mod_headers` - Header manipulation
- `mod_expires` - Cache control
- `mod_deflate` - Compression
- `mod_security` - WAF (limited)
- `mod_proxy` - Reverse proxy
- `mod_ssl` - SSL/TLS

### Common .htaccess Directives (All Supported)

```apache
# Rewrite rules
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# PHP settings
php_value upload_max_filesize 64M
php_value post_max_size 64M
php_value max_execution_time 300

# Security
Options -Indexes
ServerSignature Off

# Custom error pages
ErrorDocument 404 /404.html
ErrorDocument 500 /500.html
```

---

## PHP Handling

LiteSpeed supports multiple PHP handling methods:

### LSAPI (Recommended)

LiteSpeed's native PHP handler, faster than FastCGI:

```
/usr/local/lsws/lsphp{version}/bin/lsphp
```

### External App Configuration

```xml
extProcessor lsphp81 {
    type                    lsapi
    address                 uds://tmp/lshttpd/lsphp81.sock
    maxConns                35
    env                     PHP_LSAPI_CHILDREN=35
    initTimeout             60
    retryTimeout            0
    persistConn             1
    pcKeepAliveTimeout      1
    respBuffer              0
    autoStart               1
    path                    /usr/local/lsws/lsphp81/bin/lsphp
    backlog                 100
    instances               1
    priority                0
    memSoftLimit            2047M
    memHardLimit            2047M
    procSoftLimit           500
    procHardLimit           600
}
```

### PHP-FPM (Alternative)

LiteSpeed can also proxy to PHP-FPM pools:

```xml
extProcessor php_fpm {
    type                    proxy
    address                 uds://tmp/lshttpd/php-fpm.sock
    maxConns                100
    initTimeout             60
    retryTimeout            0
    persistConn             1
}
```

---

## WebAdmin Console

LiteSpeed provides a web-based admin interface.

### Default Access

```
URL:      https://server.example.com:7080
Username: admin
Password: (set during installation)
```

### Change Admin Password

```bash
/usr/local/lsws/admin/misc/admpass.sh
```

### Admin Features
- Real-time statistics
- Connection monitoring
- Cache management
- Configuration editor
- Log viewer
- Graceful restart

---

## Performance Tuning

### Worker Configuration

```xml
tuning {
    maxConnections          2000
    maxSSLConnections       1000
    connTimeout             300
    maxKeepAliveReq         1000
    keepAliveTimeout        5
    sendBufSize             0
    recvBufSize             0
    enableGzipCompress      1
    enableBrCompress        1
    compressMinSize         100
    compressMaxDataBufSize  614400
}
```

### Cache Configuration

```xml
cache {
    storage                 /dev/shm/lscache
    cacheMaxSize            1000M
    cacheMaxObjectSize      5120000
    cacheCheckInterval      60
    cacheByPass             0
    expireByAccess          0
    cacheReqCookie          0
    cacheRespCookie         0
    enableCache             1
    qsCache                 1
    reqCookieCache          1
    respCookieCache         1
    ignoreRespCacheControl  0
}
```

---

## LiteSpeed Cache Plugin

LiteSpeed offers a WordPress cache plugin (LSCache) that integrates directly with the web server.

### Install via WP-CLI
```bash
wp plugin install litespeed-cache --activate
```

### Features
- Page caching (server-level)
- Object caching
- Browser caching
- CSS/JS optimization
- Image optimization
- CDN integration
- Database optimization

---

## Graceful Restart

```bash
# Graceful restart (zero downtime)
/usr/local/lsws/bin/lswsctrl restart

# Hard restart
/usr/local/lsws/bin/lswsctrl stop
/usr/local/lsws/bin/lswsctrl start

# Reload configuration
/usr/local/lsws/bin/lswsctrl reload
```

---

## Log Files

| Log               | Path                                    |
|-------------------|-----------------------------------------|
| Error log         | `/usr/local/lsws/logs/error.log`        |
| Access log        | `/usr/local/lsws/logs/access.log`       |
| Stderr log        | `/usr/local/lsws/logs/stderr.log`       |
| Admin access log  | `/usr/local/lsws/admin/logs/access.log` |
| Admin error log   | `/usr/local/lsws/admin/logs/error.log`  |

---

## Common Issues

### LiteSpeed won't start
```bash
# Check if port 80 is in use
ss -tlnp | grep :80

# Check configuration
/usr/local/lsws/bin/lshttpd -t

# Check logs
tail -50 /usr/local/lsws/logs/error.log
```

### .htaccess not working
- Verify `AllowOverride All` is set in LSWS config
- Check that the .htaccess file is readable by the web server user
- Review LSWS error log for rewrite errors

### PHP not processing
- Verify LSAPI or PHP-FPM is configured
- Check socket file exists: `ls -la /tmp/lshttpd/`
- Review PHP error log

### Performance issues
- Enable LiteSpeed Cache
- Tune `maxConnections` and `maxKeepAliveReq`
- Enable Brotli compression
- Check connection limits in external app config
