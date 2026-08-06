# PHP Security Reference

## Overview

CWP provides multiple layers of PHP security including `disable_functions`, `open_basedir`, and optional Snuffleupagus integration. These prevent common attack vectors on shared hosting servers.

---

## disable_functions

Restricts dangerous PHP functions that could be exploited.

### Recommended disable_functions

```ini
; In php.ini or pool config
disable_functions = exec,passthru,shell_exec,system,proc_open,popen,
    curl_exec,curl_multi_exec,parse_ini_file,show_source,
    pcntl_exec,pcntl_fork,pcntl_signal,pcntl_waitpid,
    dl,posix_kill,posix_mkfifo,posix_setuid,posix_setpgid,
    posix_setsid,posix_setgid,putenv
```

### Per-Function Explanation

| Function         | Risk                                      |
|------------------|-------------------------------------------|
| exec()           | Execute system commands                   |
| passthru()       | Execute and display raw output            |
| shell_exec()     | Execute via shell, return output          |
| system()         | Execute and display output                |
| proc_open()      | Process execution with I/O pipes          |
| popen()          | Open process file pointer                 |
| pcntl_exec()     | Execute program in process control        |
| dl()             | Load PHP extensions at runtime            |
| putenv()         | Set environment variables                 |
| posix_kill()     | Send signal to process                    |
| posix_setuid()   | Set process UID                           |

### Setting in Pool Config (PHP-FPM)

```ini
; /opt/alt/php{version}/etc/php-fpm.d/{username}.conf
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen
```

### Setting in .htaccess (Limited)

```apache
# Only works with mod_php or suPHP, NOT with PHP-FPM
php_value disable_functions "exec,passthru,shell_exec,system"
```

### Per-User Customization

Some scripts (e.g., Composer, WP-CLI) need exec(). Solutions:

1. **Use CLI PHP** (bypasses FPM restrictions):
   ```bash
   /usr/local/php81/bin/php composer.phar install
   ```

2. **Temporarily enable** in pool config, run task, then disable

3. **Use a separate pool** with relaxed restrictions for the specific user

---

## open_basedir

Restricts PHP file operations to specified directories.

### Configuration

```ini
; In php.ini or pool config
open_basedir = /home/{username}:/tmp:/usr/share/php:/var/lib/php/session
```

### What open_basedir Restricts

- `fopen()`, `file_get_contents()` - File reading
- `include()`, `require()` - File inclusion
- `move_uploaded_file()` - File uploads (must include upload temp dir)
- `realpath()` - Path resolution

### What open_basedir Does NOT Restrict

- MySQL connections
- Network connections (curl, sockets)
- Execution of binaries (if exec is not disabled)

### Per-User in FPM Pool

```ini
php_admin_value[open_basedir] = /home/{username}:/tmp:/usr/share/php:/var/lib/php/session
```

### Common Paths to Include

| Path                          | Purpose                    |
|-------------------------------|----------------------------|
| `/home/{username}`            | User home directory        |
| `/tmp`                        | Temporary files            |
| `/usr/share/php`              | System PHP libraries       |
| `/var/lib/php/session`        | PHP session storage        |
| `/usr/share/pear`             | PEAR libraries             |
| `/opt/alt/php{ver}/usr/share`| Alt-PHP shared files       |

### open_basedir Bypass Prevention

Ensure these are also restricted:
```ini
; Prevent reading outside basedir via symlinks
disable_functions = symlink,readlink,link

; Or use CageFS (CloudLinux) for full isolation
```

---

## Snuffleupagus

Snuffleupagus is a PHP module that provides security features beyond disable_functions and open_basedir.

### Installation

```bash
# Install via PECL
pecl install snuffleupagus

# Or compile from source
cd /usr/local/src
git clone https://github.com/nbs-system/snuffleupagus.git
cd snuffleupagus
phpize
./configure --enable-snuffleupagus
make && make install
```

### Enable in php.ini

```ini
extension=snuffleupagus.so
sp.configuration_file=/etc/snuffleupagus/rules.ini
```

### Configuration Rules

**Path:** `/etc/snuffleupagus/rules.ini`

#### Disable Dangerous Functions (Hard Kill)

```ini
sp.disable_function.function("exec").drop();
sp.disable_function.function("system").drop();
sp.disable_function.function("passthru").drop();
sp.disable_function.function("shell_exec").drop();
sp.disable_function.function("proc_open").drop();
sp.disable_function.function("popen").drop();
```

#### Prevent Code Execution in Uploads

