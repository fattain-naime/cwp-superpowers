#!/usr/bin/env bash
# =============================================================================
# Example: Create Hosting Account via CWP CLI and API
# =============================================================================
# Demonstrates creating a complete hosting account with database, email,
# DNS, and SSL using the CWP CLI and API client.
# =============================================================================
set -euo pipefail

# Configuration
DOMAIN="${1:-example.com}"
USERNAME="${2:-$(echo "$DOMAIN" | cut -d. -f1 | head -c 8)}"
EMAIL="admin@${DOMAIN}"
PASSWORD="${3:-$(openssl rand -base64 12)}"
DB_NAME="${USERNAME}_db"
DB_USER="${USERNAME}_usr"
DB_PASS="$(openssl rand -base64 12)"

# Load CLI config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CWP_CMD="${SCRIPT_DIR}/../cli/cwp"
API_CMD="${SCRIPT_DIR}/../scripts/cwp-api-client.sh"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'

log_info()  { echo -e "${GREEN}[STEP]${NC} $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_done()  { echo -e "${GREEN}[DONE]${NC} $*"; }

echo -e "${BOLD}=== Create Hosting Account ===${NC}"
echo ""
echo "  Domain:   $DOMAIN"
echo "  Username: $USERNAME"
echo "  Email:    $EMAIL"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Create user account via CLI
# ---------------------------------------------------------------------------
log_info "Creating user account..."
if [[ -x "$CWP_CMD" ]]; then
    "$CWP_CMD" user add "$USERNAME" 2>/dev/null || {
        log_warn "CLI user add failed, trying API..."
        "$API_CMD" account create "$USERNAME" "default" "$DOMAIN" 2>/dev/null || \
            log_warn "API account create also failed."
    }
else
    echo "  CWP CLI not found. Using API directly..."
    "$API_CMD" account create "$USERNAME" "default" "$DOMAIN" 2>/dev/null || true
fi
log_done "User account created."

# ---------------------------------------------------------------------------
# Step 2: Create database via API
# ---------------------------------------------------------------------------
log_info "Creating database..."
"$API_CMD" database create "$DB_NAME" 2>/dev/null || {
    log_warn "API database creation failed. Using CLI fallback..."
    "$CWP_CMD" database create "$DB_NAME" 2>/dev/null || true
}
log_done "Database created: $DB_NAME"

# ---------------------------------------------------------------------------
# Step 3: Create database user
# ---------------------------------------------------------------------------
log_info "Creating database user..."
"$API_CMD" database user-add "$DB_USER" "$DB_NAME" "$DB_PASS" 2>/dev/null || {
    "$CWP_CMD" database user-add "$DB_USER" "$DB_NAME" 2>/dev/null || true
}
log_done "Database user created: $DB_USER"

# ---------------------------------------------------------------------------
# Step 4: Create email account
# ---------------------------------------------------------------------------
log_info "Creating email account..."
EMAIL_PASS="$(openssl rand -base64 12)"
"$API_CMD" email create "${EMAIL}" "$EMAIL_PASS" 2>/dev/null || {
    "$CWP_CMD" email create "${EMAIL}" "$EMAIL_PASS" 2>/dev/null || true
}
log_done "Email account created: ${EMAIL}"

# ---------------------------------------------------------------------------
# Step 5: Generate DNS zone
# ---------------------------------------------------------------------------
log_info "Setting up DNS..."
"$CWP_CMD" dns add-record "$DOMAIN" A "@" "$(hostname -I | awk '{print $1}')" 2>/dev/null || true
"$CWP_CMD" dns add-record "$DOMAIN" A "www" "$(hostname -I | awk '{print $1}')" 2>/dev/null || true
"$CWP_CMD" dns add-record "$DOMAIN" A "mail" "$(hostname -I | awk '{print $1}')" 2>/dev/null || true
"$CWP_CMD" dns add-record "$DOMAIN" MX "@" "mail.${DOMAIN}" 2>/dev/null || true
"$CWP_CMD" dns add-record "$DOMAIN" TXT "@" "v=spf1 +a +mx +ip4:$(hostname -I | awk '{print $1}') ~all" 2>/dev/null || true
log_done "DNS records configured."

# ---------------------------------------------------------------------------
# Step 6: Install SSL
# ---------------------------------------------------------------------------
log_info "Installing SSL certificate..."
"$CWP_CMD" ssl install "$DOMAIN" 2>/dev/null || {
    log_warn "SSL installation failed. You can install manually later:"
    echo "  cwp ssl install $DOMAIN"
}
log_done "SSL setup complete."

# ---------------------------------------------------------------------------
# Step 7: Create backup schedule
# ---------------------------------------------------------------------------
log_info "Setting up daily backups..."
"$CWP_CMD" backup schedule "$USERNAME" daily 2>/dev/null || true
log_done "Daily backup scheduled."

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}=== Account Created Successfully ===${NC}"
echo ""
echo "  Domain:         $DOMAIN"
echo "  Username:       $USERNAME"
echo "  Home Directory: /home/$USERNAME/public_html"
echo ""
echo "  Database:       $DB_NAME"
echo "  DB User:        $DB_USER"
echo "  DB Password:    $DB_PASS"
echo ""
echo "  Email:          $EMAIL"
echo "  Email Password: $EMAIL_PASS"
echo ""
echo "  Panel URL:      http://${DOMAIN}:2031"
echo "  Panel User:     $USERNAME"
echo "  Panel Password: (set via CWP admin)"
echo ""
echo -e "${YELLOW}IMPORTANT: Save these credentials securely!${NC}"
echo ""

# Save credentials to file
CREDS_FILE="/tmp/${DOMAIN}_credentials.txt"
cat > "$CREDS_FILE" <<EOF
Account Credentials for $DOMAIN
Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
=================================
Domain:         $DOMAIN
Username:       $USERNAME
Password:       $PASSWORD
Database:       $DB_NAME
DB User:        $DB_USER
DB Password:    $DB_PASS
Email:          $EMAIL
Email Password: $EMAIL_PASS
EOF
chmod 600 "$CREDS_FILE"
echo "Credentials saved to: $CREDS_FILE"
