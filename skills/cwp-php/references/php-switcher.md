# PHP Switcher Reference

## Overview

PHP Switcher is CWP's built-in tool for compiling and selecting the system-wide default PHP version. Unlike PHP Selector (which allows per-user/per-folder versions), PHP Switcher sets one PHP version for the entire server.

---

## How PHP Switcher Works

PHP Switcher compiles PHP from source and installs it to:
```
/usr/local/php{version}/
```

For example:
- `/usr/local/php74/` - PHP 7.4
- `/usr/local/php80/` - PHP 8.0
- `/usr/local/php81/` - PHP 8.1
- `/usr/local/php82/` - PHP 8.2
- `/usr/local/php83/` - PHP 8.3

---

## Accessing PHP Switcher

### Via CWP Admin Panel

Navigate to: **PHP Settings > PHP Switcher**

### Via CLI

```bash
# Check current PHP version
/usr/local/bin/php -v

# List compiled PHP versions
ls -la /usr/local/php*/bin/php

# Switch the system-wide PHP version via CWP Admin panel:
# PHP Settings > PHP Version Switcher > Select version > Click "Select"
# (No reliable CLI script exists for switching -- always use the admin panel)
```

---

## Compiling a New PHP Version

### Via Admin Panel

1. Go to **PHP Settings > PHP Switcher**
2. Select the PHP version from the dropdown
3. Choose the compiler options:
   - **PHP Extensions** - Select modules to compile
   - **Architecture** - x86_64 (default)
4. Click "Compile" and wait (can take 15-30 minutes)

### Compilation Options

CWP compiles PHP with these common flags:

```bash
./configure \
    --prefix=/usr/local/php{version} \
    --with-config-file-path=/usr/local/php{version}/lib \
    --with-config-file-scan-dir=/usr/local/php{version}/lib/php.d \
    --enable-fpm \
    --with-fpm-user=nobody \
    --with-fpm-group=nobody \
    --enable-mbstring \
    --enable-zip \
    --enable-bcmath \
    --enable-calendar \
    --enable-ftp \
    --enable-gd \
    --enable-intl \
    --enable-pcntl \
    --enable-soap \
    --enable-sockets \
    --with-curl \
    --with-gettext \
    --with-gmp \
    --with-imap \
    --with-imap-ssl \
    --with-kerberos \
    --with-libxml \
    --with-mysqli \
    --with-openssl \
    --with-pdo-mysql \
    --with-pear \
    --with-webp \
    --with-jpeg \
    --with-freetype \
    --with-xsl \
    --with-zlib
```

---

## Selecting the Default PHP Version

### Via Admin Panel

1. Go to **PHP Settings > PHP Switcher**
2. Click "Select" next to the desired compiled version
3. CWP will update:
   - The `/usr/local/bin/php` symlink
   - Apache/Nginx PHP-FPM configuration
   - All user PHP-FPM pools

### Via CLI

> **Note:** The primary way to switch the system PHP version is through the CWP Admin
> panel at **PHP Settings > PHP Version Switcher**. The CLI script name varies between
> CWP versions and is not always available.

```bash
# Check current PHP version
/usr/local/bin/php -v

# List compiled PHP versions
ls -la /usr/local/php*/bin/php

# Switch via admin panel:
# Navigate to PHP Settings > PHP Version Switcher > Select version > Click "Select"
```

### What Gets Updated

When switching PHP versions, CWP modifies:

| File/Path                                    | Change                              |
|----------------------------------------------|-------------------------------------|
| `/usr/local/bin/php`                         | Symlink to new PHP binary           |
| `/usr/local/apache/conf/httpd.conf`          | PHP-FPM handler paths               |
| `/etc/nginx/vhosts/*.conf`                   | FastCGI socket paths                |
| `/opt/alt/php{ver}/etc/php-fpm.d/*.conf`     | FPM pool configs (if using FPM)     |
| CWP panel PHP binary                         | `/usr/local/cwp/php/bin/php` (kept) |

---

