# Roundcube Webmail Reference

## Overview

Roundcube is the default webmail client in CWP, providing browser-based access to email via IMAP.

---

## Installation

### Via CWP Admin Panel

Navigate to: **Email > Roundcube > Install**

### Manual Installation

```bash
# Download
cd /usr/local/src
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.6/roundcubemail-1.6.6.tar.gz
tar -xzf roundcubemail-1.6.6.tar.gz
mv roundcubemail-1.6.6 /usr/local/cwpsrv/var/services/roundcube

# Set permissions
chown -R nobody:nobody /usr/local/cwpsrv/var/services/roundcube
```

---

## Directory Structure

```
/usr/local/cwpsrv/var/services/roundcube/
  bin/                    # CLI tools
  config/                 # Configuration files
    config.php           # Main configuration
    defaults.inc.php     # Default settings
  logs/                   # Log files
  plugins/               # Plugins directory
  skins/                 # Themes/skins
  SQL/                   # Database schema files
  program/               # Core application code
  vendor/                # Composer dependencies
```

---

## Configuration

**Path:** `/usr/local/cwpsrv/var/services/roundcube/config/config.php`

### Main Settings

```php
<?php
$config = [];

// Database connection
$config['db_dsnw'] = 'mysql://roundcube:password@localhost/roundcubemail';

// IMAP settings
$config['default_host'] = 'ssl://localhost';
$config['default_port'] = 993;
$config['imap_auth_type'] = 'LOGIN';
$config['imap_cache'] = 'db';
$config['messages_cache'] = 'db';
$config['imap_force_caps'] = false;
$config['imap_force_lsub'] = false;

// SMTP settings
$config['smtp_server'] = 'tls://localhost';
$config['smtp_port'] = 587;
$config['smtp_user'] = '%u';
$config['smtp_pass'] = '%p';
$config['smtp_auth_type'] = 'LOGIN';
$config['smtp_helo_host'] = '';
$config['smtp_timeout'] = 30;

// General settings
$config['product_name'] = 'Webmail';
$config['support_url'] = '';
$config['skin'] = 'elastic';
$config['language'] = 'en_US';
$config['mime_types'] = '/etc/mime.types';
$config['zipdownload_selection'] = true;

// Session
$config['session_lifetime'] = 30;
$config['session_domain'] = '';
$config['session_name'] = 'roundcube_sessid';

// Security
$config['ip_check'] = true;
$config['referer_check'] = true;
$config['x_frame_options'] = 'sameorigin';
$config['des_key'] = 'rcmail-!24ByteDESkey*Str';
$config['cipher_method'] = 'AES-256-CBC';
$config['password_charset'] = 'UTF-8';

// Display
$config['display_next'] = true;
$config['min_refresh_interval'] = 60;
$config['max_message_size'] = 26214400; // 25MB

// Logging
$config['log_driver'] = 'file';
$config['log_date_format'] = 'd-M-Y H:i:s O';
$config['log_session_id'] = true;
$config['log_logins'] = true;
$config['log_logins_ip'] = true;
$config['log_ips'] = true;

// Plugins
$config['plugins'] = [
    'archive',
    'zipdownload',
    'managesieve',
    'newmail_notifier',
];
```

---

## Database Setup

### Create Database

```sql
CREATE DATABASE roundcubemail CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER 'roundcube'@'localhost' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON roundcubemail.* TO 'roundcube'@'localhost';
FLUSH PRIVILEGES;
```

### Import Schema

```bash
mysql -u roundcube -p roundcubemail < /usr/local/cwpsrv/var/services/roundcube/SQL/mysql.initial.sql
```

---

## Plugins

### Built-in Plugins

| Plugin          | Purpose                              |
|-----------------|--------------------------------------|
| archive         | Archive emails to folders            |
| zipdownload     | Download multiple emails as ZIP      |
| managesieve     | Sieve filter management              |
| newmail_notifier| Desktop notifications                |
| markasjunk      | Spam marking                         |
| emoticons       | Emoticon support                     |
| filesystem_attachments | Attach files from server     |

### Enable Plugins

In `config/config.php`:

```php
$config['plugins'] = [
    'archive',
    'zipdownload',
    'managesieve',
    'newmail_notifier',
    'markasjunk',
    'emoticons',
];
```

### Plugin Configuration

Each plugin may have its own config file in:
```
config/<plugin_name>.inc.php
```

### Sieve Plugin Config

```php
// config/managesieve.inc.php
$config['managesieve_host'] = 'localhost';
$config['managesieve_port'] = 4190;
$config['managesieve_auth_type'] = 'PLAIN';
$config['managesieve_default'] = '/etc/dovecot/sieve/default.sieve';
$config['managesieve_script_name'] = 'managesieve';
```

