# Dovecot Configuration Reference

## Overview

Dovecot is the default IMAP/POP3 server in CWP, handling mail storage and retrieval.

---

## Directory Structure

| Item               | Path                                    |
|--------------------|-----------------------------------------|
| Binary             | `/usr/sbin/dovecot`                     |
| Config             | `/etc/dovecot/dovecot.conf`             |
| Config dir         | `/etc/dovecot/conf.d/`                  |
| Logs               | `/var/log/maillog`                      |
| Mailboxes          | `/var/vmail/`                           |
| Auth socket        | `/var/spool/postfix/private/auth`       |

---

## Main Configuration

**Path:** `/etc/dovecot/dovecot.conf`

```ini
protocols = imap pop3 lmtp
listen = *, ::!
login_greeting = Dovecot ready.
mail_gid = 1001
mail_uid = 1001

!include conf.d/*.conf
!include_try /etc/dovecot/local.conf
```

---

## conf.d/ Configuration Files

### 10-mail.conf - Mailbox Location

```ini
mail_location = maildir:/var/vmail/%d/%n/Maildir
mail_home = /var/vmail/%d/%n
mail_privileged_group = mail
first_valid_uid = 1001
last_valid_uid = 1001

# Namespace
namespace inbox {
  type = private
  separator = /
  inbox = yes
  mailbox Drafts {
    special_use = \Drafts
    auto = subscribe
  }
  mailbox Junk {
    special_use = \Junk
    auto = subscribe
  }
  mailbox Sent {
    special_use = \Sent
    auto = subscribe
  }
  mailbox "Sent Messages" {
    special_use = \Sent
  }
  mailbox Trash {
    special_use = \Trash
    auto = subscribe
  }
}
```

### 10-auth.conf - Authentication

```ini
auth_mechanisms = plain login cram-md5
disable_plaintext_auth = yes
auth_username_format = %n

# Passdb (password database)
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf
}

# Userdb (user database)
userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf
}

# Auth socket for Postfix
service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}

!include auth-system.conf.ext
```

### 10-ssl.conf - SSL/TLS

```ini
ssl = required
ssl_cert = </etc/pki/tls/certs/hostname.crt
ssl_key = </etc/pki/tls/private/hostname.key
ssl_ca = </etc/pki/tls/certs/ca-bundle.crt

ssl_min_protocol = TLSv1.2
ssl_cipher_list = ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
ssl_prefer_server_ciphers = yes

# Disable plaintext auth on non-SSL
disable_plaintext_auth = yes

# SSL session
ssl_dh = </etc/dovecot/dh.pem
```

Generate DH parameters:
```bash
openssl dhparam -out /etc/dovecot/dh.pem 4096
```

### 10-master.conf - Service Listeners

```ini
service imap-login {
  inet_listener imap {
    port = 143
  }
  inet_listener imaps {
    port = 993
    ssl = yes
  }
}

service pop3-login {
  inet_listener pop3 {
    port = 110
  }
  inet_listener pop3s {
    port = 995
    ssl = yes
  }
}

service lmtp {
  unix_listener /var/spool/postfix/private/dovecot-lmtp {
    mode = 0600
    user = postfix
    group = postfix
  }
}

service auth {
  unix_listener /var/spool/postfix/private/auth {
    mode = 0660
    user = postfix
    group = postfix
  }
}

service auth-worker {
  user = root
}
```

### 15-mailboxes.conf - Mailbox Definitions

```ini
namespace inbox {
  mailbox Drafts {
    special_use = \Drafts
    auto = subscribe
  }
  mailbox Junk {
    special_use = \Junk
    auto = subscribe
  }
  mailbox Sent {
    special_use = \Sent
    auto = subscribe
  }
  mailbox Trash {
    special_use = \Trash
    auto = subscribe
  }
  mailbox Archive {
    special_use = \Archive
    auto = subscribe
  }
}
```

---

## SQL Configuration

**Path:** `/etc/dovecot/dovecot-sql.conf`

```ini
driver = mysql
connect = host=127.0.0.1 dbname=postfix user=mail_admin password=mail_password
default_pass_scheme = SHA512-CRYPT

password_query = SELECT username AS user, password, CONCAT('/var/vmail/', domain, '/', maildir) AS userdb_home, \
    CONCAT('maildir:/var/vmail/', domain, '/', maildir) AS userdb_mail, \
    1001 AS userdb_uid, 1001 AS userdb_gid \
    FROM mailbox WHERE username='%u' AND active='1'

user_query = SELECT CONCAT('/var/vmail/', domain, '/', maildir) AS home, \
    CONCAT('maildir:/var/vmail/', domain, '/', maildir) AS mail, \
    1001 AS uid, 1001 AS gid \
    FROM mailbox WHERE username='%u' AND active='1'
```

