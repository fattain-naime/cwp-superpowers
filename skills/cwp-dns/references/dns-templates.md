# DNS Templates Reference

## Overview

CWP uses DNS templates to generate zone files for new domains. Templates contain variables that are replaced with actual values when a zone is created.

---

## Template Locations

```
/usr/local/cwp/conf/bind/zones/          # Zone templates
/usr/local/cwp/conf/bind/                 # BIND config templates
/usr/local/cwp/conf/dns/                  # DNS helper templates
```

---

## Zone Template Variables

CWP replaces these variables when generating zone files:

| Variable                 | Description                          | Example               |
|--------------------------|--------------------------------------|-----------------------|
| `{domain}`               | Domain name                          | example.com           |
| `{ip}`                   | Server IP address                    | 192.168.1.10          |
| `{hostname}`             | Server hostname                      | server.example.com    |
| `{ns1}`                  | Primary nameserver                   | ns1.example.com       |
| `{ns2}`                  | Secondary nameserver                 | ns2.example.com       |
| `{ns1_ip}`               | Primary NS IP                        | 192.168.1.10          |
| `{ns2_ip}`               | Secondary NS IP                      | 192.168.1.11          |
| `{admin_email}`          | Admin email (dot format)             | admin.example.com     |
| `{serial}`               | Zone serial (YYYYMMDDNN)             | 2024010101            |
| `{ttl}`                  | Default TTL                          | 14400                 |
| `{mx_host}`              | MX server hostname                   | mail.example.com      |
| `{dkim_key}`             | DKIM public key                      | MIGfMA0GCS...         |
| `{spf_record}`           | SPF record                           | v=spf1 +a +mx ~all   |

---

## Default Zone Template

**Path:** `/usr/local/cwp/conf/bind/zones/zone.db`

```$TTL {ttl}
@       IN      SOA     {ns1}. {admin_email}. (
                        {serial}        ; Serial
                        3600            ; Refresh
                        1800            ; Retry
                        1209600         ; Expire
                        86400           ; Minimum TTL
                )

; Nameservers
@       IN      NS      {ns1}.
@       IN      NS      {ns2}.

; A Records
@       IN      A       {ip}
www     IN      A       {ip}
mail    IN      A       {ip}
ftp     IN      A       {ip}
smtp    IN      A       {ip}
pop     IN      A       {ip}
imap    IN      A       {ip}
ns1     IN      A       {ns1_ip}
ns2     IN      A       {ns2_ip}

; MX Records
@       IN      MX      10      mail.{domain}.

; TXT Records
@       IN      TXT     "{spf_record}"

; Webmail
webmail IN      CNAME   {domain}.
```

---

## Custom Template Creation

### Create New Template

1. Copy default template:
```bash
cp /usr/local/cwp/conf/bind/zones/zone.db /usr/local/cwp/conf/bind/zones/zone_custom.db
```

2. Edit template with desired changes

3. Register template in CWP:
**Admin Panel > DNS Functions > DNS Templates**

### Example Custom Template

**Path:** `/usr/local/cwp/conf/bind/zones/zone_custom.db`

```$TTL 3600
@       IN      SOA     {ns1}. {admin_email}. (
                        {serial}
                        3600
                        900
                        1209600
                        3600
                )

; Nameservers
@       IN      NS      {ns1}.
@       IN      NS      {ns2}.

; Primary A Record
@       IN      A       {ip}
www     IN      A       {ip}

; Mail
mail    IN      A       {ip}
@       IN      MX      10      mail.{domain}.

; SPF
@       IN      TXT     "v=spf1 a mx ip4:{ip} ~all"

; DKIM
default._domainkey IN TXT "v=DKIM1; k=rsa; p={dkim_key}"

; DMARC
_dmarc  IN      TXT     "v=DMARC1; p=quarantine; rua=mailto:{admin_email}"

; CAA
@       IN      CAA     0 issue "letsencrypt.org"
@       IN      CAA     0 issuewild ";"

; Subdomains
cpanel  IN      CNAME   {domain}.
webmail IN      CNAME   {domain}.
ftp     IN      CNAME   {domain}.

; CDN
cdn     IN      CNAME   cdn.provider.com.
```

