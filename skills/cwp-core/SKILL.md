---
name: cwp-core
description: This skill should be used when the user asks to "install CWP", "configure CWP", "check CWP version", "update CWP", "manage CWP services", "understand CWP architecture", "access CWP panel", "reset CWP password", "fix CWP installation", "manage CWP users", "manage CWP packages", or needs foundational knowledge about Control Web Panel structure, configuration files, system requirements, or core operations.
version: 1.0.0
---

# CWP Core -- Foundational Knowledge

Provide foundational knowledge for managing Control Web Panel (CWP7) servers. Reference this skill for installation, configuration, service management, and structural understanding of CWP.

If the user provides specific details via "$ARGUMENTS", focus the response on that topic. For example: `/cwp-pro-centos:cwp-core check CWP version` will focus on version checking commands.

## Overview

Control Web Panel (CWP) is a free Linux web hosting control panel for managing dedicated and VPS servers. CWP7 (version 0.9.8.1244) is the current active release. The recommended operating system is AlmaLinux 8.10.

| Property | Value |
|---|---|
| Current Version | CWP7 (0.9.8.1244) |
| Recommended OS | AlmaLinux 8.10 |
| Company | LINANTO LLC, Georgia/Tbilisi |
| Pricing | Free (CWPpro from $1.49/month) |
| Architecture | Modular PHP-based with API, hooks, custom modules |

## Panel Access Ports

| Port | Protocol | Service |
|---|---|---|
| 2030 | HTTP | CWP Admin Panel |
| 2031 | HTTPS | CWP Admin Panel (SSL) |
| 2082 | HTTP | CWP User Panel |
| 2083 | HTTPS | CWP User Panel (SSL) |
| 2086/2087 | HTTP/HTTPS | CWP Admin (alternative) |
| 2095/2096 | HTTP/HTTPS | Roundcube Webmail |
| 2304 | HTTPS | CWP API |

## System Requirements

| Resource | Minimum | Recommended |
|---|---|---|
| RAM | 2 GB (64-bit) | 4 GB+ (8 GB for AlmaLinux 9) |
| CPU | 1 core | 2+ cores |
| Storage | 20 GB | 50 GB+ |
| Network | Static IP | Dedicated IP |

**Note:** PHP compilation requires 1.5-2 GB available RAM.

## Supported Operating Systems

| OS | Version | Status |
|---|---|---|
| AlmaLinux | 8.10 | Recommended -- Most stable |
| AlmaLinux | 9.x | Beta -- Missing features |
| CentOS | 7 | EOL -- Legacy only |
| Rocky Linux | 8/9 | Compatible |
| Oracle Linux | 7/8/9 | Compatible |

## Installation

Perform installation on a fresh, clean OS with a static IP and FQDN hostname.

```bash
# Set hostname
hostnamectl set-hostname srv.example.com

# Install prerequisites
dnf install epel-release -y && dnf -y install wget && dnf -y update

# Reboot after prerequisites
reboot

# Install CWP (select the appropriate OS version)
cd /usr/local/src
wget http://centos-webpanel.com/cwp-el8-latest && sh cwp-el8-latest

# Optional arguments: --restart yes --phpfpm 7.3 --softaculous yes
```

**Important:** CWP has no uninstaller. Removing CWP requires a full OS reinstall.

## Key Directory Structure

| Path | Purpose |
|---|---|
| `/usr/local/cwp/` | CWP installation root |
| `/usr/local/cwpsrv/` | CWP web server (cwpsrv) |
| `/usr/local/cwpsrv/htdocs/resources/admin/` | Admin panel PHP files |
| `/usr/local/cwpsrv/htdocs/resources/admin/modules/` | Admin modules |
| `/usr/local/cwpsrv/htdocs/resources/admin/hooks/` | Action hooks |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php` | DB connection config |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/3rdparty.php` | Menu configuration |
| `/usr/local/cwp/.conf/` | CWP configuration directory |
| `/usr/local/apache/` | Apache installation |
| `/etc/nginx/` | Nginx configuration |
| `/etc/varnish/` | Varnish configuration |
| `/scripts/` | CWP management scripts |
| `/backup/` | Default backup location |

## Core Configuration Files

| File | Purpose |
|---|---|
| `/usr/local/cwp/.conf/cwp.conf` | Main CWP configuration |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php` | Database connection |
| `/etc/my.cnf.d/server.cnf` | MariaDB configuration |
| `/root/.my.cnf` | MySQL root credentials |
| `/etc/ssh/sshd_config` | SSH daemon configuration |
| `/etc/csf/csf.conf` | CSF Firewall configuration |

## CWP Service Management

```bash
# Restart CWP service
/scripts/restart_cwpsrv

