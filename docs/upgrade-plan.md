# CWP Superpowers Plugin — Upgrade Plan v1.0.0

**Date:** August 6, 2026
**Status:** Plan (Pending Approval)
**Repository:** github.com/fattain-naime/cwp-superpowers

---

## 1. Executive Summary

This upgrade transforms the plugin from a documentation-researched prototype into a production-ready, live-server-verified plugin. Changes are categorized into security fixes, accuracy corrections, dual-path resolution, and configuration cleanup.

**Scope:** ~35 files across scripts, skills, reference files, MCP server, hooks, and configuration.

---

## 2. What's New

### 2.1 Dual-Path Resolution System

A runtime detection pattern that lets the AI agent work across different CWP versions without hardcoded assumptions.

**Pattern:**
```bash
if [ -f /scripts/new_name ]; then
    sh /scripts/new_name ARGS
elif [ -f /scripts/old_name ]; then
    sh /scripts/old_name ARGS
fi
```

**Detection table:**

| What Varies | New (CWP 0.9.8.1244) | Old (CWP 0.9.8.1178+) | How to Detect |
|-------------|---------------------|----------------------|---------------|
| Backup script | `/scripts/user_backup` | `/scripts/backup_user` | `[ -f /scripts/user_backup ]` |
| SSL generation | `/scripts/generate_hostname_ssl` | `/scripts/generate_ssl` | `[ -f /scripts/generate_hostname_ssl ]` |
| ACME renewal | `/scripts/install_acme` | `/scripts/renew_lets_encrypt` | `[ -f /scripts/install_acme ]` |
| Permissions fix | `/scripts/cwp_api account fix_perms` | `/scripts/fix_permissions` | API always works |
| Backup directory | `/backup/daily/{user}/` | `/backup/{user}/` | `[ -d "/backup/daily" ]` |
| Varnish port | 82 | 80 | `ss -tlnp \| grep varnish` |
| Varnish backend | 8181 | 8080 | `grep .port /etc/varnish/default.vcl` |
| PHP-FPM service | `php83-php-fpm`, `php-fpm83` | `php-fpm`, `php-fpm81` | `systemctl is-active` loop |
| FTP service | `pure-ftpd` | `vsftpd` (incorrect docs) | `systemctl is-active` |

### 2.2 `.gitignore` (New File)

Excludes runtime artifacts from version control:
- `.playwright-mcp/`, `.remember/`, `.zcode/plans/`
- `servers/node_modules/`, `logs/`
- `.env`, editor files

### 2.3 Script Resolution Helper (cwp-core SKILL.md)

New `cwp_resolve_script()` function for general-purpose script discovery.

### 2.4 Input Validation Functions (cli/cwp)

New `validate_db_name()` and `validate_username()` enforcing `^[a-zA-Z0-9_]+$`.

### 2.5 Safe JSON Construction Helper (scripts/cwp-api-client.sh)

New `json_create()` function using `jq -n` for all JSON body construction.

---

## 3. What's Fixed

### 3.1 Critical Security Fixes (8)

| # | Vulnerability | File | Root Cause | Fix |
|---|--------------|------|-----------|-----|
| 1 | Command blocklist broken | `hooks/scripts/validate-command.sh` | `grep -qF` with regex patterns never matches | Switch to regex mode, use `jq` for JSON |
| 2 | SQL injection | `cli/cwp` lines 297-315 | DB names interpolated into SQL | Add input validation |
| 3 | Command injection | `cli/cwp` line 272 | `echo '$user:$pass'\|chpasswd` quote breakout | `printf` pipe with validation |
| 4 | Invalid JSON output | `cli/cwp` lines 63-69 | Broken when values contain quotes | Use `jq` or proper escaping |
| 5 | JSON injection in hooks | `hooks/scripts/validate-config-syntax.sh`, `check-server-health.sh` | String interpolation into JSON | Use `jq` |
| 6 | JSON injection in API client | `scripts/cwp-api-client.sh` (17+ locations) | String interpolation into JSON | Use `json_create()` with `jq` |
| 7 | No API timeout | `servers/cwp-mcp-server.js` | Requests hang indefinitely | Add `req.setTimeout(30000)` |
| 8 | Path traversal | `servers/cwp-mcp-server.js` | `../../` passes sanitization | Reject `..`, require `/backup/` |

### 3.2 SSH Hardening (6 files)

