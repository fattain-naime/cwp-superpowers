#!/usr/bin/env bash
# =============================================================================
# Example: Install SSL Certificate on CWP
# =============================================================================
# Demonstrates installing a Let's Encrypt SSL certificate and configuring
# HTTPS for a domain hosted on CWP.
# =============================================================================
set -euo pipefail

DOMAIN="${1:-}"
EMAIL="${2:-admin@${DOMAIN}}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()       { log_error "$@"; exit 1; }

[[ -z "$DOMAIN" ]] && { echo "Usage: $0 <domain> [email]"; exit 1; }

echo -e "${BOLD}=== SSL Certificate Installation for $DOMAIN ===${NC}"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Check prerequisites
# ---------------------------------------------------------------------------
log_info "Checking prerequisites..."

# Check if certbot is installed
if ! command -v certbot &>/dev/null; then
    log_info "Installing certbot..."
    dnf install -y certbot python3-certbot-apache python3-certbot-nginx 2>/dev/null || \
        yum install -y certbot python3-certbot-apache python3-certbot-nginx 2>/dev/null || \
        die "Failed to install certbot"
fi

# Check if domain resolves to this server
log_info "Checking DNS resolution..."
SERVER_IP=$(hostname -I | awk '{print $1}')
DOMAIN_IP=$(dig +short "$DOMAIN" A 2>/dev/null | head -1)

if [[ "$DOMAIN_IP" != "$SERVER_IP" ]]; then
    log_warn "Domain $DOMAIN resolves to $DOMAIN_IP, but server IP is $SERVER_IP"
    log_warn "SSL verification may fail if DNS is not pointing to this server."
    read -rp "Continue anyway? (y/N): " confirm
    [[ "$confirm" == "y" ]] || exit 1
fi

# ---------------------------------------------------------------------------
# Step 2: Ensure web server is running
# ---------------------------------------------------------------------------
log_info "Checking web server..."

if systemctl is-active httpd &>/dev/null; then
    log_info "Apache is running."
    WEB_SERVER="apache"
elif systemctl is-active nginx &>/dev/null; then
    log_info "Nginx is running."
    WEB_SERVER="nginx"
else
    log_warn "Neither Apache nor Nginx detected. Starting Apache..."
    systemctl start httpd
    WEB_SERVER="apache"
fi

# ---------------------------------------------------------------------------
# Step 3: Create webroot for verification
# ---------------------------------------------------------------------------
log_info "Setting up webroot verification..."

mkdir -p /var/www/html/.well-known/acme-challenge
chown -R apache:apache /var/www/html/.well-known 2>/dev/null || true

# Ensure .well-known is accessible
if [[ -f /etc/httpd/conf/httpd.conf ]]; then
    # Add Alias for .well-known if not already present
    if ! grep -q "\.well-known" /etc/httpd/conf/httpd.conf; then
        cat >> /etc/httpd/conf/httpd.conf <<'WELLKNOWN'

# Let's Encrypt webroot
Alias /.well-known /var/www/html/.well-known
<Directory /var/www/html/.well-known>
    Options None
    AllowOverride None
    Require all granted
</Directory>
WELLKNOWN
        systemctl reload httpd
    fi
fi

# ---------------------------------------------------------------------------
# Step 4: Obtain SSL certificate
# ---------------------------------------------------------------------------
log_info "Obtaining SSL certificate from Let's Encrypt..."

# Method 1: Using CWP CLI
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CWP_CMD="${SCRIPT_DIR}/../cli/cwp"

if [[ -x "$CWP_CMD" ]]; then
    log_info "Using CWP CLI to install SSL..."
    "$CWP_CMD" ssl install "$DOMAIN" 2>/dev/null && {
        log_info "SSL installed via CWP CLI."
        INSTALL_METHOD="cwp"
    } || {
        log_warn "CWP CLI method failed, falling back to certbot..."
        INSTALL_METHOD="certbot"
    }
else
    INSTALL_METHOD="certbot"
fi