## PHP Extensions

### Common Extensions (Compiled by Default)

| Extension   | Purpose                          |
|-------------|----------------------------------|
| curl        | HTTP client                      |
| gd          | Image processing                 |
| intl        | Internationalization             |
| mbstring    | Multi-byte strings               |
| mysqli      | MySQL improved                   |
| openssl     | SSL/TLS support                  |
| pdo_mysql   | PDO MySQL driver                 |
| soap        | SOAP protocol                    |
| xml         | XML parsing                      |
| zip         | ZIP archive handling             |
| bcmath      | Arbitrary precision math         |
| calendar    | Calendar functions               |
| exif        | EXIF metadata                    |
| ftp         | FTP client                       |
| gettext     | Gettext translation              |
| imap        | IMAP email protocol              |
| sockets     | Low-level socket interface       |
| xsl         | XSL transformations              |

### Adding Extensions After Compilation

If an extension was not compiled, you may need to recompile PHP or use `pecl`:

```bash
# Using pecl
/usr/local/php{version}/bin/pecl install {extension}

# Add to php.ini
echo "extension={extension}.so" >> /usr/local/php{version}/lib/php.ini
```

---

## PHP Configuration (php.ini)

**Path:** `/usr/local/php{version}/lib/php.ini`

### Key Settings

```ini
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
zlib.output_compression = Off

; Resource Limits
max_execution_time = 300
max_input_time = 60
memory_limit = 256M

; Error Handling
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
display_errors = Off
log_errors = On
error_log = /usr/local/php{version}/var/log/php_errors.log

; File Uploads
file_uploads = On
upload_max_filesize = 64M
post_max_size = 64M
max_file_uploads = 20

; Date
date.timezone = UTC

; Session
session.save_handler = files
session.save_path = /tmp
session.gc_maxlifetime = 1440

; MySQLi
mysqli.default_socket = /var/lib/mysql/mysql.sock

; OPcache
opcache.enable = 1
opcache.memory_consumption = 128
opcache.interned_strings_buffer = 8
opcache.max_accelerated_files = 10000
opcache.revalidate_freq = 2
opcache.save_comments = 1
```

---

## PHP-FPM Integration

PHP Switcher works with PHP-FPM. Each compiled PHP version includes its own FPM binary:

```
/usr/local/php{version}/sbin/php-fpm
/usr/local/php{version}/etc/php-fpm.conf
/usr/local/php{version}/etc/php-fpm.d/www.conf
```

### Default FPM Pool

```ini
[www]
user = nobody
group = nobody
listen = /usr/local/php{version}/var/run/php-fpm.sock
listen.owner = nobody
listen.group = nobody
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
pm.max_requests = 500
```

---

## Rebuilding PHP

If PHP compilation fails or you need different options:

1. Go to **PHP Settings > PHP Switcher**
2. Select the version
3. Adjust options
4. Click "Recompile"

### Manual Compilation

```bash
cd /usr/local/src
wget https://www.php.net/distributions/php-{version}.tar.gz
tar -xzf php-{version}.tar.gz
cd php-{version}
./configure --prefix=/usr/local/php{version} [options]
make -j$(nproc)
make install
```

---

## Troubleshooting

### PHP version shows wrong version
```bash
# Check symlink
ls -la /usr/local/bin/php

# Verify binary
/usr/local/php{version}/bin/php -v

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

### Compilation fails
```bash
# Check build dependencies
yum install gcc gcc-c++ make autoconf libtool bison re2c \
    libxml2-devel openssl-devel curl-devel libjpeg-devel \
    libpng-devel freetype-devel libicu-devel oniguruma-devel \
    libxslt-devel libzip-devel sqlite-devel

# Check compilation log
tail -100 /var/log/php-recompile.log
```

### Extensions not loading
```bash
# Check extension directory
ls /usr/local/php{version}/lib/php/extensions/

# Verify php.ini scan directory
php -i | grep "Scan this dir"

# Check for errors
php -m 2>&1 | grep -i error
```