`StrictHostKeyChecking=no` changed to `accept-new` in:
- `cli/cwp`, `scripts/setup.sh`, `scripts/cwp-health-check.sh`
- `scripts/cwp-security-scan.sh`, `scripts/cwp-backup-verify.sh`, `scripts/cwp-remote-exec.sh`

### 3.3 Configuration Fixes (6)

| Fix | File | Before | After |
|-----|------|--------|-------|
| Repo URL | `config.json`, `plugin.json` | `your-org/cwp-pro-centos` | `fattain-naime/cwp-superpowers` |
| Author | `plugin.json` | `CWP AI Agent Team` | `Fattain Naime` |
| Duplicate MCP def | `config.json` | Wrong path `src/mcp-server.js` | Removed |
| MCP transport | `.mcp.json` | No type field | `"type": "stdio"` |
| Hook log paths | `hooks/hooks.json` | `/tmp/` | `${CLAUDE_PLUGIN_ROOT}/logs/` |
| Heredoc expansion | `scripts/install.sh` | `<<'CONF'` literal | `<<CONF` with `gen_date` |

---

## 4. What's Removed

| Removed From | What | Reason |
|-------------|------|--------|
| `config.json` | `mcp.server`, `mcp.tools`, `mcp.resources` | Duplicate/non-standard |
| `skills/cwp-security/references/mod-security.md` | `/scripts/modsec_install` | Does not exist |
| `skills/cwp-migration/references/other-panels.md` | `/scripts/create_user` | Does not exist |
| `skills/cwp-migration/references/other-panels.md` | `/scripts/rebuild_httpd` | Does not exist |
| `skills/cwp-migration/references/other-panels.md` | `/scripts/rebuild_dns` | Does not exist |
| `skills/cwp-migration/references/other-panels.md` | `/scripts/fix_permissions` | Does not exist |
| `skills/cwp-php/references/php-switcher.md` | `/scripts/php_switcher` CLI | Does not exist |
| `skills/cwp-api/references/api-endpoints.md` | `/scripts/genkey` | Does not exist |
| `skills/cwp-api/references/api-examples.md` | `/scripts/genkey` | Does not exist |
| `skills/cwp-backup/references/restore.md` | `/scripts/restore_user` | Does not exist |
| `skills/cwp-core/references/scripts-reference.md` | `/scripts/restore_user` | Does not exist |
| `skills/cwp-core/references/scripts-reference.md` | `/scripts/fix_permissions` | Does not exist |
| `skills/cwp-core/references/architecture.md` | `vsftpd` | Wrong — actual is `pure-ftpd` |
| `skills/cwp-core/references/config-files.md` | vsftpd config section | Wrong — actual is Pure-FTPd |

---

## 5. What's Changed in Skills

### 5.1 SKILL.md Files (9 of 12)

| Skill | Changes |
|-------|---------|
| `cwp-core` | Added `cwp_resolve_script()`, expanded verified script list |
| `cwp-backup` | Backup dir detection, dual-path script, restore with `find` fallback |
| `cwp-security` | SSL dual-path, ACME fallback |
| `cwp-webserver` | Varnish port detection, backend port detection |
| `cwp-php` | PHP-FPM service detection loop, PHP version detection |
| `cwp-troubleshooting` | PHP-FPM service detection for 502/503/504 |
| `cwp-performance` | Varnish port detection, PHP-FPM version detection |
| `cwp-api` | Dual-path backup script in automation example |
| `cwp-migration` | Dual-path backup script and directory for CWP-to-CWP |

**No changes needed (3):** `cwp-database`, `cwp-dns`, `cwp-email`

### 5.2 Reference Files (18 files)