---

## Web Server Configuration

### Nginx Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name webmail.example.com;

    ssl_certificate /etc/letsencrypt/live/webmail.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/webmail.example.com/privkey.pem;

    root /usr/local/cwpsrv/var/services/roundcube;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/opt/alt/php81/usr/var/running/nobody.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\. {
        deny all;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
}
```

### Apache Configuration

```apache
<VirtualHost *:443>
    ServerName webmail.example.com
    DocumentRoot /usr/local/cwpsrv/var/services/roundcube

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/webmail.example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/webmail.example.com/privkey.pem

    <Directory /usr/local/cwpsrv/var/services/roundcube>
        AllowOverride All
        Options -Indexes +FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
```

---

## Access

### Default CWP URLs

- Admin Webmail: `https://server:2031/webmail/`
- User Webmail: `https://server:2083/webmail/`
- Direct: `https://server/webmail/` (if configured)

### CWP Webmail Redirect

CWP can redirect `webmail.domain.com` to Roundcube. Configure via:
**Admin Panel > Email > Webmail Client**

---

## Security Hardening

### .htaccess (Apache)

```apache
# Prevent direct access to config
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteRule ^config/ - [F,L]
    RewriteRule ^temp/ - [F,L]
    RewriteRule ^logs/ - [F,L]
</IfModule>

# Security headers
Header always set X-Frame-Options "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set X-XSS-Protection "1; mode=block"
```

### Nginx Security

```nginx
# Deny access to sensitive directories
location ~ ^/(config|temp|logs|SQL|bin|vendor)/ {
    deny all;
    return 404;
}
```

### PHP Settings

```ini
; Recommended php.ini for Roundcube
display_errors = Off
expose_php = Off
session.cookie_httponly = 1
session.cookie_secure = 1
session.use_strict_mode = 1
```

---

## Customization

### Custom Logo

Replace the logo file:
```
skins/elastic/images/roundcube_logo.png
```

Or set in config:
```php
$config['skin_logo'] = '/images/custom_logo.png';
```

### Custom Theme

1. Copy an existing skin to `skins/custom/`
2. Modify CSS/images
3. Set in config:
```php
$config['skin'] = 'custom';
```

### Localization

Language files in `localization/`:
```php
$config['language'] = 'en_US';
$config['language'] = 'de_DE';
$config['language'] = 'fr_FR';
```

Users can change their language in Settings > Preferences.

---

## Updates

### Update via CWP

Navigate to: **Email > Roundcube > Update**

### Manual Update

```bash
# Backup current installation
cp -r /usr/local/cwpsrv/var/services/roundcube /root/roundcube-backup

# Download new version
cd /usr/local/src
wget https://github.com/roundcube/roundcubemail/releases/download/1.6.x/roundcubemail-1.6.x.tar.gz
tar -xzf roundcubemail-1.6.x.tar.gz

# Copy new files (preserving config)
cp -r roundcubemail-1.6.x/* /usr/local/cwpsrv/var/services/roundcube/

# Restore config
cp /root/roundcube-backup/config/config.php /usr/local/cwpsrv/var/services/roundcube/config/

# Run update script
cd /usr/local/cwpsrv/var/services/roundcube
php bin/installto.sh /

# Fix permissions
chown -R nobody:nobody /usr/local/cwpsrv/var/services/roundcube
```

---

## Troubleshooting

### Login fails
```bash
# Check IMAP connection
openssl s_client -connect localhost:993

# Check Roundcube logs
tail -50 /usr/local/cwpsrv/var/services/roundcube/logs/errors.log

# Verify database connection
mysql -u roundcube -p roundcubemail -e "SELECT 1"
```

### Blank page / 500 error
```bash
# Check PHP error log
tail -50 /var/log/php_errors.log

# Check permissions
ls -la /usr/local/cwpsrv/var/services/roundcube/

# Verify PHP extensions
php -m | grep -E "mbstring|xml|json|gd|intl"
```

### Emails not sending
```bash
# Check SMTP settings in config
grep smtp /usr/local/cwpsrv/var/services/roundcube/config/config.php

# Check Postfix logs
tail -50 /var/log/maillog

# Test SMTP manually
telnet localhost 587
```

### Slow performance
```php
// Enable caching in config
$config['imap_cache'] = 'db';
$config['messages_cache'] = 'db';

// Check database size
mysqlcheck -u roundcube -p roundcubemail
```

### Plugin not loading
```bash
# Check plugin directory exists
ls /usr/local/cwpsrv/var/services/roundcube/plugins/

# Check plugin config
ls /usr/local/cwpsrv/var/services/roundcube/config/

# Check error logs
tail -50 /usr/local/cwpsrv/var/services/roundcube/logs/errors.log
```
