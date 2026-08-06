# Spam Filtering Reference

## Overview

CWP supports multiple spam filtering solutions: SpamAssassin, Rspamd, ClamAV, and Policyd. These work together to filter spam, viruses, and enforce mail policies.

---

## SpamAssassin

### Installation

SpamAssassin is typically pre-installed. If not:

```bash
yum install spamassassin spamass-milter
systemctl enable spamassassin
systemctl start spamassassin
```

### Configuration

**Path:** `/etc/mail/spamassassin/local.cf`

```ini
# Scoring
required_score 5.0
report_safe 0
use_bayes 1
bayes_auto_learn 1
bayes_auto_learn_threshold_nonspam 0.1
bayes_auto_learn_threshold_spam 7.0

# Headers
add_header all Status "_YESNO_, score=_SCORE_ required=_REQD_ tests=_TESTS_"

# Whitelist
whitelist_from *@trusted-domain.com
whitelist_from user@example.com

# Blacklist
blacklist_from *@spammer.com
blacklist_from spam@example.net

# Rewriting
rewrite_header Subject [*** SPAM ***]
```

### SpamAssassin Bayes Database

```bash
# Train with spam
sa-learn --spam /path/to/spam/folder

# Train with ham (non-spam)
sa-learn --ham /path/to/ham/folder

# Check statistics
sa-learn --dump magic

# Rebuild Bayes database
sa-learn --sync
```

### Integration with Postfix

**Path:** `/etc/postfix/master.cf`

```ini
smtp      inet  n       -       n       -       -       smtpd
  -o content_filter=spamassassin

spamassassin unix -     n       n       -       -       pipe
  user=spamd argv=/usr/bin/spamc -f -e /usr/sbin/sendmail.postfix -oi -f ${sender} ${recipient}
```

### SpamAssassin Rules

Custom rules in `/etc/mail/spamassassin/local.cf`:

```ini
# Custom rules
score SUBJ_ALL_CAPS 2.5
score HTML_MESSAGE 0.5
score MIME_HTML_ONLY 1.0
score LOTS_OF_MONEY 0.5
score FROM_SUSPICIOUS_NTLD 2.0

# Rule definitions
header FROM_SUSPICIOUS_NTLD From =~ /\.xyz|\.top|\.loan|\.click/i
describe FROM_SUSPICIOUS_NTLD Sender uses suspicious TLD
score FROM_SUSPICIOUS_NTLD 3.0
```

---

## Rspamd

### Installation

```bash
# Install Rspamd
yum install rspamd rspamd-fuzzy

# Start and enable
systemctl enable rspamd
systemctl start rspamd
```

### Configuration

**Path:** `/etc/rspamd/rspamd.conf`

```ini
# Main config includes other files
.include "$CONFDIR/common.conf"
.include "$CONFDIR/options.inc"
.include "$CONFDIR/worker.inc"
```

### Options

**Path:** `/etc/rspamd/local.d/options.inc`

```ini
# DNS settings
dns {
    nameserver = ["127.0.0.1:53:1", "8.8.8.8:53:1"];
    timeout = 2s;
    retransmits = 5;
}

# Logging
log_level = "info";
log_buffer = 10M;

# Bayes classifier
classifier "bayes" {
    backend = "sqlite3";
    min_tokens = 11;
    min_learns = 200;
}
```

### Worker Configuration

**Path:** `/etc/rspamd/local.d/worker-normal.inc**

```ini
bind_socket = "localhost:11333";
```

**Path:** `/etc/rspamd/local.d/worker-controller.inc**

```ini
bind_socket = "localhost:11334";
password = "change_me_to_encrypted_password";
```

### Actions

**Path:** `/etc/rspamd/local.d/actions.conf**

```ini
# Score thresholds
reject = 15;       # Reject message
add_header = 6;    # Add spam header
greylist = 4;      # Greylist message
```

### Integration with Postfix

**Path:** `/etc/postfix/main.cf`

```ini
smtpd_milters = inet:localhost:11332
milter_default_action = accept
milter_protocol = 6
```

### Rspamd Web Interface

Access: `http://server:11334`

Default credentials: admin / (set during setup)

### Rspamd Commands

```bash
# Check configuration
rspamadm configtest

# Show statistics
rspamc stat

# Train spam
rspamc learn_spam /path/to/spam/message

# Train ham
rspamc learn_ham /path/to/ham/message

# Check message score
rspamc check < message.eml
```

---

## ClamAV

### Installation

```bash
# Via CWP script
/scripts/install_clamav

# Manual installation
yum install clamav clamav-daemon clamav-update clamd

# Update virus definitions
freshclam

# Start service
systemctl enable clamd@scan
systemctl start clamd@scan
```

### Configuration

**Path:** `/etc/clamd.d/scan.conf`