| File | Key Changes |
|------|-------------|
| `cwp-core/references/scripts-reference.md` | Script name variations section, 30+ path fixes |
| `cwp-core/references/architecture.md` | vsftpd→pure-ftpd, added port 82/8181 |
| `cwp-core/references/config-files.md` | php_version 8.1→8.3, vsftpd→pure-ftpd |
| `cwp-backup/references/local-backup.md` | `/backup/daily/` structure, dual-path script |
| `cwp-backup/references/restore.md` | Removed non-existent scripts, API alternatives |
| `cwp-security/references/ssl-tls.md` | Dual-path SSL/ACME scripts |
| `cwp-security/references/mod-security.md` | Removed `modsec_install`, panel-based |
| `cwp-webserver/references/varnish.md` | Port 80→82, 8080→8181, detection commands |
| `cwp-performance/references/caching.md` | Varnish port 80→82, detection |
| `cwp-php/references/php-fpm.md` | Service name detection loop |
| `cwp-php/references/php-selector.md` | Version detection, supported vs installed |
| `cwp-php/references/php-switcher.md` | Panel-based switching |
| `cwp-migration/references/cpanel-to-cwp.md` | External scripts note |
| `cwp-migration/references/cwp-to-cwp.md` | Dual-path backup, API alternatives |
| `cwp-migration/references/other-panels.md` | All scripts → API alternatives |
| `cwp-api/references/hooks-reference.md` | Dual-path backup script |
| `cwp-api/references/api-endpoints.md` | Version 0.9.8.1178→0.9.8.1244 |
| `cwp-api/references/api-examples.md` | Panel-based API key gen |

---

## 6. Upgrade Process

### 6.1 Implementation Order

**Phase 1 — Security Fixes (Critical)**
1. Fix `validate-command.sh` grep mode
2. Fix `cli/cwp` SQL injection, command injection, json_output
3. Fix `cwp-api-client.sh` JSON injection
4. Fix `validate-config-syntax.sh` and `check-server-health.sh` JSON injection
5. Fix `cwp-mcp-server.js` timeout and path traversal

**Phase 2 — SSH Hardening**
6. Update all 6 scripts to `accept-new`

**Phase 3 — Configuration Cleanup**
7. Update `config.json`, `plugin.json`, `.mcp.json`, `hooks/hooks.json`
8. Fix `install.sh` heredoc
9. Create `.gitignore`

**Phase 4 — Skill Updates**
10. Update 9 SKILL.md files with dual-path patterns

**Phase 5 — Reference File Updates**
11. Update 18 reference files

**Phase 6 — Documentation**
12. Rewrite `CHANGELOG.md` as fresh v1.0.0
13. Update `README.md`

### 6.2 Validation Checklist

```bash
# Bash syntax
for f in hooks/scripts/*.sh scripts/*.sh cli/cwp; do bash -n "$f"; done

# JSON syntax
for f in hooks/hooks.json .mcp.json config.json .claude-plugin/plugin.json; do
    node -e "JSON.parse(require('fs').readFileSync('$f','utf8'))"
done

# JS syntax
node -c servers/cwp-mcp-server.js

# Security fixes present
grep -q "validate_db_name" cli/cwp
grep -q "accept-new" cli/cwp
grep -q "req.setTimeout" servers/cwp-mcp-server.js

# Dual-path patterns present
grep -q "user_backup" skills/cwp-core/SKILL.md
grep -q "generate_hostname_ssl" skills/cwp-security/SKILL.md
grep -q "ss -tlnp" skills/cwp-webserver/SKILL.md
grep -q "php83-php-fpm" skills/cwp-php/SKILL.md
grep -q "backup/daily" skills/cwp-backup/SKILL.md
```

---

## 7. Verification Against Live Server

All claims verified against node.ownpay.org (AlmaLinux 8.10, CWP 0.9.8.1244):

| Item | Verified |
|------|----------|
| `/scripts/user_backup` exists (not `backup_user`) | ✅ |
| `/scripts/generate_hostname_ssl` exists (not `generate_ssl`) | ✅ |
| `/scripts/install_acme` exists | ✅ |
| `/backup/daily/` structure exists | ✅ |
| Varnish on port 82, backend 8181 | ✅ |
| PHP 8.3 only | ✅ |
| Pure-FTPd (not vsftpd) | ✅ |
| CSF v15.00 active | ✅ |
| 12 services running | ✅ |

---

## 8. File Count Summary

| Category | Modified | Created |
|----------|----------|---------|
| Security fixes (scripts) | 8 | 0 |
| SSH hardening | 6 | 0 |
| Configuration | 6 | 1 (.gitignore) |
| SKILL.md files | 9 | 0 |
| Reference files | 18 | 0 |
| Documentation | 2 | 0 |
| **Total** | **~35** | **1** |

---

## 9. Decisions Required

1. **Dual-path vs single path** — Support both old and new CWP script names, or latest only?
2. **jq dependency** — Acceptable for JSON safety, or need pure-bash fallbacks?
3. **SSH `accept-new`** — Acceptable trade-off?
4. **Scope** — Update all 18 reference files, or critical ones only?
