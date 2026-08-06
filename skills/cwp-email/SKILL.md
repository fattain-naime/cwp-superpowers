---
name: cwp-email
description: This skill should be used when the user asks to "configure email", "set up Postfix", "configure Dovecot", "install Roundcube", "fix email delivery", "set up DKIM", "configure SPF", "set up spam filtering", "install SpamAssassin", "configure ClamAV", "fix mail queue", "set up email rate limiting", "install Rspamd", "configure OpenDKIM", or needs to manage any email service on a CWP server.
version: 1.0.0
---

# CWP Email Management

Manage Postfix, Dovecot, Roundcube, spam filtering, and email authentication on CWP servers. Handle mail delivery issues, queue management, and security configuration.

## Email Components

| Component | Software | Purpose |
|---|---|---|
| MTA | Postfix | Mail transfer agent |
| IMAP/POP3 | Dovecot | Mail retrieval protocol |
| Webmail | Roundcube | Web email client |
| Anti-spam | SpamAssassin | Spam filtering |
| Anti-virus | ClamAV | Virus scanning |
| Authentication | SPF, DKIM, OpenDKIM | Email authentication |
| Rate Limiting | Policyd (cbpolicyd) | Email rate limiting |
| Alternative Anti-spam | Rspamd | Lightweight spam filter |

## Configuration Files

| File | Purpose |
|---|---|
| `/etc/postfix/main.cf` | Postfix main configuration |
| `/etc/postfix/master.cf` | Postfix master process config |
| `/etc/postfix/sender_blacklist` | Sender blacklist |
| `/etc/postfix/sender_whitelist` | Sender whitelist |
| `/etc/dovecot/dovecot.conf` | Dovecot configuration |
| `/etc/mail/spamassassin/local.cf` | SpamAssassin configuration |
| `/etc/amavisd/amavisd.conf` | AMaViS configuration |
| `/var/vmail` | Email storage directory |

## Service Management

```bash
# Postfix
systemctl restart postfix
systemctl status postfix

# Dovecot
systemctl restart dovecot
systemctl status dovecot

# SpamAssassin
systemctl restart spamassassin

# ClamAV
systemctl restart clamd

# Policyd
service cbpolicyd start|stop|restart|status
```

## Email Authentication

### SPF (Sender Policy Framework)

SPF records are added as DNS TXT records:

```
v=spf1 +a +mx +ip4:SERVER_IP ~all
```

### DKIM (DomainKeys Identified Mail)

Configure DKIM per domain via CWP. Generate and manage keys through the CWP Admin panel under Email -> DKIM Manager.

### DMARC

Add as DNS TXT record:

```
v=DMARC1; p=quarantine; rua=mailto:admin@domain.com; pct=100
```

## Email Rate Limiting

### Install Policyd

```bash
sh /scripts/install_cbpolicyd
```

### Configure Rate Limits

```bash
# Update limits for all domains
/scripts/cwp_api account update_policyd_all

# Default: 250 emails/hour per account
# Database: postfix_policyd
```

## Rspamd (SpamAssassin Alternative)

Rspamd is a lightweight alternative that reduces resource usage significantly:

| Metric | SpamAssassin | Rspamd |
|---|---|---|
| Memory usage | ~1 GB | ~98 MB |
| Messages/day | Standard | ~4,000 |
| CPU usage | Higher | ~2% |
| ARC signing | No | Yes |

Rspamd is recommended for email forwarding scenarios requiring ARC signing.

## Mail Queue Management

```bash
# View mail queue
postqueue -p

# Check mail queue stats
/scripts/mail_queue_stats

# Flush mail queue
postfix flush

# Delete all queued mail
postsuper -d ALL

# Delete deferred mail
postsuper -d ALL deferred

# Check mail queue
/scripts/check_postqueue

# Hold specific message
postsuper -h MESSAGE_ID

# Release held message
postsuper -H MESSAGE_ID
```

## Email Storage

- **Location:** `/var/vmail/DOMAIN/USER/`
- **Format:** Maildir format
- **Permissions:** Managed by Dovecot

## Roundcube Webmail

- **URL:** `https://SERVER_IP:2096`
- **Update:** `/scripts/mail_roundcube_update`

## Common Issues and Solutions

### Can't Send Emails

1. Verify DKIM, SPF, and DMARC records are correct
2. Check rDNS (reverse DNS) matches mail hostname
3. Check IP against blacklists (MXToolbox)
4. Verify Postfix is running: `systemctl status postfix`

### Amavisd 100% CPU

```bash
# Disable Bayesian filtering
echo "use_bayes 0" >> /etc/mail/spamassassin/local.cf
systemctl restart spamassassin
```

### DKIM Double Signature

Prevent double DKIM signing when using AMaViS or OpenDKIM together. Edit `/etc/postfix/master.cf`:

```bash
# Find the smtp line and add no_milters
# Before:
# smtp      inet  n       -       n       -       -       smtpd

# After:
# smtp      inet  n       -       n       -       -       smtpd -o content_filter= -o smtpd_milters= -o non_smtpd_milters=

# Or add to the pickup service:
# pickup    unix  n       -       n       60      1       pickup
#   -o content_filter=
#   -o receive_override_options=no_header_body_checks,no_milters
```

Then restart Postfix:

```bash
systemctl restart postfix
```

### Roundcube Errors

```bash
# Update Roundcube
/scripts/mail_roundcube_update

# Fix mail permissions
/scripts/cwp_api account mail_fix_permissions
```

### SpamAssassin start-limit-hit

```bash
# Add to systemd service override
# StartLimitBurst=0
systemctl daemon-reload
systemctl restart spamassassin
```

### Mail Permission Issues

```bash
# Fix mail permissions for all accounts
/scripts/cwp_api account mail_fix_permissions

# Fix specific user
/scripts/cwp_api account fix_perms USERNAME
```

## Sender Blacklist/Whitelist

Edit `/etc/postfix/sender_blacklist` and `/etc/postfix/sender_whitelist`:

```
# Blacklist format
bad@spammer.com    REJECT

# Whitelist format
good@sender.com    OK
```

After editing:

```bash
postmap /etc/postfix/sender_blacklist
postmap /etc/postfix/sender_whitelist
systemctl restart postfix
```

## Diagnostic Commands

```bash
# Check Postfix configuration
postconf -n

# Check Dovecot configuration
doveconf -n

# View mail log
tail -f /var/log/maillog

# Check mail queue
mailq

# Test email delivery
echo "Test" | mail -s "Test Subject" user@example.com

# Check open relay
postconf smtpd_relay_restrictions

# Check DKIM signing
opendkim-testkey -d domain.com -s default -vvv
```

## Additional Resources

- `references/postfix.md` -- Postfix configuration and mail transfer setup
- `references/dovecot.md` -- Dovecot IMAP/POP3 setup and tuning
- `references/spam-filtering.md` -- SpamAssassin and Rspamd configuration
- `references/roundcube.md` -- Roundcube webmail setup and troubleshooting