---

## Quotas

### Enable Quotas

In `10-mail.conf`:

```ini
plugin {
  quota = maildir:User quota
  quota_rule = *:storage=1G
  quota_rule2 = Trash:storage=+100M
  quota_warning = storage=90%% quota-warning 90 %u
  quota_warning2 = storage=80%% quota-warning 80 %u
}
```

### SQL-Based Quotas

```ini
plugin {
  quota = dict:User quota::proxy::sqlquota
}

dict {
  sqlquota = mysql:/etc/dovecot/dovecot-dict-sql.conf
}
```

**Path:** `/etc/dovecot/dovecot-dict-sql.conf`

```ini
connect = host=127.0.0.1 dbname=postfix user=mail_admin password=mail_password

map {
  pattern = priv/quota/storage
  table = quota2
  username_field = username
  value_field = bytes
}
map {
  pattern = priv/quota/messages
  table = quota2
  username_field = username
  value_field = messages
}
```

### Quota Warning Script

**Path:** `/etc/dovecot/scripts/quota-warning.sh`

```bash
#!/bin/bash
PERCENT=$1
USER=$2
cat << EOF | /usr/libexec/dovecot/dovecot-lda -d "$USER" -o "plugin/quota=dict:User quota::proxy::sqlquota"
From: postmaster@example.com
Subject: Quota warning - ${PERCENT}% reached

Your mailbox is now ${PERCENT}% full. Please delete unnecessary emails.
EOF
```

---

## Sieve Filtering

### Enable Sieve

In `20-lmtp.conf`:

```ini
protocol lmtp {
  mail_plugins = $mail_plugins sieve
}
```

In `90-plugin.conf`:

```ini
plugin {
  sieve = ~/.dovecot.sieve
  sieve_before = /var/vmail/sieve/global-spam.sieve
  sieve_dir = ~/sieve
}
```

### Example Sieve Script

```sieve
require ["fileinto", "reject", "regex"];

# Move spam to Junk
if header :contains "X-Spam-Flag" "YES" {
    fileinto "Junk";
    stop;
}

# Reject large attachments
if size :over 10M {
    reject "Message too large (max 10MB)";
    stop;
}

# Auto-sort mailing lists
if header :contains "List-Id" "example.com" {
    fileinto "Lists/example";
    stop;
}
```

---

## Common Commands

```bash
# Reload configuration
systemctl reload dovecot

# Check configuration
doveconf -n

# Test authentication
doveadm auth test user@domain.com password

# List users
doveadm user '*'

# Check mailbox
doveadm mailbox status -u user@domain.com '*'

# Quota status
doveadm quota get -u user@domain.com

# Force quota recalculation
doveadm quota recalc -u user@domain.com

# View logs
tail -f /var/log/maillog | grep dovecot
```

---

## Troubleshooting

### Login failed
```bash
# Check authentication config
doveconf -n | grep auth

# Test auth
doveadm auth test user@domain.com password

# Check SQL connection
mysql -u mail_admin -p postfix -e "SELECT * FROM mailbox WHERE username='user@domain.com'"

# Check logs
grep "auth failed" /var/log/maillog
```

### Mail not delivered to mailbox
```bash
# Check mail_location
doveconf mail_location

# Check permissions
ls -la /var/vmail/domain/user/

# Check mail log
grep "deliver" /var/log/maillog
```

### SSL errors
```bash
# Verify certificate
openssl s_client -connect localhost:993

# Check certificate paths
doveconf ssl_cert ssl_key

# Check dh parameters
ls -la /etc/dovecot/dh.pem
```

### Quota issues
```bash
# Check quota
doveadm quota get -u user@domain.com

# Recalculate
doveadm quota recalc -u user@domain.com

# Check quota warnings
grep "quota-warning" /var/log/maillog
```

### Connection refused
```bash
# Check Dovecot is running
systemctl status dovecot

# Check ports
ss -tlnp | grep -E "143|993|110|995"

# Check config
doveconf -n | grep -E "listen|port"
```