```ini
; Block PHP execution in /uploads directory
sp.disable_function.function("eval").filename_r("~^/home/.*/uploads/.*~").drop();
sp.disable_function.function("assert").filename_r("~^/home/.*/uploads/.*~").drop();
sp.disable_function.function("preg_replace").filename_r("~^/home/.*/uploads/.*~").drop();
```

#### Cookie Protection

```ini
; Enforce cookie encryption
sp.global.cookie_encryption_key("CHANGE_ME_TO_A_RANDOM_STRING");
sp.global.cookie_encryption_algorithm("aes128-gcm");
```

#### Upload Protection

```ini
; Validate uploaded files
sp.upload_validation.upload_handler("/usr/local/bin/upload_validator.sh").drop();
```

#### Prevent PHP Object Injection

```ini
; Block unserialize on untrusted data
sp.disable_function.function("unserialize").value_r("~^[aOi]:~").drop();
```

#### Self-Rewriting Protection

```ini
; Prevent modifying PHP files via PHP
sp.disable_function.function("file_put_contents").param("filename").value_r("~\.php$~").drop();
sp.disable_function.function("rename").param("old").value_r("~\.php$~").drop();
sp.disable_function.function("unlink").value_r("~\.php$~").allow();
```

#### Environment Variable Protection

```ini
; Block putenv to prevent LD_PRELOAD attacks
sp.disable_function.function("putenv").drop();
```

---

## Additional PHP Security Measures

### Disable Dangerous php.ini Settings

```ini
; Disable URL includes
allow_url_include = Off

; Disable remote file opening (optional, may break some scripts)
allow_url_fopen = Off

; Hide PHP version
expose_php = Off

; Restrict file uploads (if not needed)
file_uploads = Off

; Limit upload size
upload_max_filesize = 10M
post_max_size = 10M
```

### Error Display in Production

```ini
; Never display errors to users
display_errors = Off
display_startup_errors = Off

; Log errors instead
log_errors = On
error_log = /home/{username}/logs/php_error.log

; Show minimal errors
error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT
```

### Session Security

```ini
; Use secure session settings
session.use_strict_mode = 1
session.use_only_cookies = 1
session.cookie_httponly = 1
session.cookie_secure = 1
session.cookie_samesite = "Lax"
session.gc_maxlifetime = 1440
session.entropy_length = 32
```

---

## CWP Panel PHP Security Settings

### Via Admin Panel

Navigate to: **PHP Settings > PHP Configuration**

You can set:
- `disable_functions` (global)
- `open_basedir` (per-user via PHP-FPM Selector)
- `memory_limit`
- `max_execution_time`
- `upload_max_filesize`

### Via PHP-FPM Selector (Per-User)

Navigate to: **PHP Settings > PHP-FPM Selector > Edit Pool**

Each user's FPM pool can have custom:
- `disable_functions`
- `open_basedir`
- `memory_limit`
- `max_execution_time`

---

## Web Application Firewall Integration

### ModSecurity + PHP

ModSecurity can detect and block PHP-based attacks:

```apache
# In ModSecurity rules
SecRule REQUEST_URI "\.php" \
    "id:1001,phase:1,deny,status:403,\
    msg:'PHP injection attempt',\
    severity:CRITICAL"
```

### CWP Recommended Security Stack

1. **PHP disable_functions** - Block dangerous functions
2. **open_basedir** - Restrict file access
3. **Snuffleupagus** - Advanced PHP hardening
4. **ModSecurity** - HTTP-level WAF
5. **CSF/LFD** - Server-level firewall and intrusion detection
6. **CageFS** (CloudLinux) - Full user isolation

---

## Audit and Monitoring

### Check PHP Security Settings

```bash
# Check current settings
php -i | grep "disable_functions"
php -i | grep "open_basedir"
php -i | grep "allow_url_include"

# Check FPM pool settings
php-fpm -tt 2>&1 | grep -A50 "[{username}]"
```

### Monitor for Suspicious Activity

```bash
# Watch PHP error logs
tail -f /home/*/logs/php_error.log | grep -i "exec\|system\|passthru"

# Check for open_basedir violations
grep "open_basedir" /home/*/logs/php_error.log

# Monitor upload directory for PHP files
find /home/*/public_html/uploads/ -name "*.php" -type f
```

### Regular Security Audit

```bash
# Find PHP files with dangerous functions
grep -rn "eval\|exec\|system\|passthru\|shell_exec" /home/*/public_html/ \
    --include="*.php" | grep -v "wp-content/cache"

# Check for suspicious .htaccess files
find /home/ -name ".htaccess" -exec grep -l "auto_prepend\|auto_append" {} \;
```
