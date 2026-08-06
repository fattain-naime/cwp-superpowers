# CWP Pro Skills Index

This document provides a quick reference for all available skills in the CWP Pro plugin. Each skill is triggered by specific keywords or phrases.

## Quick Reference

| Skill | Trigger Keywords | Description |
|-------|------------------|-------------|
| [cwp-api](#cwp-api) | "use CWP API", "create API key", "manage accounts via API", "automate CWP tasks" | API integration and automation |
| [cwp-backup](#cwp-backup) | "configure backups", "restore from backup", "set up S3 backup", "schedule backups" | Backup management |
| [cwp-core](#cwp-core) | "install CWP", "configure CWP", "check CWP version", "manage CWP services" | Core CWP knowledge |
| [cwp-database](#cwp-database) | "create MySQL database", "manage MariaDB", "reset MySQL password", "tune database" | Database management |
| [cwp-dns](#cwp-dns) | "manage DNS zones", "add DNS records", "configure nameservers", "set up DNS clustering" | DNS management |
| [cwp-email](#cwp-email) | "configure email", "set up Postfix", "fix email delivery", "set up DKIM" | Email services |
| [cwp-migration](#cwp-migration) | "migrate from cPanel", "transfer accounts", "CWP to CWP migration" | Server migration |
| [cwp-performance](#cwp-performance) | "optimize performance", "enable caching", "configure Varnish", "reduce server load" | Performance optimization |
| [cwp-php](#cwp-php) | "switch PHP version", "install PHP extensions", "configure PHP-FPM", "PHP Selector" | PHP management |
| [cwp-security](#cwp-security) | "configure CSF firewall", "set up ModSecurity", "install SSL", "harden server" | Security management |
| [cwp-troubleshooting](#cwp-troubleshooting) | "fix CWP error", "troubleshoot server issue", "check server logs", "diagnose problem" | Troubleshooting |
| [cwp-webserver](#cwp-webserver) | "configure Apache", "configure Nginx", "set up Varnish", "switch web server stack" | Web server management |

---

## Detailed Skill Descriptions

### cwp-api

**Purpose:** Interact with the CWP REST API and shell-based API for automation, account management, and third-party integrations.

**Trigger Phrases:**
- "use CWP API"
- "create API key"
- "manage accounts via API"
- "automate CWP tasks"
- "list API endpoints"
- "integrate with CWP"
- "use cwp_api script"
- "configure API access"
- "create account via API"
- "manage databases via API"
- "set up billing integration"
- "configure WHMCS"

**Reference Files:**
- `references/api-endpoints.md` - Complete API endpoint reference
- `references/api-examples.md` - API request/response examples
- `references/hooks-reference.md` - All available action hooks

---

### cwp-backup

**Purpose:** Manage local, remote, and cloud backups on CWP servers. Configure backup schedules, destinations, and restoration procedures.

**Trigger Phrases:**
- "configure backups"
- "set up automatic backups"
- "restore from backup"
- "configure remote backup"
- "set up S3 backup"
- "configure Google Drive backup"
- "set up SSH remote backup"
- "fix backup issues"
- "schedule backups"
- "create manual backup"
- "restore database from backup"

**Reference Files:**
- `references/local-backup.md` - Local backup configuration
- `references/remote-backup.md` - Remote backup destinations (FTP, SFTP, S3)
- `references/restore.md` - Backup restoration procedures

---

### cwp-core

**Purpose:** Provide foundational knowledge for managing Control Web Panel (CWP7) servers. Installation, configuration, service management, and structural understanding.

**Trigger Phrases:**
- "install CWP"
- "configure CWP"
- "check CWP version"
- "update CWP"
- "manage CWP services"
- "understand CWP architecture"
- "access CWP panel"
- "reset CWP password"
- "fix CWP installation"
- "manage CWP users"
- "manage CWP packages"

**Reference Files:**
- `references/architecture.md` - CWP directory structure and architecture
- `references/config-files.md` - Configuration file locations
- `references/scripts-reference.md` - CWP scripts reference

---

### cwp-database

**Purpose:** Manage MySQL/MariaDB, PostgreSQL, and MongoDB databases on CWP servers. Handle database creation, user management, performance tuning, upgrades, and recovery.

**Trigger Phrases:**
- "create MySQL database"
- "manage MariaDB"
- "install PostgreSQL"
- "configure MongoDB"
- "reset MySQL password"
- "tune database performance"
- "upgrade MariaDB"
- "fix database crash"
- "set up remote MySQL"
- "import database"
- "repair tables"
- "optimize database"

**Reference Files:**
- `references/mysql.md` - MySQL/MariaDB configuration and tuning
- `references/postgresql.md` - PostgreSQL installation and configuration
- `references/mongodb.md` - MongoDB setup and management

---

### cwp-dns

**Purpose:** Manage DNS zones, records, templates, and clustering on CWP servers. Handle BIND configuration, zone templates, nameserver setup, and DNS security.

**Trigger Phrases:**
- "manage DNS zones"
- "add DNS records"
- "configure nameservers"
- "set up DNS clustering"
- "edit DNS templates"
- "fix DNS resolution"
- "configure FreeDNS"
- "set up slave DNS"
- "add MX records"
- "add TXT records"
- "configure BIND"
- "secure DNS"

**Reference Files:**
- `references/bind.md` - BIND configuration and DNS security
- `references/dns-cluster.md` - DNS cluster setup
- `references/dns-templates.md` - Zone templates

---

### cwp-email

**Purpose:** Manage Postfix, Dovecot, Roundcube, spam filtering, and email authentication on CWP servers.

**Trigger Phrases:**
- "configure email"
- "set up Postfix"
- "configure Dovecot"
- "install Roundcube"
- "fix email delivery"
- "set up DKIM"
- "configure SPF"
- "set up spam filtering"
- "install SpamAssassin"
- "configure ClamAV"
- "fix mail queue"
- "set up email rate limiting"
- "install Rspamd"
- "configure OpenDKIM"

**Reference Files:**
- `references/postfix.md` - Postfix configuration and mail transfer
- `references/dovecot.md` - Dovecot IMAP/POP3 setup
- `references/spam-filtering.md` - SpamAssassin and Rspamd configuration
- `references/roundcube.md` - Roundcube webmail setup

---

### cwp-migration

**Purpose:** Migrate accounts and data from cPanel, other CWP servers, or alternative control panels to CWP.

**Trigger Phrases:**
- "migrate from cPanel"
- "migrate to CWP"
- "transfer accounts"
- "cPanel to CWP migration"
- "CWP to CWP migration"
- "migrate single account"
- "migrate from Webuzo"
- "import cPanel backup"
- "export cPanel data"
- "set up migration scripts"

**Reference Files:**
- `references/cpanel-to-cwp.md` - cPanel to CWP migration
- `references/cwp-to-cwp.md` - CWP to CWP migration
- `references/other-panels.md` - Webuzo, Plesk, DirectAdmin migration

---

### cwp-performance

**Purpose:** Optimize server performance including caching, compression, PHP tuning, and database optimization.

**Trigger Phrases:**
- "optimize server performance"
- "enable caching"
- "configure Varnish"
- "set up Redis"
- "configure Memcached"
- "enable OPcache"
- "enable Brotli compression"
- "tune PHP-FPM"
- "optimize database"
- "reduce server load"
- "improve page speed"
- "tune MySQL performance"

**Reference Files:**
- `references/caching.md` - Caching solutions
- `references/compression.md` - Compression configuration
- `references/php-tuning.md` - PHP-FPM optimization

---

### cwp-php

**Purpose:** Manage PHP versions, extensions, and configurations on CWP servers. Handle PHP Switcher, PHP Selector, PHP-FPM Selector, and security hardening.

**Trigger Phrases:**
- "switch PHP version"
- "install PHP extensions"
- "configure PHP-FPM"
- "use PHP Selector"
- "compile PHP"
- "fix PHP errors"
- "disable PHP functions"
- "set up open_basedir"
- "configure PHP Defender"
- "rebuild PHP-FPM"
- "set PHP upload limit"
- "manage multiple PHP versions"

**Reference Files:**
- `references/php-switcher.md` - PHP Switcher compilation
- `references/php-selector.md` - PHP Selector multi-version
- `references/php-security.md` - PHP security hardening
- `references/php-fpm.md` - PHP-FPM pool configuration

---

### cwp-security

**Purpose:** Manage CSF firewall, ModSecurity, SSL certificates, SSH hardening, and server security auditing.

**Trigger Phrases:**
- "configure CSF firewall"
- "set up ModSecurity"
- "install SSL certificate"
- "enable AutoSSL"
- "harden server security"
- "configure SSH security"
- "set up brute force protection"
- "block IP address"
- "whitelist IP"
- "install OWASP CRS"
- "check for hacks"
- "run security audit"
- "configure firewall rules"

**Reference Files:**
- `references/csf-firewall.md` - CSF Firewall configuration
- `references/mod-security.md` - ModSecurity and OWASP CRS
- `references/ssl-tls.md` - SSL/TLS certificate management
- `references/secure-kernel.md` - CWP Secure Kernel

---

### cwp-troubleshooting

**Purpose:** Diagnose and resolve common issues on CWP servers. Handle web server errors, PHP problems, email delivery issues, database crashes, and panel access problems.

**Trigger Phrases:**
- "fix CWP error"
- "troubleshoot server issue"
- "check server logs"
- "diagnose web server problem"
- "fix login issue"
- "resolve 502 error"
- "fix email problem"
- "debug PHP issue"
- "check service status"
- "fix CWP panel"
- "resolve DNS issue"
- "check server health"

**Reference Files:**
- `references/common-issues.md` - Common server and service issues
- `references/log-analysis.md` - Log file locations and analysis
- `references/error-codes.md` - Error code reference

---

### cwp-webserver

**Purpose:** Manage Apache, Nginx, Varnish, and LiteSpeed web server configurations within CWP.

**Trigger Phrases:**
- "configure Apache"
- "configure Nginx"
- "set up Varnish"
- "switch web server stack"
- "edit vhost template"
- "rebuild vhosts"
- "fix web server errors"
- "configure SSL for web server"
- "set up reverse proxy"
- "enable Brotli compression"
- "fix 502 bad gateway"
- "fix redirect loop"
- "manage web server modules"

**Reference Files:**
- `references/apache.md` - Apache configuration and modules
- `references/nginx.md` - Nginx configuration and reverse proxy
- `references/varnish.md` - Varnish cache configuration
- `references/litespeed.md` - LiteSpeed Enterprise setup

---

## Using Skills

Skills are automatically triggered when you use matching keywords in your request. You can also explicitly invoke a skill using the command format:

```
/cwp-pro-centos:<skill-name> <your request>
```

For example:
- `/cwp-pro-centos:cwp-security block IP 1.2.3.4`
- `/cwp-pro-centos:cwp-performance optimize MySQL`
- `/cwp-pro-centos:cwp-api create account for example.com`
