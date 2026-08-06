# Changelog

All notable changes to the CWP Superpowers Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-08-06

Initial public release.

### Plugin Components

#### Skills (12)
- **cwp-core** — CWP architecture, installation, configuration, service management
- **cwp-webserver** — Apache, Nginx, Varnish, LiteSpeed configuration and management
- **cwp-php** — PHP version management (Switcher, Selector, FPM Selector), extensions, security
- **cwp-database** — MariaDB/MySQL, PostgreSQL, MongoDB management and tuning
- **cwp-email** — Postfix, Dovecot, Roundcube, SpamAssassin, Rspamd, DKIM/SPF/DMARC
- **cwp-dns** — BIND zones, records, templates, FreeDNS, DNS clustering
- **cwp-security** — CSF Firewall, ModSecurity, OWASP CRS, SSL/TLS, SSH hardening
- **cwp-backup** — Local/remote/cloud backups, scheduling, verification, restoration
- **cwp-migration** — cPanel to CWP, CWP to CWP, Webuzo migration
- **cwp-troubleshooting** — Diagnostic workflows, log analysis, common fixes
- **cwp-performance** — Varnish, Redis, Memcached, OPcache, Brotli, PHP-FPM tuning
- **cwp-api** — REST API, shell API, action hooks, billing integration

#### Commands (12)
- `/cwp-install`, `/cwp-status`, `/cwp-user`, `/cwp-database`, `/cwp-email`, `/cwp-dns`
- `/cwp-ssl`, `/cwp-security`, `/cwp-backup`, `/cwp-migrate`, `/cwp-fix`, `/cwp-optimize`

#### Agents (5)
- **cwp-security-auditor** — Comprehensive security auditing and vulnerability scanning
- **cwp-performance-optimizer** — Performance analysis and optimization
- **cwp-troubleshooter** — Issue diagnosis and resolution
- **cwp-migration-planner** — Migration planning and execution
- **cwp-backup-manager** — Backup strategy and disaster recovery

#### MCP Server
- **cwp-mcp-server.js** — 17 tools for account, database, email, DNS, SSL, service, and backup management via CWP REST API
- Stdio transport with configurable host, API key, and port via environment variables
- Input sanitization, service name validation, path traversal prevention, and 30-second API timeout

#### CLI Tool
- `cli/cwp` — Full CLI with 14 subcommands: status, user, database, email, dns, ssl, security, backup, service, php, fix, optimize, migrate, logs
- Bash and Zsh shell completions
- Interactive setup wizard (`cwp setup`)
- Remote server management via SSH
- JSON and text output formats

#### Utility Scripts (8)
- `scripts/install.sh` — Plugin installer with prerequisite checking
- `scripts/uninstall.sh` — Clean uninstaller
- `scripts/setup.sh` — Interactive server connection setup
- `scripts/cwp-api-client.sh` — Standalone REST API client
- `scripts/cwp-remote-exec.sh` — SSH remote execution with file transfer
- `scripts/cwp-backup-verify.sh` — Backup integrity verification
- `scripts/cwp-security-scan.sh` — Security vulnerability scanner
- `scripts/cwp-health-check.sh` — Health monitoring with notifications

#### Templates (7)
- `templates/vhost-apache.tpl` — Apache virtual host with PHP-FPM
- `templates/vhost-nginx.tpl` — Nginx virtual host with reverse proxy
- `templates/vhost-varnish.tpl` — Varnish VCL configuration
- `templates/dns-zone.tpl` — DNS zone with SOA, NS, A, MX, TXT, DKIM
- `templates/backup-config.tpl` — Backup configuration
- `templates/email-config.tpl` — Postfix + Dovecot + OpenDKIM
- `templates/php-fpm-pool.tpl` — PHP-FPM pool configuration

#### Examples (5)
- `examples/install-cwp.sh` — Complete CWP installation on AlmaLinux
- `examples/create-account.sh` — Create hosting account with database, email, DNS, SSL
- `examples/setup-email.sh` — Configure email with DKIM/SPF/DMARC
- `examples/configure-ssl.sh` — Install Let's Encrypt SSL
- `examples/security-hardening.sh` — Apply security hardening

