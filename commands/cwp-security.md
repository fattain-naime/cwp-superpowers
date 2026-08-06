---
description: Security hardening and auditing for CWP servers
argument-hint: <action>
allowed-tools: Bash, Read, Write, Edit, Grep
---

# CWP Security Hardening Command

You are performing security operations on a CWP server. Determine the action from `$1` and execute accordingly.

## Arguments

- `$1` — Action: `audit`, `harden`, `firewall`, `modsecurity`, `ssh`

## Step 1: Validate Action

Confirm `$1` is one of the supported actions. If not, display usage and stop.

## Step 2: Execute Action

### audit
Perform a comprehensive security audit and report findings:

- **Open ports**: Run `ss -tlnp` and list all listening services. Flag unexpected ports.
- **Firewall status**: Check if CSF is running (`csf -v`). Review `/etc/csf/csf.conf` for key settings (TESTING mode, port flood protection).
- **SSH security**: Check `/etc/ssh/sshd_config` for: PermitRootLogin, PasswordAuthentication, Port, MaxAuthTries, Protocol.
- **File permissions**: Check permissions on critical files: `/etc/shadow` (640), `/etc/passwd` (644), `/etc/my.cnf` (644), `.my.cnf` in root (600).
- **PHP security**: Check `php.ini` for: expose_php, display_errors, allow_url_include, disable_functions.
- **SSL certificates**: Check expiry dates for all certificates in use.
- **User accounts**: List users with shell access (non-nologin shells). Flag any unexpected users.
- **SUID/SGID binaries**: Run `find / -perm /6000 -type f 2>/dev/null` and flag unusual entries.
- **Outdated packages**: Run `yum check-update` and flag security-related updates.
- Compile findings into a severity-rated report (Critical/High/Medium/Low/Info).

### harden
Apply security hardening measures:

- **SSH hardening**: Set `PermitRootLogin prohibit-password`, `PasswordAuthentication no` (if SSH keys exist), `MaxAuthTries 3`, change default port if desired.
- **Firewall**: Ensure CSF is installed and not in TESTING mode. Set `TESTING = "0"`.
- **PHP hardening**: Set `expose_php = Off`, `display_errors = Off`, `allow_url_include = Off`, add dangerous functions to `disable_functions`.
- **File permissions**: Fix permissions on critical files.
- **Disable unused services**: List and disable services that are not needed.
- **Kernel hardening**: Add sysctl settings: `net.ipv4.conf.all.rp_filter = 1`, `net.ipv4.icmp_echo_ignore_broadcasts = 1`, `net.ipv4.conf.all.accept_redirects = 0`.
- Apply each change and report what was modified.

### firewall
Manage the CSF firewall:

- Check CSF status: `csf -v`.
- Review current rules: `csf -l`.
- If `$2` is `allow`, add an IP to the allow list: `csf -a $3 "$4"`.
- If `$2` is `deny`, block an IP: `csf -d $3 "$4"`.
- If `$2` is `remove`, remove an IP: `csf -ar $3` or `csf -dr $3`.
- If `$2` is `restart`, restart CSF: `csf -ra`.
- If no sub-action, display current allow/deny lists and SYN flood protection status.

### modsecurity
Manage ModSecurity WAF:

- Check if ModSecurity is installed: `httpd -M 2>/dev/null | grep security` or `nginx -V 2>&1 | grep modsec`.
- Check current configuration: review `/etc/httpd/conf.d/mod_security.conf` or the Nginx equivalent.
- If `$2` is `enable`, enable ModSecurity and restart the web server.
- If `$2` is `disable`, disable ModSecurity and restart.
- If `$2` is `rules`, list or update the active rule sets (OWASP CRS).
- If `$2` is `logs`, show recent ModSecurity audit log entries: `tail -50 /var/log/httpd/modsec_audit.log`.

### ssh
Manage SSH configuration:

- Display current SSH config: port, authentication methods, allowed users.
- If `$2` is `port`, change the SSH port to `$3` and update CSF and SELinux.
- If `$2` is `key`, manage SSH keys for user `$3`.
- If `$2` is `lockdown`, restrict SSH to specific users/groups.
- After any change, restart sshd and verify connectivity before closing the session.

## Step 3: Report

Compile all changes or findings into a clear report. For the `audit` action, include a remediation priority list. Log all actions to `/var/log/cwp/security-actions.log`.
