# CWP AI Agent Plugin - Complete Architecture Design

**Plugin Name:** `cwp-pro-centos`  
**Version:** 1.0.0  
**Purpose:** AI-powered God Mode plugin for CWP (Control Web Panel) management  
**Platform:** Claude Code Plugin System  

---

## Table of Contents

1. [Plugin Overview](#1-plugin-overview)
2. [Directory Structure](#2-directory-structure)
3. [Plugin Manifest](#3-plugin-manifest)
4. [Skills Architecture](#4-skills-architecture)
5. [Commands Architecture](#5-commands-architecture)
6. [Agents Architecture](#6-agents-architecture)
7. [Hooks Architecture](#7-hooks-architecture)
8. [MCP Integration](#8-mcp-integration)
9. [Scripts Architecture](#9-scripts-architecture)
10. [Configuration System](#10-configuration-system)
11. [Security Model](#11-security-model)
12. [Error Handling](#12-error-handling)
13. [Testing Strategy](#13-testing-strategy)
14. [Deployment Guide](#14-deployment-guide)
15. [Usage Guide](#15-usage-guide)

---

## 1. Plugin Overview

### What This Plugin Does

The CWP AI Agent Plugin transforms Claude Code into a comprehensive CWP server management assistant. It can:

- Install and configure CWP on any supported OS
- Manage web servers (Apache, Nginx, Varnish, LiteSpeed)
- Configure PHP versions and extensions
- Manage databases (MySQL, PostgreSQL, MongoDB)
- Configure email services (Postfix, Dovecot, Roundcube)
- Manage DNS zones and records
- Handle SSL/TLS certificates
- Perform security hardening
- Troubleshoot common issues
- Automate backups and recovery
- Migrate from cPanel and other panels
- Monitor server performance
- Manage user accounts and packages

### Design Principles

1. **Modular Architecture:** Each component (skill, command, agent) handles one domain
2. **Progressive Disclosure:** Core instructions in skills, details in references
3. **Security First:** Validate all inputs, least privilege access
4. **Idempotent Operations:** Safe to run multiple times
5. **Error Recovery:** Graceful failure with clear error messages
6. **Portable Paths:** Use `${CLAUDE_PLUGIN_ROOT}` everywhere

---

## 2. Directory Structure

```
cwp-pro-centos/
├── .claude-plugin/
│   └── plugin.json                    # Plugin manifest
├── commands/                          # Slash commands
│   ├── cwp-install.md                 # /cwp-install
│   ├── cwp-status.md                  # /cwp-status
│   ├── cwp-user.md                    # /cwp-user
│   ├── cwp-database.md                # /cwp-database
│   ├── cwp-email.md                   # /cwp-email
│   ├── cwp-dns.md                     # /cwp-dns
│   ├── cwp-ssl.md                     # /cwp-ssl
│   ├── cwp-security.md                # /cwp-security
│   ├── cwp-backup.md                  # /cwp-backup
│   ├── cwp-migrate.md                 # /cwp-migrate
│   ├── cwp-fix.md                     # /cwp-fix
│   └── cwp-optimize.md                # /cwp-optimize
├── agents/                            # Autonomous agents
│   ├── cwp-security-auditor.md        # Security auditing
│   ├── cwp-performance-optimizer.md   # Performance tuning
│   ├── cwp-troubleshooter.md          # Issue diagnosis
│   ├── cwp-migration-planner.md       # Migration planning
│   └── cwp-backup-manager.md          # Backup management
├── skills/                            # Auto-activating skills
│   ├── cwp-core/
│   │   ├── SKILL.md                   # Core CWP knowledge
│   │   └── references/
│   │       ├── architecture.md        # CWP architecture
│   │       ├── config-files.md        # Configuration files
│   │       └── scripts-reference.md   # CWP scripts
│   ├── cwp-webserver/
│   │   ├── SKILL.md                   # Web server management
│   │   └── references/
│   │       ├── apache.md              # Apache configuration
│   │       ├── nginx.md               # Nginx configuration
│   │       ├── varnish.md             # Varnish configuration
│   │       └── litespeed.md           # LiteSpeed configuration
│   ├── cwp-php/
│   │   ├── SKILL.md                   # PHP management
│   │   └── references/
│   │       ├── php-switcher.md        # PHP Switcher
│   │       ├── php-selector.md        # PHP Selector
│   │       ├── php-fpm.md             # PHP-FPM Selector
│   │       └── php-security.md        # PHP security
│   ├── cwp-database/
│   │   ├── SKILL.md                   # Database management
│   │   └── references/
│   │       ├── mysql.md               # MySQL/MariaDB
│   │       ├── postgresql.md          # PostgreSQL
│   │       └── mongodb.md             # MongoDB
│   ├── cwp-email/
│   │   ├── SKILL.md                   # Email management
│   │   └── references/
│   │       ├── postfix.md             # Postfix configuration
│   │       ├── dovecot.md             # Dovecot configuration
│   │       ├── roundcube.md           # Roundcube configuration
│   │       └── spam-filtering.md      # SpamAssassin/Rspamd
│   ├── cwp-dns/
│   │   ├── SKILL.md                   # DNS management
│   │   └── references/
│   │       ├── bind.md                # BIND configuration
│   │       ├── dns-templates.md       # DNS templates
│   │       └── dns-cluster.md         # DNS clustering
│   ├── cwp-security/
│   │   ├── SKILL.md                   # Security management
│   │   └── references/
│   │       ├── csf-firewall.md        # CSF Firewall
│   │       ├── mod-security.md        # ModSecurity
│   │       ├── ssl-tls.md             # SSL/TLS management
│   │       └── secure-kernel.md       # CWP Secure Kernel
│   ├── cwp-backup/
│   │   ├── SKILL.md                   # Backup management
│   │   └── references/
│   │       ├── local-backup.md        # Local backups
│   │       ├── remote-backup.md       # Remote backups
│   │       └── restore.md             # Restoration
│   ├── cwp-migration/
│   │   ├── SKILL.md                   # Migration tools
│   │   └── references/
│   │       ├── cpanel-to-cwp.md       # cPanel migration
│   │       ├── cwp-to-cwp.md          # CWP migration
│   │       └── other-panels.md        # Other panels
│   ├── cwp-troubleshooting/
│   │   ├── SKILL.md                   # Troubleshooting
│   │   └── references/
│   │       ├── common-issues.md       # Common issues
│   │       ├── log-analysis.md        # Log analysis
│   │       └── error-codes.md         # Error codes
│   ├── cwp-performance/
│   │   ├── SKILL.md                   # Performance tuning
│   │   └── references/
│   │       ├── caching.md             # Caching strategies
│   │       ├── compression.md         # Compression
│   │       └── optimization.md        # General optimization
│   └── cwp-api/
│       ├── SKILL.md                   # API integration
│       └── references/
│           ├── api-endpoints.md       # API endpoints
│           ├── api-examples.md        # API examples
│           └── hooks-reference.md     # Action hooks
├── hooks/
│   ├── hooks.json                     # Hook configuration
│   └── scripts/
│       ├── validate-command.sh        # Command validation
│       ├── check-server-health.sh     # Health check
│       └── load-server-context.sh     # Context loading
├── .mcp.json                          # MCP server configuration
├── servers/
│   └── cwp-mcp-server.js              # MCP server implementation
├── cli/
│   ├── cwp                            # Main CWP CLI command
│   ├── cwp-completion.bash            # Bash completion
│   └── cwp-completion.zsh             # Zsh completion
├── scripts/
│   ├── install.sh                     # Plugin installer
│   ├── uninstall.sh                   # Plugin uninstaller
│   ├── setup.sh                       # Interactive setup wizard
│   ├── cwp-api-client.sh              # CWP API client
│   ├── cwp-remote-exec.sh             # Remote execution
│   ├── cwp-backup-verify.sh           # Backup verification
│   ├── cwp-security-scan.sh           # Security scanning
│   └── cwp-health-check.sh            # Health monitoring
├── templates/
│   ├── vhost-apache.tpl               # Apache vhost template
│   ├── vhost-nginx.tpl                # Nginx vhost template
│   ├── vhost-varnish.tpl              # Varnish template
│   ├── dns-zone.tpl                   # DNS zone template
│   ├── backup-config.tpl              # Backup configuration
│   ├── email-config.tpl               # Email configuration
│   └── php-fpm-pool.tpl               # PHP-FPM pool template
├── examples/
│   ├── install-cwp.sh                 # Example: Install CWP
│   ├── create-account.sh              # Example: Create account
│   ├── setup-email.sh                 # Example: Setup email
│   ├── configure-ssl.sh               # Example: Configure SSL
│   └── security-hardening.sh          # Example: Security hardening
├── tests/
│   ├── test-cli.sh                    # CLI tests
│   ├── test-api.sh                    # API tests
│   └── test-integration.sh            # Integration tests
├── docs/
│   ├── research.md                    # Research report
│   ├── plugin.md                      # This file
│   ├── api-reference.md               # API reference
│   ├── cli-reference.md               # CLI reference
│   └── troubleshooting.md             # Troubleshooting guide
├── README.md                          # Plugin documentation
├── CHANGELOG.md                       # Version history
├── CONTRIBUTING.md                    # Contributing guide
├── LICENSE                            # MIT License
└── .github/
    └── workflows/
        ├── test.yml                   # CI: Run tests
        └── release.yml                # CI: Release plugin
```

---

## 3. Plugin Manifest

### plugin.json

```json
{
  "name": "cwp-pro-centos",
  "version": "1.0.0",
  "description": "AI-powered God Mode plugin for CWP (Control Web Panel) management. Install, configure, troubleshoot, and manage CWP servers with natural language commands.",
  "author": {
    "name": "CWP AI Agent Team",
    "url": "https://github.com/cwp-pro-centos"
  },
  "homepage": "https://github.com/cwp-pro-centos/cwp-pro-centos",
  "license": "MIT",
  "keywords": [
    "cwp",
    "centos-web-panel",
    "web-hosting",
    "server-management",
    "apache",
    "nginx",
    "php",
    "mysql",
    "email",
    "dns",
    "ssl",
    "security",
    "backup",
    "migration"
  ],
  "commands": "./commands",
  "agents": "./agents",
  "skills": "./skills",
  "hooks": "./hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

---

## 4. Skills Architecture

### 4.1 cwp-core (Core CWP Knowledge)

**File:** `skills/cwp-core/SKILL.md`

```markdown
---
name: cwp-core
description: This skill should be used when the user asks about "CWP", "CentOS Web Panel", "control panel", "server management", "CWP configuration", "CWP installation", or any CWP-related task. Provides foundational knowledge about CWP architecture, configuration files, and scripts.
version: 1.0.0
---

# CWP Core Knowledge

## Overview

CWP (Control Web Panel) is a free Linux web hosting control panel for managing dedicated and VPS servers.

**Current Version:** CWP7 (0.9.8.1244)  
**Recommended OS:** AlmaLinux 8.10  
**API Port:** 2304 (HTTPS)  
**Admin Panel:** 2030 (HTTP), 2031 (HTTPS)  
**User Panel:** 2082 (HTTP), 2083 (HTTPS)  

## Key Concepts

### CWP Architecture

CWP consists of:
- **cwpsrv:** Internal web server for panel (port 2030/2031)
- **Apache/Nginx:** Web servers for hosted sites
- **PHP:** Multiple versions via Switcher/Selector
- **MariaDB:** Database server
- **Postfix/Dovecot:** Email server
- **BIND:** DNS server
- **Pure-FTPd:** FTP server
- **CSF/LFD:** Firewall

### Configuration Files

| File | Purpose |
|------|---------|
| `/usr/local/cwp/.conf/` | CWP configuration directory |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php` | DB connection |
| `/root/.my.cnf` | MySQL root credentials |
| `/etc/csf/csf.conf` | CSF Firewall config |
| `/etc/postfix/main.cf` | Postfix config |
| `/etc/nginx/nginx.conf` | Nginx config |
| `/usr/local/apache/conf/httpd.conf` | Apache config |
| `/etc/my.cnf.d/server.cnf` | MariaDB config |

### CWP Scripts

Key scripts at `/scripts/`:
- `update_cwp` - Update CWP
- `restart_cwpsrv` - Restart panel service
- `cwp_api` - API client
- `install_acme` - Install Let's Encrypt
- `mysql_pwd_reset` - Reset MySQL password

## Common Operations

### Check CWP Status
```bash
sh /scripts/cwp_version
service cwpsrv status
```

### Restart Services
```bash
sh /scripts/restart_cwpsrv        # CWP panel
service httpd restart              # Apache
service nginx restart              # Nginx
service mariadb restart            # MariaDB
service postfix restart            # Postfix
```

### View Logs
```bash
tail -f /usr/local/apache/logs/error_log      # Apache errors
tail -f /var/log/maillog                       # Mail logs
tail -f /var/log/cwp/webservers.log            # CWP webserver logs
```

## Additional Resources

- **`references/architecture.md`** - Detailed CWP architecture
- **`references/config-files.md`** - Complete configuration file reference
- **`references/scripts-reference.md`** - All CWP scripts
```

### 4.2 cwp-webserver (Web Server Management)

**File:** `skills/cwp-webserver/SKILL.md`

```markdown
---
name: cwp-webserver
description: This skill should be used when the user asks about "Apache", "Nginx", "Varnish", "LiteSpeed", "web server", "vhost", "virtual host", "reverse proxy", "web server configuration", or "web server stack". Provides guidance for configuring and managing CWP web servers.
version: 1.0.0
---

# CWP Web Server Management

## Web Server Stacks

CWP supports multiple web server configurations:

| Stack | Description |
|-------|-------------|
| Apache + PHP-FPM | Standard configuration |
| Nginx + PHP-FPM | High-performance |
| Nginx → Varnish → Apache | Maximum performance |
| Apache + suPHP | Legacy compatibility |
| LiteSpeed Enterprise | Commercial option |

## Vhost Templates

**Location:** `/usr/local/cwpsrv/htdocs/resources/conf/web_servers/`

- `vhosts/httpd/` - Apache templates
- `vhosts/nginx/` - Nginx templates
- `vhosts/varnish/` - Varnish templates

**Important:** Never edit templates directly. Create custom copies.

## Common Tasks

### Switch Web Server Stack
1. CWP Admin → WebServer Settings → Select WebServers
2. Choose desired stack
3. Click "Save and Rebuild"

### Configure Per-Domain
1. CWP Admin → WebServer Settings → WebServers Domain Conf
2. Select user and domain
3. Choose template and configuration
4. Click "Create Configuration"

### Rebuild Web Servers
```bash
/scripts/cwp_api webservers rebuild_all
/scripts/cwp_api webservers rebuild_user USERNAME
```

## Additional Resources

- **`references/apache.md`** - Apache configuration
- **`references/nginx.md`** - Nginx configuration
- **`references/varnish.md`** - Varnish configuration
- **`references/litespeed.md`** - LiteSpeed configuration
```

### 4.3 cwp-php (PHP Management)

**File:** `skills/cwp-php/SKILL.md`

```markdown
---
name: cwp-php
description: This skill should be used when the user asks about "PHP", "PHP version", "PHP selector", "PHP-FPM", "PHP extensions", "PHP configuration", "php.ini", "PHP security", or "PHP compilation". Provides guidance for managing PHP versions and configurations in CWP.
version: 1.0.0
---

# CWP PHP Management

## PHP Version Tools

| Tool | Behavior | Versions |
|------|----------|----------|
| **PHP Switcher** | ONE default PHP for all users | 5.3-8.1+ |
| **PHP Selector** | Multiple versions via .htaccess | 4.4-8.1 |
| **PHP-FPM Selector** | Per-domain via Domain Conf | 5.3-8.1+ (CWP Pro) |

## Configuration Paths

| Component | Path |
|-----------|------|
| Main PHP php.ini | `/usr/local/php/php.ini` |
| Per-user php.ini | `/home/USERNAME/php.ini` |
| Selector PHP binaries | `/opt/alt/php{VERSION}/usr/bin/php` |
| Selector php.ini | `/opt/alt/php{VERSION}/usr/php/php.ini` |
| FPM user configs | `/opt/alt/php-fpm{VERSION}/usr/etc/php-fpm.d/users/USERNAME.conf` |

## Common Tasks

### Change PHP Version (Per-Folder)
```apache
# .htaccess
AddHandler application/x-httpd-php74 .php
```

### Disable Dangerous Functions
```bash
echo "disable_functions = exec, system, popen, proc_open, shell_exec, passthru, show_source" > /usr/local/php/php.d/disabled_function.ini
```

### Compile PHP
1. CWP Admin → PHP Settings → PHP Version Switcher
2. Select version
3. Choose modules
4. Click "Start Compiler"

## Additional Resources

- **`references/php-switcher.md`** - PHP Switcher details
- **`references/php-selector.md`** - PHP Selector details
- **`references/php-fpm.md`** - PHP-FPM Selector details
- **`references/php-security.md`** - PHP security hardening
```

### 4.4 cwp-database (Database Management)

**File:** `skills/cwp-database/SKILL.md`

```markdown
---
name: cwp-database
description: This skill should be used when the user asks about "MySQL", "MariaDB", "PostgreSQL", "MongoDB", "database", "phpMyAdmin", "database backup", "database restore", "database migration", or "database optimization". Provides guidance for managing databases in CWP.
version: 1.0.0
---

# CWP Database Management

## Supported Databases

| Database | Management Tool | Installation |
|----------|-----------------|--------------|
| MySQL/MariaDB | phpMyAdmin | Default |
| PostgreSQL | phpPgAdmin | Manual install |
| MongoDB | Built-in Manager | Manual install |

## Configuration Files

| File | Purpose |
|------|---------|
| `/etc/my.cnf.d/server.cnf` | MariaDB config |
| `/root/.my.cnf` | MySQL root credentials |
| `/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php` | CWP DB connection |

## Common Tasks

### Create Database
```bash
# Via API
/scripts/cwp_api account create_database USERNAME DBNAME
```

### Reset MySQL Password
```bash
sh /scripts/mysql_pwd_reset
```

### Upgrade MariaDB
```bash
sed -i 's/10.2/10.4/g' /etc/yum.repos.d/mariadb.repo
systemctl stop mariadb mysql mysqld
rpm --nodeps -ev MariaDB-server
yum clean all
yum -y update "MariaDB-*"
yum -y install MariaDB-server
systemctl enable mariadb
systemctl start mariadb
mysql_upgrade --force
```

## Additional Resources

- **`references/mysql.md`** - MySQL/MariaDB details
- **`references/postgresql.md`** - PostgreSQL details
- **`references/mongodb.md`** - MongoDB details
```

### 4.5 cwp-email (Email Management)

**File:** `skills/cwp-email/SKILL.md`

```markdown
---
name: cwp-email
description: This skill should be used when the user asks about "email", "Postfix", "Dovecot", "Roundcube", "mail server", "spam filter", "DKIM", "SPF", "email configuration", "email deliverability", or "email security". Provides guidance for managing email services in CWP.
version: 1.0.0
---

# CWP Email Management

## Email Components

| Component | Software | Purpose |
|-----------|----------|---------|
| MTA | Postfix | Mail transfer |
| IMAP/POP3 | Dovecot | Mail retrieval |
| Webmail | Roundcube | Web email client |
| Anti-spam | SpamAssassin | Spam filtering |
| Anti-virus | ClamAV | Virus scanning |
| Security | SPF, DKIM, OpenDKIM | Email authentication |
| Rate Limiting | Policyd | Email rate limiting |

## Configuration Files

| File | Purpose |
|------|---------|
| `/etc/postfix/main.cf` | Postfix main config |
| `/etc/postfix/master.cf` | Postfix master config |
| `/etc/dovecot/dovecot.conf` | Dovecot config |
| `/var/vmail` | Email storage |
| `/etc/mail/spamassassin/local.cf` | SpamAssassin config |

## Common Tasks

### Rebuild Mail Server
CWP Admin → Email → MailServer Manager → Rebuild Mail Server

### Configure DKIM
1. CWP Admin → Email → DKIM Manager
2. Select domain
3. Generate DKIM key
4. Add DNS record

### Install Policyd
```bash
sh /scripts/install_cbpolicyd
```

## Additional Resources

- **`references/postfix.md`** - Postfix configuration
- **`references/dovecot.md`** - Dovecot configuration
- **`references/roundcube.md`** - Roundcube configuration
- **`references/spam-filtering.md`** - Spam filtering
```

### 4.6 cwp-dns (DNS Management)

**File:** `skills/cwp-dns/SKILL.md`

```markdown
---
name: cwp-dns
description: This skill should be used when the user asks about "DNS", "nameserver", "DNS zone", "DNS records", "BIND", "FreeDNS", "DNS cluster", "DNS template", or "DNS configuration". Provides guidance for managing DNS in CWP.
version: 1.0.0
---

# CWP DNS Management

## DNS Features

- FreeDNS Service (free DNS clustering)
- Zone Management (add, edit, list, remove)
- Template Editor (custom DNS zone templates)
- Nameserver Editor (configure nameserver IPs)
- Record Types: A, AAAA, MX, TXT, CNAME, SRV

## DNS Zone Template

**Location:** `/usr/local/cwpsrv/htdocs/resources/conf/dns/bind/zones/`

**Variables:**
- `%domain%` - Domain name
- `%dns-email%` - Email of domain owner
- `%ns1%` - Nameserver 1
- `%ns2%` - Nameserver 2
- `%ip%` - Account/domain IP address

## Common Tasks

### Setup Nameservers
1. CWP Admin → DNS Functions → Edit NameServers IPs
2. Add nameserver entries
3. Register with domain registrar

### Add DNS Zone
1. CWP Admin → DNS Functions → Add DNS Zone
2. Enter domain and IP
3. Select template

## Additional Resources

- **`references/bind.md`** - BIND configuration
- **`references/dns-templates.md`** - DNS templates
- **`references/dns-cluster.md`** - DNS clustering
```

### 4.7 cwp-security (Security Management)

**File:** `skills/cwp-security/SKILL.md`

```markdown
---
name: cwp-security
description: This skill should be used when the user asks about "security", "firewall", "CSF", "ModSecurity", "SSL", "TLS", "Let's Encrypt", "AutoSSL", "security hardening", "brute force", or "security audit". Provides guidance for securing CWP servers.
version: 1.0.0
---

# CWP Security Management

## Security Components

| Component | Purpose |
|-----------|---------|
| CSF Firewall | Network firewall |
| LFD | Login failure daemon |
| ModSecurity | Web application firewall |
| AutoSSL | Automatic SSL certificates |
| CWP Secure Kernel | MAC kernel security |
| Snuffleupagus | PHP security module |

## Critical Security Issues

**Status:** CSF Firewall discontinued (Aug 2025). Use Aetherinox fork.

**Active CVEs:**
- CVE-2025-48703: Command Injection in File Manager
- CVE-2026-57517: Blind SQL Injection (CVSS 9.8)
- CVE-2025-49113: Roundcube Vulnerability

## Common Tasks

### Enable CSF Firewall
```bash
csf -e
```

### Install SSL Certificate
1. CWP Admin → WebServer Settings → SSL Certificates → AutoSSL
2. Select domain
3. Click "Install"

### Security Hardening
1. Change SSH port
2. Enable CSF Firewall
3. Enable ModSecurity with OWASP CRS
4. Disable dangerous PHP functions
5. Enable PHP open_basedir

## Additional Resources

- **`references/csf-firewall.md`** - CSF Firewall
- **`references/mod-security.md`** - ModSecurity
- **`references/ssl-tls.md`** - SSL/TLS management
- **`references/secure-kernel.md`** - CWP Secure Kernel
```

### 4.8 cwp-backup (Backup Management)

**File:** `skills/cwp-backup/SKILL.md`

```markdown
---
name: cwp-backup
description: This skill should be used when the user asks about "backup", "restore", "disaster recovery", "backup configuration", "remote backup", "Google Drive backup", or "backup verification". Provides guidance for managing backups in CWP.
version: 1.0.0
---

# CWP Backup Management

## Backup Features

- Daily, weekly, monthly schedules
- Full, incremental, overwrite modes
- Local, SMB, NFS, S3, Google Drive, SSH remote

## Default Locations

- Backups: `/backup`
- Mail: `/var/vmail`

## Backup Issues (CRITICAL)

**Status:** Backup system in "perpetual beta" for 4+ years

**Known Issues:**
- Temporary files not cleaned up
- Email notifications unreliable
- Restore process stalls

## Common Tasks

### Configure Backup
1. CWP Admin → CWP Settings → Backup Configuration
2. Set schedule and retention
3. Configure remote destination

### Manual Backup
```bash
/scripts/user_backup USERNAME
```

### Google Drive Backup
```bash
# Install gdrive
wget -O gdrive https://drive.google.com/uc?id=ID&export=download
mv gdrive /usr/sbin/gdrive && chmod 755 /usr/sbin/gdrive

# Upload
gdrive upload --parent FOLDER_TOKEN /backup/file.tar.gz
```

## Additional Resources

- **`references/local-backup.md`** - Local backups
- **`references/remote-backup.md`** - Remote backups
- **`references/restore.md`** - Restoration
```

### 4.9 cwp-migration (Migration Tools)

**File:** `skills/cwp-migration/SKILL.md`

```markdown
---
name: cwp-migration
description: This skill should be used when the user asks about "migration", "cPanel migration", "CWP migration", "Webuzo migration", "account transfer", or "server migration". Provides guidance for migrating to CWP from other panels.
version: 1.0.0
---

# CWP Migration Tools

## Migration Paths

| Source | Method | Complexity |
|--------|--------|------------|
| cPanel (full server) | 5-script process | Medium-High |
| cPanel (single account) | CWP module | Low |
| CWP to CWP | Built-in module | Low-Medium |
| Webuzo | Manual or Softaculous | Low-Medium |

## cPanel to CWP (Full Server)

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

## cPanel to CWP (Single Account)

CWP Admin → User Account → cPanel Migration

## CWP to CWP

CWP Admin → User Accounts → CWP→CWP Migration

## Additional Resources

- **`references/cpanel-to-cwp.md`** - cPanel migration
- **`references/cwp-to-cwp.md`** - CWP migration
- **`references/other-panels.md`** - Other panels
```

### 4.10 cwp-troubleshooting (Troubleshooting)

**File:** `skills/cwp-troubleshooting/SKILL.md`

```markdown
---
name: cwp-troubleshooting
description: This skill should be used when the user asks about "troubleshooting", "error", "fix", "problem", "issue", "not working", "broken", "failed", "502", "503", "504", "403", "404", or any CWP error. Provides guidance for diagnosing and fixing CWP issues.
version: 1.0.0
---

# CWP Troubleshooting

## Common Issues

### Web Server Issues

| Issue | Solution |
|-------|----------|
| ERR_TOO_MANY_REDIRECTS | Use X-Forwarded-Proto header |
| 502 Bad Gateway | Restart PHP-FPM, increase process limit |
| 503 Service Unavailable | Check port redirection, PHP-FPM socket |
| 504 Gateway Timeout | Restart Apache/PHP-FPM, increase limits |
| Apache proxy mutex | Clear IPC semaphores |

### PHP Issues

| Issue | Solution |
|-------|----------|
| Installation failing | Need 1.5-2GB RAM, fix DNS |
| "No Loader installed" | sh /scripts/update_ioncube |
| intl extension missing | Recompile PHP with intl |

### Email Issues

| Issue | Solution |
|-------|----------|
| Can't send emails | Check DKIM/SPF/DMARC, rDNS |
| Amavisd 100% CPU | Add use_bayes 0 to SpamAssassin |
| Roundcube error | Update Roundcube, fix permissions |

### Database Issues

| Issue | Solution |
|-------|----------|
| MySQL crashed | innodb_force_recovery = 1 |
| "BAD CONFIGURATION" | Tune my.cnf |
| MariaDB upgrade failed | Follow version-specific path |

## Log Files

| Service | Log Path |
|---------|----------|
| Apache | `/usr/local/apache/logs/` |
| Nginx | `/var/log/nginx/` |
| Mail | `/var/log/maillog` |
| MySQL | `/var/lib/mysql/HOSTNAME.err` |
| CWP | `/var/log/cwp/webservers.log` |

## Additional Resources

- **`references/common-issues.md`** - Common issues
- **`references/log-analysis.md`** - Log analysis
- **`references/error-codes.md`** - Error codes
```

### 4.11 cwp-performance (Performance Tuning)

**File:** `skills/cwp-performance/SKILL.md`

```markdown
---
name: cwp-performance
description: This skill should be used when the user asks about "performance", "optimization", "speed", "caching", "compression", "Brotli", "Varnish", "OPcache", "Redis", "Memcached", or "performance tuning". Provides guidance for optimizing CWP server performance.
version: 1.0.0
---

# CWP Performance Optimization

## Caching Compatibility

| Cache | suPHP | PHP-FPM |
|-------|-------|---------|
| Varnish | Yes | Yes |
| Memcached | Yes | Yes |
| Redis | Yes | Yes |
| OPcache | No | Yes |
| APC | No | Yes |

## Brotli Compression

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

## MySQL Tuning

```ini
# /etc/my.cnf.d/server.cnf under [mysqld]
innodb_buffer_pool_size = 1G
max_connections = 500
query_cache_size = 32M
```

## Additional Resources

- **`references/caching.md`** - Caching strategies
- **`references/compression.md`** - Compression
- **`references/optimization.md`** - General optimization
```

### 4.12 cwp-api (API Integration)

**File:** `skills/cwp-api/SKILL.md`

```markdown
---
name: cwp-api
description: This skill should be used when the user asks about "API", "CWP API", "automation", "scripting", "WHMCS", "billing integration", "action hooks", or "programmatic access". Provides guidance for using CWP API and automation features.
version: 1.0.0
---

# CWP API & Automation

## API Configuration

**Setup:** CWP Settings → API Manager  
**Base URL:** `https://IPSERVERAPI:2304/v1/{function}`  
**Method:** POST  
**Auth:** API key (`key` parameter)

## API Endpoints

| Endpoint | Operations |
|----------|------------|
| `/v1/account` | add, update, delete, list, suspend, unsuspend |
| `/v1/autossl` | add, list, delete, renew |
| `/v1/databasemysql` | add, delete, list |
| `/v1/usermysql` | add, delete, list |
| `/v1/packages` | add, update, delete, list |
| `/v1/admindomains` | add, delete, list |

## Shell API

```bash
/scripts/cwp_api account remove_user USERNAME
/scripts/cwp_api webservers rebuild_all
/scripts/cwp_api apps install_softaculous
```

## Action Hooks

**Location:** `/usr/local/cwpsrv/htdocs/resources/admin/hooks/`

- DNS Hooks: dns_serial_update, dns_new_zone_add, etc.
- Account Hooks: account_new, account_remove, account_suspend, etc.

## Additional Resources

- **`references/api-endpoints.md`** - API endpoints
- **`references/api-examples.md`** - API examples
- **`references/hooks-reference.md`** - Action hooks
```

---

## 5. Commands Architecture

### 5.1 cwp-install

**File:** `commands/cwp-install.md`

```markdown
---
description: Install CWP on a fresh server
argument-hint: [os-version] [hostname] [ip-address]
allowed-tools: Bash, Read, Write
---

Install CWP (Control Web Panel) on a fresh server.

**Arguments:**
- $1: OS version (alma8, alma9, centos7, rocky8, rocky9)
- $2: Hostname (e.g., srv1.example.com)
- $3: Server IP address

**Steps:**

1. Validate OS version is supported
2. Set hostname: `hostnamectl set-hostname $2`
3. Install prerequisites:
   ```bash
   dnf install epel-release -y && dnf -y install wget && dnf -y update
   ```
4. Reboot server
5. Download and run CWP installer:
   ```bash
   cd /usr/local/src
   wget http://centos-webpanel.com/cwp-el9-latest
   sh cwp-el9-latest
   ```
6. Wait for installation to complete (30+ minutes)
7. Display login credentials and next steps

**Post-Installation:**
- Access admin panel: http://$3:2030
- Set root email
- Configure nameservers
- Create hosting packages
```

### 5.2 cwp-status

**File:** `commands/cwp-status.md`

```markdown
---
description: Check CWP server status and health
allowed-tools: Bash, Read
---

Check CWP server status and health.

**Steps:**

1. Check CWP version: `sh /scripts/cwp_version`
2. Check services status:
   - Apache: `service httpd status`
   - Nginx: `service nginx status`
   - MariaDB: `service mariadb status`
   - Postfix: `service postfix status`
   - Dovecot: `service dovecot status`
   - CSF: `csf -l`
3. Check disk usage: `df -h`
4. Check memory: `free -m`
5. Check load: `uptime`
6. Check recent errors: `tail -20 /var/log/cwp/webservers.log`

**Report:**
- CWP version and license status
- Service statuses (running/stopped)
- Resource usage (disk, memory, CPU)
- Recent errors or warnings
- Recommendations for any issues found
```

### 5.3 cwp-user

**File:** `commands/cwp-user.md`

```markdown
---
description: Manage CWP user accounts
argument-hint: [action] [username] [options]
allowed-tools: Bash, Read
---

Manage CWP user accounts.

**Actions:**
- create: Create new user account
- delete: Delete user account
- suspend: Suspend user account
- unsuspend: Unsuspend user account
- list: List all user accounts
- info: Show account details

**Examples:**
- `/cwp-user create john example.com password123 john@example.com`
- `/cwp-user delete john`
- `/cwp-user suspend john`
- `/cwp-user list`

**For create action:**
1. Validate username (6-8 chars, lowercase only)
2. Validate domain
3. Create account via API
4. Configure DNS zone
5. Install AutoSSL
6. Display account details
```

### 5.4 cwp-database

**File:** `commands/cwp-database.md`

```markdown
---
description: Manage CWP databases
argument-hint: [action] [options]
allowed-tools: Bash, Read
---

Manage CWP databases.

**Actions:**
- create: Create database and user
- delete: Delete database
- list: List databases
- backup: Backup database
- restore: Restore database
- optimize: Optimize database tables

**Examples:**
- `/cwp-database create username dbname dbuser dbpass`
- `/cwp-database backup dbname`
- `/cwp-database optimize dbname`
```

### 5.5 cwp-email

**File:** `commands/cwp-email.md`

```markdown
---
description: Manage CWP email services
argument-hint: [action] [options]
allowed-tools: Bash, Read
---

Manage CWP email services.

**Actions:**
- create: Create email account
- delete: Delete email account
- list: List email accounts
- forwarder: Create email forwarder
- autoresponder: Create autoresponder
- rebuild: Rebuild mail server

**Examples:**
- `/cwp-email create user@domain.com password`
- `/cwp-email forwarder user@domain.com forward@other.com`
- `/cwp-email rebuild`
```

### 5.6 cwp-dns

**File:** `commands/cwp-dns.md`

```markdown
---
description: Manage CWP DNS zones and records
argument-hint: [action] [options]
allowed-tools: Bash, Read
---

Manage CWP DNS zones and records.

**Actions:**
- add-zone: Add DNS zone
- delete-zone: Delete DNS zone
- add-record: Add DNS record
- delete-record: Delete DNS record
- list: List DNS zones
- setup-ns: Setup nameservers

**Examples:**
- `/cwp-dns add-zone example.com 1.2.3.4`
- `/cwp-dns add-record example.com A www 1.2.3.4`
- `/cwp-dns setup-ns ns1.example.com ns2.example.com 1.2.3.4`
```

### 5.7 cwp-ssl

**File:** `commands/cwp-ssl.md`

```markdown
---
description: Manage CWP SSL certificates
argument-hint: [action] [domain]
allowed-tools: Bash, Read
---

Manage CWP SSL certificates.

**Actions:**
- install: Install AutoSSL certificate
- renew: Renew SSL certificate
- list: List SSL certificates
- hostname: Generate hostname SSL

**Examples:**
- `/cwp-ssl install example.com`
- `/cwp-ssl renew example.com`
- `/cwp-ssl hostname`
```

### 5.8 cwp-security

**File:** `commands/cwp-security.md`

```markdown
---
description: Perform security hardening on CWP server
argument-hint: [action]
allowed-tools: Bash, Read
---

Perform security hardening on CWP server.

**Actions:**
- audit: Run security audit
- harden: Apply security hardening
- firewall: Configure CSF firewall
- modsecurity: Configure ModSecurity
- ssh: Secure SSH configuration

**Steps for harden:**
1. Change SSH port
2. Enable CSF Firewall
3. Enable ModSecurity with OWASP CRS
4. Disable dangerous PHP functions
5. Enable PHP open_basedir
6. Hide system processes
7. Configure fail2ban
8. Report changes made
```

### 5.9 cwp-backup

**File:** `commands/cwp-backup.md`

```markdown
---
description: Manage CWP backups
argument-hint: [action] [options]
allowed-tools: Bash, Read
---

Manage CWP backups.

**Actions:**
- create: Create backup
- restore: Restore from backup
- list: List backups
- configure: Configure backup settings
- verify: Verify backup integrity

**Examples:**
- `/cwp-backup create username`
- `/cwp-backup restore username backup-file.tar.gz`
- `/cwp-backup configure`
```

### 5.10 cwp-migrate

**File:** `commands/cwp-migrate.md`

```markdown
---
description: Migrate accounts to CWP
argument-hint: [source] [options]
allowed-tools: Bash, Read
---

Migrate accounts to CWP.

**Sources:**
- cpanel-single: Migrate single cPanel account
- cpanel-full: Migrate full cPanel server
- cwp: Migrate from another CWP server
- webuzo: Migrate from Webuzo

**Examples:**
- `/cwp-migrate cpanel-single /path/to/backup.tar.gz`
- `/cwp-migrate cpanel-full`
- `/cwp-migrate cwp source-server-ip api-key`
```

### 5.11 cwp-fix

**File:** `commands/cwp-fix.md`

```markdown
---
description: Fix common CWP issues
argument-hint: [issue]
allowed-tools: Bash, Read
---

Fix common CWP issues.

**Issues:**
- apache: Fix Apache issues
- nginx: Fix Nginx issues
- php: Fix PHP issues
- mysql: Fix MySQL issues
- email: Fix email issues
- dns: Fix DNS issues
- ssl: Fix SSL issues
- permissions: Fix file permissions
- panel: Fix panel access issues

**Examples:**
- `/cwp-fix apache`
- `/cwp-fix php`
- `/cwp-fix permissions username`
```

### 5.12 cwp-optimize

**File:** `commands/cwp-optimize.md`

```markdown
---
description: Optimize CWP server performance
argument-hint: [component]
allowed-tools: Bash, Read
---

Optimize CWP server performance.

**Components:**
- all: Optimize everything
- apache: Optimize Apache
- nginx: Optimize Nginx
- php: Optimize PHP
- mysql: Optimize MySQL
- caching: Configure caching
- compression: Enable compression

**Examples:**
- `/cwp-optimize all`
- `/cwp-optimize mysql`
- `/cwp-optimize caching`
```

---

## 6. Agents Architecture

### 6.1 cwp-security-auditor

**File:** `agents/cwp-security-auditor.md`

```markdown
---
name: cwp-security-auditor
description: Use this agent when the user asks to "audit security", "check security", "security scan", "find vulnerabilities", or "security assessment". Typical triggers include security audit requests, vulnerability scanning, and security hardening tasks. See "When to invoke" in the agent body.
model: inherit
color: red
tools: ["Read", "Bash", "Grep"]
---

You are a CWP security auditor specializing in server security assessment.

## When to invoke

- **Security Audit.** User requests a comprehensive security audit of their CWP server.
- **Vulnerability Scan.** User wants to identify security vulnerabilities.
- **Security Hardening.** User wants to apply security best practices.

**Your Core Responsibilities:**
1. Audit CWP server configuration
2. Identify security vulnerabilities
3. Check for known CVEs
4. Verify firewall configuration
5. Check SSL/TLS configuration
6. Audit PHP security settings
7. Check file permissions
8. Review user access controls

**Analysis Process:**
1. Check CWP version and known CVEs
2. Audit CSF Firewall configuration
3. Check ModSecurity status
4. Verify SSL certificates
5. Check PHP security settings
6. Audit file permissions
7. Review user accounts
8. Check for malware indicators
9. Generate security report

**Output Format:**
Provide a security report with:
- Critical issues (immediate action required)
- High severity issues
- Medium severity issues
- Low severity issues
- Recommendations for each issue
- Overall security score
```

### 6.2 cwp-performance-optimizer

**File:** `agents/cwp-performance-optimizer.md`

```markdown
---
name: cwp-performance-optimizer
description: Use this agent when the user asks to "optimize performance", "improve speed", "reduce load", "performance tuning", or "server optimization". Typical triggers include performance issues, slow websites, and resource optimization tasks. See "When to invoke" in the agent body.
model: inherit
color: green
tools: ["Read", "Bash", "Grep"]
---

You are a CWP performance optimizer specializing in server performance tuning.

## When to invoke

- **Performance Issues.** User reports slow websites or high server load.
- **Optimization Request.** User wants to optimize server performance.
- **Resource Issues.** User experiences high CPU, memory, or disk usage.

**Your Core Responsibilities:**
1. Analyze server resource usage
2. Identify performance bottlenecks
3. Optimize web server configuration
4. Tune PHP settings
5. Optimize database configuration
6. Configure caching
7. Enable compression
8. Monitor improvements

**Analysis Process:**
1. Check current resource usage
2. Analyze web server configuration
3. Review PHP settings
4. Check database configuration
5. Verify caching status
6. Check compression settings
7. Identify bottlenecks
8. Apply optimizations
9. Verify improvements

**Output Format:**
Provide a performance report with:
- Current performance metrics
- Identified bottlenecks
- Applied optimizations
- Expected improvements
- Recommendations for further optimization
```

### 6.3 cwp-troubleshooter

**File:** `agents/cwp-troubleshooter.md`

```markdown
---
name: cwp-troubleshooter
description: Use this agent when the user reports a "problem", "error", "issue", "not working", "broken", or "failed" with their CWP server. Typical triggers include service failures, website errors, and configuration issues. See "When to invoke" in the agent body.
model: inherit
color: yellow
tools: ["Read", "Bash", "Grep"]
---

You are a CWP troubleshooter specializing in diagnosing and fixing server issues.

## When to invoke

- **Service Failure.** A CWP service is not working.
- **Website Error.** Websites show errors (502, 503, 504, 403, 404).
- **Configuration Issue.** Something is misconfigured.

**Your Core Responsibilities:**
1. Diagnose the root cause of issues
2. Check service statuses
3. Analyze log files
4. Identify configuration problems
5. Apply fixes
6. Verify fixes work
7. Prevent recurrence

**Analysis Process:**
1. Gather symptoms from user
2. Check relevant service status
3. Analyze log files
4. Identify root cause
5. Apply appropriate fix
6. Verify fix works
7. Document solution

**Output Format:**
Provide a troubleshooting report with:
- Problem description
- Root cause analysis
- Steps taken to fix
- Verification results
- Prevention recommendations
```

### 6.4 cwp-migration-planner

**File:** `agents/cwp-migration-planner.md`

```markdown
---
name: cwp-migration-planner
description: Use this agent when the user asks to "plan migration", "migrate to CWP", "migrate from cPanel", "transfer accounts", or "server migration". Typical triggers include migration planning, account transfers, and server transitions. See "When to invoke" in the agent body.
model: inherit
color: cyan
tools: ["Read", "Bash", "Grep"]
---

You are a CWP migration planner specializing in server migration planning and execution.

## When to invoke

- **Migration Planning.** User wants to migrate to CWP from another panel.
- **Account Transfer.** User needs to transfer accounts between servers.
- **Server Transition.** User is moving to a new server.

**Your Core Responsibilities:**
1. Assess current server configuration
2. Plan migration strategy
3. Identify potential issues
4. Create migration checklist
5. Execute migration steps
6. Verify migration success
7. Handle rollback if needed

**Analysis Process:**
1. Inventory current accounts and services
2. Check compatibility
3. Plan migration order
4. Create backup strategy
5. Execute migration
6. Verify all services
7. Update DNS if needed

**Output Format:**
Provide a migration plan with:
- Current server inventory
- Migration strategy
- Step-by-step checklist
- Potential issues and mitigations
- Rollback plan
- Verification steps
```

### 6.5 cwp-backup-manager

**File:** `agents/cwp-backup-manager.md`

```markdown
---
name: cwp-backup-manager
description: Use this agent when the user asks to "manage backups", "configure backup", "verify backup", "restore from backup", or "backup strategy". Typical triggers include backup configuration, backup verification, and disaster recovery planning. See "When to invoke" in the agent body.
model: inherit
color: magenta
tools: ["Read", "Bash", "Grep"]
---

You are a CWP backup manager specializing in backup strategy and disaster recovery.

## When to invoke

- **Backup Configuration.** User wants to configure backups.
- **Backup Verification.** User wants to verify backup integrity.
- **Disaster Recovery.** User needs to restore from backup.

**Your Core Responsibilities:**
1. Configure backup schedules
2. Set up remote backup destinations
3. Verify backup integrity
4. Test restoration procedures
5. Monitor backup health
6. Manage backup retention
7. Document backup strategy

**Analysis Process:**
1. Assess current backup configuration
2. Identify critical data to backup
3. Configure backup schedules
4. Set up remote destinations
5. Test backup and restore
6. Monitor backup health
7. Document procedures

**Output Format:**
Provide a backup management report with:
- Current backup status
- Configured schedules
- Remote destinations
- Verification results
- Restoration test results
- Recommendations
```

---

## 7. Hooks Architecture

### hooks.json

```json
{
  "description": "CWP AI Agent Plugin hooks for server management automation",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/load-server-context.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/validate-command.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-server-health.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Verify that all CWP operations were completed successfully. Check for any errors or warnings. If issues remain unresolved, provide recommendations.",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

### Hook Scripts

#### load-server-context.sh

```bash
#!/bin/bash
# Load CWP server context on session start

set -euo pipefail

# Detect CWP installation
if [ -f "/scripts/cwp_version" ]; then
    CWP_VERSION=$(sh /scripts/cwp_version 2>/dev/null || echo "unknown")
    echo "export CWP_VERSION=\"$CWP_VERSION\"" >> "$CLAUDE_ENV_FILE"
    echo "export CWP_INSTALLED=true" >> "$CLAUDE_ENV_FILE"
    
    # Detect OS
    if [ -f "/etc/os-release" ]; then
        OS_ID=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        OS_VERSION=$(grep "^VERSION_ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
        echo "export CWP_OS=\"$OS_ID $OS_VERSION\"" >> "$CLAUDE_ENV_FILE"
    fi
    
    # Detect web server
    if systemctl is-active --quiet httpd 2>/dev/null; then
        echo "export CWP_WEBSERVER=apache" >> "$CLAUDE_ENV_FILE"
    elif systemctl is-active --quiet nginx 2>/dev/null; then
        echo "export CWP_WEBSERVER=nginx" >> "$CLAUDE_ENV_FILE"
    fi
    
    # Detect PHP version
    PHP_VERSION=$(php -v 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    echo "export CWP_PHP_VERSION=\"$PHP_VERSION\"" >> "$CLAUDE_ENV_FILE"
fi
```

#### validate-command.sh

```bash
#!/bin/bash
# Validate CWP commands before execution

set -euo pipefail

input=$(cat)
tool_input=$(echo "$input" | jq -r '.tool_input.command // empty')

if [ -z "$tool_input" ]; then
    exit 0
fi

# Block dangerous commands
DANGEROUS_PATTERNS=(
    "rm -rf /"
    "mkfs"
    "dd if="
    "> /dev/sd"
    "chmod 777 /"
    "chown -R root /"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if echo "$tool_input" | grep -q "$pattern"; then
        echo '{"decision": "deny", "reason": "Dangerous command detected: '"$pattern"'"}' >&2
        exit 2
    fi
done

exit 0
```

#### check-server-health.sh

```bash
#!/bin/bash
# Check server health after CWP operations

set -euo pipefail

input=$(cat)
tool_input=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only check after CWP-related commands
if ! echo "$tool_input" | grep -qE "(cwp|httpd|nginx|mariadb|postfix|dovecot)"; then
    exit 0
fi

# Check critical services
ISSUES=()

if ! systemctl is-active --quiet httpd 2>/dev/null && ! systemctl is-active --quiet nginx 2>/dev/null; then
    ISSUES+=("Web server is not running")
fi

if ! systemctl is-active --quiet mariadb 2>/dev/null; then
    ISSUES+=("MariaDB is not running")
fi

if [ ${#ISSUES[@]} -gt 0 ]; then
    echo "⚠️ Server health issues detected:" >&2
    for issue in "${ISSUES[@]}"; do
        echo "  - $issue" >&2
    done
    exit 2
fi

exit 0
```

---

## 8. MCP Integration

### .mcp.json

```json
{
  "cwp-api": {
    "command": "bash",
    "args": ["${CLAUDE_PLUGIN_ROOT}/scripts/cwp-api-client.sh"],
    "env": {
      "CWP_HOST": "${CWP_HOST}",
      "CWP_API_KEY": "${CWP_API_KEY}",
      "CWP_API_PORT": "2304"
    }
  }
}
```

### MCP Tools Provided

| Tool | Description | Parameters |
|------|-------------|------------|
| `cwp_account_create` | Create user account | domain, username, password, email, package |
| `cwp_account_delete` | Delete user account | username |
| `cwp_account_suspend` | Suspend user account | username |
| `cwp_account_unsuspend` | Unsuspend user account | username |
| `cwp_account_list` | List all accounts | none |
| `cwp_database_create` | Create database | username, dbname |
| `cwp_database_delete` | Delete database | username, dbname |
| `cwp_database_list` | List databases | username |
| `cwp_email_create` | Create email account | username, email, password |
| `cwp_email_list` | List email accounts | username |
| `cwp_dns_add_zone` | Add DNS zone | domain, ip |
| `cwp_dns_add_record` | Add DNS record | domain, type, name, value |
| `cwp_ssl_install` | Install SSL | domain |
| `cwp_service_restart` | Restart service | service_name |
| `cwp_service_status` | Check service status | service_name |
| `cwp_backup_create` | Create backup | username |
| `cwp_backup_restore` | Restore backup | username, backup_file |

---

## 9. Scripts Architecture

### cwp-api-client.sh

```bash
#!/bin/bash
# CWP API Client Script

set -euo pipefail

CWP_HOST="${CWP_HOST:-localhost}"
CWP_API_KEY="${CWP_API_KEY:-}"
CWP_API_PORT="${CWP_API_PORT:-2304}"

# Function to call CWP API
cwp_api_call() {
    local endpoint="$1"
    local action="$2"
    shift 2
    local params=("$@")
    
    local url="https://${CWP_HOST}:${CWP_API_PORT}/v1/${endpoint}"
    local data="key=${CWP_API_KEY}&action=${action}"
    
    for param in "${params[@]}"; do
        data="${data}&${param}"
    done
    
    curl -s -k -X POST "$url" -d "$data"
}

# Main command handler
case "${1:-help}" in
    account)
        cwp_api_call "account" "${2:-list}" "${@:3}"
        ;;
    database)
        cwp_api_call "databasemysql" "${2:-list}" "${@:3}"
        ;;
    email)
        cwp_api_call "email" "${2:-list}" "${@:3}"
        ;;
    dns)
        cwp_api_call "admindomains" "${2:-list}" "${@:3}"
        ;;
    ssl)
        cwp_api_call "autossl" "${2:-list}" "${@:3}"
        ;;
    help)
        echo "CWP API Client"
        echo "Usage: cwp-api-client.sh [command] [action] [params]"
        echo ""
        echo "Commands:"
        echo "  account    - Manage accounts"
        echo "  database   - Manage databases"
        echo "  email      - Manage email"
        echo "  dns        - Manage DNS"
        echo "  ssl        - Manage SSL"
        ;;
    *)
        echo "Unknown command: $1"
        exit 1
        ;;
esac
```

### cwp-health-check.sh

```bash
#!/bin/bash
# CWP Health Check Script

set -euo pipefail

echo "=== CWP Health Check ==="
echo ""

# Check CWP version
if [ -f "/scripts/cwp_version" ]; then
    echo "CWP Version: $(sh /scripts/cwp_version 2>/dev/null || echo 'unknown')"
else
    echo "CWP: Not installed"
    exit 1
fi

echo ""
echo "=== Services ==="

# Check services
services=("httpd" "nginx" "mariadb" "postfix" "dovecot" "named" "pure-ftpd")
for service in "${services[@]}"; do
    if systemctl is-active --quiet "$service" 2>/dev/null; then
        echo "✓ $service: running"
    else
        echo "✗ $service: stopped"
    fi
done

echo ""
echo "=== Resources ==="

# Disk usage
echo "Disk Usage:"
df -h / /home /var 2>/dev/null | tail -n +2

# Memory
echo ""
echo "Memory:"
free -m | head -2

# Load
echo ""
echo "Load Average:"
uptime | awk -F'load average:' '{print $2}'

echo ""
echo "=== Recent Errors ==="

# Check for recent errors
if [ -f "/usr/local/apache/logs/error_log" ]; then
    errors=$(tail -5 /usr/local/apache/logs/error_log 2>/dev/null | grep -i "error" | wc -l)
    echo "Apache errors (last 5 lines): $errors"
fi

if [ -f "/var/log/maillog" ]; then
    errors=$(tail -5 /var/log/maillog 2>/dev/null | grep -i "error\|warning" | wc -l)
    echo "Mail errors (last 5 lines): $errors"
fi

echo ""
echo "=== Health Check Complete ==="
```

### CWP CLI Command

**File:** `cli/cwp`

The CWP CLI is a unified command-line interface that wraps all CWP operations into a single `cwp` command. It provides both local server management and remote server management via SSH.

#### Installation

```bash
# Install CWP CLI
cp ${CLAUDE_PLUGIN_ROOT}/cli/cwp /usr/local/bin/cwp
chmod +x /usr/local/bin/cwp

# Or add to PATH
export PATH="${CLAUDE_PLUGIN_ROOT}/cli:$PATH"
```

#### Configuration

**Config file:** `~/.cwp-cli.conf`

```bash
# CWP CLI Configuration
CWP_HOST="your-server-ip"
CWP_API_KEY="your-api-key"
CWP_API_PORT="2304"
CWP_SSH_USER="root"
CWP_SSH_PORT="22"
CWP_SSH_KEY="~/.ssh/id_rsa"
```

#### Usage

```bash
# Local server management
cwp status
cwp user list
cwp database create mydb

# Remote server management
cwp --host 1.2.3.4 status
cwp --host 1.2.3.4 user list

# With inline credentials
cwp --host 1.2.3.4 --api-key YOUR_KEY user list
```

#### Complete CLI Implementation

```bash
#!/bin/bash
# CWP CLI - Unified Command Line Interface for CWP Management
# Version: 1.0.0

set -euo pipefail

# ============================================================================
# Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${HOME}/.cwp-cli.conf"

# Default values
CWP_HOST="${CWP_HOST:-localhost}"
CWP_API_KEY="${CWP_API_KEY:-}"
CWP_API_PORT="${CWP_API_PORT:-2304}"
CWP_SSH_USER="${CWP_SSH_USER:-root}"
CWP_SSH_PORT="${CWP_SSH_PORT:-22}"
CWP_SSH_KEY="${CWP_SSH_KEY:-}"
CWP_REMOTE="false"

# Load config file if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# ============================================================================
# Color Output
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# ============================================================================
# API Functions
# ============================================================================

cwp_api() {
    local endpoint="$1"
    local action="$2"
    shift 2
    local params=("$@")
    
    local url="https://${CWP_HOST}:${CWP_API_PORT}/v1/${endpoint}"
    local data="key=${CWP_API_KEY}&action=${action}"
    
    for param in "${params[@]}"; do
        data="${data}&${param}"
    done
    
    if [ "$CWP_REMOTE" = "true" ]; then
        ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
            "${CWP_SSH_USER}@${CWP_HOST}" \
            "curl -s -k -X POST '$url' -d '$data'"
    else
        curl -s -k -X POST "$url" -d "$data"
    fi
}

cwp_script() {
    local script="$1"
    shift
    
    if [ "$CWP_REMOTE" = "true" ]; then
        ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
            "${CWP_SSH_USER}@${CWP_HOST}" \
            "sh /scripts/${script} $*"
    else
        sh "/scripts/${script}" "$@"
    fi
}

# ============================================================================
# Command: status
# ============================================================================

cmd_status() {
    echo "=== CWP Server Status ==="
    echo ""
    
    # CWP Version
    if [ -f "/scripts/cwp_version" ] || [ "$CWP_REMOTE" = "true" ]; then
        local version
        version=$(cwp_script "cwp_version" 2>/dev/null || echo "unknown")
        echo "CWP Version: $version"
    else
        log_error "CWP not installed"
        return 1
    fi
    
    echo ""
    echo "=== Services ==="
    
    local services=("httpd" "nginx" "mariadb" "postfix" "dovecot" "named" "pure-ftpd" "csf")
    for service in "${services[@]}"; do
        if [ "$CWP_REMOTE" = "true" ]; then
            local status
            status=$(ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                "${CWP_SSH_USER}@${CWP_HOST}" \
                "systemctl is-active $service 2>/dev/null || echo 'unknown'")
        else
            local status
            status=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
        fi
        
        if [ "$status" = "active" ]; then
            echo -e "  ${GREEN}✓${NC} $service: running"
        else
            echo -e "  ${RED}✗${NC} $service: $status"
        fi
    done
    
    echo ""
    echo "=== Resources ==="
    
    if [ "$CWP_REMOTE" = "true" ]; then
        ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
            "${CWP_SSH_USER}@${CWP_HOST}" \
            "echo 'Disk:'; df -h / /home /var 2>/dev/null | tail -n +2; echo ''; echo 'Memory:'; free -m | head -2; echo ''; echo 'Load:'; uptime"
    else
        echo "Disk:"
        df -h / /home /var 2>/dev/null | tail -n +2
        echo ""
        echo "Memory:"
        free -m | head -2
        echo ""
        echo "Load:"
        uptime
    fi
}

# ============================================================================
# Command: user
# ============================================================================

cmd_user() {
    local action="${1:-list}"
    shift
    
    case "$action" in
        create)
            local domain="$1"
            local username="$2"
            local password="$3"
            local email="$4"
            local package="${5:-default}"
            
            # Validate username
            if [[ ! "$username" =~ ^[a-z]{6,8}$ ]]; then
                log_error "Username must be 6-8 lowercase letters only"
                return 1
            fi
            
            log_info "Creating account: $username ($domain)"
            cwp_api "account" "add" \
                "domain=$domain" \
                "user=$username" \
                "pass=$password" \
                "email=$email" \
                "package=$package" \
                "inode=0" \
                "limit_nproc=40" \
                "limit_nofile=100" \
                "server_ips=${CWP_HOST}"
            ;;
        delete)
            local username="$1"
            log_info "Deleting account: $username"
            cwp_api "account" "del" "user=$username" "email=admin@${CWP_HOST}"
            ;;
        suspend)
            local username="$1"
            log_info "Suspending account: $username"
            cwp_api "account" "susp" "user=$username"
            ;;
        unsuspend)
            local username="$1"
            log_info "Unsuspending account: $username"
            cwp_api "account" "unsp" "user=$username"
            ;;
        list)
            log_info "Listing accounts"
            cwp_api "account" "list"
            ;;
        info)
            local username="$1"
            log_info "Account details: $username"
            cwp_api "accountdetail" "list" "user=$username"
            ;;
        *)
            echo "Usage: cwp user [create|delete|suspend|unsuspend|list|info]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: database
# ============================================================================

cmd_database() {
    local action="${1:-list}"
    shift
    
    case "$action" in
        create)
            local username="$1"
            local dbname="$2"
            local dbuser="${3:-$username}"
            local dbpass="${4:-$(openssl rand -base64 12)}"
            
            log_info "Creating database: $dbname for $username"
            cwp_api "databasemysql" "add" "user=$username" "database=$dbname"
            cwp_api "usermysql" "add" "user=$username" "userdb=$dbuser" "pass=$dbpass" "dbase=$dbname" "host=localhost"
            echo ""
            echo "Database: $dbname"
            echo "User: $dbuser"
            echo "Password: $dbpass"
            ;;
        delete)
            local username="$1"
            local dbname="$2"
            log_info "Deleting database: $dbname"
            cwp_api "databasemysql" "del" "user=$username" "database=$dbname"
            ;;
        list)
            local username="${1:-}"
            if [ -n "$username" ]; then
                log_info "Listing databases for: $username"
                cwp_api "databasemysql" "list" "user=$username"
            else
                log_info "Listing all databases"
                cwp_script "list_databases"
            fi
            ;;
        backup)
            local dbname="$1"
            local outfile="${2:-/tmp/${dbname}_$(date +%Y%m%d_%H%M%S).sql.gz}"
            log_info "Backing up database: $dbname"
            mysqldump "$dbname" | gzip > "$outfile"
            log_success "Backup saved to: $outfile"
            ;;
        restore)
            local dbname="$1"
            local infile="$2"
            log_info "Restoring database: $dbname from $infile"
            gunzip -c "$infile" | mysql "$dbname"
            log_success "Database restored"
            ;;
        optimize)
            local dbname="$1"
            log_info "Optimizing database: $dbname"
            mysql -e "USE $dbname; SHOW TABLES;" | tail -n +2 | while read table; do
                mysql -e "OPTIMIZE TABLE $dbname.$table"
            done
            log_success "Database optimized"
            ;;
        *)
            echo "Usage: cwp database [create|delete|list|backup|restore|optimize]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: email
# ============================================================================

cmd_email() {
    local action="${1:-list}"
    shift
    
    case "$action" in
        create)
            local email_addr="$1"
            local password="$2"
            local domain="${email_addr#*@}"
            local username="${email_addr%@*}"
            
            log_info "Creating email: $email_addr"
            # Use CWP API or script
            cwp_script "create_email" "$domain" "$username" "$password"
            ;;
        delete)
            local email_addr="$1"
            local domain="${email_addr#*@}"
            local username="${email_addr%@*}"
            
            log_info "Deleting email: $email_addr"
            cwp_script "delete_email" "$domain" "$username"
            ;;
        list)
            local domain="${1:-}"
            if [ -n "$domain" ]; then
                log_info "Listing emails for: $domain"
                cwp_script "list_emails" "$domain"
            else
                log_info "Listing all emails"
                cwp_script "list_emails"
            fi
            ;;
        forwarder)
            local from="$1"
            local to="$2"
            log_info "Creating forwarder: $from -> $to"
            cwp_script "create_forwarder" "$from" "$to"
            ;;
        rebuild)
            log_info "Rebuilding mail server"
            cwp_script "rebuild_mailserver"
            ;;
        *)
            echo "Usage: cwp email [create|delete|list|forwarder|rebuild]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: dns
# ============================================================================

cmd_dns() {
    local action="${1:-list}"
    shift
    
    case "$action" in
        add-zone)
            local domain="$1"
            local ip="$2"
            log_info "Adding DNS zone: $domain ($ip)"
            cwp_api "admindomains" "add" "user=admin" "type=domain" "name=$domain"
            ;;
        delete-zone)
            local domain="$1"
            log_info "Deleting DNS zone: $domain"
            cwp_api "admindomains" "del" "user=admin" "type=domain" "name=$domain"
            ;;
        add-record)
            local domain="$1"
            local rtype="$2"
            local name="$3"
            local value="$4"
            local ttl="${5:-14400}"
            
            log_info "Adding $rtype record: $name.$domain -> $value"
            # Edit zone file directly
            if [ "$CWP_REMOTE" = "true" ]; then
                ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                    "${CWP_SSH_USER}@${CWP_HOST}" \
                    "echo '$name $ttl IN $rtype $value' >> /var/named/$domain.db && systemctl reload named"
            else
                echo "$name $ttl IN $rtype $value" >> "/var/named/$domain.db"
                systemctl reload named
            fi
            ;;
        delete-record)
            local domain="$1"
            local name="$2"
            local rtype="$3"
            
            log_info "Deleting $rtype record: $name from $domain"
            if [ "$CWP_REMOTE" = "true" ]; then
                ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                    "${CWP_SSH_USER}@${CWP_HOST}" \
                    "sed -i '/^$name.*IN $rtype/d' /var/named/$domain.db && systemctl reload named"
            else
                sed -i "/^$name.*IN $rtype/d" "/var/named/$domain.db"
                systemctl reload named
            fi
            ;;
        list)
            local domain="${1:-}"
            if [ -n "$domain" ]; then
                log_info "DNS records for: $domain"
                if [ "$CWP_REMOTE" = "true" ]; then
                    ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                        "${CWP_SSH_USER}@${CWP_HOST}" \
                        "cat /var/named/$domain.db"
                else
                    cat "/var/named/$domain.db"
                fi
            else
                log_info "Listing DNS zones"
                if [ "$CWP_REMOTE" = "true" ]; then
                    ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                        "${CWP_SSH_USER}@${CWP_HOST}" \
                        "ls /var/named/*.db 2>/dev/null | xargs -I {} basename {} .db"
                else
                    ls /var/named/*.db 2>/dev/null | xargs -I {} basename {} .db
                fi
            fi
            ;;
        setup-ns)
            local ns1="$1"
            local ns2="$2"
            local ip="$3"
            
            log_info "Setting up nameservers: $ns1, $ns2 ($ip)"
            cwp_script "setup_nameservers" "$ns1" "$ns2" "$ip"
            ;;
        *)
            echo "Usage: cwp dns [add-zone|delete-zone|add-record|delete-record|list|setup-ns]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: ssl
# ============================================================================

cmd_ssl() {
    local action="${1:-list}"
    shift
    
    case "$action" in
        install)
            local domain="$1"
            log_info "Installing SSL for: $domain"
            cwp_api "autossl" "add" "user=admin" "name=$domain"
            ;;
        renew)
            local domain="$1"
            log_info "Renewing SSL for: $domain"
            cwp_api "autossl" "renew" "user=admin" "name=$domain"
            ;;
        list)
            log_info "Listing SSL certificates"
            cwp_api "autossl" "list"
            ;;
        hostname)
            log_info "Generating hostname SSL"
            cwp_script "generate_hostname_ssl"
            ;;
        *)
            echo "Usage: cwp ssl [install|renew|list|hostname]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: security
# ============================================================================

cmd_security() {
    local action="${1:-audit}"
    shift
    
    case "$action" in
        audit)
            log_info "Running security audit"
            cwp_script "cwp_security_audit"
            ;;
        harden)
            log_info "Applying security hardening"
            
            # Change SSH port
            log_info "Changing SSH port to 2222"
            if [ "$CWP_REMOTE" = "true" ]; then
                ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                    "${CWP_SSH_USER}@${CWP_HOST}" \
                    "sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config && systemctl restart sshd"
            else
                sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
                systemctl restart sshd
            fi
            
            # Enable CSF
            log_info "Enabling CSF Firewall"
            if [ "$CWP_REMOTE" = "true" ]; then
                ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                    "${CWP_SSH_USER}@${CWP_HOST}" \
                    "csf -e"
            else
                csf -e
            fi
            
            log_success "Security hardening applied"
            ;;
        firewall)
            local fw_action="${1:-status}"
            case "$fw_action" in
                enable)
                    log_info "Enabling CSF Firewall"
                    csf -e
                    ;;
                disable)
                    log_info "Disabling CSF Firewall"
                    csf -x
                    ;;
                status)
                    csf -l
                    ;;
                *)
                    echo "Usage: cwp security firewall [enable|disable|status]"
                    ;;
            esac
            ;;
        *)
            echo "Usage: cwp security [audit|harden|firewall]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: backup
# ============================================================================

cmd_backup() {
    local action="${1:-list}"
    shift
    
    case "$action" in
        create)
            local username="$1"
            log_info "Creating backup for: $username"
            cwp_script "user_backup" "$username"
            ;;
        restore)
            local username="$1"
            local backup_file="$2"
            log_info "Restoring backup for: $username from $backup_file"
            cwp_script "restore_backup" "$username" "$backup_file"
            ;;
        list)
            log_info "Listing backups"
            if [ "$CWP_REMOTE" = "true" ]; then
                ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                    "${CWP_SSH_USER}@${CWP_HOST}" \
                    "ls -lh /backup/daily/ 2>/dev/null || echo 'No backups found'"
            else
                ls -lh /backup/daily/ 2>/dev/null || echo "No backups found"
            fi
            ;;
        configure)
            log_info "Opening backup configuration"
            echo "Navigate to: CWP Admin → CWP Settings → Backup Configuration"
            ;;
        verify)
            local backup_file="$1"
            log_info "Verifying backup: $backup_file"
            if [ "$CWP_REMOTE" = "true" ]; then
                ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                    "${CWP_SSH_USER}@${CWP_HOST}" \
                    "tar -tzf '$backup_file' > /dev/null 2>&1 && echo 'Backup is valid' || echo 'Backup is corrupted'"
            else
                tar -tzf "$backup_file" > /dev/null 2>&1 && echo "Backup is valid" || echo "Backup is corrupted"
            fi
            ;;
        *)
            echo "Usage: cwp backup [create|restore|list|configure|verify]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: service
# ============================================================================

cmd_service() {
    local action="${1:-status}"
    local service_name="${2:-all}"
    
    case "$action" in
        restart)
            if [ "$service_name" = "all" ]; then
                log_info "Restarting all services"
                for svc in httpd nginx mariadb postfix dovecot named pure-ftpd; do
                    systemctl restart "$svc" 2>/dev/null && log_success "$svc restarted" || log_warn "$svc failed to restart"
                done
            else
                log_info "Restarting: $service_name"
                systemctl restart "$service_name"
            fi
            ;;
        stop)
            log_info "Stopping: $service_name"
            systemctl stop "$service_name"
            ;;
        start)
            log_info "Starting: $service_name"
            systemctl start "$service_name"
            ;;
        status)
            if [ "$service_name" = "all" ]; then
                for svc in httpd nginx mariadb postfix dovecot named pure-ftpd csf; do
                    local status
                    status=$(systemctl is-active "$svc" 2>/dev/null || echo "unknown")
                    if [ "$status" = "active" ]; then
                        echo -e "  ${GREEN}✓${NC} $svc: running"
                    else
                        echo -e "  ${RED}✗${NC} $svc: $status"
                    fi
                done
            else
                systemctl status "$service_name"
            fi
            ;;
        *)
            echo "Usage: cwp service [restart|stop|start|status] [service-name|all]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: php
# ============================================================================

cmd_php() {
    local action="${1:-list}"
    shift
    
    case "$action" in
        list)
            log_info "Installed PHP versions"
            if [ "$CWP_REMOTE" = "true" ]; then
                ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                    "${CWP_SSH_USER}@${CWP_HOST}" \
                    "ls /opt/alt/php*/usr/bin/php 2>/dev/null | xargs -I {} {} -v | grep '^PHP'"
            else
                ls /opt/alt/php*/usr/bin/php 2>/dev/null | xargs -I {} {} -v | grep "^PHP"
            fi
            ;;
        version)
            local version="$1"
            log_info "Setting PHP version: $version"
            echo "Navigate to: CWP Admin → PHP Settings → PHP Version Switcher"
            ;;
        extensions)
            local version="${1:-}"
            if [ -n "$version" ]; then
                log_info "PHP extensions for: $version"
                if [ "$CWP_REMOTE" = "true" ]; then
                    ssh -p "$CWP_SSH_PORT" ${CWP_SSH_KEY:+-i "$CWP_SSH_KEY"} \
                        "${CWP_SSH_USER}@${CWP_HOST}" \
                        "/opt/alt/php$version/usr/bin/php -m"
                else
                    "/opt/alt/php$version/usr/bin/php" -m
                fi
            else
                log_info "Current PHP extensions"
                php -m
            fi
            ;;
        *)
            echo "Usage: cwp php [list|version|extensions]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: fix
# ============================================================================

cmd_fix() {
    local issue="${1:-all}"
    
    case "$issue" in
        apache)
            log_info "Fixing Apache issues"
            # Check if Apache is running
            if ! systemctl is-active --quiet httpd; then
                log_info "Starting Apache"
                systemctl start httpd
            fi
            # Rebuild vhosts
            log_info "Rebuilding vhosts"
            cwp_script "rebuild_vhosts"
            ;;
        nginx)
            log_info "Fixing Nginx issues"
            if ! systemctl is-active --quiet nginx; then
                log_info "Starting Nginx"
                systemctl start nginx
            fi
            ;;
        php)
            log_info "Fixing PHP issues"
            # Restart PHP-FPM
            for fpm in /opt/alt/php-fpm*/usr/sbin/php-fpm; do
                local version
                version=$(basename "$(dirname "$(dirname "$fpm")")" | sed 's/php-fpm//')
                log_info "Restarting PHP-FPM $version"
                systemctl restart "php-fpm$version" 2>/dev/null || true
            done
            ;;
        mysql)
            log_info "Fixing MySQL issues"
            if ! systemctl is-active --quiet mariadb; then
                log_info "Starting MariaDB"
                systemctl start mariadb
            fi
            ;;
        email)
            log_info "Fixing email issues"
            systemctl restart postfix dovecot
            ;;
        dns)
            log_info "Fixing DNS issues"
            systemctl restart named
            ;;
        ssl)
            log_info "Fixing SSL issues"
            cwp_script "install_acme"
            ;;
        permissions)
            local username="${1:-}"
            if [ -n "$username" ]; then
                log_info "Fixing permissions for: $username"
                cwp_script "fix_permissions" "$username"
            else
                log_info "Fixing permissions for all users"
                cwp_script "fix_all_permissions"
            fi
            ;;
        panel)
            log_info "Fixing panel access"
            cwp_script "restart_cwpsrv"
            ;;
        all)
            log_info "Fixing all common issues"
            cmd_fix apache
            cmd_fix nginx
            cmd_fix php
            cmd_fix mysql
            cmd_fix email
            cmd_fix dns
            log_success "All fixes applied"
            ;;
        *)
            echo "Usage: cwp fix [apache|nginx|php|mysql|email|dns|ssl|permissions|panel|all]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: optimize
# ============================================================================

cmd_optimize() {
    local component="${1:-all}"
    
    case "$component" in
        mysql)
            log_info "Optimizing MySQL"
            # Run MySQL tuner
            if command -v mysqltuner &>/dev/null; then
                mysqltuner
            else
                log_warn "mysqltuner not installed. Install with: yum install mysqltuner"
            fi
            ;;
        apache)
            log_info "Optimizing Apache"
            # Check MPM configuration
            log_info "Current MPM:"
            httpd -V | grep "MPM"
            ;;
        nginx)
            log_info "Optimizing Nginx"
            # Check worker processes
            log_info "Current configuration:"
            nginx -T 2>/dev/null | grep -E "worker_processes|worker_connections"
            ;;
        php)
            log_info "Optimizing PHP"
            # Check OPcache
            php -i 2>/dev/null | grep -i "opcache" | head -10
            ;;
        caching)
            log_info "Configuring caching"
            echo "Varnish, Redis, Memcached can be configured"
            echo "Navigate to: CWP Admin → WebServer Settings"
            ;;
        all)
            log_info "Optimizing all components"
            cmd_optimize mysql
            cmd_optimize apache
            cmd_optimize nginx
            cmd_optimize php
            ;;
        *)
            echo "Usage: cwp optimize [mysql|apache|nginx|php|caching|all]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: migrate
# ============================================================================

cmd_migrate() {
    local source="${1:-help}"
    shift
    
    case "$source" in
        cpanel-single)
            local backup_file="$1"
            log_info "Migrating cPanel account from: $backup_file"
            echo "Navigate to: CWP Admin → User Account → cPanel Migration"
            echo "Select backup file: $backup_file"
            ;;
        cpanel-full)
            log_info "Full cPanel server migration"
            echo "Step 1: Export data - sh 1-cpanel-data-export.sh"
            echo "Step 2: Uninstall cPanel - sh 2-cpanel-uninstall.sh"
            echo "Step 3: Install CWP - sh cwp-el7-latest"
            echo "Step 4: Import data - sh 4-import-into-cwp.sh"
            echo "Step 5: Generate mail certs - sh 5-mail-sni.sh"
            ;;
        cwp)
            local source_ip="$1"
            local api_key="$2"
            log_info "Migrating from CWP server: $source_ip"
            echo "Navigate to: CWP Admin → User Accounts → CWP→CWP Migration"
            echo "Add source server: $source_ip"
            ;;
        webuzo)
            log_info "Migrating from Webuzo"
            echo "Manual migration required:"
            echo "1. Create account in CWP"
            echo "2. Unpack Webuzo backup"
            echo "3. Create database and import"
            ;;
        *)
            echo "Usage: cwp migrate [cpanel-single|cpanel-full|cwp|webuzo]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: logs
# ============================================================================

cmd_logs() {
    local service="${1:-all}"
    local lines="${2:-50}"
    
    case "$service" in
        apache)
            log_info "Apache error log (last $lines lines)"
            tail -n "$lines" /usr/local/apache/logs/error_log
            ;;
        nginx)
            log_info "Nginx error log (last $lines lines)"
            tail -n "$lines" /var/log/nginx/error.log
            ;;
        mail)
            log_info "Mail log (last $lines lines)"
            tail -n "$lines" /var/log/maillog
            ;;
        mysql)
            log_info "MySQL error log (last $lines lines)"
            tail -n "$lines" /var/lib/mysql/*.err 2>/dev/null || echo "No MySQL error log found"
            ;;
        cwp)
            log_info "CWP webserver log (last $lines lines)"
            tail -n "$lines" /var/log/cwp/webservers.log
            ;;
        all)
            cmd_logs apache "$lines"
            echo "---"
            cmd_logs nginx "$lines"
            echo "---"
            cmd_logs mail "$lines"
            echo "---"
            cmd_logs cwp "$lines"
            ;;
        *)
            echo "Usage: cwp logs [apache|nginx|mail|mysql|cwp|all] [lines]"
            return 1
            ;;
    esac
}

# ============================================================================
# Command: help
# ============================================================================

cmd_help() {
    echo "CWP CLI - Unified Command Line Interface for CWP Management"
    echo ""
    echo "Usage: cwp [command] [subcommand] [options]"
    echo ""
    echo "Commands:"
    echo "  status      Show server status and health"
    echo "  user        Manage user accounts"
    echo "  database    Manage databases"
    echo "  email       Manage email accounts"
    echo "  dns         Manage DNS zones and records"
    echo "  ssl         Manage SSL certificates"
    echo "  security    Security management"
    echo "  backup      Backup management"
    echo "  service     Service management"
    echo "  php         PHP management"
    echo "  fix         Fix common issues"
    echo "  optimize    Performance optimization"
    echo "  migrate     Migration tools"
    echo "  logs        View service logs"
    echo "  help        Show this help message"
    echo ""
    echo "Options:"
    echo "  --host HOST       Remote server hostname/IP"
    echo "  --api-key KEY     CWP API key"
    echo "  --api-port PORT   CWP API port (default: 2304)"
    echo "  --ssh-user USER   SSH username (default: root)"
    echo "  --ssh-port PORT   SSH port (default: 22)"
    echo "  --ssh-key PATH    SSH key path"
    echo ""
    echo "Examples:"
    echo "  cwp status"
    echo "  cwp user create example.com myuser mypass my@email.com"
    echo "  cwp database create myuser mydb"
    echo "  cwp ssl install example.com"
    echo "  cwp fix apache"
    echo "  cwp --host 1.2.3.4 status"
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    # Parse global options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --host)
                CWP_HOST="$2"
                CWP_REMOTE="true"
                shift 2
                ;;
            --api-key)
                CWP_API_KEY="$2"
                shift 2
                ;;
            --api-port)
                CWP_API_PORT="$2"
                shift 2
                ;;
            --ssh-user)
                CWP_SSH_USER="$2"
                shift 2
                ;;
            --ssh-port)
                CWP_SSH_PORT="$2"
                shift 2
                ;;
            --ssh-key)
                CWP_SSH_KEY="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done
    
    # Get command
    local command="${1:-help}"
    shift || true
    
    # Execute command
    case "$command" in
        status)     cmd_status "$@" ;;
        user)       cmd_user "$@" ;;
        database)   cmd_database "$@" ;;
        email)      cmd_email "$@" ;;
        dns)        cmd_dns "$@" ;;
        ssl)        cmd_ssl "$@" ;;
        security)   cmd_security "$@" ;;
        backup)     cmd_backup "$@" ;;
        service)    cmd_service "$@" ;;
        php)        cmd_php "$@" ;;
        fix)        cmd_fix "$@" ;;
        optimize)   cmd_optimize "$@" ;;
        migrate)    cmd_migrate "$@" ;;
        logs)       cmd_logs "$@" ;;
        help|--help|-h) cmd_help ;;
        *)
            log_error "Unknown command: $command"
            cmd_help
            return 1
            ;;
    esac
}

main "$@"
```

#### CLI Commands Reference

| Command | Subcommands | Description |
|---------|-------------|-------------|
| `cwp status` | | Show server status and health |
| `cwp user` | create, delete, suspend, unsuspend, list, info | Manage user accounts |
| `cwp database` | create, delete, list, backup, restore, optimize | Manage databases |
| `cwp email` | create, delete, list, forwarder, rebuild | Manage email accounts |
| `cwp dns` | add-zone, delete-zone, add-record, delete-record, list, setup-ns | Manage DNS |
| `cwp ssl` | install, renew, list, hostname | Manage SSL certificates |
| `cwp security` | audit, harden, firewall | Security management |
| `cwp backup` | create, restore, list, configure, verify | Backup management |
| `cwp service` | restart, stop, start, status | Service management |
| `cwp php` | list, version, extensions | PHP management |
| `cwp fix` | apache, nginx, php, mysql, email, dns, ssl, permissions, panel, all | Fix common issues |
| `cwp optimize` | mysql, apache, nginx, php, caching, all | Performance optimization |
| `cwp migrate` | cpanel-single, cpanel-full, cwp, webuzo | Migration tools |
| `cwp logs` | apache, nginx, mail, mysql, cwp, all | View service logs |

#### Remote Management

```bash
# Remote server management
cwp --host 1.2.3.4 status
cwp --host 1.2.3.4 user list
cwp --host 1.2.3.4 --ssh-port 2222 service restart httpd

# With inline credentials
cwp --host 1.2.3.4 --api-key YOUR_KEY database list

# Using SSH key
cwp --host 1.2.3.4 --ssh-key ~/.ssh/myserver status
```

### Shell Completion

#### Bash Completion

**File:** `cli/cwp-completion.bash`

```bash
#!/bin/bash
# CWP CLI Bash Completion

_cwp_completions() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    commands="status user database email dns ssl security backup service php fix optimize migrate logs help"
    
    # Complete commands
    if [ "$COMP_CWORD" -eq 1 ]; then
        COMPREPLY=( $(compgen -W "$commands" -- "$cur") )
        return 0
    fi
    
    # Complete subcommands
    case "$prev" in
        user)
            COMPREPLY=( $(compgen -W "create delete suspend unsuspend list info" -- "$cur") )
            return 0
            ;;
        database)
            COMPREPLY=( $(compgen -W "create delete list backup restore optimize" -- "$cur") )
            return 0
            ;;
        email)
            COMPREPLY=( $(compgen -W "create delete list forwarder rebuild" -- "$cur") )
            return 0
            ;;
        dns)
            COMPREPLY=( $(compgen -W "add-zone delete-zone add-record delete-record list setup-ns" -- "$cur") )
            return 0
            ;;
        ssl)
            COMPREPLY=( $(compgen -W "install renew list hostname" -- "$cur") )
            return 0
            ;;
        security)
            COMPREPLY=( $(compgen -W "audit harden firewall" -- "$cur") )
            return 0
            ;;
        backup)
            COMPREPLY=( $(compgen -W "create restore list configure verify" -- "$cur") )
            return 0
            ;;
        service)
            COMPREPLY=( $(compgen -W "restart stop start status" -- "$cur") )
            return 0
            ;;
        php)
            COMPREPLY=( $(compgen -W "list version extensions" -- "$cur") )
            return 0
            ;;
        fix)
            COMPREPLY=( $(compgen -W "apache nginx php mysql email dns ssl permissions panel all" -- "$cur") )
            return 0
            ;;
        optimize)
            COMPREPLY=( $(compgen -W "mysql apache nginx php caching all" -- "$cur") )
            return 0
            ;;
        migrate)
            COMPREPLY=( $(compgen -W "cpanel-single cpanel-full cwp webuzo" -- "$cur") )
            return 0
            ;;
        logs)
            COMPREPLY=( $(compgen -W "apache nginx mail mysql cwp all" -- "$cur") )
            return 0
            ;;
    esac
    
    return 0
}

complete -F _cwp_completions cwp
```

**Installation:**
```bash
# Add to ~/.bashrc
echo 'source /path/to/cwp-completion.bash' >> ~/.bashrc
source ~/.bashrc
```

#### Zsh Completion

**File:** `cli/cwp-completion.zsh`

```zsh
#compdef cwp

_cwp() {
    local commands=(
        'status:Show server status and health'
        'user:Manage user accounts'
        'database:Manage databases'
        'email:Manage email accounts'
        'dns:Manage DNS zones and records'
        'ssl:Manage SSL certificates'
        'security:Security management'
        'backup:Backup management'
        'service:Service management'
        'php:PHP management'
        'fix:Fix common issues'
        'optimize:Performance optimization'
        'migrate:Migration tools'
        'logs:View service logs'
        'help:Show help message'
    )
    
    local user_cmds=(
        'create:Create new user account'
        'delete:Delete user account'
        'suspend:Suspend user account'
        'unsuspend:Unsuspend user account'
        'list:List all user accounts'
        'info:Show account details'
    )
    
    local database_cmds=(
        'create:Create database and user'
        'delete:Delete database'
        'list:List databases'
        'backup:Backup database'
        'restore:Restore database'
        'optimize:Optimize database tables'
    )
    
    local email_cmds=(
        'create:Create email account'
        'delete:Delete email account'
        'list:List email accounts'
        'forwarder:Create email forwarder'
        'rebuild:Rebuild mail server'
    )
    
    local dns_cmds=(
        'add-zone:Add DNS zone'
        'delete-zone:Delete DNS zone'
        'add-record:Add DNS record'
        'delete-record:Delete DNS record'
        'list:List DNS zones'
        'setup-ns:Setup nameservers'
    )
    
    local ssl_cmds=(
        'install:Install SSL certificate'
        'renew:Renew SSL certificate'
        'list:List SSL certificates'
        'hostname:Generate hostname SSL'
    )
    
    local security_cmds=(
        'audit:Run security audit'
        'harden:Apply security hardening'
        'firewall:Configure CSF firewall'
    )
    
    local backup_cmds=(
        'create:Create backup'
        'restore:Restore from backup'
        'list:List backups'
        'configure:Configure backup settings'
        'verify:Verify backup integrity'
    )
    
    local service_cmds=(
        'restart:Restart service'
        'stop:Stop service'
        'start:Start service'
        'status:Check service status'
    )
    
    local php_cmds=(
        'list:List PHP versions'
        'version:Set PHP version'
        'extensions:List PHP extensions'
    )
    
    local fix_cmds=(
        'apache:Fix Apache issues'
        'nginx:Fix Nginx issues'
        'php:Fix PHP issues'
        'mysql:Fix MySQL issues'
        'email:Fix email issues'
        'dns:Fix DNS issues'
        'ssl:Fix SSL issues'
        'permissions:Fix file permissions'
        'panel:Fix panel access issues'
        'all:Fix all common issues'
    )
    
    local optimize_cmds=(
        'mysql:Optimize MySQL'
        'apache:Optimize Apache'
        'nginx:Optimize Nginx'
        'php:Optimize PHP'
        'caching:Configure caching'
        'all:Optimize all components'
    )
    
    local migrate_cmds=(
        'cpanel-single:Migrate single cPanel account'
        'cpanel-full:Migrate full cPanel server'
        'cwp:Migrate from another CWP server'
        'webuzo:Migrate from Webuzo'
    )
    
    local logs_cmds=(
        'apache:Apache error log'
        'nginx:Nginx error log'
        'mail:Mail log'
        'mysql:MySQL error log'
        'cwp:CWP webserver log'
        'all:All logs'
    )
    
    _arguments -C \
        '1: :->command' \
        '2: :->subcommand' \
        '*:: :->args'
    
    case $state in
        command)
            _describe 'command' commands
            ;;
        subcommand)
            case $words[2] in
                user) _describe 'subcommand' user_cmds ;;
                database) _describe 'subcommand' database_cmds ;;
                email) _describe 'subcommand' email_cmds ;;
                dns) _describe 'subcommand' dns_cmds ;;
                ssl) _describe 'subcommand' ssl_cmds ;;
                security) _describe 'subcommand' security_cmds ;;
                backup) _describe 'subcommand' backup_cmds ;;
                service) _describe 'subcommand' service_cmds ;;
                php) _describe 'subcommand' php_cmds ;;
                fix) _describe 'subcommand' fix_cmds ;;
                optimize) _describe 'subcommand' optimize_cmds ;;
                migrate) _describe 'subcommand' migrate_cmds ;;
                logs) _describe 'subcommand' logs_cmds ;;
            esac
            ;;
    esac
}

_cwp "$@"
```

**Installation:**
```bash
# Add to ~/.zshrc
echo 'fpath=(/path/to/cli $fpath)' >> ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc
source ~/.zshrc
```

### MCP Server Implementation

**File:** `servers/cwp-mcp-server.js`

```javascript
#!/usr/bin/env node
/**
 * CWP MCP Server
 * Model Context Protocol server for CWP API integration
 */

const { Server } = require('@modelcontextprotocol/sdk/server/index.js');
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');
const {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} = require('@modelcontextprotocol/sdk/types.js');
const https = require('https');
const http = require('http');

// Configuration
const CWP_HOST = process.env.CWP_HOST || 'localhost';
const CWP_API_KEY = process.env.CWP_API_KEY || '';
const CWP_API_PORT = process.env.CWP_API_PORT || '2304';

/**
 * Make API call to CWP
 */
async function cwpApiCall(endpoint, action, params = {}) {
  return new Promise((resolve, reject) => {
    const url = `https://${CWP_HOST}:${CWP_API_PORT}/v1/${endpoint}`;
    
    const postData = new URLSearchParams({
      key: CWP_API_KEY,
      action: action,
      ...params
    }).toString();

    const options = {
      method: 'POST',
      rejectUnauthorized: false,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData)
      }
    };

    const req = https.request(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          resolve({ raw: data });
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

/**
 * Define available tools
 */
const TOOLS = [
  {
    name: 'cwp_account_create',
    description: 'Create a new CWP user account',
    inputSchema: {
      type: 'object',
      properties: {
        domain: { type: 'string', description: 'Main domain for the account' },
        username: { type: 'string', description: 'Username (6-8 lowercase letters)' },
        password: { type: 'string', description: 'Account password' },
        email: { type: 'string', description: 'Account owner email' },
        package: { type: 'string', description: 'Package name', default: 'default' }
      },
      required: ['domain', 'username', 'password', 'email']
    }
  },
  {
    name: 'cwp_account_delete',
    description: 'Delete a CWP user account',
    inputSchema: {
      type: 'object',
      properties: {
        username: { type: 'string', description: 'Username to delete' }
      },
      required: ['username']
    }
  },
  {
    name: 'cwp_account_suspend',
    description: 'Suspend a CWP user account',
    inputSchema: {
      type: 'object',
      properties: {
        username: { type: 'string', description: 'Username to suspend' }
      },
      required: ['username']
    }
  },
  {
    name: 'cwp_account_unsuspend',
    description: 'Unsuspend a CWP user account',
    inputSchema: {
      type: 'object',
      properties: {
        username: { type: 'string', description: 'Username to unsuspend' }
      },
      required: ['username']
    }
  },
  {
    name: 'cwp_account_list',
    description: 'List all CWP user accounts',
    inputSchema: {
      type: 'object',
      properties: {}
    }
  },
  {
    name: 'cwp_database_create',
    description: 'Create a MySQL database',
    inputSchema: {
      type: 'object',
      properties: {
        username: { type: 'string', description: 'Account username' },
        dbname: { type: 'string', description: 'Database name (max 8 chars)' }
      },
      required: ['username', 'dbname']
    }
  },
  {
    name: 'cwp_database_delete',
    description: 'Delete a MySQL database',
    inputSchema: {
      type: 'object',
      properties: {
        username: { type: 'string', description: 'Account username' },
        dbname: { type: 'string', description: 'Database name' }
      },
      required: ['username', 'dbname']
    }
  },
  {
    name: 'cwp_database_list',
    description: 'List databases for an account',
    inputSchema: {
      type: 'object',
      properties: {
        username: { type: 'string', description: 'Account username' }
      },
      required: ['username']
    }
  },
  {
    name: 'cwp_ssl_install',
    description: 'Install SSL certificate via AutoSSL',
    inputSchema: {
      type: 'object',
      properties: {
        domain: { type: 'string', description: 'Domain name for SSL' }
      },
      required: ['domain']
    }
  },
  {
    name: 'cwp_service_restart',
    description: 'Restart a CWP service',
    inputSchema: {
      type: 'object',
      properties: {
        service: { type: 'string', description: 'Service name (httpd, nginx, mariadb, postfix, etc.)' }
      },
      required: ['service']
    }
  },
  {
    name: 'cwp_service_status',
    description: 'Check service status',
    inputSchema: {
      type: 'object',
      properties: {
        service: { type: 'string', description: 'Service name' }
      },
      required: ['service']
    }
  }
];

/**
 * Create MCP server
 */
const server = new Server(
  {
    name: 'cwp-mcp-server',
    version: '1.0.0',
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

/**
 * Handle list tools request
 */
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return { tools: TOOLS };
});

/**
 * Handle call tool request
 */
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;

    switch (name) {
      case 'cwp_account_create':
        result = await cwpApiCall('account', 'add', {
          domain: args.domain,
          user: args.username,
          pass: args.password,
          email: args.email,
          package: args.package || 'default',
          inode: '0',
          limit_nproc: '40',
          limit_nofile: '100',
          server_ips: CWP_HOST
        });
        break;

      case 'cwp_account_delete':
        result = await cwpApiCall('account', 'del', {
          user: args.username,
          email: `admin@${CWP_HOST}`
        });
        break;

      case 'cwp_account_suspend':
        result = await cwpApiCall('account', 'susp', {
          user: args.username
        });
        break;

      case 'cwp_account_unsuspend':
        result = await cwpApiCall('account', 'unsp', {
          user: args.username
        });
        break;

      case 'cwp_account_list':
        result = await cwpApiCall('account', 'list');
        break;

      case 'cwp_database_create':
        result = await cwpApiCall('databasemysql', 'add', {
          user: args.username,
          database: args.dbname
        });
        break;

      case 'cwp_database_delete':
        result = await cwpApiCall('databasemysql', 'del', {
          user: args.username,
          database: args.dbname
        });
        break;

      case 'cwp_database_list':
        result = await cwpApiCall('databasemysql', 'list', {
          user: args.username
        });
        break;

      case 'cwp_ssl_install':
        result = await cwpApiCall('autossl', 'add', {
          user: 'admin',
          name: args.domain
        });
        break;

      case 'cwp_service_restart':
        const { execSync } = require('child_process');
        execSync(`systemctl restart ${args.service}`);
        result = { status: 'OK', message: `${args.service} restarted` };
        break;

      case 'cwp_service_status':
        const status = require('child_process').execSync(
          `systemctl is-active ${args.service}`
        ).toString().trim();
        result = { status: 'OK', service: args.service, state: status };
        break;

      default:
        throw new Error(`Unknown tool: ${name}`);
    }

    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify(result, null, 2)
        }
      ]
    };
  } catch (error) {
    return {
      content: [
        {
          type: 'text',
          text: JSON.stringify({ error: error.message }, null, 2)
        }
      ],
      isError: true
    };
  }
});

/**
 * Start server
 */
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  console.error('CWP MCP Server running on stdio');
}

main().catch(console.error);
```

### Installation Script

**File:** `scripts/install.sh`

```bash
#!/bin/bash
# CWP AI Agent Plugin Installer

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI_DIR="${PLUGIN_DIR}/cli"
CONFIG_FILE="${HOME}/.cwp-cli.conf"

echo "=== CWP AI Agent Plugin Installer ==="
echo ""

# Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check Node.js (for MCP server)
    if ! command -v node &>/dev/null; then
        echo "⚠️  Node.js not found. MCP server will not work."
        echo "   Install with: curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && apt-get install -y nodejs"
    else
        echo "✓ Node.js: $(node --version)"
    fi
    
    # Check jq (for JSON processing)
    if ! command -v jq &>/dev/null; then
        echo "⚠️  jq not found. Installing..."
        if command -v apt-get &>/dev/null; then
            sudo apt-get install -y jq
        elif command -v yum &>/dev/null; then
            sudo yum install -y jq
        fi
    else
        echo "✓ jq: $(jq --version)"
    fi
    
    # Check curl
    if ! command -v curl &>/dev/null; then
        echo "❌ curl not found. Please install curl."
        exit 1
    else
        echo "✓ curl: $(curl --version | head -1)"
    fi
    
    echo ""
}

# Install CLI
install_cli() {
    echo "Installing CWP CLI..."
    
    # Create symlink
    if [ -d "/usr/local/bin" ]; then
        ln -sf "${CLI_DIR}/cwp" /usr/local/bin/cwp
        chmod +x "${CLI_DIR}/cwp"
        echo "✓ CLI installed to /usr/local/bin/cwp"
    else
        echo "⚠️  /usr/local/bin not found. Add ${CLI_DIR} to your PATH"
        echo "   export PATH=\"${CLI_DIR}:\$PATH\""
    fi
    
    # Install bash completion
    if [ -f "${CLI_DIR}/cwp-completion.bash" ]; then
        if [ -d "/etc/bash_completion.d" ]; then
            sudo cp "${CLI_DIR}/cwp-completion.bash" /etc/bash_completion.d/cwp
            echo "✓ Bash completion installed"
        else
            echo "⚠️  Add to ~/.bashrc: source ${CLI_DIR}/cwp-completion.bash"
        fi
    fi
    
    echo ""
}

# Setup configuration
setup_config() {
    echo "Setting up configuration..."
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "✓ Configuration file exists: $CONFIG_FILE"
    else
        echo "Creating configuration file: $CONFIG_FILE"
        cat > "$CONFIG_FILE" << 'EOF'
# CWP CLI Configuration
# Edit these values with your server details

CWP_HOST="your-server-ip"
CWP_API_KEY="your-api-key"
CWP_API_PORT="2304"
CWP_SSH_USER="root"
CWP_SSH_PORT="22"
# CWP_SSH_KEY="~/.ssh/id_rsa"
EOF
        echo "✓ Configuration file created"
        echo "  Edit $CONFIG_FILE with your server details"
    fi
    
    echo ""
}

# Install MCP dependencies
install_mcp_deps() {
    echo "Installing MCP server dependencies..."
    
    if [ -f "${PLUGIN_DIR}/servers/package.json" ]; then
        cd "${PLUGIN_DIR}/servers"
        npm install 2>/dev/null || echo "⚠️  npm install failed. MCP server may not work."
        cd "$PLUGIN_DIR"
    else
        echo "⚠️  MCP server package.json not found"
    fi
    
    echo ""
}

# Main installation
main() {
    check_prerequisites
    install_cli
    setup_config
    install_mcp_deps
    
    echo "=== Installation Complete ==="
    echo ""
    echo "Next steps:"
    echo "1. Edit configuration: $CONFIG_FILE"
    echo "2. Set environment variables:"
    echo "   export CWP_HOST=\"your-server-ip\""
    echo "   export CWP_API_KEY=\"your-api-key\""
    echo "3. Test connection: cwp status"
    echo ""
    echo "For Claude Code integration:"
    echo "  claude plugin install ${PLUGIN_DIR}"
    echo ""
}

main "$@"
```

### Setup Wizard

**File:** `scripts/setup.sh`

```bash
#!/bin/bash
# CWP AI Agent Plugin Setup Wizard

set -euo pipefail

CONFIG_FILE="${HOME}/.cwp-cli.conf"

echo "=== CWP AI Agent Plugin Setup Wizard ==="
echo ""

# Prompt for server details
read -p "CWP Server IP/Hostname: " CWP_HOST
read -p "CWP API Key: " CWP_API_KEY
read -p "CWP API Port [2304]: " CWP_API_PORT
CWP_API_PORT="${CWP_API_PORT:-2304}"
read -p "SSH Username [root]: " CWP_SSH_USER
CWP_SSH_USER="${CWP_SSH_USER:-root}"
read -p "SSH Port [22]: " CWP_SSH_PORT
CWP_SSH_PORT="${CWP_SSH_PORT:-22}"
read -p "SSH Key Path (optional): " CWP_SSH_KEY

# Write configuration
cat > "$CONFIG_FILE" << EOF
# CWP CLI Configuration
# Generated by setup wizard on $(date)

CWP_HOST="${CWP_HOST}"
CWP_API_KEY="${CWP_API_KEY}"
CWP_API_PORT="${CWP_API_PORT}"
CWP_SSH_USER="${CWP_SSH_USER}"
CWP_SSH_PORT="${CWP_SSH_PORT}"
EOF

if [ -n "$CWP_SSH_KEY" ]; then
    echo "CWP_SSH_KEY=\"${CWP_SSH_KEY}\"" >> "$CONFIG_FILE"
fi

chmod 600 "$CONFIG_FILE"

echo ""
echo "✓ Configuration saved to: $CONFIG_FILE"
echo ""

# Test connection
echo "Testing connection..."
source "$CONFIG_FILE"

if curl -s -k "https://${CWP_HOST}:${CWP_API_PORT}/v1/account" -d "key=${CWP_API_KEY}&action=list" >/dev/null 2>&1; then
    echo "✓ Connection successful!"
else
    echo "⚠️  Connection failed. Please check your configuration."
fi

echo ""
echo "Setup complete!"
```

### Templates

#### Apache Vhost Template

**File:** `templates/vhost-apache.tpl`

```apache
# CWP AI Agent - Apache Vhost Template
# Domain: %domain%
# User: %user%
# IP: %ip%

<VirtualHost %ip%:80>
    ServerName %domain%
    ServerAlias www.%domain%
    ServerAdmin %email%
    DocumentRoot /home/%user%/public_html
    
    # PHP-FPM Configuration
    <IfModule proxy_fcgi_module>
        <FilesMatch \.php$>
            SetHandler "proxy:unix:/opt/alt/php-fpm%php_version%/usr/var/sockets/%user%.sock|fcgi://localhost"
        </FilesMatch>
    </IfModule>
    
    # Directory Configuration
    <Directory /home/%user%/public_html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    # Logging
    ErrorLog /usr/local/apache/domlogs/%domain%.error.log
    CustomLog /usr/local/apache/domlogs/%domain%.log combined
    
    # Security Headers
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
</VirtualHost>
```

#### Nginx Vhost Template

**File:** `templates/vhost-nginx.tpl`

```nginx
# CWP AI Agent - Nginx Vhost Template
# Domain: %domain%
# User: %user%
# IP: %ip%

server {
    listen %ip%:80;
    server_name %domain% www.%domain%;
    
    # Proxy to Apache
    location / {
        proxy_pass http://127.0.0.1:8181;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static files (bypass proxy)
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|svg|woff|woff2|ttf|eot)$ {
        root /home/%user%/public_html;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Security
    location ~ /\. {
        deny all;
    }
}
```

#### DNS Zone Template

**File:** `templates/dns-zone.tpl`

```
; CWP AI Agent - DNS Zone Template
; Domain: %domain%
; IP: %ip%

$TTL 14400
@       IN      SOA     %ns1%. %dns-email%. (
                        %serial%        ; Serial
                        7200            ; Refresh
                        3600            ; Retry
                        1209600         ; Expire
                        86400           ; Minimum TTL
                        )

; Nameservers
@       IN      NS      %ns1%.
@       IN      NS      %ns2%.

; A Records
@       IN      A       %ip%
www     IN      A       %ip%
mail    IN      A       %ip%
ftp     IN      A       %ip%

; MX Records
@       IN      MX      10 mail.%domain%.

; TXT Records
@       IN      TXT     "v=spf1 +a +mx +ip4:%ip% ~all"
```

#### PHP-FPM Pool Template

**File:** `templates/php-fpm-pool.tpl`

```ini
; CWP AI Agent - PHP-FPM Pool Template
; User: %user%

[%user%]
user = %user%
group = %user%

listen = /opt/alt/php-fpm%php_version%/usr/var/sockets/%user%.sock
listen.owner = %user%
listen.group = nobody
listen.mode = 0660

pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 60s
pm.max_requests = 500

php_admin_value[error_log] = /home/%user%/logs/php_error.log
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M
php_admin_value[memory_limit] = 256M
php_admin_value[max_execution_time] = 300
php_admin_value[opcache.enable] = 1
```

### Examples

**File:** `examples/install-cwp.sh`

```bash
#!/bin/bash
# Example: Install CWP on AlmaLinux 9

# Set hostname
hostnamectl set-hostname srv1.example.com

# Install prerequisites
dnf install epel-release -y
dnf -y install wget
dnf -y update

# Reboot
reboot

# After reboot, install CWP
cd /usr/local/src
wget http://centos-webpanel.com/cwp-el9-latest
sh cwp-el9-latest --restart yes --softaculous yes

# After installation completes:
echo "CWP installed! Access at: http://$(hostname -I | awk '{print $1}'):2030"
```

**File:** `examples/create-account.sh`

```bash
#!/bin/bash
# Example: Create a hosting account

# Using CWP CLI
cwp user create example.com myuser SecurePass123! admin@example.com

# Using CWP API directly
curl -k -X POST "https://localhost:2304/v1/account" \
  -d "key=YOUR_API_KEY" \
  -d "action=add" \
  -d "domain=example.com" \
  -d "user=myuser" \
  -d "pass=SecurePass123!" \
  -d "email=admin@example.com" \
  -d "package=default"
```

### Tests

**File:** `tests/test-cli.sh`

```bash
#!/bin/bash
# CWP CLI Tests

set -euo pipefail

PASS=0
FAIL=0

# Test help command
test_help() {
    echo "Testing: cwp help"
    if cwp help >/dev/null 2>&1; then
        echo "✓ PASS"
        ((PASS++))
    else
        echo "✗ FAIL"
        ((FAIL++))
    fi
}

# Test status command
test_status() {
    echo "Testing: cwp status"
    if cwp status >/dev/null 2>&1; then
        echo "✓ PASS"
        ((PASS++))
    else
        echo "✗ FAIL"
        ((FAIL++))
    fi
}

# Run tests
echo "=== CWP CLI Tests ==="
echo ""
test_help
test_status
echo ""
echo "Results: $PASS passed, $FAIL failed"
```

### README.md

```markdown
# CWP AI Agent Plugin

AI-powered God Mode plugin for CWP (Control Web Panel) management.

## Features

- 🖥️ Server management via natural language
- 👤 User account management
- 🗄️ Database management
- 📧 Email configuration
- 🌐 DNS management
- 🔒 SSL certificate management
- 🛡️ Security hardening
- 💾 Backup management
- 🚀 Performance optimization
- 🔧 Troubleshooting

## Installation

```bash
# Clone repository
git clone https://github.com/cwp-pro-centos/cwp-pro-centos.git

# Run installer
cd cwp-pro-centos
bash scripts/install.sh

# Or install as Claude Code plugin
claude plugin install ./cwp-pro-centos
```

## Configuration

Edit `~/.cwp-cli.conf`:

```bash
CWP_HOST="your-server-ip"
CWP_API_KEY="your-api-key"
CWP_API_PORT="2304"
```

## Usage

### CLI

```bash
cwp status
cwp user create example.com myuser mypass my@email.com
cwp ssl install example.com
```

### Claude Code

```
"Create a new hosting account for example.com"
"Install SSL certificate for example.com"
"Check why Apache is not starting"
```

## Documentation

- [Research Report](docs/research.md)
- [Plugin Architecture](docs/plugin.md)
- [API Reference](docs/api-reference.md)
- [CLI Reference](docs/cli-reference.md)

## License

MIT
```

### CHANGELOG.md

```markdown
# Changelog

## 1.0.0 (2026-07-21)

### Features
- CWP CLI command with 14 subcommands
- 12 skills for CWP management
- 12 slash commands
- 5 autonomous agents
- MCP server with 17 tools
- Bash and Zsh completion
- Installation and setup scripts
- Templates for Apache, Nginx, DNS, PHP-FPM
- Comprehensive documentation
```

### LICENSE

```
MIT License

Copyright (c) 2026 CWP AI Agent Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 10. Configuration System

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `CWP_HOST` | CWP server hostname/IP | localhost |
| `CWP_API_KEY` | CWP API key | (required) |
| `CWP_API_PORT` | CWP API port | 2304 |
| `CWP_SSH_USER` | SSH username | root |
| `CWP_SSH_PORT` | SSH port | 22 |
| `CWP_SSH_KEY` | SSH key path | ~/.ssh/id_rsa |

### Configuration File

**Location:** `${CLAUDE_PLUGIN_ROOT}/config.json`

```json
{
  "server": {
    "host": "your-server-ip",
    "api_port": 2304,
    "ssh_port": 22
  },
  "defaults": {
    "php_version": "8.1",
    "web_server": "nginx+apache",
    "mysql_version": "10.11"
  },
  "security": {
    "auto_ssl": true,
    "csf_enabled": true,
    "modsecurity_enabled": true
  },
  "backup": {
    "auto_backup": true,
    "retention_days": 30,
    "remote_destination": ""
  }
}
```

---

## 11. Security Model

### Input Validation

1. **Validate all user inputs** before passing to CWP API
2. **Sanitize file paths** to prevent path traversal
3. **Block dangerous commands** via PreToolUse hooks
4. **Use least privilege** for all operations

### API Security

1. **Never expose API keys** in logs or output
2. **Use HTTPS** for all API calls
3. **Validate API responses** before processing
4. **Handle errors gracefully** without exposing internals

### SSH Security

1. **Use key-based authentication** when possible
2. **Validate SSH commands** before execution
3. **Limit SSH access** to necessary operations
4. **Log all SSH commands** for audit

### File Security

1. **Validate file paths** before read/write
2. **Check file permissions** before operations
3. **Backup before modification** when possible
4. **Use atomic operations** to prevent corruption

---

## 12. Error Handling

### Error Categories

| Category | Handling |
|----------|----------|
| Connection errors | Retry with backoff, then fail with clear message |
| Authentication errors | Prompt for credentials, don't retry |
| Validation errors | Show validation failure, suggest fixes |
| API errors | Show API error message, suggest troubleshooting |
| Permission errors | Show permission issue, suggest resolution |

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "CONNECTION_FAILED",
    "message": "Failed to connect to CWP API",
    "details": "Connection refused on port 2304",
    "suggestion": "Check if CWP API is enabled and port 2304 is open in firewall"
  }
}
```

### Error Recovery

1. **Graceful degradation:** Continue with available functionality
2. **Clear error messages:** Explain what went wrong and why
3. **Actionable suggestions:** Provide steps to resolve the issue
4. **Rollback capability:** Undo changes if operation fails

---

## 13. Testing Strategy

### Unit Tests

Test individual components:
- API client functions
- Input validation
- Error handling
- Configuration parsing

### Integration Tests

Test component interactions:
- Skill triggering
- Command execution
- Agent activation
- Hook execution

### End-to-End Tests

Test complete workflows:
- Install CWP
- Create user account
- Configure web server
- Setup email
- Install SSL

### Test Environment

Use a dedicated test server:
- Fresh AlmaLinux 8 installation
- CWP installed and configured
- Test domains and accounts
- Snapshot for rollback

---

## 14. Deployment Guide

### Installation

```bash
# Clone repository
git clone https://github.com/cwp-pro-centos/cwp-pro-centos.git

# Install plugin
claude plugin install ./cwp-pro-centos

# Configure environment
export CWP_HOST="your-server-ip"
export CWP_API_KEY="your-api-key"
```

### Configuration

1. Set environment variables
2. Configure `config.json`
3. Enable API in CWP
4. Open firewall ports

### Verification

```bash
# Check plugin loaded
claude plugin list

# Test API connection
claude /cwp-status

# Run health check
claude /cwp-fix panel
```

---

## 15. Usage Guide

### Quick Start

```
# Check server status
/cwp-status

# Create user account
/cwp-user create john example.com password123 john@example.com

# Install SSL
/cwp-ssl install example.com

# Security audit
/cwp-security audit

# Fix common issues
/cwp-fix apache
```

### Natural Language Commands

```
"Create a new hosting account for john@example.com with domain example.com"
"Install SSL certificate for example.com"
"Check why Apache is not starting"
"Optimize MySQL performance"
"Migrate accounts from cPanel server 1.2.3.4"
```

### Agent Invocation

```
"Run a security audit on my server"
"Optimize my server performance"
"Help me troubleshoot email delivery issues"
"Plan migration from cPanel to CWP"
"Configure and verify backups"
```

---

**Document Version:** 1.0.0  
**Last Updated:** July 21, 2026  
**Status:** Complete
