#!/usr/bin/env bash
# =============================================================================
# Example: Setup Email with DKIM and SPF
# =============================================================================
# Configures a domain for email with proper DNS records (SPF, DKIM, DMARC),
# Postfix, Dovecot, and OpenDKIM.
# =============================================================================
set -euo pipefail

DOMAIN="${1:-}"
SERVER_IP="${2:-$(hostname -I | awk '{print $1}')}"
HOSTNAME="$(hostname -f)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
die()       { log_error "$@"; exit 1; }

[[ -z "$DOMAIN" ]] && { echo "Usage: $0 <domain> [server-ip]"; exit 1; }

echo -e "${BOLD}=== Email Setup for $DOMAIN ===${NC}"
echo "  Server: $HOSTNAME"
echo "  IP:     $SERVER_IP"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Verify prerequisites
# ---------------------------------------------------------------------------
log_info "Checking prerequisites..."

command -v postfix &>/dev/null || die "Postfix not installed."
command -v dovecot &>/dev/null || die "Dovecot not installed."
command -v opendkim-genkey &>/dev/null || {
    log_warn "OpenDKIM not installed. Installing..."
    yum install -y opendkim || dnf install -y opendkim || die "Failed to install OpenDKIM"
}

# ---------------------------------------------------------------------------
# Step 2: Configure Postfix
# ---------------------------------------------------------------------------
log_info "Configuring Postfix..."

# Backup original config
cp /etc/postfix/main.cf /etc/postfix/main.cf.bak.$(date +%s)

# Set hostname and domain
postconf -e "myhostname = $HOSTNAME"
postconf -e "mydomain = $DOMAIN"
postconf -e "myorigin = \$mydomain"
postconf -e "mydestination = \$myhostname, \$mydomain, localhost.\$mydomain, localhost"

# Enable TLS
postconf -e "smtpd_tls_cert_file = /etc/pki/tls/certs/${HOSTNAME}.pem"
postconf -e "smtpd_tls_key_file = /etc/pki/tls/private/${HOSTNAME}.pem"
postconf -e "smtpd_tls_security_level = may"
postconf -e "smtp_tls_security_level = may"

# Enable SASL authentication via Dovecot
postconf -e "smtpd_sasl_type = dovecot"
postconf -e "smtpd_sasl_path = private/auth"
postconf -e "smtpd_sasl_auth_enable = yes"

# Anti-spam restrictions
postconf -e "smtpd_helo_required = yes"
postconf -e "smtpd_recipient_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination"

# Message size limit
postconf -e "message_size_limit = 52428800"

log_info "Postfix configured."

# ---------------------------------------------------------------------------
# Step 3: Configure Dovecot
# ---------------------------------------------------------------------------
log_info "Configuring Dovecot..."

DOVECOT_CONF="/etc/dovecot/dovecot.conf"
DOVECOT_LOCAL="/etc/dovecot/local.conf"

cat > "$DOVECOT_LOCAL" <<EOF
# CWP Email Configuration - Generated $(date -u +%Y-%m-%dT%H:%M:%SZ)
protocols = imap pop3 lmtp
listen = *, ::

ssl = required
ssl_cert = </etc/pki/tls/certs/${HOSTNAME}.pem
ssl_key = </etc/pki/tls/private/${HOSTNAME}.pem
ssl_min_protocol = TLSv1.2

auth_mechanisms = plain login

userdb {
    driver = passwd
}

passdb {
    driver = pam
}

service auth {
    unix_listener /var/spool/postfix/private/auth {
        mode = 0660
        user = postfix
        group = postfix
    }
}

namespace inbox {
    mailbox Drafts { special_use = \Drafts; auto = subscribe }
    mailbox Junk { special_use = \Junk; auto = subscribe }
    mailbox Trash { special_use = \Trash; auto = subscribe }
    mailbox Sent { special_use = \Sent; auto = subscribe }
}

log_path = /var/log/dovecot.log
auth_verbose = yes
EOF

log_info "Dovecot configured."

# ---------------------------------------------------------------------------
# Step 4: Generate DKIM keys
# ---------------------------------------------------------------------------
log_info "Generating DKIM keys..."

DKIM_DIR="/etc/opendkim/keys/${DOMAIN}"
mkdir -p "$DKIM_DIR"

# Generate DKIM key
opendkim-genkey -b 2048 -d "$DOMAIN" -D "$DKIM_DIR" -s default -v

# Set permissions
chown -R opendkim:opendkim /etc/opendkim
chmod 600 "$DKIM_DIR/default.private"

