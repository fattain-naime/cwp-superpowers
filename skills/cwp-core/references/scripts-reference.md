# CWP Scripts Reference

## Script Name Variations

Script names vary by CWP version (0.9.8.1178 vs 0.9.8.1244+). Always detect the correct script at runtime:

```bash
# Helper: resolve a script by trying multiple names
cwp_resolve_script() {
    local candidates=("$@")
    for path in "${candidates[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}
```

Common variations on AlmaLinux 8 / CWP 0.9.8.1244:

| Older Name               | Newer Name / Alternative                              |
|--------------------------|-------------------------------------------------------|
| `/scripts/backup_user`   | `/scripts/user_backup`                                |
| `/scripts/restore_user`  | CWP Admin panel or manual tar extraction              |
| `/scripts/generate_ssl`  | `/scripts/generate_hostname_ssl`                      |
| `/scripts/fix_permissions` | `/scripts/cwp_api account fix_perms USERNAME`       |
| `/scripts/rebuild_dns_zone` | `/scripts/cwp_api account rebuild_etc_named_conf` + `rebuild_var_named_all` |
| `/scripts/php_switch`    | CWP Admin panel (PHP Switcher / PHP Selector)         |
| `/scripts/create_mail_account` | CWP Admin panel or `/scripts/cwp_api`          |
| `/scripts/delete_mail_account` | CWP Admin panel or `/scripts/cwp_api`          |

**Detection pattern:**
```bash
# Backup: try user_backup first (newer), fallback to backup_user
if [ -f /scripts/user_backup ]; then
    sh /scripts/user_backup USERNAME
elif [ -f /scripts/backup_user ]; then
    sh /scripts/backup_user USERNAME
fi

# SSL: try generate_hostname_ssl first, fallback to generate_ssl
if [ -f /scripts/generate_hostname_ssl ]; then
    sh /scripts/generate_hostname_ssl
elif [ -f /scripts/generate_ssl ]; then
    sh /scripts/generate_ssl
fi
```

## Script Locations

All CWP scripts are located in `/usr/local/cwp/bin/` unless otherwise noted.

---

## System Scripts

### update_cwp
Updates CWP to the latest version.
```bash
sh /scripts/update_cwp
```
Performs: downloads latest CWP package, updates panel files, restarts services.

### restart_cwpsrv
Restarts the CWP internal web server.
```bash
sh /scripts/restart_cwpsrv
```

### restart_cwp
Full CWP service restart (all managed services).
```bash
sh /scripts/restart_cwp
```

### cwpsrv
Controls the cwpsrv service.
```bash
/usr/local/cwpsrv/sbin/cwpsrv -s {start|stop|restart|reload}
```

---

## User Account Scripts

### create_user
Creates a new hosting account.
```bash
sh /scripts/create_user <username> <password> <email> <plan> <domain>
```

### delete_user
Removes a hosting account and all associated data.
```bash
sh /scripts/delete_user <username>
```

### modify_user
Modifies account properties (quota, bandwidth, domains).
```bash
sh /scripts/modify_user <username> [options]
```

### list_users
Lists all CWP user accounts.
```bash
sh /scripts/list_users
```

### change_package
Changes the hosting plan for a user.
```bash
sh /scripts/change_package <username> <plan>
```

### change_password
Changes a user's panel password.
```bash
sh /scripts/change_password <username> <new_password>
```

### suspend_user
Suspends a user account.
```bash
sh /scripts/suspend_user <username> [reason]
```

### unsuspend_user
Unsuspends a user account.
```bash
sh /scripts/unsuspend_user <username>
```

---

## Domain Scripts

### add_domain
Adds a domain to a user account.
```bash
sh /scripts/add_domain <username> <domain>
```

### remove_domain
Removes a domain from a user account.
```bash
sh /scripts/remove_domain <username> <domain>
```

### add_subdomain
Adds a subdomain.
```bash
sh /scripts/add_subdomain <username> <subdomain> <parent_domain>
```

### add_parked_domain
Adds a parked (alias) domain.
```bash
sh /scripts/add_parked_domain <username> <domain> <target_domain>
```

