# Apache Configuration Reference

## CWP Apache Installation

CWP installs Apache from source at `/usr/local/apache/`.

```
Binary:    /usr/local/apache/bin/httpd
Config:    /usr/local/apache/conf/httpd.conf
Modules:   /usr/local/apache/modules/
Logs:      /usr/local/apache/logs/
```

---

## Main httpd.conf Structure

CWP generates `httpd.conf` automatically. Key sections:

```apache
ServerRoot "/usr/local/apache"
Listen 80
Listen 443

# MPM Configuration
<IfModule mpm_prefork_module>
    StartServers             5
    MinSpareServers          5
    MaxSpareServers         10
    MaxRequestWorkers      256
    MaxConnectionsPerChild   0
</IfModule>

# When using PHP-FPM (recommended)
<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadsPerChild         25
    MaxRequestWorkers      400
    MaxConnectionsPerChild   0
</IfModule>

# Module loading
LoadModule rewrite_module modules/mod_rewrite.so
LoadModule ssl_module modules/mod_ssl.so
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
LoadModule deflate_module modules/mod_deflate.so
LoadModule headers_module modules/mod_headers.so
LoadModule expires_module modules/mod_expires.so

# Includes
Include /usr/local/apache/conf/extra/*.conf
Include /usr/local/apache/conf/users/*.conf
Include /usr/local/apache/conf.d/*.conf
```

---

## Virtual Host Configuration

Per-user vhost files are stored at:
```
/usr/local/apache/conf/users/{username}.conf
```

### Standard VHost

```apache
<VirtualHost *:80>
    ServerName domain.com
    ServerAlias www.domain.com
    DocumentRoot /home/{username}/public_html

    <Directory /home/{username}/public_html>
        AllowOverride All
        Options -Indexes +FollowSymLinks
        Require all granted
    </Directory>

    # Logging
    ErrorLog /usr/local/apache/logs/{username}_error.log
    CustomLog /usr/local/apache/logs/{username}_access.log combined
</VirtualHost>
```

### SSL VHost

```apache
<VirtualHost *:443>
    ServerName domain.com
    ServerAlias www.domain.com
    DocumentRoot /home/{username}/public_html

    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/domain.com.crt
    SSLCertificateKeyFile /etc/pki/tls/private/domain.com.key
    SSLCertificateChainFile /etc/pki/tls/certs/domain.com.ca-bundle

    <Directory /home/{username}/public_html>
        AllowOverride All
        Options -Indexes +FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
```

---

## PHP-FPM Proxy (mod_proxy_fcgi)

When CWP uses PHP-FPM, Apache proxies PHP requests:

```apache
# Global PHP-FPM proxy
<FilesMatch \.php$>
    SetHandler "proxy:unix:/opt/alt/php{version}/usr/var//run/{username}.sock|fcgi://localhost"
</FilesMatch>
```

Per-user socket path:
```
/opt/alt/php{version}/usr/var/running/{username}.sock
```

### Alternative: Proxy via TCP

```apache
<FilesMatch \.php$>
    SetHandler "proxy:fcgi://127.0.0.1:90{version}"
</FilesMatch>
```

---

## mod_rewrite

mod_rewrite is enabled by default. Common `.htaccess` patterns:

```apache
# Force HTTPS
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]

# Remove www
RewriteCond %{HTTP_HOST} ^www\.(.*)$ [NC]
RewriteRule ^(.*)$ https://%1/$1 [R=301,L]

# WordPress pretty permalinks
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]

# Protect wp-config.php
<Files wp-config.php>
    Order Allow,Deny
    Deny from all
</Files>
```

---

## Security Headers

CWP can add security headers via `/usr/local/apache/conf.d/security.conf`:

```apache
Header always set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-XSS-Protection "1; mode=block"
Header always set Referrer-Policy "strict-origin-when-cross-origin"
Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains" env=HTTPS
```

---

## Compression (mod_deflate)

```apache
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml
    AddOutputFilterByType DEFLATE text/css text/javascript
    AddOutputFilterByType DEFLATE application/javascript application/json
    AddOutputFilterByType DEFLATE application/xml application/xhtml+xml
    AddOutputFilterByType DEFLATE image/svg+xml
    AddOutputFilterByType DEFLATE font/ttf font/otf font/woff
</IfModule>
```

---

## Caching (mod_expires)

```apache
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType text/css "access plus 1 month"
    ExpiresByType application/javascript "access plus 1 month"
    ExpiresByType application/pdf "access plus 1 month"
    ExpiresByType text/html "access plus 0 seconds"
</IfModule>
```

---

## Performance MPM Tuning

### mpm_prefork (for mod_php compatibility)
```apache
<IfModule mpm_prefork_module>
    StartServers             5
    MinSpareServers          5
    MaxSpareServers         10
    MaxRequestWorkers      150
    MaxConnectionsPerChild 1000
</IfModule>
```

### mpm_event (recommended with PHP-FPM)
```apache
<IfModule mpm_event_module>
    StartServers             3
    MinSpareThreads         75
    MaxSpareThreads        250
    ThreadsPerChild         25
    MaxRequestWorkers      400
    MaxConnectionsPerChild 10000
</IfModule>
```

---

## Common Directives

### Disable directory listing
```apache
Options -Indexes
```

### Protect .htaccess
```apache
<Files .htaccess>
    Order Allow,Deny
    Deny from all
</Files>
```

### Custom error pages
```apache
ErrorDocument 404 /404.html
ErrorDocument 500 /500.html
```

### Block specific IPs
```apache
<RequireAll>
    Require all granted
    Require not ip 192.168.1.100
</RequireAll>
```

---

## Log Rotation

CWP configures logrotate for Apache:
```
/usr/local/apache/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 root root
    postrotate
        /usr/local/apache/bin/httpd -k graceful
    endscript
}
```

---

## Rebuilding Apache Configs

After manual edits, rebuild:
```bash
/scripts/rebuild_httpd
/scripts/rebuild_vhosts
systemctl restart httpd
```

Or via CWP admin: **WebServer Settings > WebServers Conf > Rebuild Apache Config**
