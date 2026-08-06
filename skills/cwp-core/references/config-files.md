# CWP Configuration Files Reference

## Primary Configuration Directory

```
/usr/local/cwp/.conf/
```

All critical CWP configuration files reside here. A symlink exists at `/etc/cwp/.conf/`.

---

## db_conn.php

**Path:** `/usr/local/cwp/.conf/db_conn.php`

Database credentials for the CWP panel itself (not user databases).

```php
<?php
$db_host = 'localhost';
$db_name = 'cwp';
$db_user = 'root';
$db_pass = 'MySQLRootPassword';
$db_port = 3306;
```

This file is read by every CWP panel page. If corrupted, the panel will not load.

---

## .my.cnf (Root MySQL Config)

**Path:** `/root/.my.cnf`

```ini
[client]
user=root
password=MySQLRootPassword
host=localhost
```

Used by CWP scripts to connect to MySQL without prompting for passwords. Also used by `mysql` CLI as root.

---

## cwp.conf

**Path:** `/usr/local/cwp/.conf/cwp.conf`

Main CWP configuration key-value store.

```properties
# Web server mode: apache | nginx | nginx_reverse | varnish
web_server=nginx_reverse

# PHP mode: php-fpm | php-cgi | suphp
php_module=php-fpm

# Default PHP version (varies by system; 8.3 is current default on AlmaLinux 8 CWP 0.9.8.1244)
php_version=8.3

# Nameservers
ns1=ns1.example.com
ns2=ns2.example.com

# Server hostname
hostname=server.example.com

# Email settings
server_email=admin@example.com

# Backup settings
backup_enabled=yes
backup_dir=/backup
backup_count=3

# Security
cwp_version=0.9.8.1178
```

---

## CSF Firewall Configuration

**Path:** `/etc/csf/csf.conf`

Key CWP-relevant settings:

```ini
# TCP ports to allow (CWP adds these automatically)
TCP_IN = "20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,2082,2083,2086,2087,2095,2096,2304,3306"
TCP_OUT = "20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,2082,2083,2086,2087,2095,2096,2304,3306"
UDP_IN = "53"
UDP_OUT = "53"

# Login failure blocking
LF_TRIGGER = "0"
LF_SSHD = "5"
LF_FTPD = "10"
LF_SMTPAUTH = "5"
LF_POP3D = "10"
LF_IMAPD = "10"

# Process tracking
PT_LIMIT = "60"

# Login tracking
LT_EMAIL_ALERT = "1"
```

---

## Postfix Main Configuration

**Path:** `/etc/postfix/main.cf`

Key CWP-managed settings:

```ini
myhostname = server.example.com
mydomain = example.com
myorigin = $mydomain
inet_interfaces = all
mydestination = $myhostname, localhost.$mydomain, localhost, $mydomain

# Virtual hosting
virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql-virtual_domains.cf
virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql-virtual_mailboxes.cf
virtual_alias_maps = proxy:mysql:/etc/postfix/mysql-virtual_alias.cf

# TLS
smtpd_tls_cert_file = /etc/pki/tls/certs/hostname.crt
smtpd_tls_key_file = /etc/pki/tls/private/hostname.key
smtpd_use_tls = yes
smtp_tls_security_level = may

# SASL
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes

# Restrictions
smtpd_recipient_restrictions =
    permit_sasl_authenticated,
    permit_mynetworks,
    reject_unauth_destination
```

---

## Nginx Main Configuration

**Path:** `/etc/nginx/nginx.conf`

```nginx
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 128m;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css application/json application/javascript text/xml;

    # Include CWP-generated configs
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/vhosts/*.conf;
}
```

---

## Apache Configuration

**Path:** `/usr/local/apache/conf/httpd.conf`

Main Apache config. CWP manages this file directly. Key includes:

```apache
ServerRoot "/usr/local/apache"
Listen 80
Listen 443

# PHP-FPM proxy (when using nginx_reverse mode)
# Managed by CWP under /usr/local/apache/conf.d/

# Virtual hosts
Include /usr/local/apache/conf.d/*.conf
Include /usr/local/apache/conf/users/*.conf
```

Per-user vhost configs: `/usr/local/apache/conf/users/{username}.conf`

---

## MySQL/MariaDB Configuration

**Path:** `/etc/my.cnf` (symlink to `/etc/my.cnf.d/server.cnf`)

```ini
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

# Performance
innodb_buffer_pool_size=256M
innodb_log_file_size=64M
innodb_file_per_table=1
max_connections=151
query_cache_type=0
query_cache_size=0

# Logging
slow_query_log=1
slow_query_log_file=/var/log/mariadb/slow.log
long_query_time=2

# Security
local_infile=0
symbolic-links=0
```

---

## Dovecot Configuration

**Path:** `/etc/dovecot/dovecot.conf`

```ini
protocols = imap pop3 lmtp
listen = *, ::
login_greeting = Dovecot ready.

!include conf.d/*.conf
```

Key sub-configs in `/etc/dovecot/conf.d/`:
- `10-mail.conf` - Mailbox location
- `10-auth.conf` - Authentication
- `10-ssl.conf` - SSL/TLS settings
- `10-master.conf` - Service listeners
- `15-mailboxes.conf` - Mailbox definitions

---

## BIND DNS Configuration

**Path:** `/etc/named.conf`

```options {
    listen-on port 53 { any; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";

    allow-query { any; };
    recursion no;
    dnssec-validation auto;
};

zone "." IN {
    type hint;
    file "named.ca";
};

# CWP adds per-domain zones here
include "/etc/named/user-zones/*.conf";
```

Zone files: `/var/named/{domain}.db`

---

## pure-ftpd Configuration

**Path:** `/etc/pure-ftpd/pure-ftpd.conf`

```ini
# CWP uses pure-ftpd (not vsftpd) on AlmaLinux 8 / CWP 0.9.8.1244
NoAnonymous yes
PureDB /etc/pure-ftpd/pureftpd.pdb
ChrootEveryone yes
BrokenClientsCompatibility no
Daemonize yes
MaxClientsPerIP 20
MaxIdleTime 15
PassivePortRange 40000 50000
TLSCipherSuite HIGH:MEDIUM:+TLSv1:!SSLv3:!SSLv2
```

---

## PHP Configuration Locations

| Item               | Path                                          |
|--------------------|-----------------------------------------------|
| PHP binary (CWP)   | `/usr/local/cwp/php/bin/php`                  |
| PHP-FPM pool defs  | `/usr/local/php{version}/etc/php-fpm.d/`      |
| php.ini            | `/usr/local/php{version}/lib/php.ini`         |
| PHP Switcher       | `/usr/local/cwp/php/`                         |
| PHP Selector        | `/opt/alt/php{version}/`                      |

---

## SSL Certificate Locations

| Purpose          | Path                                              |
|------------------|---------------------------------------------------|
| CWP Admin Panel  | `/usr/local/cwp/ssl/`                             |
| AutoSSL certs    | `/etc/pki/tls/certs/` and `/etc/pki/tls/private/`|
| Let's Encrypt    | `/etc/letsencrypt/live/{domain}/`                 |
| Apache vhosts    | Referenced in `/usr/local/apache/conf/users/`     |
| Nginx vhosts     | Referenced in `/etc/nginx/vhosts/`                |
