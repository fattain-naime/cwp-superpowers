# CWP (Control Web Panel) - Final Research Report

**Research Date:** July 21, 2026  
**Purpose:** AI Agent Plugin Development for CWP Control Panel Management  
**Sources:** CWP Wiki (200+ articles), CWP Forum (11,000+ topics), CWP Official Site, CWP API Documentation, GitHub, AlphaGNU, Reddit, Community Resources  
**Status:** Complete

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [CWP Overview](#2-cwp-overview)
3. [System Requirements](#3-system-requirements)
4. [Web Server Stack](#4-web-server-stack)
5. [PHP Management](#5-php-management)
6. [Database Management](#6-database-management)
7. [Email Services](#7-email-services)
8. [DNS Management](#8-dns-management)
9. [FTP Services](#9-ftp-services)
10. [Security](#10-security)
11. [API Reference](#11-api-reference)
12. [Plugin & Module Development](#12-plugin--module-development)
13. [Action Hooks](#13-action-hooks)
14. [Billing Integration](#14-billing-integration)
15. [Backup & Recovery](#15-backup--recovery)
16. [Migration](#16-migration)
17. [Performance](#17-performance)
18. [Troubleshooting](#18-troubleshooting)
19. [Critical Issues](#19-critical-issues)
20. [Community & Support](#20-community--support)
21. [Plugin Architecture](#21-plugin-architecture)
22. [Configuration Files](#22-configuration-files)
23. [Scripts Reference](#23-scripts-reference)

---

## 1. Executive Summary

Control Web Panel (CWP) is a free Linux web hosting control panel for managing dedicated and VPS servers. It provides a GUI for server management, eliminating SSH console access for routine tasks.

| Item | Value |
|------|-------|
| **Current Version** | CWP7 (0.9.8.1244) - CWP6 is EOL |
| **Recommended OS** | AlmaLinux 8.10 |
| **Company** | LINANTO LLC, Georgia/Tbilisi (since 2013) |
| **Community** | 30,652 forum members, 47,257 posts |
| **Pricing** | Free (CWPpro from $1.49/month) |
| **Architecture** | Modular PHP-based with API, hooks, custom modules |

**Critical Issues:**
- Multiple CVEs (CVE-2025-48703, CVE-2026-57517) with silent patches
- Backup system in "perpetual beta" for 4+ years
- CSF Firewall discontinued (use Aetherinox fork)
- Comodo WAF abandoned (use OWASP CRS)
- Update v0.9.8.1239 deleted database users and SSH keys
- Dev team communication gaps

---

## 2. CWP Overview

### Features

- **Web Servers:** Apache, Nginx, Varnish Cache, LiteSpeed Enterprise
- **PHP:** Multiple versions (5.3-8.1+), per-user config, PHP-FPM
- **Databases:** MySQL/MariaDB, PostgreSQL, MongoDB
- **Email:** Postfix, Dovecot, Roundcube, SpamAssassin, ClamAV
- **DNS:** FreeDNS, zone management, templates
- **Security:** CSF Firewall, ModSecurity, SSL/TLS, file system lock
- **Users:** Reseller accounts, resource limits, CageFS isolation

### Company

- **Entity:** LINANTO LLC, Georgia/Tbilisi
- **Tax ID:** 405471537
- **Address:** 0160 Tbilisi, Pekin Avenue N44, GEORGIA
- **Contact:** info@centos-webpanel.com
- **Website:** https://control-webpanel.com

### Versions

| Version | Status |
|---------|--------|
| CWP6 (0.9.8.1026) | End-of-Life |
| CWP7 (0.9.8.1244) | Active |
| CWP for EL9 | Beta (missing features) |

---

## 3. System Requirements

### Hardware

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **RAM** | 2 GB (64-bit) | 4 GB+ (8 GB for AlmaLinux 9) |
| **CPU** | 1 core | 2+ cores |
| **Storage** | 20 GB | 50 GB+ |
| **Network** | Static IP | Dedicated IP |

**Note:** PHP compilation requires 1.5-2 GB available RAM.

### Supported Operating Systems

| OS | Version | Status |
|----|---------|--------|
| **AlmaLinux** | 8.10 | **Recommended** - Most stable |
| **AlmaLinux** | 9.x | Beta - Missing features |
| **CentOS** | 7 | EOL - Legacy only |
| **CentOS Stream** | 8/9 | Not recommended |
| **Rocky Linux** | 8/9 | Compatible |
| **Oracle Linux** | 7/8/9 | Compatible |
| **CloudLinux** | Commercial | Supported with CageFS |

### Installation Requirements

- Fresh, clean OS installation required
- No uninstaller - requires OS reinstall to remove
- Static IP address required
- FQDN hostname required (e.g., srv1.example.com)
- Minimal OS installation required

### Installation Commands

```bash
# Set hostname
hostnamectl set-hostname srv.example.com

# Install prerequisites
dnf install epel-release -y && dnf -y install wget && dnf -y update

# Reboot
reboot

# Install CWP (choose one)
cd /usr/local/src
wget http://centos-webpanel.com/cwp-el7-latest && sh cwp-el7-latest  # CentOS 7
wget http://centos-webpanel.com/cwp-el8-latest && sh cwp-el8-latest  # AlmaLinux 8
wget http://centos-webpanel.com/cwp-el9-latest && sh cwp-el9-latest  # AlmaLinux 9

# Optional arguments: --restart yes --phpfpm 7.3 --softaculous yes
```

### Port Mapping

| Port | Service |
|------|---------|
| 2030 | CWP Admin (HTTP) |
| 2031 | CWP Admin (HTTPS) |
| 2082 | CWP User Panel (HTTP) |
| 2083 | CWP User Panel (HTTPS) |
| 2086/2087 | CWP Admin (alternative) |
| 2095/2096 | Roundcube Webmail |
| 2304 | CWP API |
| 8080 | Tomcat |
| 8181 | Apache (behind Nginx) |
| 82 | Varnish |

---

## 4. Web Server Stack

### Configurations

| Stack | Description |
|-------|-------------|
| Apache + PHP-FPM | Standard configuration |
| Nginx + PHP-FPM | High-performance |
| Nginx → Varnish → Apache | Maximum performance |
| Apache + suPHP | Legacy compatibility |
| LiteSpeed Enterprise | Commercial option |

### Vhost Templates

**Location:** `/usr/local/cwpsrv/htdocs/resources/conf/web_servers/`

- `vhosts/httpd/` - Apache templates (main, php-fpm, proxy)
- `vhosts/nginx/` - Nginx templates (main, php-fpm)
- `vhosts/varnish/` - Varnish templates (main only)

**Important:** Never edit templates directly - they are overwritten on CWP updates. Create custom copies.

### Apache Modules

| Module | Purpose |
|--------|---------|
| mod_xsendfile | X-SENDFILE header processing |
| mod_cloudflare | Real IP from Cloudflare |
| mod_brotli | Brotli compression |
| mod_pagespeed | Google page optimization |
| mod_limits | DDoS protection |
| mod_suexec | CGI scripts run as file owner |
| mod_cgid | CGI script execution |
| mod_userdir | Per-user web directories |

---

## 5. PHP Management

### Version Management Tools

| Tool | Behavior | Versions |
|------|----------|----------|
| **PHP Switcher** | ONE default PHP for all users | 5.3-8.1+ (one at a time) |
| **PHP Selector** | Multiple versions via .htaccess | 4.4-8.1 (per folder) |
| **PHP-FPM Selector** | Per-domain via Domain Conf | 5.3-8.1+ (per domain, CWP Pro) |

### PHP Version Assignment

```apache
# Per-folder PHP version via .htaccess
AddHandler application/x-httpd-php56 .php    # PHP 5.6
AddHandler application/x-httpd-php74 .php    # PHP 7.4
AddHandler application/x-httpd-php81 .php    # PHP 8.1
```

### Configuration Paths

| Component | Path |
|-----------|------|
| Main PHP php.ini | `/usr/local/php/php.ini` |
| Main PHP config dir | `/usr/local/php/php.d/` |
| Per-user php.ini | `/home/USERNAME/php.ini` |
| Selector PHP binaries | `/opt/alt/php{VERSION}/usr/bin/php` |
| Selector php.ini | `/opt/alt/php{VERSION}/usr/php/php.ini` |
| FPM user configs | `/opt/alt/php-fpm{VERSION}/usr/etc/php-fpm.d/users/USERNAME.conf` |
| PHP Switcher configs | `/usr/local/cwpsrv/htdocs/resources/conf/el{7,8}/php_switcher/` |
| Compile log | `/var/log/php-rebuild.log` |

### PHP Security

**Disable Dangerous Functions:**
```bash
# PHP Switcher
echo "disable_functions = exec, system, popen, proc_open, shell_exec, passthru, show_source" > /usr/local/php/php.d/disabled_function.ini

# PHP-FPM Selector (restart required)
echo "disable_functions = exec, system, popen, proc_open, shell_exec, passthru, show_source" > /opt/alt/php-fpm{VERSION}/usr/php/php.d/disabled_function.ini
service php-fpm{VERSION} restart
```

**PHP Defender (Snuffleupagus):**
- Config: `/usr/local/cwp/.conf/phpdefender/`
- Rules: `/usr/local/cwp/.conf/phpdefender/rules/`
- Module: `/opt/alt/php-fpm{VERSION}/usr/lib/php/extensions/no-debug-non-zts-*/snuffleupagus.so`

**PHP open_basedir:**
```bash
# Per-user (recommended)
echo "open_basedir = /home/USERNAME:/tmp:/var/tmp:/usr/local/lib/php/" > /home/USERNAME/php.ini
chown root.root /home/USERNAME/php.ini
chmod 555 /home/USERNAME/php.ini
```

---

## 6. Database Management

### MySQL/MariaDB

- **Default:** MariaDB (MySQL drop-in replacement)
- **Management:** phpMyAdmin included
- **Config:** `/etc/my.cnf.d/server.cnf`
- **Root credentials:** `/root/.my.cnf`
- **CWP DB connection:** `/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php`

### PostgreSQL

- **Install:** CWP Admin → SQL Services → PostgreSQL Installer
- **phpPgAdmin:** `sh /scripts/install_phpPgAdmin`
- **PHP support:** Recompile PHP with `--with-pgsql` flag

### MongoDB

- **Install:** CWP Admin → SQL Services → MongoDB Manager
- **Versions:** MongoDB 2 or 3

### Remote MySQL

```bash
# Whitelist IP permanently
csf -a 10.10.23.124 "mysql remote connection"

# Whitelist IP temporarily (24h)
csf -ta 86400 10.10.23.124 "mysql remote connection"

# Create remote user in CWP MySQL manager with Host set to % or specific IP
```

### MariaDB Upgrade

```bash
# Example: 10.2 to 10.4
sed -i 's/10.2/10.4/g' /etc/yum.repos.d/mariadb.repo
systemctl stop mariadb mysql mysqld
systemctl disable mariadb
rpm --nodeps -ev MariaDB-server
yum clean all
yum -y update "MariaDB-*"
yum -y install MariaDB-server
systemctl enable mariadb
systemctl start mariadb
mysql_upgrade --force
```

### Key Tuning Parameters

```ini
# /etc/my.cnf.d/server.cnf under [mysqld]
max_connections = 500           # Default is 150
innodb_buffer_pool_size = 1G    # Adjust based on RAM
max_allowed_packet = 256M       # For large imports
wait_timeout = 86400            # For large imports
max_user_connections = 45       # Per-user limit for shared hosting
```

---

## 7. Email Services

### Components

| Component | Software | Purpose |
|-----------|----------|---------|
| MTA | Postfix | Mail transfer |
| IMAP/POP3 | Dovecot | Mail retrieval |
| Webmail | Roundcube | Web email client |
| Anti-spam | SpamAssassin | Spam filtering |
| Anti-virus | ClamAV | Virus scanning |
| Security | SPF, DKIM, OpenDKIM | Email authentication |
| Rate Limiting | Policyd (cbpolicyd) | Email rate limiting |

### Configuration Files

| File | Purpose |
|------|---------|
| `/etc/postfix/main.cf` | Postfix main config |
| `/etc/postfix/master.cf` | Postfix master config |
| `/etc/postfix/sender_blacklist` | Sender blacklist |
| `/etc/postfix/sender_whitelist` | Sender whitelist |
| `/etc/dovecot/dovecot.conf` | Dovecot config |
| `/etc/mail/spamassassin/local.cf` | SpamAssassin config |
| `/etc/amavisd/amavisd.conf` | AMaViS config |
| `/var/vmail` | Email storage |

### Email Rate Limiting

```bash
# Install Policyd
sh /scripts/install_cbpolicyd

# Update limits for all domains
/scripts/cwp_api account update_policyd_all

# Default: 250 emails/hour
# Service: service cbpolicyd start|stop|restart|status
# Database: postfix_policyd
```

### Rspamd (SpamAssassin Alternative)

- Reduces resource usage from ~1GB to ~98MB
- Handles ~4,000 messages/day with 2% CPU
- Compatible with AlmaLinux 8
- Essential for email forwarding (ARC signing)

---

## 8. DNS Management

### Features

- FreeDNS Service (free DNS clustering with DDoS protection)
- Zone Management (add, edit, list, remove)
- Template Editor (custom DNS zone templates)
- Nameserver Editor (configure nameserver IPs)
- Record Types: A, AAAA, MX, TXT, CNAME, SRV

### DNS Zone Template

**Location:** `/usr/local/cwpsrv/htdocs/resources/conf/dns/bind/zones/`

**Variables:** `%domain%`, `%dns-email%`, `%ns1%`, `%ns2%`, `%ip%`

### DNS Cluster Options

1. **FreeDNS:** Free hosted cluster
2. **Slave DNS Manager:** Self-hosted, unlimited accounts
3. **Slave2 DNS Server:** Additional nodes for redundancy

### DNS Security

```bash
# Secure BIND (disable open resolver)
sed -i 's/recursion yes/recursion no/g' /etc/named.conf

# Additional hardening
allow-recursion { localnets; };
allow-transfer {"none";};
version none;
server-id none;
```

---

## 9. FTP Services

### Server: Pure-FTPd

### Connection Types

| Type | Port | Security | Notes |
|------|------|----------|-------|
| FTP | 21 | None | Plain, unencrypted |
| FTPS | 990 | Implicit SSL/TLS | Deprecated |
| FTPES | 21 | Explicit SSL/TLS | **Preferred** |
| SFTP | 22 | SSH | Not recommended for users |

### Configuration

```bash
# /etc/pure-ftpd/pure-ftpd.conf
PassivePortRange 35000 50000
TLS 1
TLSCipherSuite HIGH
CertFile /etc/pki/tls/private/pure-ftpd.pem

# CSF firewall (TCP_IN)
20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,30000:50000,6666
```

---

## 10. Security

### CSF Firewall

**Status:** Original CSF discontinued (Aug 2025). Use Aetherinox fork (v15.08+).

```bash
# Install iptables on AlmaLinux
yum install iptables

# Core commands
csf -e          # Enable
csf -x          # Disable
csf -r          # Restart
csf -g IP       # Check block reason
csf -d IP       # Block permanently
csf -dr IP      # Unblock
csf -a IP       # Whitelist
csf -ta IP 86400 # Temporary whitelist (24h)
```

### ModSecurity

**Status:** Comodo WAF abandoned. Use OWASP CRS.

1. Update ModSecurity to 2.9.13
2. Install OWASP CRS v4.27.0
3. Lock: `chattr -R +i` on CRS directory
4. Select "OWASP old" (not "OWASP Latest") in CWP

### CWP Secure Kernel

- Custom kernel with MAC (Mandatory Access Control)
- Default-deny policy protecting against symlink attacks, malware
- Supported: CentOS 7, AlmaLinux 8/9, Rocky Linux 8/9
- NOT supported: OpenVZ, CloudLinux, Docker
- Requires active CWP support service

### SSL/TLS

```bash
# Reinstall ACME client
/scripts/install_acme

# Generate hostname SSL
/scripts/generate_hostname_ssl

# SSL Grade improvement (/usr/local/apache/conf.d/ssl.conf)
SSLCipherSuite ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
```

### Security Best Practices

1. Enable AutoSSL for all domains
2. Activate CSF Firewall with proper rules
3. Enable ModSecurity with OWASP CRS
4. Change SSH port + update CSF
5. Disable dangerous PHP functions
6. Enable PHP open_basedir per user
7. Hide system processes
8. Strong passwords enforced
9. IP whitelisting for admin access
10. Regular updates with backups first

---

## 11. API Reference

### API Configuration

**Setup:** CWP Settings → API Manager
**Base URL:** `https://IPSERVERAPI:2304/v1/{function}`
**Method:** POST for all endpoints
**Response:** JSON or XML
**Auth:** API key (`key` parameter)

### API Endpoints

| Endpoint | Operations |
|----------|------------|
| `/v1/account` | add, update, delete, list, suspend, unsuspend |
| `/v1/accountdetail` | list |
| `/v1/changepack` | update |
| `/v1/accountquota` | list |
| `/v1/autossl` | add, list, delete, renew |
| `/v1/changepass` | update |
| `/v1/cronjobsusers` | add, delete, list |
| `/v1/admindomains` | add, delete, list |
| `/v1/emailadmin` | list |
| `/v1/account_metadata` | list |
| `/v1/databasemysql` | add, delete, list |
| `/v1/usermysql` | add, delete, list |
| `/v1/packages` | add, update, delete, list |
| `/v1/quotalimit` | list |
| `/v1/typeserver` | list |

### PHP API Client

```php
require_once 'vendor/autoload.php';
$cwpApi = new Cwpapi('https://yourcwpdomain.com', 'API_KEY');

// Create account
$status = $cwpApi->createAccount('domain.com', 'username', 'password', 'email@domain.com', '1.2.3.4');

// Create database
$status = $cwpApi->createMysqlDatabase('username', 'dbname');
```

### Shell API

```bash
# Account
/scripts/cwp_api account remove_user USERNAME
/scripts/cwp_api account suspend_user USERNAME
/scripts/cwp_api account unsuspend_user USERNAME
/scripts/cwp_api account fix_perms USERNAME

# WebServer
/scripts/cwp_api webservers rebuild_all
/scripts/cwp_api webservers restart

# Apps
/scripts/cwp_api apps install_softaculous
```

---

## 12. Plugin & Module Development

### Admin Modules

**Location:** `/usr/local/cwpsrv/htdocs/resources/admin/modules`

```php
// Create mymodule.php in modules directory
// Access: http://SERVER_IP:2030/index.php?module=mymodule
```

**Add to Menu:** Edit `/usr/local/cwpsrv/htdocs/resources/admin/include/3rdparty.php`
```html
<li><a href="index.php?module=mymodule"><i class="fa fa-puzzle-piece"></i> My Module</a></li>
```

### User Modules

**Location:** `/usr/local/cwpsrv/htdocs/resources/client/modules`

### Resources

- GitHub: https://github.com/boxbillinggit/cwp_modules/blob/master/php_phalcon.php
- Docs: https://docs.control-webpanel.com/docs/developer-tools/custom-modules

---

## 13. Action Hooks

### DNS Hooks

**Location:** `/usr/local/cwpsrv/htdocs/resources/admin/hooks/dns/`

| Hook | Trigger |
|------|---------|
| `dns_serial_update` | Zone additions, subdomain changes |
| `dns_new_zone_add` | New DNS zone |
| `dns_new_subdomain_add` | New subdomain |
| `dns_zone_remove` | Domain deleted |
| `dns_subdomain_remove` | Subdomain deleted |

### Account Hooks

**Location:** `/usr/local/cwpsrv/htdocs/resources/admin/hooks/account/`

| Hook | Trigger |
|------|---------|
| `account_new` | Account created |
| `account_remove` | Account deleted |
| `account_suspend` | Account suspended |
| `account_unsuspend` | Account reactivated |
| `account_new_domain` | Domain added |
| `account_remove_domain` | Domain removed |
| `account_new_subdomain` | Subdomain added |
| `account_remove_subdomain` | Subdomain removed |

### Hook Example

```php
<?php
function account_new($array){
    // $array: username, domain, status
    // Reseller accounts also include 'reseller' key
    echo "New account: {$array['username']} ({$array['domain']})";
}
?>
```

---

## 14. Billing Integration

### WHMCS

**Download:** `http://dl1.centos-webpanel.com/files/3rdparty/whmcs/cwp7.zip`

1. Extract to `WHMCS/modules/servers/cwp7/`
2. WHMCS: Setup → Products/Services → Servers → Type: Cwp7
3. Generate API key in CWP: CWP Settings → API Manager

### Other Systems

- WiseCP, HostBill, Blesta, Clientexec (all supported)

---

## 15. Backup & Recovery

### Features

- Daily, weekly, monthly schedules
- Full, incremental, overwrite modes
- Local, SMB, NFS, S3, Google Drive, SSH remote

### Default Locations

- Backups: `/backup`
- Mail: `/var/vmail`

### Backup Issues (CRITICAL)

**Status:** "Perpetual beta" for 4+ years

- Temporary files not cleaned up
- S3 backup files not auto-deleted
- Email notifications unreliable
- Restore stalls at "Detecting files"
- Database backup gaps

### Google Drive Backup

```bash
# Install gdrive
wget -O gdrive https://drive.google.com/uc?id=ID&export=download
mv gdrive /usr/sbin/gdrive && chmod 755 /usr/sbin/gdrive

# Upload
tar -czf "/tmp/backup-$(date '+%d-%m-%Y').tar.gz" /backup/daily/user
gdrive upload --parent FOLDER_TOKEN /tmp/backup.tar.gz --delete
```

---

## 16. Migration

### cPanel to CWP (Full Server)

```bash
# 1. Export data
sh 1-cpanel-data-export.sh

# 2. Uninstall cPanel
sh 2-cpanel-uninstall.sh

# 3. Install CWP
sh cwp-el7-latest

# 4. Import data
sh 4-import-into-cwp.sh

# 5. Generate mail certs
sh 5-mail-sni.sh
```

### cPanel to CWP (Single Account)

CWP Admin → User Account → cPanel Migration

### CWP to CWP

CWP Admin → User Accounts → CWP→CWP Migration

### Webuzo to CWP

Manual: unpack backup, create database, import via phpMyAdmin

---

## 17. Performance

### Caching Compatibility

| Cache | suPHP | PHP-FPM |
|-------|-------|---------|
| Varnish | Yes | Yes |
| Memcached | Yes | Yes |
| Redis | Yes | Yes |
| OPcache | No | Yes |
| APC | No | Yes |

### Brotli Compression

**Nginx:**
```bash
cd /etc/nginx/modules
wget http://dl1.centos-webpanel.com/files/nginx/modules/nginx-brotli-modules.zip
unzip nginx-brotli-modules.zip
```

**Apache:**
```bash
yum install pcre-devel cmake -y
cd /usr/local/src && git clone https://github.com/google/brotli.git
cd brotli && git checkout v1.0 && ./configure-cmake && make && make install
```

---

## 18. Troubleshooting

### Installation

| Issue | Solution |
|-------|----------|
| "Could not resolve host" | `sh /scripts/centos7_fix_repository` |
| Root login error (AL9) | Comment `SHA_CRYPT_MAX_ROUNDS` in `/etc/login.defs` |
| Varnish fails on EL9 | Manual installation required |
| MariaDB 10.4 EOL | Edit `/etc/yum.repos.d/mariadb.repo` to use 10.6+ |

### Web Server

| Issue | Solution |
|-------|----------|
| ERR_TOO_MANY_REDIRECTS | Use `X-Forwarded-Proto` header in .htaccess |
| 502 Bad Gateway | Restart PHP-FPM, increase process limit |
| 503 Service Unavailable | Check port redirection, PHP-FPM socket |
| 504 Gateway Timeout | Restart Apache/PHP-FPM, increase limits |
| Apache proxy mutex | `ipcs -s \| awk -v user=nobody '$3==user {system("ipcrm -s "$2)}'` |
| Default page for all domains | Rebuild vHosts, check shared IP setting |

### PHP

| Issue | Solution |
|-------|----------|
| Installation failing | Need 1.5-2GB RAM, fix DNS resolver |
| "No Loader installed" | `sh /scripts/update_ioncube` |
| intl extension missing | Recompile PHP with intl or install from Remi repo |
| suPHP 500 error | Fix ownership: `chown -R USER:USER /home/USER/public_html/*` |

### Email

| Issue | Solution |
|-------|----------|
| Can't send emails | Check DKIM/SPF/DMARC, rDNS, IP blacklisting |
| Amavisd 100% CPU | Add `use_bayes 0` to SpamAssassin config |
| DKIM double signature | Add `no_milters` to Postfix master.cf |
| Roundcube error | Update Roundcube, fix mail permissions |
| SpamAssassin start-limit-hit | Add `StartLimitBurst=0` to systemd service |

### Database

| Issue | Solution |
|-------|----------|
| MySQL crashed (InnoDB) | `innodb_force_recovery = 1` (increment 1-6) |
| "BAD CONFIGURATION" | Tune my.cnf with proper settings |
| MariaDB upgrade failed | Follow version-specific upgrade path |
| Too many connections | `max_connections = 500` in my.cnf |

### Panel Access

| Issue | Solution |
|-------|----------|
| Can't login | Reset password: `passwd` |
| CWP Expired (Error 500) | Manual update from `static.cdn-cwp.com` |
| 404 on user login | `sh /scripts/cwpsrv_rebuild_user_conf` |
| Invalid session | Close all browser windows, re-login |

---

## 19. Critical Issues

### Active CVEs

| CVE | Severity | Description | Fix |
|-----|----------|-------------|-----|
| CVE-2025-48703 | Critical | Command Injection in File Manager | Update to 0.9.8.1205+ |
| CVE-2026-57517 | CVSS 9.8 | Blind SQL Injection (RCE) | Update to 0.9.8.1225+ |
| CVE-2025-49113 | Critical | Roundcube Vulnerability | Update to 1.5.11+ |
| CVE-2022-44877 | Critical | RCE in CWP7 | Update to latest |

### Recent Attacks

- **gsocket Systemd Backdoor:** Persistent backdoors via CVEs
- **Yanz Webshell:** Active exploit hitting CWP servers
- **Multiple CWP Servers Infected:** 137 replies, 27,821 views

### Update Incidents

- **v0.9.8.1239:** Deleted `/root/.ssh` directories and database users
- **v0.9.8.1243:** No changelog, opaque "anti-hacker" scripts
- **temp_hacker_check:** Script that destroyed authorized_keys files

---

## 20. Community & Support

### Forum

| Metric | Value |
|--------|-------|
| Members | 30,652 |
| Posts | 47,257 |
| Topics | 11,073 |
| Peak Online | 25,066 |

### Key Contributors

- **Starburst** - Most active, provides guides and mirrors
- **overseer** - Frequent helper
- **cyberspace** - Frequent helper
- **BeZazz** - Frequent helper

### Support Tiers

| Tier | Price |
|------|-------|
| CWPpro (no support) | $1.49/month or $11.99/year |
| CWPpro + Support | $12.99/month |
| Managed Support | $10/server (min 10) |
| Pay Per Ticket | $5/ticket (min 10) |
| Business Support | Contact sales |
| Enterprise Support | Contact sales |

### Resources

- Wiki: http://wiki.centos-webpanel.com (200+ articles)
- Forum: http://forum.centos-webpanel.com
- Docs: https://docs.control-webpanel.com
- AlphaGNU: https://www.alphagnu.com/forum/7-cwp-control-web-panel/
- Support: https://control-webpanel.com/support-services

---

## 21. Plugin Architecture

### Skills Module

| Skill | Purpose |
|-------|---------|
| `cwp-installation` | OS prep, CWP install, initial setup |
| `cwp-security` | Security hardening, firewall, SSL, WAF |
| `cwp-webserver` | Apache/Nginx/Varnish config |
| `cwp-php` | PHP version management, extensions |
| `cwp-database` | MySQL/PostgreSQL/MongoDB management |
| `cwp-email` | Postfix/Dovecot/Roundcube config |
| `cwp-dns` | DNS zone management, templates |
| `cwp-backup` | Backup config, restoration |
| `cwp-troubleshooting` | Issue diagnosis and resolution |
| `cwp-performance` | Performance tuning |
| `cwp-api` | API integration and automation |
| `cwp-migration` | cPanel/CWP migration tools |

### MCP Tools

| Tool | Purpose |
|------|---------|
| `cwp-account-manager` | Account CRUD operations |
| `cwp-database-manager` | Database operations |
| `cwp-email-manager` | Email management |
| `cwp-dns-manager` | DNS management |
| `cwp-ssl-manager` | SSL certificate management |
| `cwp-backup-manager` | Backup and restore |
| `cwp-service-manager` | Service control |
| `cwp-log-analyzer` | Log parsing and analysis |
| `cwp-security-scanner` | Security audit |
| `cwp-performance-monitor` | Resource monitoring |

### Workflows

| Workflow | Description |
|----------|-------------|
| `new-server-setup` | Complete server provisioning |
| `security-hardening` | Full security audit |
| `performance-tuning` | Performance optimization |
| `disaster-recovery` | Full recovery procedure |
| `migration-workflow` | cPanel to CWP migration |
| `monitoring-setup` | Monitoring configuration |

### Agents

| Agent | Purpose |
|-------|---------|
| `cwp-admin-agent` | Administrative automation |
| `cwp-security-agent` | Security monitoring |
| `cwp-performance-agent` | Performance optimization |
| `cwp-backup-agent` | Backup management |
| `cwp-troubleshoot-agent` | Issue resolution |

---

## 22. Configuration Files

### CWP Core

| File | Purpose |
|------|---------|
| `/usr/local/cwp/` | CWP installation |
| `/usr/local/cwpsrv/` | CWP web server |
| `/usr/local/cwpsrv/htdocs/resources/admin/modules/` | Admin modules |
| `/usr/local/cwpsrv/htdocs/resources/admin/hooks/` | Action hooks |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/3rdparty.php` | Menu config |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php` | DB connection |
| `/usr/local/cwp/.conf/` | CWP configuration |

### Web Servers

| File | Purpose |
|------|---------|
| `/usr/local/apache/conf/httpd.conf` | Apache main config |
| `/usr/local/apache/conf.d/` | Apache module configs |
| `/usr/local/apache/logs/` | Apache logs |
| `/usr/local/apache/domlogs/` | Per-domain logs |
| `/etc/nginx/nginx.conf` | Nginx config |
| `/etc/varnish/varnish.params` | Varnish config |
| `/usr/local/cwpsrv/htdocs/resources/conf/web_servers/` | Vhost templates |

### Database

| File | Purpose |
|------|---------|
| `/etc/my.cnf.d/server.cnf` | MariaDB config |
| `/root/.my.cnf` | MySQL root credentials |
| `/etc/yum.repos.d/mariadb.repo` | MariaDB repo |

### Email

| File | Purpose |
|------|---------|
| `/etc/postfix/main.cf` | Postfix config |
| `/etc/postfix/master.cf` | Postfix master config |
| `/etc/dovecot/dovecot.conf` | Dovecot config |
| `/var/vmail` | Email storage |
| `/etc/mail/spamassassin/local.cf` | SpamAssassin config |

### Security

| File | Purpose |
|------|---------|
| `/etc/csf/csf.conf` | CSF Firewall |
| `/etc/ssh/sshd_config` | SSH config |
| `/usr/local/apache/conf.d/mod_security.conf` | ModSecurity |
| `/usr/local/apache/conf.d/ssl.conf` | SSL config |
| `/etc/letsencrypt/` | Let's Encrypt certs |
| `/usr/local/cwp/.conf/phpdefender/` | Snuffleupagus rules |

### DNS

| File | Purpose |
|------|---------|
| `/etc/named.conf` | BIND config |
| `/var/named/` | DNS zone files |

---

## 23. Scripts Reference

### Account Management

```bash
/scripts/cwp_api account remove_user USERNAME
/scripts/cwp_api account suspend_user USERNAME
/scripts/cwp_api account unsuspend_user USERNAME
/scripts/cwp_api account unsuspend_bandwidth USERNAME
/scripts/cwp_api account reset_bandwidth USERNAME
/scripts/cwp_api account fix_perms USERNAME
/scripts/cwp_api account list_domains USERNAME
/scripts/cwp_api account update_diskquota_all
/scripts/cwp_api account update_limits_all
/scripts/cwp_api account mail_fix_permissions
/scripts/cwp_api account update_policyd_all
/scripts/cwp_api account rebuild_etc_named_conf
/scripts/cwp_api account rebuild_var_named_all
```

### WebServer Management

```bash
/scripts/cwp_api webservers rebuild_all
/scripts/cwp_api webservers rebuild_user USERNAME
/scripts/cwp_api webservers restart
/scripts/cwp_api webservers reload
```

### System Scripts

```bash
/scripts/update_cwp                    # Update CWP
/scripts/restart_cwpsrv                # Restart CWP service
/scripts/cwp_version                   # Check version
/scripts/mysql_pwd_reset               # Reset MySQL password
/scripts/install_acme                  # Install Let's Encrypt
/scripts/generate_hostname_ssl         # Generate hostname SSL
/scripts/clean_all_server_logs         # Clean all logs
/scripts/disk_usage_per_user           # Disk usage per user
/scripts/disk_check                    # Check disk usage
/scripts/centos7_fix_repository        # Fix CentOS 7 repos
/scripts/install_cbpolicyd             # Install Policyd
/scripts/install_pure-ftpd_tls         # Install FTP TLS
/scripts/mail_roundcube_update         # Update Roundcube
/scripts/mysql_phpmyadmin_update       # Update phpMyAdmin
/scripts/varnish_clear_cache           # Clear Varnish cache
/scripts/security_is_my_server_hacked  # Check for hacks
/scripts/cwp_security_audit            # Security audit
/scripts/phpfpm_rebuild_user_conf      # Rebuild PHP-FPM configs
/scripts/cwpsrv_rebuild_user_conf      # Rebuild user configs
```

### Application Scripts

```bash
/scripts/install_imagick               # Install ImageMagick
/scripts/install_maldet                # Install Malware Detect
/scripts/install_softaculous           # Install Softaculous
/scripts/install_phpPgAdmin            # Install phpPgAdmin
/scripts/user_backup USERNAME          # Create user backup
/scripts/whoowns DOMAIN                # Get domain owner
/scripts/list_users                    # List all users
/scripts/list_domains                  # List all domains
/scripts/list_subdomains               # List all subdomains
```

### Monitoring Scripts

```bash
/scripts/cwp_monitor                   # Check server load
/scripts/bandwidth_run                 # Check bandwidth
/scripts/check_api                     # API check
/scripts/checkdb                        # Check databases
/scripts/check_postqueue               # Check mail queue
/scripts/net_show_connections           # Show connections
/scripts/mail_queue_stats              # Mail queue stats
/scripts/clamd_fix_100_cpu_usage       # Fix Clamd CPU
/scripts/mysql_fix_myisam_tables       # Repair MyISAM
```

### Security Scripts

```bash
/scripts/cwp_bruteforce_protection     # Enable brute-force protection
/scripts/open_basedir-suphp            # Force open_basedir
/scripts/chroot_add USERNAME           # Add to JailKit
/scripts/chroot_remove USERNAME        # Remove from JailKit
/scripts/autossl_fix_tmp_path          # Fix AutoSSL temp path
/scripts/freshclam                     # Update ClamAV
/scripts/php_big_file_upload           # Set upload limit
```

---

**Research Sources:**
- CWP Wiki: http://wiki.centos-webpanel.com (200+ articles)
- CWP Forum: http://forum.centos-webpanel.com (30,652 members, 47,257 posts)
- CWP Official: https://control-webpanel.com
- CWP API Docs: https://docs.control-webpanel.com/docs/developer-tools/api-manager
- GitHub: https://github.com/puerari/cwp_api
- AlphaGNU: https://www.alphagnu.com/forum/7-cwp-control-web-panel/
- Community: Reddit, Stack Overflow, Hosting Provider Guides
