# BIND DNS Configuration Reference

## Overview

BIND (Berkeley Internet Name Domain) is the default DNS server in CWP, providing authoritative DNS for hosted domains.

---

## Directory Structure

| Item               | Path                                    |
|--------------------|-----------------------------------------|
| Binary             | `/usr/sbin/named`                       |
| Main config        | `/etc/named.conf`                       |
| Zone files         | `/var/named/`                           |
| User zones         | `/etc/named/user-zones/`               |
| Logs               | `/var/log/named/`                       |
| PID                | `/var/run/named/named.pid`              |
| Cache              | `/var/named/data/cache_dump.db`         |
| Stats              | `/var/named/data/named_stats.txt`       |

---

## named.conf

**Path:** `/etc/named.conf`

```options {
    listen-on port 53 { any; };
    listen-on-v6 port 53 { any; };
    directory "/var/named";
    dump-file "/var/named/data/cache_dump.db";
    statistics-file "/var/named/data/named_stats.txt";
    memstatistics-file "/var/named/data/named_mem_stats.txt";

    # Access control
    allow-query { any; };
    allow-transfer { none; };
    allow-update { none; };
    recursion no;

    # DNSSEC
    dnssec-validation auto;
    managed-keys-directory "/var/named/dynamic";

    # Rate limiting
    rate-limit {
        responses-per-second 10;
        window 5;
    };

    # Logging
    pid-file "/var/run/named/named.pid";
    session-keyfile "/var/run/named/session.key";
};

# Logging
logging {
    channel default_debug {
        file "data/named.run";
        severity dynamic;
    };
    channel query_log {
        file "/var/log/named/queries.log" versions 3 size 10m;
        severity dynamic;
        print-time yes;
        print-category yes;
    };
    category queries { query_log; };
};

# Root hints
zone "." IN {
    type hint;
    file "named.ca";
};

# Local zones
zone "localhost" IN {
    type master;
    file "named.localhost";
};

zone "0.0.127.in-addr.arpa" IN {
    type master;
    file "named.loopback";
};

# CWP user zones
include "/etc/named/user-zones/*.conf";
```

---

## Zone Files

### Standard Zone File

**Path:** `/var/named/{domain}.db`

```$TTL 14400
@       IN      SOA     ns1.example.com. admin.example.com. (
                        2024010101      ; Serial (YYYYMMDDNN)
                        3600            ; Refresh (1 hour)
                        1800            ; Retry (30 min)
                        1209600         ; Expire (2 weeks)
                        86400           ; Minimum TTL (1 day)
                )

; Nameservers
@       IN      NS      ns1.example.com.
@       IN      NS      ns2.example.com.

; A Records
@       IN      A       192.168.1.10
www     IN      A       192.168.1.10
mail    IN      A       192.168.1.10
ns1     IN      A       192.168.1.10
ns2     IN      A       192.168.1.11

; MX Records
@       IN      MX      10      mail.example.com.
@       IN      MX      20      mail2.example.com.

; TXT Records (SPF, DKIM, DMARC)
@       IN      TXT     "v=spf1 +a +mx +ip4:192.168.1.10 ~all"
_dmarc  IN      TXT     "v=DMARC1; p=quarantine; rua=mailto:admin@example.com"
default._domainkey IN TXT "v=DKIM1; k=rsa; p=MIGfMA0GCS..."

; CNAME Records
ftp     IN      CNAME   example.com.
webmail IN      CNAME   example.com.

; SRV Records
_sip._tcp   IN  SRV     10 60 5060 sip.example.com.

; AAAA (IPv6)
@       IN      AAAA    2001:db8::10
```

### Reverse Zone File

**Path:** `/var/named/{reverse}.db`

```$TTL 14400
@       IN      SOA     ns1.example.com. admin.example.com. (
                        2024010101
                        3600
                        1800
                        1209600
                        86400
                )

@       IN      NS      ns1.example.com.
@       IN      NS      ns2.example.com.

10      IN      PTR     example.com.
11      IN      PTR     ns2.example.com.
```

---

## DNS Record Types

### A Record (IPv4)
```; hostname    TTL    IN    A    IP_ADDRESS
www           14400  IN    A    192.168.1.10
```

### AAAA Record (IPv6)
```; hostname    TTL    IN    AAAA    IPv6_ADDRESS
www           14400  IN    AAAA    2001:db8::10
```

### CNAME Record (Alias)
```; alias    TTL    IN    CNAME    target
ftp        14400  IN    CNAME    example.com.
```

### MX Record (Mail)
```; domain    TTL    IN    MX    priority    mail_server
@           14400  IN    MX    10          mail.example.com.
@           14400  IN    MX    20          mail2.example.com.
```

### TXT Record
```; name    TTL    IN    TXT    "value"
@         14400  IN    TXT    "v=spf1 +a +mx ~all"
_dmarc    14400  IN    TXT    "v=DMARC1; p=reject;"
```

