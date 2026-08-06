---
name: cwp-dns
description: This skill should be used when the user asks to "manage DNS zones", "add DNS records", "configure nameservers", "set up DNS clustering", "edit DNS templates", "fix DNS resolution", "configure FreeDNS", "set up slave DNS", "add MX records", "add TXT records", "configure BIND", "secure DNS", or needs to manage any DNS-related configuration on a CWP server.
version: 1.0.0
---

# CWP DNS Management

Manage DNS zones, records, templates, and clustering on CWP servers. Handle BIND configuration, zone templates, nameserver setup, and DNS security.

## DNS Features

Manage DNS through these components:

- FreeDNS Service (free DNS clustering with DDoS protection)
- Zone Management (add, edit, list, remove zones)
- Template Editor (custom DNS zone templates)
- Nameserver Editor (configure nameserver IPs)
- Record Types: A, AAAA, MX, TXT, CNAME, SRV

## Configuration Files

| File | Purpose |
|---|---|
| `/etc/named.conf` | BIND main configuration |
| `/var/named/` | DNS zone files directory |
| `/usr/local/cwpsrv/htdocs/resources/conf/dns/bind/zones/` | Zone templates |

## DNS Zone Templates

### Template Location

`/usr/local/cwpsrv/htdocs/resources/conf/dns/bind/zones/`

### Template Variables

| Variable | Replacement |
|---|---|
| `%domain%` | Domain name |
| `%dns-email%` | DNS admin email |
| `%ns1%` | Primary nameserver |
| `%ns2%` | Secondary nameserver |
| `%ip%` | Server IP address |

### Example Zone Template

```
$TTL 14400
@   IN  SOA %ns1%. %dns-email%. (
    %domain_serial%
    7200
    3600
    1209600
    86400 )

@       14400   IN  NS      %ns1%.
@       14400   IN  NS      %ns2%.
@       14400   IN  A       %ip%
%domain%. 14400 IN  MX      0 %domain%.
mail    14400   IN  A       %ip%
www     14400   IN  A       %ip%
ftp     14400   IN  A       %ip%
smtp    14400   IN  A       %ip%
pop     14400   IN  A       %ip%
imap    14400   IN  A       %ip%
```

## DNS Record Types

| Type | Purpose | Example |
|---|---|---|
| A | IPv4 address | `@ 14400 IN A 1.2.3.4` |
| AAAA | IPv6 address | `@ 14400 IN AAAA ::1` |
| MX | Mail exchange | `@ 14400 IN MX 0 mail.domain.com.` |
| CNAME | Alias | `www 14400 IN CNAME domain.com.` |
| TXT | Text record | `@ 14400 IN TXT "v=spf1 +a +mx ~all"` |
| SRV | Service record | `_sip._tcp 14400 IN SRV 10 60 5060 sip.domain.com.` |

## DNS Cluster Options

### Option 1: FreeDNS

Free hosted DNS cluster with DDoS protection. Configure via CWP Admin -> DNS -> FreeDNS.

### Option 2: Slave DNS Manager

Self-hosted DNS clustering with unlimited accounts.

### Option 3: Slave2 DNS Server

Additional nodes for redundancy in self-hosted clusters.

## Nameserver Configuration

Configure nameserver IPs via CWP Admin -> DNS -> Nameserver IPs.

```bash
# Rebuild named.conf
/scripts/cwp_api account rebuild_etc_named_conf

# Rebuild all zone files
/scripts/cwp_api account rebuild_var_named_all
```

## DNS Operations

### Add DNS Zone

```bash
# Via CWP API or Admin panel
# DNS -> Add New Zone
```

### Edit DNS Records

```bash
# Via CWP Admin panel
# DNS -> Zone Editor -> Select domain
```

### Remove DNS Zone

```bash
# Via CWP Admin panel
# DNS -> List DNS Zones -> Delete
```

## DNS Security

### Disable Open Resolver

Prevent DNS amplification attacks:

```bash
# Edit /etc/named.conf
sed -i 's/recursion yes/recursion no/g' /etc/named.conf
```

### Additional BIND Hardening

Add to `/etc/named.conf` in the `options` block:

```
allow-recursion { localnets; };
allow-transfer {"none";};
version none;
server-id none;
```

After changes:

```bash
systemctl restart named
```

## Common DNS Operations

```bash
# Restart BIND
systemctl restart named

# Check BIND configuration
named-checkconf /etc/named.conf

# Check zone file
named-checkzone domain.com /var/named/domain.com.db

# Query local DNS
dig @localhost domain.com
dig @localhost domain.com MX
dig @localhost domain.com TXT

# Trace DNS resolution
dig +trace domain.com

# Check propagation
dig +short domain.com @8.8.8.8
```

## Troubleshooting

| Issue | Solution |
|---|---|
| DNS not resolving | Check BIND is running: `systemctl status named` |
| Zone not updating | Rebuild zones: `/scripts/cwp_api account rebuild_var_named_all` |
| Serial mismatch | Check serial in zone file, rebuild named.conf |
| Open resolver abuse | Set `recursion no` in named.conf |
| DNS propagation delay | Check TTL values, verify upstream NS records |
| Slave DNS not syncing | Check master allow-transfer settings |

### Diagnostic Commands

```bash
# Check BIND status
systemctl status named

# View BIND logs
tail -f /var/log/messages | grep named

# List all zones
ls /var/named/*.db

# Verify zone syntax
for zone in /var/named/*.db; do named-checkzone $(basename $zone .db) $zone; done

# Check named.conf syntax
named-checkconf
```

## Additional Resources

- `references/dns-templates.md` -- Complete zone template examples
- `references/dns-cluster.md` -- DNS cluster and FreeDNS setup guide
- `references/bind.md` -- BIND configuration and security hardening