---

## DNS Scripts

### dns_add_zone
Adds a DNS zone for a domain.
```bash
sh /scripts/dns_add_zone <domain>
```

### dns_delete_zone
Deletes a DNS zone.
```bash
sh /scripts/dns_delete_zone <domain>
```

### dns_add_record
Adds a DNS record to a zone.
```bash
sh /scripts/dns_add_record <domain> <type> <name> <value> <ttl> <priority>
```

### dns_delete_record
Deletes a DNS record.
```bash
sh /scripts/dns_delete_record <domain> <record_id>
```

### rebuild_dns (or via API)
Rebuilds all DNS zones from templates.
```bash
sh /scripts/rebuild_dns

# Alternatively, rebuild via CWP API (preferred on modern CWP):
/scripts/cwp_api account rebuild_etc_named_conf
/scripts/cwp_api account rebuild_var_named_all
```

---

## SSL/TLS Scripts

### install_acme
Installs or renews ACME/Let's Encrypt certificates.
```bash
sh /scripts/install_acme <domain>
```

### install_ssl
Installs a custom SSL certificate.
```bash
sh /scripts/install_ssl <domain> <cert_file> <key_file> <ca_file>
```

### generate_csr
Generates a Certificate Signing Request.
```bash
sh /scripts/generate_csr <domain>
```

### remove_ssl
Removes SSL configuration for a domain.
```bash
sh /scripts/remove_ssl <domain>
```

---

## Email Scripts

> **Note:** Email account management is primarily done via the CWP Admin panel or the CWP API (`/scripts/cwp_api mail ...`). Standalone email CLI scripts may not exist on all CWP versions.

### create_mailbox
Creates an email mailbox.
```bash
sh /scripts/create_mailbox <email> <password>
```

### delete_mailbox
Deletes an email mailbox.
```bash
sh /scripts/delete_mailbox <email>
```

### create_mailforward
Creates an email forwarder.
```bash
sh /scripts/create_mailforward <source_email> <target_email>
```

### add_autoresponder
Sets up an autoresponder for an email account.
```bash
sh /scripts/add_autoresponder <email> <subject> <message>
```

### rebuild_mail
Rebuilds mail configuration for all domains.
```bash
sh /scripts/rebuild_mail
```

---

## Database Scripts

### mysql_pwd_reset
Resets the MySQL root password.
```bash
sh /scripts/mysql_pwd_reset <new_password>
```

### create_database
Creates a new MySQL database.
```bash
sh /scripts/create_database <database_name>
```

### create_dbuser
Creates a MySQL database user.
```bash
sh /scripts/create_dbuser <username> <password>
```

### grant_database
Grants a user access to a database.
```bash
sh /scripts/grant_database <username> <database> <privileges>
```

---

## Web Server Scripts

### rebuild_httpd
Rebuilds Apache configuration files.
```bash
sh /scripts/rebuild_httpd
```

### rebuild_vhosts
Rebuilds virtual host configurations.
```bash
sh /scripts/rebuild_vhosts
```

### rebuild_nginx
Rebuilds Nginx configuration files.
```bash
sh /scripts/rebuild_nginx
```

### switch_webserver
Switches between web server modes.
```bash
sh /scripts/switch_webserver <mode>
# Modes: apache, nginx, nginx_reverse, varnish
```

---

## PHP Scripts

### php_switcher / php_select
Switches the default PHP version (PHP Switcher) or per-user PHP version (PHP Selector).
> **Note:** PHP switching is primarily done via the CWP Admin panel under **PHP Settings > PHP Switcher** or **PHP Settings > PHP Selector**. The CLI equivalents may not exist on all versions.
```bash
# These may or may not exist depending on CWP version:
sh /scripts/php_switcher <version>
sh /scripts/php_select <username> <version>
```

### compile_php
Compiles a new PHP version for PHP Switcher.
```bash
sh /scripts/compile_php <version>
```

### rebuild_php_fpm
Rebuilds PHP-FPM pool configurations.
```bash
sh /scripts/rebuild_php_fpm
```

---

## Backup Scripts