### NS Record (Nameserver)
```; domain    TTL    IN    NS    nameserver
@           14400  IN    NS    ns1.example.com.
@           14400  IN    NS    ns2.example.com.
```

### SRV Record
```; _service._protocol    TTL    IN    SRV    priority    weight    port    target
_sip._tcp               14400  IN    SRV    10          60        5060    sip.example.com.
```

### PTR Record (Reverse DNS)
```; last_octet    TTL    IN    PTR    hostname
10              14400  IN    PTR    mail.example.com.
```

### CAA Record (Certificate Authority Authorization)
```; domain    TTL    IN    CAA    flags    tag    value
@           14400  IN    CAA    0        issue  "letsencrypt.org"
@           14400  IN    CAA    0        issuewild ";"
@           14400  IN    CAA    0        iodef  "mailto:admin@example.com"
```

---

## CWP Zone Management

### Via CWP Admin Panel

Navigate to: **DNS Functions > List DNS Zones**

### Add Zone

1. Go to **DNS Functions > Add DNS Zone**
2. Enter domain name and IP address
3. CWP creates zone file and adds to named.conf

### Edit Zone

1. Go to **DNS Functions > List DNS Zones**
2. Click "Edit" next to the domain
3. Modify records and save

### CWP Zone Template

CWP uses templates to generate zone files. Template location:
```
/usr/local/cwp/conf/bind/zones/
```

---

## Named Commands

```bash
# Start/Stop/Restart
systemctl start named
systemctl stop named
systemctl restart named

# Reload configuration
systemctl reload named
rndc reload

# Check configuration
named-checkconf /etc/named.conf

# Check zone file
named-checkzone example.com /var/named/example.com.db

# Flush cache
rndc flush

# Query server
dig @localhost example.com
dig @localhost example.com A
dig @localhost example.com MX
dig @localhost example.com NS

# Reverse lookup
dig -x 192.168.1.10

# Trace query path
dig +trace example.com
```

---

## rndc (Remote Name Daemon Control)

**Path:** `/etc/rndc.conf`

```bash
# Reload zone
rndc reload example.com

# Refresh zone
rndc refresh example.com

# Freeze zone (for editing)
rndc freeze example.com

# Thaw zone (after editing)
rndc thaw example.com

# Query log
rndc querylog on
rndc querylog off

# Flush specific domain
rndc flushname example.com

# Status
rndc status

# Dump cache
rndc dumpdb -cache
```

---

## Security

### Restrict Zone Transfers

```options {
    allow-transfer { none; };
    # Or allow specific IPs
    # allow-transfer { 192.168.1.11; };
};
```

### Restrict Queries

```options {
    allow-query { any; };  # Public DNS
    # Or restrict to specific networks
    # allow-query { localhost; 192.168.1.0/24; };
};
```

### DNSSEC

```bash
# Generate ZSK (Zone Signing Key)
dnssec-keygen -a ECDSAP256SHA256 -n ZONE example.com

# Generate KSK (Key Signing Key)
dnssec-keygen -a ECDSAP256SHA256 -n ZONE -f KSK example.com

# Sign zone
dnssec-signzone -A -3 $(head -c 1000 /dev/urandom | sha1sum | cut -b 1-16) -N INCREMENT -o example.com -t /var/named/example.com.db
```

### Rate Limiting

```options {
    rate-limit {
        responses-per-second 10;
        referrals-per-second 5;
        nodata-per-second 5;
        errors-per-second 5;
        all-per-second 20;
        window 5;
        log-only no;
    };
};
```

---

## Troubleshooting

### Zone not resolving
```bash
# Check zone file syntax
named-checkzone example.com /var/named/example.com.db

# Check named.conf
named-checkconf

# Check named is running
systemctl status named

# Check logs
tail -50 /var/log/named/named.run

# Test locally
dig @localhost example.com
```

### Serial number issues
```bash
# Check current serial
grep "Serial" /var/named/example.com.db

# Increment serial (required for zone transfers)
# Format: YYYYMMDDNN
# Example: 2024010101 -> 2024010102
```

### Zone transfer failed
```bash
# Check allow-transfer setting
grep "allow-transfer" /etc/named.conf

# Test zone transfer
dig @ns1.example.com example.com AXFR

# Check slave server logs
tail -50 /var/log/named/named.run
```

### High CPU/Memory usage
```bash
# Check query rate
rndc stats
cat /var/named/data/named_stats.txt

# Enable query logging
rndc querylog on

# Check for DNS amplification attacks
grep "rate-limit" /var/log/named/named.run
```

### Cache poisoning protection
```bash
# Enable DNSSEC validation
dnssec-validation auto;

# Check DNSSEC
dig example.com +dnssec
dig example.com DNSKEY
```
