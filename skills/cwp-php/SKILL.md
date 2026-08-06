---
name: cwp-php
description: This skill should be used when the user asks to "switch PHP version", "install PHP extensions", "configure PHP-FPM", "use PHP Selector", "compile PHP", "fix PHP errors", "disable PHP functions", "set up open_basedir", "configure PHP Defender", "rebuild PHP-FPM", "set PHP upload limit", "manage multiple PHP versions", or needs to manage PHP versions, extensions, or configurations on a CWP server.
version: 1.0.0
---

# CWP PHP Management

Manage PHP versions, extensions, and configurations on CWP servers. Handle PHP Switcher, PHP Selector, PHP-FPM Selector, and security hardening for PHP.

## PHP Version Management Tools

Use three distinct tools for PHP version management:

| Tool | Behavior | Versions | Use Case |
|---|---|---|---|
| **PHP Switcher** | ONE default PHP for all users | 5.3-8.1+ | Simple setups |
| **PHP Selector** | Multiple versions via .htaccess | 4.4-8.1 | Per-folder version |
| **PHP-FPM Selector** | Per-domain via Domain Conf | 5.3-8.1+ | Per-domain (CWP Pro) |

### PHP Switcher

Sets a single default PHP version compiled from source for the entire server.

```bash
# Rebuild PHP via Switcher
/scripts/phpfpm_rebuild_user_conf

# Compile log location
tail -f /var/log/php-rebuild.log
```

### PHP Selector

Allows multiple PHP versions simultaneously. Users select versions per folder via `.htaccess`.

```apache
# Per-folder PHP version via .htaccess
AddHandler application/x-httpd-php56 .php    # PHP 5.6
AddHandler application/x-httpd-php74 .php    # PHP 7.4
AddHandler application/x-httpd-php81 .php    # PHP 8.1
```

### PHP-FPM Selector (CWP Pro)

Per-domain PHP-FPM configuration via the Domain Conf panel.

## Configuration Paths

| Component | Path |
|---|---|
| Main PHP php.ini | `/usr/local/php/php.ini` |
| Main PHP config dir | `/usr/local/php/php.d/` |
| Per-user php.ini | `/home/USERNAME/php.ini` |
| Selector PHP binaries | `/opt/alt/php{VERSION}/usr/bin/php` |
| Selector php.ini | `/opt/alt/php{VERSION}/usr/php/php.ini` |
| FPM user configs | `/opt/alt/php-fpm{VERSION}/usr/etc/php-fpm.d/users/USERNAME.conf` |
| PHP Switcher configs | `/usr/local/cwpsrv/htdocs/resources/conf/el{7,8}/php_switcher/` |
| Compile log | `/var/log/php-rebuild.log` |
| PHP Defender rules | `/usr/local/cwp/.conf/phpdefender/rules/` |

## PHP Version Matrix

| PHP Version | Switcher | Selector | FPM Selector |
|---|---|---|---|
| 5.3 - 5.6 | Yes | Yes | Yes |
| 7.0 - 7.4 | Yes | Yes | Yes |
| 8.0 - 8.1+ | Yes | Yes | Yes |
| 4.4 | No | Yes | No |

## Detect Installed PHP Versions

PHP versions vary by server. Detect what's actually installed:

```bash
# List all installed PHP Selector versions
ls /opt/alt/ | grep php

# Check system default PHP
php -v 2>/dev/null | head -1

# Check specific version (replace VERSION)
/opt/alt/php83/usr/bin/php -v 2>/dev/null | head -1

# List PHP-FPM services
systemctl list-units --type=service | grep php-fpm

# Find PHP-FPM service name (varies by version)
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    systemctl is-active "$svc" 2>/dev/null && echo "$svc is active" || true
done
```

## Common Operations

### Check Active PHP Version

```bash
# System default
php -v

# Detect installed Selector versions
for dir in /opt/alt/php*/usr/bin/php; do
    [ -f "$dir" ] && echo "$dir: $($dir -v 2>/dev/null | head -1)"
done

# Check loaded modules
php -m

# Check PHP configuration
php --ini
```

