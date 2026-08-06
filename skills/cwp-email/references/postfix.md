# Postfix Configuration Reference

## Overview

Postfix is the default MTA (Mail Transfer Agent) in CWP, handling SMTP services for sending and receiving email.

---

## Directory Structure

| Item               | Path                                    |
|--------------------|-----------------------------------------|
| Binary             | `/usr/sbin/postfix`, `/usr/sbin/postmap`|
| Config             | `/etc/postfix/main.cf`, `/etc/postfix/master.cf`|
| Queue              | `/var/spool/postfix/`                   |
| Logs               | `/var/log/maillog`                      |
| Virtual mailboxes  | `/var/vmail/`                           |

---

## main.cf

**Path:** `/etc/postfix/main.cf`

### Core Settings

```ini
# Server identity
myhostname = server.example.com
mydomain = example.com
myorigin = $mydomain
mydestination = $myhostname, localhost.$mydomain, localhost
mynetworks = 127.0.0.0/8, 192.168.1.0/24

# Interfaces
inet_interfaces = all
inet_protocols = all

# Banner
smtpd_banner = $myhostname ESMTP
```

### Virtual Hosting (CWP Managed)

```ini
# Virtual domain support
virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql-virtual_domains.cf
virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql-virtual_mailboxes.cf
virtual_alias_maps = proxy:mysql:/etc/postfix/mysql-virtual_alias.cf

virtual_mailbox_base = /var/vmail
virtual_uid_maps = static:1001
virtual_gid_maps = static:1001
virtual_minimum_uid = 1001
virtual_transport = dovecot
```

### MySQL Lookup Files

**Path:** `/etc/postfix/mysql-virtual_domains.cf`

```ini
user = mail_admin
password = mail_password
hosts = 127.0.0.1
dbname = postfix
query = SELECT domain FROM domain WHERE domain='%s' AND active='1'
```

**Path:** `/etc/postfix/mysql-virtual_mailboxes.cf`

```ini
user = mail_admin
password = mail_password
hosts = 127.0.0.1
dbname = postfix
query = SELECT CONCAT(domain, '/', maildir) FROM mailbox WHERE username='%s' AND active='1'
```

**Path:** `/etc/postfix/mysql-virtual_alias.cf`

```ini
user = mail_admin
password = mail_password
hosts = 127.0.0.1
dbname = postfix
query = SELECT goto FROM alias WHERE address='%s' AND active='1'
```

---

## TLS Configuration

### Outgoing TLS

```ini
smtp_tls_security_level = may
smtp_tls_cert_file = /etc/pki/tls/certs/hostname.crt
smtp_tls_key_file = /etc/pki/tls/private/hostname.key
smtp_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt
smtp_tls_loglevel = 1
smtp_tls_session_cache_database = btree:/var/lib/postfix/smtp_tls_session_cache
```

### Incoming TLS

```ini
smtpd_tls_cert_file = /etc/pki/tls/certs/hostname.crt
smtpd_tls_key_file = /etc/pki/tls/private/hostname.key
smtpd_tls_CAfile = /etc/pki/tls/certs/ca-bundle.crt
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_loglevel = 1
smtpd_tls_received_header = yes
smtpd_tls_session_cache_database = btree:/var/lib/postfix/smtpd_tls_session_cache
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3
smtpd_tls_protocols = !SSLv2, !SSLv3
```

---

## SASL Authentication

### Dovecot SASL

```ini
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname
```

### Dovecot Auth Socket

In `/etc/dovecot/conf.d/10-master.conf`:

```ini
service auth {
    unix_listener /var/spool/postfix/private/auth {
        mode = 0660
        user = postfix
        group = postfix
    }
}
```

---

## master.cf

**Path:** `/etc/postfix/master.cf`

