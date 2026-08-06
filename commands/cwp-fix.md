---
description: Diagnose and fix common CWP server issues
argument-hint: <issue>
allowed-tools: Bash, Read, Write, Edit, Grep
---

# CWP Fix Command

You are diagnosing and fixing issues on a CWP server. Determine the issue from `$1` and apply the appropriate fix.

## Arguments

- `$1` — Issue type: `apache`, `nginx`, `php`, `mysql`, `email`, `dns`, `ssl`, `permissions`, `panel`, `all`

## Step 1: Validate Issue Type

Confirm `$1` is one of the supported issues. If not, display usage and stop.

## Step 2: Diagnose and Fix

### apache
- Check if httpd is running: `systemctl status httpd`.
- If stopped, attempt to start: `systemctl start httpd`.
- If it fails to start, run `httpd -t` to check for configuration syntax errors.
- Check error log: `tail -50 /var/log/httpd/error_log`.
- Common fixes: fix syntax errors in vhost configs, free port 80/443 if occupied, restart with `systemctl restart httpd`.

### nginx
- Check if nginx is running: `systemctl status nginx`.
- If stopped, attempt to start.
- Check config: `nginx -t`.
- Check error log: `tail -50 /var/log/nginx/error_log`.
- Common fixes: fix upstream config, resolve port conflicts with Apache, reload config.

### php
- Check PHP-FPM: `systemctl status php-fpm`.
- Check PHP version and active configuration: `php -v` and `php --ini`.
- Review PHP error log: `tail -50 /var/log/php-fpm/error.log`.
- Check for module issues: `php -m`.
- Common fixes: restart PHP-FPM, fix php.ini syntax, install missing extensions, adjust memory_limit.

### mysql
- Check MariaDB/MySQL: `systemctl status mariadb`.
- If stopped, attempt to start.
- Check error log: `tail -50 /var/log/mariadb/mariadb.log`.
- Test connectivity: `mysql -e "SELECT 1"`.
- Check for crashed tables: `mysqlcheck --all-databases --check`.
- Common fixes: repair tables with `mysqlcheck --repair`, fix InnoDB recovery settings, increase buffer pool size.

### email
- Check Postfix: `systemctl status postfix`.
- Check Dovecot: `systemctl status dovecot`.
- Test SMTP: `telnet localhost 25`.
- Test IMAP: `telnet localhost 143`.
- Check mail log: `tail -50 /var/log/maillog`.
- Common fixes: restart services, fix Postfix config (`postfix check`), rebuild virtual maps, fix DNS MX records.

### dns
- Check BIND/named: `systemctl status named`.
- Validate config: `named-checkconf`.
- Check zone files: `named-checkzone <domain> /var/named/<domain>.db`.
- Test resolution: `dig @localhost <domain>`.
- Common fixes: fix zone file syntax, reload named, fix serial numbers, add missing records.

### ssl
- Check certificate validity: `openssl x509 -in /path/to/cert.pem -noout -dates`.
- Check certificate chain: `openssl verify -CAfile chain.pem cert.pem`.
- Test SSL connection: `echo | openssl s_client -connect domain:443`.
- Common fixes: renew expired certificates, fix certificate chain, update vhost SSL paths.

### permissions
- Check ownership of user home directories: `ls -la /home/`.
- Fix common permission issues:
  - `chown -R <user>:<user> /home/<user>/public_html`
  - `chmod 750 /home/<user>/public_html`
  - `chmod 600 /home/<user>/.my.cnf` (if exists)
- Check and fix `/tmp` permissions: should be 1777.
- Fix cron permissions: `/etc/cron.d/` should be 755.

### panel
- Check CWP panel service: `systemctl status cwpsrv`.
- If stopped, start it: `systemctl start cwpsrv`.
- Check panel logs: `tail -50 /usr/local/cwpsrv/logs/error_log`.
- Verify panel SSL certificate.
- Test panel access: `curl -sk -o /dev/null -w "%{http_code}" https://localhost:2031`.
- Common fixes: restart cwpsrv, fix SSL cert, reset admin password via `/scripts/admin_password_change`.

### all
- Run diagnostics for all issue types in sequence: apache, nginx, php, mysql, email, dns, ssl, permissions, panel.
- For each, check the service status and report issues found.
- Apply safe fixes (restarts, config validation) automatically.
- Report issues that require manual intervention.

## Step 3: Report

After fixes are applied, verify the service is running and functional. Display a summary of issues found and fixes applied. Log all actions to `/var/log/cwp/fix-actions.log`.