```ini
# Socket
LocalSocket /var/run/clamd.scan/clamd.sock
FixStaleSocket yes

# Limits
MaxFileSize 100M
MaxScanSize 400M
MaxRecursion 16
MaxFiles 10000

# Logging
LogFile /var/log/clamd.scan
LogFileMaxSize 50M
LogTime yes
LogClean yes

# Detection
DetectPUA yes
ExcludePUA NetTool
ExcludePUA PWTool
AlertBrokenExecutables yes
AlertEncrypted yes
```

### Freshclam (Virus Definition Updates)

**Path:** `/etc/freshclam.conf**

```ini
DatabaseMirror database.clamav.net
UpdateLogFile /var/log/freshclam.log
NotifyClamd /etc/clamd.d/scan.conf
Checks 24
```

```bash
# Manual update
freshclam

# Check version
clamscan --version
```

### Integration with Postfix

Using amavisd-new or milter:

```bash
# Install amavisd-new
yum install amavisd-new

# Configure in /etc/amavisd/amavisd.conf
$forward_method = 'smtp:127.0.0.1:10025';
$max_servers = 2;
@local_domains_maps = (["."]);
```

### ClamAV Commands

```bash
# Scan a file
clamscan /path/to/file

# Scan directory
clamscan -r /home/user/

# Scan with removal
clamscan -r --remove /home/user/

# Scan mail queue
clamscan -r /var/spool/postfix/
```

---

## Policyd (Postfix Policy Daemon)

### Installation

```bash
yum install cluebringer
systemctl enable cluebringer
systemctl start cluebringer
```

### Configuration

**Path:** `/etc/policyd/cluebringer.conf`

```ini
# Database
DB_Type=mysql
DB_Host=localhost
DB_Name=policyd
DB_User=policyd
DB_Pass=password

# Logging
LOG_LEVEL=2
LOG_FILE=/var/log/cluebringer.log

# Modules
module[100]=CBP::Core
module[200]=CBP::AccessControl
module[300]=CBP::Greylisting
module[400]=CBP::Quotas
module[500]=CBP::Amavis
```

### Integration with Postfix

**Path:** `/etc/postfix/main.cf`

```ini
smtpd_recipient_restrictions =
    ...
    check_policy_service inet:127.0.0.1:10031
    permit
```

### Rate Limiting

In Policyd database:

```sql
-- Create quota policy
INSERT INTO quotas (PolicyID, Name, Track, Period, Verdict, Data)
VALUES (1, 'Sender rate limit', 'Sender:/^From:/', 60, 'REJECT', 'Sender rate limit exceeded');

-- Set limits
INSERT INTO quotas_limits (PolicyID, Type, CounterLimit)
VALUES (1, 'MessageCount', 50);
```

---

## Recommended Spam Filtering Stack

### Basic Setup (Free)

1. SpamAssassin for content filtering
2. ClamAV for virus scanning
3. Postfix RBL checks

### Advanced Setup (Recommended)

1. Rspamd (replaces SpamAssassin + ClamAV integration)
2. ClamAV for virus scanning
3. Policyd for rate limiting
4. Postfix RBL + header checks

### CWP Configuration

**Admin Panel > Email > AntiSpam**

- Enable/Disable SpamAssassin
- Set spam score threshold
- Configure whitelist/blacklist
- Enable virus scanning

---

## Whitelist/Blacklist Management

### Global Whitelist

**Path:** `/etc/mail/spamassassin/local.cf`

```ini
# Domain whitelist
whitelist_from *.example.com
whitelist_from *.trusted-domain.net

# Email whitelist
whitelist_from admin@example.com
whitelist_from alerts@service.com
```

### Per-User Whitelist

**Path:** `/home/{user}/.spamassassin/user_prefs`

```ini
whitelist_from friend@example.com
blacklist_from spammer@evil.com
required_score 5.0
```

### Postfix Restrictions (RBL)

```ini
smtpd_recipient_restrictions =
    ...
    reject_rbl_client zen.spamhaus.org,
    reject_rbl_client bl.spamcop.net,
    reject_rbl_client b.barracudacentral.org,
    ...
```

---

## Quarantine

### SpamAssassin Quarantine

Mail quarantined to:
```
/var/vmail/quarantine/
```

### Rspamd Quarantine

Rspamd can quarantine via the web interface or database.

### Manual Review

```bash
# List quarantined messages
ls /var/vmail/quarantine/

# Release a message
sendmail -f sender@example.com recipient@example.com < /var/vmail/quarantine/message
```

---

## Monitoring

### Spam Statistics

```bash
# SpamAssassin stats
sa-learn --dump magic

# Rspamd stats
rspamc stat

# ClamAV stats
clamdscan --version
freshclam --version

# Mail log analysis
grep "spam" /var/log/maillog | wc -l
grep "reject.*RBL" /var/log/maillog | wc -l
```

### Log Paths

| Component      | Log Path                            |
|----------------|-------------------------------------|
| Postfix        | `/var/log/maillog`                  |
| SpamAssassin   | `/var/log/maillog` (via syslog)     |
| Rspamd         | `/var/log/rspamd/rspamd.log`        |
| ClamAV         | `/var/log/clamd.scan`               |
| Policyd        | `/var/log/cluebringer.log`          |
