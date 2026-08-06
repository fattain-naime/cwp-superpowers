# CWP Architecture Reference

## Overview

CentOS Web Panel (CWP) is a free web hosting control panel for CentOS, AlmaLinux, and Rocky Linux.
It uses an internal web server called **cwpsrv** (based on Nginx) to serve the admin and user panels.

---

## cwpsrv Internal Server

CWP runs its own Nginx-based server (`cwpsrv`) independent of any user-facing web server.

```
Service: cwpsrv
Binary:  /usr/local/cwpsrv/sbin/cwpsrv
Config:  /usr/local/cwpsrv/conf/cwpsrv.conf
PID:     /var/run/cwpsrv.pid
Logs:    /usr/local/cwpsrv/logs/
```

cwpsrv handles:
- Admin panel on ports 2030 (HTTP) and 2031 (HTTPS)
- User panel on ports 2082 (HTTP) and 2083 (HTTPS)
- API listener on port 2304

cwpsrv is always Nginx-based regardless of the user-selected web server (Apache, Nginx, or Varnish+Nginx).

---

## Port Assignments

| Port  | Protocol | Service                    |
|-------|----------|----------------------------|
| 2030  | HTTP     | CWP Admin Panel            |
| 2031  | HTTPS    | CWP Admin Panel (SSL)      |
| 2082  | HTTP     | CWP User Panel             |
| 2083  | HTTPS    | CWP User Panel (SSL)       |
| 2086  | HTTP     | WHM/cPanel compat (unused) |
| 2087  | HTTPS    | WHM/cPanel compat (unused) |
| 2095  | HTTP     | Webmail (optional)         |
| 2096  | HTTPS    | Webmail (optional)         |
| 2304  | HTTP     | CWP API                    |
| 80    | HTTP     | User websites              |
| 82    | HTTP     | Varnish cache (when enabled; some older configs use port 80) |
| 443   | HTTPS    | User websites (SSL)        |
| 8181  | TCP      | Apache behind Nginx reverse proxy (internal) |
| 3306  | TCP      | MySQL/MariaDB              |
| 5432  | TCP      | PostgreSQL                 |
| 25    | SMTP     | Postfix                    |
| 465   | SMTPS    | Postfix                    |
| 587   | SUBM     | Postfix                    |
| 993   | IMAPS    | Dovecot                    |
| 995   | POP3S    | Dovecot                    |
| 21    | FTP      | pure-ftpd                  |
| 22    | SSH      | OpenSSH                    |
| 53    | UDP/TCP  | BIND DNS                   |

---

## Directory Structure

```
/usr/local/cwp/               # CWP installation root
  .conf/                      # Configuration files
  conf/                       # Generated configs
  php/                        # CWP internal PHP binary
  xml/                        # Module XML definitions
  modules/                    # Module PHP files
  templates/                  # Panel templates
  plugins/                    # Plugins directory
  accounts/                   # User account data
    users/                    # Per-user directories
  ssl/                        # CWP panel SSL certs

/usr/local/cwpsrv/            # CWP internal web server
  sbin/cwpsrv                 # Binary
  conf/cwpsrv.conf            # Main config
  logs/                       # Access/error logs
  modules/                    # Nginx modules

/var/cwp/                     # Runtime data
  accounts/                   # Symlink to /usr/local/cwp/accounts

/etc/cwp/                     # CWP system configs
  .conf/                      # Symlink to /usr/local/cwp/.conf/

/home/                        # User home directories
  {username}/
    public_html/              # Document root
    .htaccess                 # Apache directives
    cgi-bin/                  # CGI scripts

/usr/local/apache/            # Apache installation
/usr/local/nginx/             # Nginx installation
/var/lib/mysql/               # MySQL data
```

---

## Module System

CWP uses an XML+PHP module system for its admin panel interface.

### Module XML Files

Located in `/usr/local/cwp/xml/`, each XML file defines:
- Module name and description
- Menu placement (navigation tree)
- Required permissions
- Associated PHP file

Example XML structure:
```xml
<module>
  <name>PHP Switcher</name>
  <description>Switch PHP versions</description>
  <file>php_switcher.php</file>
  <category>WebServer Settings</category>
  <subcategory>PHP Settings</subcategory>
</module>
```

### Module PHP Files

Located in `/usr/local/cwp/modules/`, these process form submissions and render pages.

### Key Configuration Files

| File                              | Purpose                        |
|-----------------------------------|--------------------------------|
| `/usr/local/cwp/.conf/db_conn.php`| MySQL credentials for CWP      |
| `/usr/local/cwp/.conf/cwp.conf`   | Main CWP configuration         |
| `/etc/cwp/cwp.conf`               | Symlink to above               |
| `/root/.my.cnf`                   | MySQL root credentials         |

---

## Service Management

CWP manages services via scripts in `/usr/local/cwp/bin/` and systemd units.

```
systemctl status cwpsrv          # CWP panel server
systemctl status httpd            # Apache
systemctl status nginx            # Nginx
systemctl status mysql            # MySQL/MariaDB
systemctl status postfix          # Mail server
systemctl status dovecot          # IMAP/POP3
systemctl status named            # BIND DNS
systemctl status crond            # Cron scheduler
```

---

## CWP Cron Jobs

CWP installs several cron jobs in `/etc/cron.d/cwp*`:

- `/etc/cron.d/cwp_php_switcher` - PHP version checks
- `/etc/cron.d/cwp_backup` - Backup schedule
- `/etc/cron.d/cwp_csfcron` - CSF firewall cron

Root crontab (`crontab -l`) also contains CWP entries for monitoring and updates.

---

## Web Server Modes

CWP supports four web server configurations:

1. **Apache Only** - Apache serves all traffic directly on port 80/443
2. **Nginx + Apache (Reverse Proxy)** - Nginx on port 80 handles static files, proxies PHP to Apache on port 8181
3. **Nginx + Varnish + Apache** - Varnish caches on port 82 in front of Nginx+Apache (some older CWP configs use port 80 for Varnish)
4. **Nginx Only** - Nginx + PHP-FPM on port 80 (no Apache)

Configuration is managed through the CWP admin panel under "WebServer Settings".