```ini
# SMTP
smtp      inet  n       -       n       -       -       smtpd
  -o smtpd_sasl_auth_enable=yes

# Submission (port 587)
submission inet n       -       n       -       -       smtpd
  -o smtpd_tls_security_level=encrypt
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject
  -o milter_macro_daemon_name=ORIGINATING

# SMTPS (port 465)
smtps     inet  n       -       n       -       -       smtpd
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_recipient_restrictions=permit_sasl_authenticated,reject
  -o smtpd_relay_restrictions=permit_sasl_authenticated,reject

# Dovecot delivery
dovecot   unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail:vmail argv=/usr/libexec/dovecot/deliver -f ${sender} -d ${recipient}

# Relay
relay     unix  -       -       n       -       -       smtp
```

---

## Restrictions

### Recipient Restrictions

```ini
smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    reject_non_fqdn_hostname,
    reject_non_fqdn_sender,
    reject_non_fqdn_recipient,
    reject_unknown_sender_domain,
    reject_unknown_recipient_domain,
    reject_rbl_client zen.spamhaus.org,
    reject_rbl_client bl.spamcop.net,
    reject_rhsbl_reverse_client dbl.spamhaus.org,
    reject_rhsbl_sender dbl.spamhaus.org,
    permit
```

### Sender Restrictions

```ini
smtpd_sender_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain,
    reject_sender_login_mismatch,
    permit
```

### Client Restrictions

```ini
smtpd_client_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unknown_client_hostname,
    reject_rbl_client zen.spamhaus.org,
    permit
```

---

## Relay Configuration

### Smart Host Relay

```ini
relayhost = [smtp.example.com]:587
smtp_sasl_auth_enable = yes
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_sasl_security_options = noanonymous
smtp_tls_security_level = encrypt
smtp_sasl_tls_security_options = noanonymous
```

### SASL Password File

**Path:** `/etc/postfix/sasl_passwd`

```ini
[smtp.example.com]:587 username:password
```

```bash
postmap /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
systemctl reload postfix
```

---

## Mail Queue Management

```bash
# View queue
postqueue -p

# Flush queue
postqueue -f

# Delete specific message
postsuper -d MESSAGE_ID

# Delete all queued messages
postsuper -d ALL

# Hold message
postsuper -h MESSAGE_ID

# Release held message
postsuper -H MESSAGE_ID

# View deferred queue
qshape deferred
```

---

## Common Commands

```bash
# Reload configuration
systemctl reload postfix

# Check configuration
postfix check

# Show all settings
postconf

# Show specific setting
postconf myhostname

# Set a parameter
postconf -e "myhostname = mail.example.com"

# View mail log
tail -f /var/log/maillog

# Test SMTP connection
telnet localhost 25
# EHLO test
# MAIL FROM:<test@example.com>
# RCPT TO:<user@domain.com>
# DATA
# Subject: Test
# Test message
# .
# QUIT
```

---

## Troubleshooting

### Mail not sending
```bash
# Check Postfix is running
systemctl status postfix

# Check queue
postqueue -p

# Check logs
tail -100 /var/log/maillog

# Check DNS
dig MX example.com
dig +short example.com
```

### Mail not receiving
```bash
# Check MX records
dig MX yourdomain.com

# Check Postfix is listening
ss -tlnp | grep :25

# Check virtual domain configuration
postconf virtual_mailbox_domains

# Check logs for specific address
grep "user@domain.com" /var/log/maillog
```

### Deferred mail
```bash
# Check deferred queue
qshape deferred

# Retry delivery
postqueue -f

# Check reason
grep "status=deferred" /var/log/maillog | tail -20
```

### Authentication failures
```bash
# Check SASL configuration
postconf smtpd_sasl_auth_enable

# Test authentication
swaks --to user@domain.com --server localhost --auth-user user --auth-password pass

# Check Dovecot auth socket
ls -la /var/spool/postfix/private/auth
```

### Blacklisted IP
```bash
# Check blacklist status
# Visit: https://mxtoolbox.com/blacklists.aspx

# Check outgoing mail
postconf relayhost
postconf smtp_tls_security_level

# Review queue for bounces
postqueue -p | grep -i "bounced\|rejected"
```
