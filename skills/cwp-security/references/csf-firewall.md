# CSF Firewall Reference

## Overview

ConfigServer Security & Firewall (CSF) is the default firewall in CWP, providing iptables management, intrusion detection (LFD), and login failure monitoring.

**Important:** CSF was discontinued by its original developers in August 2025. The **Aetherinox fork** (https://github.com/Aetherinox/csf-firewall) continues active development and is recommended for ongoing support.

---

## Installation

### Via CWP Admin Panel

Navigate to: **Security > CSF Firewall > Install**

### Manual Installation

```bash
cd /usr/local/src
wget https://github.com/Aetherinox/csf-firewall/releases/latest/download/csf.tgz
tar -xzf csf.tgz
cd csf
sh install.sh
```

### Verify Installation

```bash
csf -v
# Should show CSF version and Aetherinox fork info
```

---

## Directory Structure

| Item               | Path                                    |
|--------------------|-----------------------------------------|
| Main config        | `/etc/csf/csf.conf`                     |
| Allow list         | `/etc/csf/csf.allow`                    |
| Deny list          | `/etc/csf/csf.deny`                     |
| Ignore list        | `/etc/csf/csf.ignore`                   |
| Block lists        | `/etc/csf/csf.blocklists`              |
| Firewall rules     | `/etc/csf/csfpre.sh`, `/etc/csf/csfpost.sh`|
| LFD config         | `/etc/csf/csf.conf` (same file)        |
| Logs               | `/var/log/lfd.log`                      |
| Alert templates    | `/etc/csf/alerts/`                      |

---

## csf.conf

**Path:** `/etc/csf/csf.conf`

### Core Settings

```ini
# Enable/disable (1=enabled, 0=disabled)
TESTING = "0"

# TCP ports to allow (incoming)
TCP_IN = "20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,2082,2083,2086,2087,2095,2096,2304,3306"

# TCP ports to allow (outgoing)
TCP_OUT = "20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,2082,2083,2086,2087,2095,2096,2304,3306"

# UDP ports (incoming)
UDP_IN = "53"

# UDP ports (outgoing)
UDP_OUT = "53"

# IPv6 ports
IPV6 = "1"
TCP6_IN = "20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,2082,2083"
TCP6_OUT = "20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,2082,2083"
UDP6_IN = "53"
UDP6_OUT = "53"
```

### Connection Limits

```ini
# Connection rate limiting
CONNLIMIT = "22;5,80;50,443;50"
PORTFLOOD = "22;tcp;5;300,80;tcp;30;30"

# SYN flood protection
SYNFLOOD = "1"
SYNFLOOD_RATE = "75/s"
SYNFLOOD_BURST = "25"

# Packet filtering
PACKET_FILTER = "1"
SYNFLOOD = "1"
PORTSCAN = "1"
```

### Login Failure Detection (LFD)

```ini
# Login failure thresholds
LF_TRIGGER = "0"
LF_SSHD = "5"
LF_FTPD = "10"
LF_SMTPAUTH = "5"
LF_POP3D = "10"
LF_IMAPD = "10"
LF_HTACCESS = "5"
LF_CPANEL = "5"
LF_MODSEC = "5"

# Temporary ban duration (seconds, 0=permanent)
LF_TRIGGER_PERM = "1"
LF_SSHD_PERM = "3600"
LF_FTPD_PERM = "3600"

# Email alerts
LF_EMAIL_ALERT = "1"
LF_ALERT_TO = "admin@example.com"

# Process tracking
PT_LIMIT = "60"
PT_USERMEM = "512"
PT_USERTIME = "1800"
PT_USERKILL = "1"
PT_USERKILL_ALERT = "1"
```

### Country Code Blocking (CC)

```ini
# Block countries (ISO codes)
CC_DENY = "CN,RU,KP,IR"
CC_ALLOW = ""
CC_ALLOW_FILTER = ""
CC_LOOKUPS = "1"
```

### Block Lists

```ini
# Enable block lists
BLOCKLIST_DE = "1"
BLOCKLIST_BRUTEFORCE = "1"

# Spamhaus
LF_SPAMHAUS = "86400"
LF_SPAMHAUS_URL = "https://www.spamhaus.org/drop/drop.txt"

# DShield
LF_DSHIELD = "86400"
```

---

## CSF Commands

```bash
# Start firewall
csf -s

# Stop firewall
csf -f

# Restart firewall
csf -r

# Enable/disable
csf -e    # Enable
csf -x    # Disable

# Status
csf -t    # Show iptables rules

# Add IP to allow
csf -a 192.168.1.100 "Admin access"

# Remove IP from allow
csf -ar 192.168.1.100

# Add IP to deny
csf -d 192.168.1.200 "Blocked for abuse"

# Remove IP from deny
csf -dr 192.168.1.200

# Remove IP from temp ban
csf -tr 192.168.1.200

# Check if IP is blocked
csf -g 192.168.1.100

# Flush all rules
csf -f

# View lfd log
tail -f /var/log/lfd.log
```

---

## Allow/Deny Lists

### csf.allow

**Path:** `/etc/csf/csf.allow`

```# Trusted IPs (never blocked)
192.168.1.100 # Admin office
10.0.0.0/8 # Internal network
203.0.113.50 # Backup server
```

### csf.deny

**Path:** `/etc/csf/csf.deny`

```# Permanently blocked IPs
# Format: IP - comment
# Added by lfd: 192.168.1.200 - Failed SSH login (5 attempts)
```

### csf.ignore

**Path:** `/etc/csf/csf.ignore`

```# IPs excluded from LFD monitoring
127.0.0.1
192.168.1.100 # Admin office
```

---

## Custom Rules

### csfpre.sh (Before Main Rules)

**Path:** `/etc/csf/csfpre.sh`

```bash
#!/bin/bash
# Custom rules applied before CSF rules

# Allow specific application
iptables -A INPUT -p tcp --dport 8443 -j ACCEPT

# Rate limit specific port
iptables -A INPUT -p tcp --dport 25 -m limit --limit 10/min -j ACCEPT
```

### csfpost.sh (After Main Rules)

**Path:** `/etc/csf/csfpost.sh`

```bash
#!/bin/bash
# Custom rules applied after CSF rules

# Log dropped packets
iptables -A INPUT -j LOG --log-prefix "CSF-DROP: "
```

### Allow Specific Service

```bash
# Allow port 8443
csf -a 0/0 8443

# Or edit /etc/csf/csf.conf
TCP_IN = "...,8443"
```

---

## LFD (Login Failure Daemon)

LFD monitors authentication logs and blocks IPs with too many failures.

### Monitored Services

| Service      | Log File                  | Config Variable |
|--------------|---------------------------|-----------------|
| SSH          | /var/log/secure           | LF_SSHD         |
| FTP          | /var/log/messages         | LF_FTPD         |
| SMTP Auth    | /var/log/maillog          | LF_SMTPAUTH     |
| POP3         | /var/log/maillog          | LF_POP3D        |
| IMAP         | /var/log/maillog          | LF_IMAPD        |
| cPanel       | /usr/local/cwpsrv/logs/   | LF_CPANEL       |
| ModSecurity  | /usr/local/apache/logs/   | LF_MODSEC       |

### LFD Email Alerts

Configure in csf.conf:
```ini
LF_EMAIL_ALERT = "1"
LF_ALERT_TO = "admin@example.com"
LF_ALERT_FROM = "lfd@server.example.com"
```

---

## Block Lists (csf.blocklists)

**Path:** `/etc/csf/csf.blocklists`

```# Spamhaus DROP
SPAMhaus|drop|https://www.spamhaus.org/drop/drop.txt|86400
SPAMhaus|edrop|https://www.spamhaus.org/drop/edrop.txt|86400

# DShield
DSHIELD|https://www.dshield.org/block.txt|86400

# Blocklist.de
BDE|https://lists.blocklist.de/lists/all.txt|86400

# Autoshun
AUTOSHUN|https://www.autoshun.org/files/shunlist.csv|86400
```

---

## CSF Integration with CWP

CWP automatically manages CSF settings:

1. **Port Configuration** - CWP adds its ports to TCP_IN/TCP_OUT
2. **LFD Integration** - CWP logs are monitored by LFD
3. **API Protection** - CSF protects CWP API endpoints
4. **User Panel** - Basic CSF controls in user panel

---

## Troubleshooting

### Locked out of server
```bash
# Via console/KVM
csf -f    # Flush all rules
# or
csf -x    # Disable CSF

# Edit /etc/csf/csf.conf
# TESTING = "1"  (disables firewall after 5 minutes)
```

### Legitimate IP blocked
```bash
# Check if blocked
csf -g IP_ADDRESS

# Remove from deny
csf -dr IP_ADDRESS

# Add to allow
csf -a IP_ADDRESS "Reason"

# Add to ignore (won't be auto-blocked)
echo "IP_ADDRESS" >> /etc/csf/csf.ignore
```

### High server load from LFD
```bash
# Check LFD activity
tail -50 /var/log/lfd.log

# Reduce thresholds
# In csf.conf: increase LF_* values

# Temporarily disable LFD
systemctl stop lfd
```

### Firewall rules not applying
```bash
# Check CSF status
csf -t

# Restart CSF
csf -r

# Check for errors
csf -e 2>&1 | grep -i error

# Verify iptables
iptables -L -n
```
