# PHP Selector Reference

## Overview

PHP Selector (provided by CloudLinux's CageFS/alt-php or CWP's own implementation) allows users to select different PHP versions per directory using `.htaccess` directives. This is different from PHP Switcher which sets a server-wide default.

---

## PHP Selector vs PHP Switcher

| Feature              | PHP Switcher           | PHP Selector               |
|----------------------|------------------------|----------------------------|
| Scope                | Server-wide            | Per-user / per-directory   |
| Configuration        | Admin panel only       | User panel + .htaccess     |
| PHP installation     | Compiled from source   | Pre-built alt-php packages |
| Path                 | `/usr/local/php{ver}/` | `/opt/alt/php{ver}/`       |
| Requires CloudLinux  | No                     | Optional (alt-php)         |
| CWP Pro feature      | No                     | Yes (with alt-php)         |

---

## PHP Selector Installation

### Using CloudLinux alt-php

If CloudLinux is installed, alt-php packages provide PHP Selector:

```bash
yum install alt-php*
```

### Using CWP's Built-in PHP Selector

CWP installs alternate PHP versions to `/opt/alt/php{version}/`.

> **Note:** Installed PHP versions vary by server. The directory listing below shows
> commonly supported versions, not what is actually installed. To detect installed
> versions on a specific server, run:
>
> ```bash
> ls /opt/alt/ | grep php
> ```

Common version directories:
```
/opt/alt/php74/
/opt/alt/php80/
/opt/alt/php81/
/opt/alt/php82/
/opt/alt/php83/
```

---

## Directory Structure

```
/opt/alt/php{version}/
  usr/
    bin/
      php                  # PHP CLI binary
    etc/
      php.ini              # PHP configuration
      php.d/               # Module config files
    lib/
      php/
        extensions/        # PHP extensions
    var/
      run/
        {username}.sock    # Per-user FPM sockets
      log/
        php_errors.log     # Error log
```

---

## Setting PHP Version Per User

### Via CWP Admin Panel

1. Go to **User Accounts > List Accounts**
2. Click on the username
3. Select **PHP Settings > PHP Selector**
4. Choose the PHP version for the user
5. Save

### Via CLI

```bash
/scripts/php_select <username> <version>
# Example
/scripts/php_select john 8.1
```

---

## .htaccess Handlers

PHP Selector uses `.htaccess` directives to route PHP files to the correct handler.

### CGI Handler (Default)

```apache
# Use PHP 8.1 for this directory
<IfModule lsapi_module>
    lsapi_engine On
    lsapi_php_path /opt/alt/php81/usr/bin/php
</IfModule>

# Alternative CGI-style
AddHandler application/x-httpd-alt-php81 .php
```

### Common .htaccess Patterns

```apache
# Set PHP 8.1
AddHandler application/x-httpd-alt-php81 .php

# Set PHP 7.4
AddHandler application/x-httpd-alt-php74 .php

# Set PHP 8.2
AddHandler application/x-httpd-alt-php82 .php
```

### Per-Directory PHP Version

```apache
# Root uses PHP 8.1
AddHandler application/x-httpd-alt-php81 .php

# /legacy subdirectory uses PHP 7.4
<Directory "/home/user/public_html/legacy">
    AddHandler application/x-httpd-alt-php74 .php
</Directory>
```

---

## PHP Version Handlers

Each alt-php version registers as a handler.

> **Note:** The table below shows supported PHP versions. Not all versions will be
> installed on every server. Use `ls /opt/alt/ | grep php` to check which are present.

| PHP Version | Handler Name                          |
|-------------|---------------------------------------|
| 5.6         | `application/x-httpd-alt-php56`       |
| 7.0         | `application/x-httpd-alt-php70`       |
| 7.1         | `application/x-httpd-alt-php71`       |
| 7.2         | `application/x-httpd-alt-php72`       |
| 7.3         | `application/x-httpd-alt-php73`       |
| 7.4         | `application/x-httpd-alt-php74`       |
| 8.0         | `application/x-httpd-alt-php80`       |
| 8.1         | `application/x-httpd-alt-php81`       |
| 8.2         | `application/x-httpd-alt-php82`       |
| 8.3         | `application/x-httpd-alt-php83`       |

---

## PHP Selector Configuration

### php.ini for Each Version

Each alt-php version has its own php.ini:

```
/opt/alt/php{version}/usr/etc/php.ini
```