# Method 2: Using certbot directly
if [[ "$INSTALL_METHOD" == "certbot" ]]; then
    certbot certonly \
        --webroot \
        -w /var/www/html \
        -d "$DOMAIN" \
        -d "www.${DOMAIN}" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive \
        --force-renewal 2>/dev/null || {

        # Fallback: standalone mode
        log_warn "Webroot method failed. Trying standalone mode..."
        systemctl stop httpd nginx 2>/dev/null || true

        certbot certonly \
            --standalone \
            -d "$DOMAIN" \
            -d "www.${DOMAIN}" \
            --email "$EMAIL" \
            --agree-tos \
            --non-interactive

        systemctl start httpd nginx 2>/dev/null || true
    }
fi

# ---------------------------------------------------------------------------
# Step 5: Configure Apache for SSL
# ---------------------------------------------------------------------------
log_info "Configuring Apache SSL virtual host..."

SSL_CONF="/etc/httpd/conf.d/${DOMAIN}-ssl.conf"

if [[ ! -f "$SSL_CONF" ]]; then
    cat > "$SSL_CONF" <<EOF
# SSL Virtual Host for ${DOMAIN}
# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

<VirtualHost *:443>
    ServerName ${DOMAIN}
    ServerAlias www.${DOMAIN}
    DocumentRoot /home/${DOMAIN}/public_html

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${DOMAIN}/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${DOMAIN}/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/${DOMAIN}/chain.pem

    # SSL Security
    SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!RC4
    SSLHonorCipherOrder on

    # HSTS Header
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"

    # Security Headers
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    <Directory /home/${DOMAIN}/public_html>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog /var/log/httpd/${DOMAIN}-ssl-error.log
    CustomLog /var/log/httpd/${DOMAIN}-ssl-access.log combined
</VirtualHost>
EOF
    log_info "SSL virtual host created."
fi

# ---------------------------------------------------------------------------
# Step 6: HTTP to HTTPS redirect
# ---------------------------------------------------------------------------
log_info "Setting up HTTP to HTTPS redirect..."

REDIRECT_CONF="/etc/httpd/conf.d/${DOMAIN}-redirect.conf"

if [[ ! -f "$REDIRECT_CONF" ]]; then
    cat > "$REDIRECT_CONF" <<EOF
# HTTP to HTTPS redirect for ${DOMAIN}
<VirtualHost *:80>
    ServerName ${DOMAIN}
    ServerAlias www.${DOMAIN}
    RewriteEngine On
    RewriteCond %{HTTPS} off
    RewriteRule ^(.*)$ https://%{HTTP_HOST}%{REQUEST_URI} [L,R=301]
</VirtualHost>
EOF
    log_info "HTTP to HTTPS redirect configured."
fi

# ---------------------------------------------------------------------------
# Step 7: Restart and verify
# ---------------------------------------------------------------------------
log_info "Restarting Apache..."

apachectl configtest 2>&1 || die "Apache configuration test failed!"
systemctl restart httpd

# Verify SSL
log_info "Verifying SSL certificate..."
echo ""
echo "Testing HTTPS connection..."
if curl -sS -o /dev/null -w "HTTP Status: %{http_code}\nSSL Verify: %{ssl_verify_result}\n" "https://${DOMAIN}" 2>/dev/null; then
    echo ""
fi

# Show certificate info
echo ""
echo -e "${BOLD}Certificate Details:${NC}"
echo | openssl s_client -servername "$DOMAIN" -connect "${DOMAIN}:443" 2>/dev/null | openssl x509 -noout -subject -issuer -dates 2>/dev/null || echo "  Could not retrieve certificate."

# ---------------------------------------------------------------------------
# Step 8: Setup auto-renewal
# ---------------------------------------------------------------------------
log_info "Setting up auto-renewal..."

# Add cron job for renewal
CRON_CMD="0 3 * * * certbot renew --quiet --post-hook 'systemctl reload httpd nginx' 2>/dev/null"
(crontab -l 2>/dev/null | grep -v certbot; echo "$CRON_CMD") | crontab -
log_info "Auto-renewal cron job added."

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${GREEN}${BOLD}=== SSL Installation Complete ===${NC}"
echo ""
echo "  Domain:     https://${DOMAIN}"
echo "  Certificate: /etc/letsencrypt/live/${DOMAIN}/"
echo "  Auto-renewal: Configured (daily at 3:00 AM)"
echo ""
echo "Verify your SSL configuration:"
echo "  - https://www.ssllabs.com/ssltest/analyze.html?d=${DOMAIN}"
echo "  - https://www.sslshopper.com/ssl-checker.html#hostname=${DOMAIN}"
echo ""