#### Tests (3)
- `tests/test-cli.sh` — CLI unit tests
- `tests/test-api.sh` — API connectivity and authentication tests
- `tests/test-integration.sh` — Full integration tests

### Hooks (10 Event Types)
- **SessionStart** — Loads CWP server context (version, OS, services, PHP)
- **PreToolUse** (Bash) — Validates commands, blocks dangerous patterns (rm -rf /, mkfs, wget|sh, curl|sh)
- **PreToolUse** (CWP API) — Validates CWP API calls for safety
- **PostToolUse** (Bash) — Checks server health after CWP-related commands
- **PostToolUse** (Write|Edit) — Validates config file syntax (Apache, Nginx, BIND, PHP)
- **PostToolUseFailure** (CWP API) — Analyzes API errors and suggests fixes
- **Stop** — Verifies all CWP operations completed successfully
- **SubagentStart** — Logs CWP agent sessions
- **SubagentStop** — Summarizes subagent findings
- **PreCompact** — Preserves CWP context before compaction
- **SessionEnd** — Logs session end
- **FileChanged** — Warns when critical config files change externally

### Security
- Command injection prevention via input validation (`^[a-zA-Z0-9_]+$`) for database names and usernames
- SQL injection prevention with validated inputs and parameterized operations
- JSON injection prevention using `jq` for all JSON construction in hooks, CLI, and API client
- SSH MITM prevention with `StrictHostKeyChecking=accept-new` (auto-accepts new, rejects changed)
- MCP server path traversal prevention (rejects `..`, requires `/backup/` prefix)
- MCP server 30-second API timeout to prevent indefinite hangs
- Dangerous command blocklist using regex mode (`wget.*|.*sh`, `curl.*|.*sh`, `rm -rf /`, `mkfs`, etc.)
- Sensitive operation warnings for `rm -rf`, `systemctl stop`, `iptables -F`, `csf -x`
- Config file syntax validation after Apache, Nginx, BIND, and PHP config edits
- Server health checks after CWP-related shell commands

### Dual-Path Resolution
All skills implement dynamic detection to support different CWP versions:

| What Varies | Detection |
|-------------|-----------|
| Backup script name | `user_backup` OR `backup_user` |
| Backup directory structure | `/backup/daily/{user}/` OR `/backup/{user}/` |
| SSL script name | `generate_hostname_ssl` OR `generate_ssl` |
| ACME/renewal script | `install_acme` OR `renew_lets_encrypt` |
| Varnish listening port | 82 OR 80 (detected via `ss -tlnp`) |
| Varnish backend port | 8181 OR 8080 (detected via `default.vcl`) |
| PHP-FPM service name | `php-fpm`, `php83-php-fpm`, `php-fpm83`, `php-fpm81`, etc. |
| Installed PHP versions | Detected via `ls /opt/alt/ \| grep php` |
| Permissions fix method | `/scripts/cwp_api account fix_perms` OR `/scripts/fix_permissions` |

### Verified Against Live Server
Plugin claims verified against a live CWP server (node.ownpay.org):
- **OS:** AlmaLinux 8.10
- **CWP:** 0.9.8.1244
- **Services confirmed:** Apache, Nginx, MariaDB 10.3, Postfix, Dovecot, BIND 9.11, Pure-FTPd, Redis 5.0, Varnish 6.4, CSF v15.00, PHP 8.3
- **Scripts confirmed:** All referenced scripts verified to exist on live server
- **Paths confirmed:** Config files, backup directories, DNS zones, email storage
- **Ports confirmed:** 2030, 2031, 2086, 2087, 2082, 2083, 2304, 82, 8181

### Documentation
- `README.md` — Installation, configuration, CLI reference, scripts, templates, examples
- `CHANGELOG.md` — This file
- `CONTRIBUTING.md` — Contributing guidelines
- `LICENSE` — MIT License
- `docs/research.md` — Comprehensive CWP research (200+ wiki articles, 11,000+ forum topics)
- `docs/plugin.md` — Complete plugin architecture design document