### User-Editable Settings

Users can modify these settings via CWP panel or `.user.ini`:

| Setting                  | Default    | Range           |
|--------------------------|------------|-----------------|
| display_errors           | Off        | On/Off          |
| error_reporting          | E_ALL      | See PHP docs    |
| file_uploads             | On         | On/Off          |
| max_execution_time       | 300        | 0-3600          |
| max_input_time           | 60         | 0-3600          |
| max_input_vars           | 1000       | 100-10000       |
| memory_limit             | 256M       | 32M-1024M       |
| post_max_size            | 64M        | 1M-1024M        |
| upload_max_filesize      | 64M        | 1M-1024M        |
| session.gc_maxlifetime   | 1440       | 60-86400        |
| allow_url_fopen          | On         | On/Off          |
| allow_url_include        | Off        | On/Off          |

### .user.ini

PHP-FPM reads `.user.ini` files in the document root:

```ini
; /home/user/public_html/.user.ini
display_errors = On
memory_limit = 512M
upload_max_filesize = 128M
post_max_size = 128M
max_execution_time = 600
```

Changes in `.user.ini` take effect after the `user_ini.cache_ttl` (default 300 seconds):
```bash
# Force refresh
systemctl restart php-fpm
```

---

## PHP Extensions Management

### Via CWP Panel

Users can enable/disable extensions for their selected PHP version:
**User Panel > PHP Settings > PHP Selector > Extensions**

### Common Extensions

| Extension     | Purpose                        |
|---------------|--------------------------------|
| bcmath        | Math functions                 |
| bz2           | Bzip2 compression              |
| calendar      | Calendar functions             |
| ctype         | Character type checking        |
| curl          | URL transfers                  |
| dom           | DOM parsing                    |
| exif          | Image metadata                 |
| fileinfo      | File type detection            |
| ftp           | FTP protocol                   |
| gd            | Image manipulation             |
| gettext       | Internationalization           |
| gmp           | GNU multiple precision         |
| iconv         | Character encoding             |
| imap          | IMAP protocol                  |
| intl          | ICU internationalization       |
| json          | JSON parsing                   |
| ldap          | LDAP protocol                  |
| mbstring      | Multi-byte strings             |
| mysqli        | MySQL improved                 |
| openssl       | SSL/TLS                        |
| pcntl         | Process control                |
| pdo           | PHP Data Objects               |
| pdo_mysql     | PDO MySQL driver               |
| pdo_sqlite    | PDO SQLite driver              |
| phar          | PHP Archive                    |
| posix         | POSIX functions                |
| session       | Session handling               |
| simplexml     | SimpleXML parsing              |
| soap          | SOAP protocol                  |
| sockets       | Socket interface               |
| sqlite3       | SQLite3 database               |
| tidy          | HTML tidying                   |
| tokenizer     | PHP tokenizer                  |
| xml           | XML parsing                    |
| xmlreader     | XML reader                     |
| xmlwriter     | XML writer                     |
| xsl           | XSL transformations            |
| zip           | ZIP archives                   |
| zlib          | Gzip compression               |

---

## Rebuilding PHP Selector

After changes, rebuild configs:

```bash
# Rebuild for all users
/scripts/rebuild_php_fpm

# Restart services
systemctl restart httpd
# or
systemctl restart nginx

# Restart PHP-FPM (service name varies by version)
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    if systemctl is-active "$svc" 2>/dev/null; then
        systemctl restart "$svc"
        echo "Restarted $svc"
        break
    fi
done
```

---

## Troubleshooting

### Wrong PHP version displayed in phpinfo()
- Check `.htaccess` handler directive
- Verify alt-php package is installed: `rpm -qa | grep alt-php`
- Check Apache is loading the handler module

### Extensions not available
- Check extension is installed: `ls /opt/alt/php{version}/usr/lib/php/extensions/`
- Verify extension is enabled in php.ini or php.d/

### 500 error after changing PHP version
- Check Apache error log: `tail -50 /usr/local/apache/logs/error_log`
- Verify the handler name is correct
- Ensure the alt-php binary exists: `ls -la /opt/alt/php{version}/usr/bin/php`

### .user.ini not taking effect
- Check `user_ini.cache_ttl` in php.ini (default 300 seconds)
- Verify file ownership: `chown {user}:{user} .user.ini`
- Restart PHP-FPM to force reload