# Check CWP version
/scripts/cwp_version

# Update CWP
/scripts/update_cwp

# Restart CWP panel daemon
systemctl restart cwpsrv
```

## Essential Management Scripts

### Script Resolution

CWP script names vary across versions. Use this resolution pattern to find the correct script:

```bash
# Resolve script path (checks multiple possible locations)
cwp_resolve_script() {
    local script_name="$1"
    local candidates=(
        "/scripts/${script_name}"
        "/scripts/${script_name//-/_}"      # hyphen to underscore
        "/scripts/${script_name//_/-}"      # underscore to hyphen
    )
    for path in "${candidates[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    return 1
}

# Common script name variations:
# Backup:    user_backup OR backup_user
# SSL:       generate_hostname_ssl OR generate_ssl
# ACME:      install_acme OR renew_lets_encrypt
# Fix perms: /scripts/cwp_api account fix_perms OR /scripts/fix_permissions
```

### Account Management

```bash
/scripts/cwp_api account remove_user USERNAME
/scripts/cwp_api account suspend_user USERNAME
/scripts/cwp_api account unsuspend_user USERNAME
/scripts/cwp_api account fix_perms USERNAME
/scripts/cwp_api account list_domains USERNAME
/scripts/cwp_api account update_diskquota_all
/scripts/cwp_api account update_limits_all
/scripts/cwp_api account mail_fix_permissions
/scripts/cwp_api account rebuild_etc_named_conf
/scripts/cwp_api account rebuild_var_named_all
```

### System Utilities

```bash
# These scripts exist on most CWP installations:
/scripts/list_users                    # List all users
/scripts/list_domains                  # List all domains
/scripts/list_subdomains               # List all subdomains
/scripts/whoowns DOMAIN                # Get domain owner
/scripts/disk_usage_per_user           # Disk usage report
/scripts/disk_check                    # Check disk usage
/scripts/clean_all_server_logs         # Clean all logs
/scripts/cwp_version                   # Check CWP version
/scripts/update_cwp                    # Update CWP
/scripts/restart_cwpsrv                # Restart CWP service
/scripts/mysql_pwd_reset               # Reset MySQL password
/scripts/install_acme                  # Install Let's Encrypt ACME
/scripts/generate_hostname_ssl         # Generate hostname SSL
/scripts/varnish_clear_cache           # Clear Varnish cache
/scripts/security_is_my_server_hacked  # Check for hacks
/scripts/cwp_security_audit            # Security audit
/scripts/phpfpm_rebuild_user_conf      # Rebuild PHP-FPM configs
/scripts/cwpsrv_rebuild_user_conf      # Rebuild user configs
```

### Web Server Operations

```bash
/scripts/cwp_api webservers rebuild_all
/scripts/cwp_api webservers rebuild_user USERNAME
/scripts/cwp_api webservers restart
/scripts/cwp_api webservers reload
```

## Web Server Stacks

Choose from multiple web server configurations:

| Stack | Description |
|---|---|
| Apache + PHP-FPM | Standard configuration |
| Nginx + PHP-FPM | High-performance |
| Nginx -> Varnish -> Apache | Maximum performance |
| Apache + suPHP | Legacy compatibility |
| LiteSpeed Enterprise | Commercial option |

## User Account Structure

Each CWP user has:

- Home directory: `/home/USERNAME/`
- Web root: `/home/USERNAME/public_html/`
- Per-user PHP config: `/home/USERNAME/php.ini`
- Email storage: `/var/vmail/DOMAIN/USER/`
- Cron jobs: Managed via CWP panel or API

## Action Hooks

Hooks allow executing custom code on CWP events. Key hooks include DNS hooks (`dns_serial_update`, `dns_new_zone_add`, `dns_zone_remove`) and Account hooks (`account_new`, `account_remove`, `account_suspend`, `account_unsuspend`).

For complete hook documentation with examples, see the **cwp-api** skill or `references/scripts-reference.md`.

## Critical Security Notices

| CVE | Severity | Description |
|---|---|---|
| CVE-2025-48703 | Critical | Command Injection in File Manager |
| CVE-2026-57517 | CVSS 9.8 | Blind SQL Injection (RCE) |
| CVE-2025-49113 | Critical | Roundcube Vulnerability |

**Update incidents:** Version 0.9.8.1239 deleted `/root/.ssh` directories and database users. Always back up before updating.

## Additional Resources

- `references/architecture.md` -- Full CWP architecture details
- `references/config-files.md` -- Complete configuration file reference
- `references/scripts-reference.md` -- All available management scripts
