# SSL/TLS Reference

## Overview

CWP supports multiple SSL/TLS certificate management methods: AutoSSL (Let's Encrypt), ACME protocol, and custom certificates.

---

## Certificate Locations

| Type                | Path                                              |
|---------------------|---------------------------------------------------|
| CWP Panel SSL       | `/usr/local/cwp/ssl/`                             |
| Let's Encrypt       | `/etc/letsencrypt/live/{domain}/`                 |
| Custom certificates | `/etc/pki/tls/certs/` and `/etc/pki/tls/private/`|
| AutoSSL             | `/etc/pki/tls/certs/` (symlinks to LE certs)     |

---

## AutoSSL (Let's Encrypt)

AutoSSL is CWP's built-in automatic SSL certificate management using Let's Encrypt.

### Enable AutoSSL

**Admin Panel > Security > SSL Certificates > AutoSSL**

Or per-user:
**User Panel > Security > SSL Certificates > AutoSSL**

### How AutoSSL Works

1. CWP checks domains configured on the server
2. Generates ACME challenge for each domain
3. Places challenge files in `/.well-known/acme-challenge/`
4. Validates domain ownership
5. Obtains certificate from Let's Encrypt
6. Installs certificate automatically
7. Sets up auto-renewal via cron

### AutoSSL Configuration

**Path:** `/usr/local/cwp/.conf/autossl.conf`

```ini
enabled=yes
provider=letsencrypt
email=admin@example.com
staging=no
auto_renew=yes
renew_days=30
include_www=yes
include_subdomains=no
```

### Manual AutoSSL

AutoSSL is managed via the **CWP Admin panel** (Security > SSL Certificates > AutoSSL). There is no `/scripts/autossl` CLI script.

To generate the server hostname certificate:

```bash
if [ -f /scripts/generate_hostname_ssl ]; then
    sh /scripts/generate_hostname_ssl
elif [ -f /scripts/generate_ssl ]; then
    sh /scripts/generate_ssl
fi
```

### Renewing Let's Encrypt Certificates

```bash
if [ -f /scripts/renew_lets_encrypt ]; then
    sh /scripts/renew_lets_encrypt
else
    certbot renew --quiet 2>/dev/null || acme.sh --renew-all
fi
```

---

## ACME Protocol (Let's Encrypt)

### Installation

```bash
# Install acme.sh (CWP default ACME client)
curl https://get.acme.sh | sh

# Or via CWP script
/scripts/install_acme
```

### acme.sh Usage

```bash
# Issue certificate
acme.sh --issue -d example.com -d www.example.com --webroot /home/user/public_html

# Install certificate
acme.sh --install-cert -d example.com \
    --key-file /etc/pki/tls/private/example.com.key \
    --fullchain-file /etc/pki/tls/certs/example.com.crt \
    --reloadcmd "systemctl reload httpd"

# Revoke certificate
acme.sh --revoke -d example.com

# Renew certificate
acme.sh --renew -d example.com --force

# List certificates
acme.sh --list

# Delete certificate
acme.sh --remove -d example.com
```

### DNS Challenge (for Wildcard)

```bash
# Using Cloudflare DNS
export CF_Token="your_cloudflare_api_token"
export CF_Zone_ID="your_zone_id"

acme.sh --issue -d example.com -d "*.example.com" --dns dns_cf

# Using manual DNS
acme.sh --issue -d example.com -d "*.example.com" --dns --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

### Cron Auto-Renewal

acme.sh installs its own cron job:
```bash
# Check cron
crontab -l | grep acme

# Should show something like:
# 0 0 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh"
```

---

## Custom Certificates

### Install via CWP Panel

**Admin Panel > Security > SSL Certificates > Install Certificate**

Required files:
- Certificate (CRT)
- Private Key (KEY)
- CA Bundle (optional but recommended)

### Manual Installation

```bash
# Place certificate files
cp server.crt /etc/pki/tls/certs/example.com.crt
cp server.key /etc/pki/tls/private/example.com.key
cp ca-bundle.crt /etc/pki/tls/certs/example.com.ca-bundle

# Set permissions
chmod 644 /etc/pki/tls/certs/example.com.crt
chmod 600 /etc/pki/tls/private/example.com.key
```

### Generate Self-Signed Certificate

```bash
# Generate private key
openssl genrsa -out /etc/pki/tls/private/server.key 2048

# Generate CSR
openssl req -new -key /etc/pki/tls/private/server.key \
    -out /etc/pki/tls/certs/server.csr

# Generate self-signed certificate
openssl req -x509 -nodes -days 365 \
    -key /etc/pki/tls/private/server.key \
    -out /etc/pki/tls/certs/server.crt \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=server.example.com"
```

### Generate CSR (Certificate Signing Request)

```bash
# Via CWP script
/scripts/generate_csr example.com

# Manual
openssl req -new -newkey rsa:2048 -nodes \
    -keyout /etc/pki/tls/private/example.com.key \
    -out /etc/pki/tls/certs/example.com.csr \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=example.com"
```

---

## SNI (Server Name Indication)

SNI allows multiple SSL certificates on a single IP address.

### Apache SNI

Apache supports SNI by default with mod_ssl:

```apache
# Virtual host 1
<VirtualHost *:443>
    ServerName site1.com
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/site1.com.crt
    SSLCertificateKeyFile /etc/pki/tls/private/site1.com.key
</VirtualHost>

# Virtual host 2 (same IP)
<VirtualHost *:443>
    ServerName site2.com
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/site2.com.crt
    SSLCertificateKeyFile /etc/pki/tls/private/site2.com.key
</VirtualHost>
```

### Nginx SNI

```nginx
server {
    listen 443 ssl;
    server_name site1.com;
    ssl_certificate /etc/pki/tls/certs/site1.com.crt;
    ssl_certificate_key /etc/pki/tls/private/site1.com.key;
}

server {
    listen 443 ssl;
    server_name site2.com;
    ssl_certificate /etc/pki/tls/certs/site2.com.crt;
    ssl_certificate_key /etc/pki/tls/private/site2.com.key;
}
```

---

## TLS Configuration Best Practices

### Apache SSL Configuration

```apache
# SSL Protocol (disable old versions)
SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1

# Strong cipher suite
SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384
SSLHonorCipherOrder on

# OCSP Stapling
SSLUseStapling on
SSLStaplingCache "shmcb:/var/run/ocsp(128000)"

# HSTS Header
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
```

### Nginx SSL Configuration

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
ssl_prefer_server_ciphers off;

ssl_session_cache shared:SSL:10m;
ssl_session_timeout 1d;
ssl_session_tickets off;

ssl_stapling on;
ssl_stapling_verify on;

add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
```

### Generate DH Parameters

```bash
openssl dhparam -out /etc/pki/tls/dhparams.pem 2048
```

---

## CWP Panel SSL

### Change Panel Certificate

**Admin Panel > Security > SSL Certificates > Panel Certificate**

### Manual Panel SSL

```bash
# Edit cwpsrv SSL config
vi /usr/local/cwpsrv/conf/ssl/panel.pem

# Contains certificate + key + CA bundle
cat server.crt server.key ca-bundle.crt > /usr/local/cwpsrv/conf/ssl/panel.pem

# Restart CWP panel
systemctl restart cwpsrv
```

---

## Certificate Verification

### Check Certificate

```bash
# View certificate details
openssl x509 -in /etc/pki/tls/certs/example.com.crt -text -noout

# Check certificate expiration
openssl x509 -in /etc/pki/tls/certs/example.com.crt -enddate -noout

# Verify certificate matches key
openssl x509 -noout -modulus -in /etc/pki/tls/certs/example.com.crt | openssl md5
openssl rsa -noout -modulus -in /etc/pki/tls/private/example.com.key | openssl md5
# Both should output the same hash

# Test SSL connection
openssl s_client -connect example.com:443 -servername example.com

# Check certificate chain
openssl s_client -connect example.com:443 -showcerts
```

---

## Troubleshooting

### Certificate not trusted
```bash
# Verify CA bundle is included
openssl s_client -connect example.com:443 -servername example.com 2>&1 | grep "Verify"

# Check certificate chain
openssl s_client -connect example.com:443 -showcerts

# Ensure CA bundle is correct
cat server.crt ca-bundle.crt > fullchain.crt
```

### AutoSSL not working
```bash
# Check if domain resolves to server
dig +short example.com

# Verify webroot is accessible
curl http://example.com/.well-known/acme-challenge/test

# Check Let's Encrypt rate limits
# https://letsencrypt.org/docs/rate-limits/

# Check acme.sh logs
tail -50 /root/.acme.sh/acme.sh.log
```

### SSL handshake failed
```bash
# Check SSL configuration
apache -t  # or nginx -t

# Verify certificate files exist
ls -la /etc/pki/tls/certs/example.com.crt
ls -la /etc/pki/tls/private/example.com.key

# Check file permissions
# Key should be 600, cert should be 644

# Test with openssl
openssl s_client -connect example.com:443 -servername example.com
```

### Mixed content warnings
```bash
# Check for HTTP resources on HTTPS page
grep -r "http://" /home/user/public_html/ --include="*.php" --include="*.html"

# Add HSTS header
Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

# Force HTTPS redirect
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
```