### Install PHP Extensions

Install extensions via:

1. CWP Admin -> PHP Selector -> Toggle extensions
2. Recompile PHP with desired flags
3. Install from Remi repository

```bash
# Install intl extension from Remi
yum install php-intl

# Install ImageMagick
/scripts/install_imagick
```

### Rebuild PHP-FPM

```bash
# Rebuild all PHP-FPM configurations
/scripts/phpfpm_rebuild_user_conf

# Restart PHP-FPM (service name varies by version)
# Try common service names:
for svc in php-fpm php83-php-fpm php-fpm83 php-fpm81 php-fpm74; do
    if systemctl is-active "$svc" 2>/dev/null; then
        systemctl restart "$svc"
        echo "Restarted $svc"
        break
    fi
done

# Or restart via CWP API
/scripts/phpfpm_service_manage restart
```

### Set Upload Limits

```bash
# Increase upload file size limit
/scripts/php_big_file_upload
```

Or manually edit php.ini:

```ini
upload_max_filesize = 256M
post_max_size = 256M
max_execution_time = 300
max_input_time = 300
memory_limit = 512M
```

## PHP Security

### Disable Dangerous Functions

Disable functions that enable remote code execution:

```bash
# PHP Switcher
echo "disable_functions = exec, system, popen, proc_open, shell_exec, passthru, show_source" > /usr/local/php/php.d/disabled_function.ini

# PHP-FPM Selector (restart required)
echo "disable_functions = exec, system, popen, proc_open, shell_exec, passthru, show_source" > /opt/alt/php-fpm{VERSION}/usr/php/php.d/disabled_function.ini
service php-fpm{VERSION} restart
```

### PHP open_basedir

Restrict file access per user to prevent directory traversal. For detailed open_basedir configuration and security hardening, see the **cwp-security** skill.

```bash
# Per-user (recommended)
echo "open_basedir = /home/USERNAME:/tmp:/var/tmp:/usr/local/lib/php/" > /home/USERNAME/php.ini
chown root.root /home/USERNAME/php.ini
chmod 555 /home/USERNAME/php.ini
```

### PHP Defender (Snuffleupagus)

Use Snuffleupagus as the PHP security module:

| Component | Path |
|---|---|
| Configuration | `/usr/local/cwp/.conf/phpdefender/` |
| Rules | `/usr/local/cwp/.conf/phpdefender/rules/` |
| Module | `/opt/alt/php-fpm{VERSION}/usr/lib/php/extensions/no-debug-non-zts-*/snuffleupagus.so` |

## Troubleshooting

| Issue | Solution |
|---|---|
| PHP installation failing | Need 1.5-2GB free RAM, verify DNS resolver |
| "No Loader installed" | `sh /scripts/update_ioncube` |
| intl extension missing | Recompile PHP with intl or install from Remi repo |
| suPHP 500 error | Fix ownership: `chown -R USER:USER /home/USER/public_html/*` |
| FPM socket errors | Rebuild configs: `/scripts/phpfpm_rebuild_user_conf` |
| Compilation timeout | Increase swap space, ensure 2GB+ RAM available |

### Diagnostic Commands

```bash
# Check PHP-FPM pools
ls /opt/alt/php-fpm*/usr/etc/php-fpm.d/users/

# View FPM error log
tail -f /opt/alt/php-fpm81/var/log/php-fpm-error.log

# Check PHP extensions per version
/opt/alt/php81/usr/bin/php -m

# Verify open_basedir
php -i | grep open_basedir

# Check disable_functions
php -i | grep "disable_functions"
```

## Additional Resources

- `references/php-switcher.md` -- PHP Switcher compilation and version management
- `references/php-selector.md` -- PHP Selector multi-version configuration
- `references/php-security.md` -- Complete PHP hardening guide
- `references/php-fpm.md` -- PHP-FPM pool configuration and tuning