---

## Template Categories

### Basic Template

Standard records for most websites:
- A records for @, www, mail
- MX record pointing to mail server
- SPF record

### Email-Optimized Template

Enhanced email deliverability:
- All basic records
- DKIM record
- DMARC record
- Multiple MX records with priorities
- SPF with IP-specific rules

### CDN Template

For sites using a CDN:
- CNAME for www pointing to CDN
- A record for @ pointing to origin
- Separate mail records

### Multi-Server Template

For distributed setups:
- Different IPs for web and mail
- Multiple A records for load balancing
- SRV records for services

---

## DKIM Template Variables

### Generate DKIM Key

```bash
# Generate DKIM key pair
opendkim-genkey -s default -d example.com

# Move keys
mv default.private /etc/opendkim/keys/example.com/
mv default.txt /etc/opendkim/keys/example.com/

# Extract public key for DNS
cat /etc/opendkim/keys/example.com/default.txt
```

### DKIM in Template

```
default._domainkey IN TXT "v=DKIM1; k=rsa; p={dkim_key}"
```

### CWP DKIM Integration

CWP can automatically generate and manage DKIM keys. Enable via:
**Admin Panel > Email > DKIM Manager**

---

## SPF Templates

### Basic SPF
```
v=spf1 a mx ip4:{ip} ~all
```

### Strict SPF
```
v=spf1 a mx ip4:{ip} -all
```

### Multi-Server SPF
```
v=spf1 a mx ip4:{ip} ip4:192.168.1.20 ip4:192.168.1.21 include:_spf.google.com ~all
```

### Include Third-Party Services
```
v=spf1 a mx ip4:{ip} include:_spf.google.com include:spf.protection.outlook.com include:sendgrid.net ~all
```

---

## DMARC Templates

### Quarantine Policy
```
v=DMARC1; p=quarantine; rua=mailto:{admin_email}; pct=100
```

### Reject Policy
```
v=DMARC1; p=reject; rua=mailto:{admin_email}; pct=100
```

### Monitor Only
```
v=DMARC1; p=none; rua=mailto:{admin_email}; ruf=mailto:{admin_email}
```

---

## Using Templates via API

```bash
# List templates
curl -X GET "https://server:2304/api/?action=dns.list_templates&apikey=YOUR_KEY"

# Apply template to domain
curl -X POST "https://server:2304/api/?action=dns.apply_template&domain=example.com&template=zone_custom&apikey=YOUR_KEY"
```

---

## Template Best Practices

1. **Always use variables** - Never hardcode values that should be configurable
2. **Set appropriate TTLs** - Lower TTLs for records that change frequently
3. **Include all standard records** - A, MX, SPF, DKIM, DMARC
4. **Use CAA records** - Restrict certificate issuance
5. **Include reverse DNS** - For mail servers
6. **Test templates** - Verify generated zones before applying
7. **Version control** - Keep backups of custom templates

---

## Modifying Default Template

To change the default template for all new domains:

1. Edit `/usr/local/cwp/conf/bind/zones/zone.db`
2. Changes apply to newly created domains only
3. Existing domains retain their current zone files

To update existing domains, use:
**DNS Functions > Rebuild DNS Zones**

---

## Troubleshooting

### Template variables not replaced
```bash
# Check template file
cat /usr/local/cwp/conf/bind/zones/zone.db

# Verify CWP config has correct values
grep -E "nameserver|ip|hostname" /usr/local/cwp/.conf/cwp.conf

# Rebuild zone
/scripts/rebuild_dns
```

### Generated zone has syntax errors
```bash
# Check generated zone
named-checkzone example.com /var/named/example.com.db

# Compare with template
diff /usr/local/cwp/conf/bind/zones/zone.db /var/named/example.com.db
```

### Template not showing in panel
```bash
# Check template directory
ls -la /usr/local/cwp/conf/bind/zones/

# Verify file permissions
chmod 644 /usr/local/cwp/conf/bind/zones/zone_custom.db
```