### user_backup (or backup_user on older CWP)
Backs up a single user account. Script name varies by CWP version.
```bash
# Dual-path: prefer user_backup, fallback to backup_user
if [ -f /scripts/user_backup ]; then
    sh /scripts/user_backup <username>
elif [ -f /scripts/backup_user ]; then
    sh /scripts/backup_user <username>
fi
```

### backup_all
Backs up all user accounts.
```bash
sh /scripts/backup_all
```

### restore_user (deprecated -- use CWP panel or manual tar extraction)
Restores a user from backup. There is no `/scripts/restore_user` on modern CWP. Use the CWP Admin panel under **Backup > Restore Backup**, or extract archives manually:
```bash
# Manual restore example:
tar -xzf /backup/daily/<username>/<username>.tar.gz -C /
gunzip -c /backup/daily/<username>/<username>_mysql.sql.gz | mysql -u root -p
```

### backup_generate_config
Generates backup configuration.
```bash
sh /scripts/backup_generate_config
```

---

## Migration Scripts

### cwp_import
Imports accounts from cPanel backups.
```bash
sh /scripts/cwp_import <backup_file>
```

### cwp_migrate
Migrates accounts from another CWP server.
```bash
sh /scripts/cwp_migrate <remote_ip> <remote_key>
```

### cwp_transfer
Transfers a single account between CWP servers.
```bash
sh /scripts/cwp_transfer <username> <remote_ip> <remote_port>
```

---

## Security Scripts

### csf_install
Installs or updates CSF firewall.
```bash
sh /scripts/csf_install
```

### modsec_install
Installs ModSecurity.
```bash
sh /scripts/modsec_install
```

### secure_mysql
Runs MySQL security script (removes test databases, sets root password).
```bash
sh /scripts/secure_mysql
```

### install_clamav
Installs ClamAV antivirus.
```bash
sh /scripts/install_clamav
```

---

## Utility Scripts

### genkey
Generates API key for CWP API access.
```bash
sh /scripts/genkey
```

### disk_usage
Shows disk usage per user.
```bash
sh /scripts/disk_usage
```

### memory_check
Displays memory usage summary.
```bash
sh /scripts/memory_check
```

### fix_perms (via API)
Fixes file permissions for a user. There is no standalone `/scripts/fix_permissions` on modern CWP.
```bash
/scripts/cwp_api account fix_perms <username>
```

### rebuild_all
Rebuilds all CWP configurations (DNS, web, mail).
```bash
sh /scripts/rebuild_all
```

---

## Scripts Directory Listing

The `/scripts/` path at root is a convenience alias. Most scripts resolve to `/usr/local/cwp/bin/` or are shell wrappers. Key wrapper scripts:

| Script Path                        | Purpose                           |
|------------------------------------|-----------------------------------|
| `/scripts/update_cwp`              | Update CWP                        |
| `/scripts/restart_cwpsrv`          | Restart panel server              |
| `/scripts/restart_cwp`             | Restart all services              |
| `/scripts/mysql_pwd_reset`         | Reset MySQL root password         |
| `/scripts/install_acme`            | Install Let's Encrypt certs       |
| `/scripts/genkey`                  | Generate API key                  |
| `/scripts/cwp_import`              | Import cPanel backup              |
| `/scripts/rebuild_httpd`           | Rebuild Apache configs            |
| `/scripts/rebuild_vhosts`          | Rebuild virtual hosts             |
| `/scripts/rebuild_dns`             | Rebuild DNS zones                 |
| `/scripts/rebuild_mail`            | Rebuild mail config               |
| `/scripts/user_backup`             | Backup single user (or `backup_user` on older CWP) |
| `/scripts/cwp_api account fix_perms` | Fix user file permissions       |
| `/scripts/cwp_api account rebuild_etc_named_conf` | Rebuild DNS named.conf |
| `/scripts/generate_hostname_ssl`   | Generate hostname SSL (or `generate_ssl` on older CWP) |

> **Note:** `/scripts/restore_user` does not exist on modern CWP. Use the CWP Admin panel (**Backup > Restore Backup**) or extract tar archives manually.