# Get DKIM public key
DKIM_PUBKEY=$(cat "$DKIM_DIR/default.txt" | grep -oP 'p=\K[^"]+' | tr -d '[:space:]' || echo "")

if [[ -z "$DKIM_PUBKEY" ]]; then
    log_warn "Could not extract DKIM public key automatically."
    DKIM_PUBKEY="<CHECK ${DKIM_DIR}/default.txt>"
fi

# Configure OpenDKIM
cat > /etc/opendkim.conf <<EOF
AutoRestart yes
AutoRestartRate 10/1h
Syslog yes
SyslogSuccess yes
LogWhy yes
Canonicalization relaxed/simple
ExternalIgnoreList refile:/etc/opendkim/TrustedHosts
InternalHosts refile:/etc/opendkim/TrustedHosts
KeyTable refile:/etc/opendkim/KeyTable
SigningTable refile:/etc/opendkim/SigningTable
Mode sv
PidFile /run/opendkim/opendkim.pid
SignatureAlgorithm rsa-sha256
UserID opendkim:opendkim
Socket inet:8891@localhost
EOF

# Configure signing tables
echo "default._domainkey.${DOMAIN}    ${DOMAIN}:default:/etc/opendkim/keys/${DOMAIN}/default.private" > /etc/opendkim/KeyTable
echo "*@${DOMAIN}    default._domainkey.${DOMAIN}" > /etc/opendkim/SigningTable
echo "127.0.0.1" > /etc/opendkim/TrustedHosts
echo "::1" >> /etc/opendkim/TrustedHosts
echo "${SERVER_IP}" >> /etc/opendkim/TrustedHosts
echo "*.${DOMAIN}" >> /etc/opendkim/TrustedHosts

# Configure Postfix to use OpenDKIM
postconf -e "milter_default_action = accept"
postconf -e "milter_protocol = 6"
postconf -e "smtpd_milters = inet:localhost:8891"
postconf -e "non_smtpd_milters = inet:localhost:8891"

log_info "DKIM keys generated."

# ---------------------------------------------------------------------------
# Step 5: Display DNS records to add
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== DNS Records to Add ===${NC}"
echo ""
echo "Add the following DNS records to your zone:"
echo ""
echo "  ; SPF Record"
echo "  @    IN    TXT    \"v=spf1 +a +mx +ip4:${SERVER_IP} ~all\""
echo ""
echo "  ; DKIM Record"
echo "  default._domainkey    IN    TXT    \"v=DKIM1; k=rsa; p=${DKIM_PUBKEY}\""
echo ""
echo "  ; DMARC Record"
echo "  _dmarc    IN    TXT    \"v=DMARC1; p=quarantine; rua=mailto:dmarc@${DOMAIN}; fo=1\""
echo ""
echo "  ; MX Record"
echo "  @    IN    MX    10    mail.${DOMAIN}."
echo ""
echo "  ; A Record for mail subdomain"
echo "  mail    IN    A    ${SERVER_IP}"
echo ""

# ---------------------------------------------------------------------------
# Step 6: Start services
# ---------------------------------------------------------------------------
log_info "Starting services..."

systemctl restart postfix
systemctl restart dovecot
systemctl enable opendkim 2>/dev/null || true
systemctl restart opendkim

systemctl enable postfix dovecot

log_info "Services started."

# ---------------------------------------------------------------------------
# Step 7: Verify
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== Verification ===${NC}"
echo ""

# Check Postfix
if systemctl is-active postfix &>/dev/null; then
    echo -e "  ${GREEN}OK${NC}  Postfix is running"
else
    echo -e "  ${RED}FAIL${NC} Postfix is not running"
fi

# Check Dovecot
if systemctl is-active dovecot &>/dev/null; then
    echo -e "  ${GREEN}OK${NC}  Dovecot is running"
else
    echo -e "  ${RED}FAIL${NC} Dovecot is not running"
fi

# Check OpenDKIM
if systemctl is-active opendkim &>/dev/null; then
    echo -e "  ${GREEN}OK${NC}  OpenDKIM is running"
else
    echo -e "  ${RED}FAIL${NC} OpenDKIM is not running"
fi

echo ""
echo -e "${BOLD}=== Setup Complete ===${NC}"
echo ""
echo "Next steps:"
echo "  1. Add the DNS records listed above"
echo "  2. Wait for DNS propagation (up to 48 hours)"
echo "  3. Test email delivery:"
echo "     echo 'Test' | mail -s 'Test Subject' test@gmail.com"
echo "  4. Check your score: https://www.mail-tester.com/"
echo "  5. Verify DKIM: https://mxtoolbox.com/dkim.aspx"
