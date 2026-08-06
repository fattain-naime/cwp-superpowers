#!/bin/bash
# CWP API Example: Complete Account Provisioning
# This script demonstrates creating a new hosting account with all resources.

# Configuration
API_URL="https://SERVER_IP:2304/v1"
API_KEY="${CWP_API_KEY}"  # Set this environment variable before running

# Validate API key is set
if [ -z "$API_KEY" ]; then
    echo "Error: CWP_API_KEY environment variable not set"
    echo "Run: export CWP_API_KEY='your-api-key'"
    exit 1
fi

# Account details
DOMAIN="$1"
USERNAME="$2"
PASSWORD="$3"
EMAIL="$4"
IP="${5:-$(hostname -I | awk '{print $1}')}"
PACKAGE="${6:-default}"

if [ -z "$DOMAIN" ] || [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$EMAIL" ]; then
    echo "Usage: $0 <domain> <username> <password> <email> [ip] [package]"
    echo "Example: $0 example.com examuser SecurePass123 admin@example.com"
    exit 1
fi

echo "=== CWP Account Provisioning ==="
echo "Domain: $DOMAIN"
echo "Username: $USERNAME"
echo "IP: $IP"
echo "Package: $PACKAGE"
echo ""

# Step 1: Create account
echo "[1/5] Creating account..."
RESULT=$(curl -s -X POST "$API_URL/account" \
    -d "key=$API_KEY" \
    -d "action=add" \
    -d "domain=$DOMAIN" \
    -d "username=$USERNAME" \
    -d "password=$PASSWORD" \
    -d "email=$EMAIL" \
    -d "server_ips=$IP" \
    -d "package=$PACKAGE")

if echo "$RESULT" | grep -q '"status":"success"'; then
    echo "  Account created successfully"
else
    echo "  Failed to create account: $RESULT"
    exit 1
fi

# Step 2: Create database
echo "[2/5] Creating database..."
DBNAME="${USERNAME}_db"
DBUSER="${USERNAME}_user"
DBPASS=$(openssl rand -base64 12)

RESULT=$(curl -s -X POST "$API_URL/databasemysql" \
    -d "key=$API_KEY" \
    -d "action=add" \
    -d "username=$USERNAME" \
    -d "dbname=$DBNAME")

echo "  Database: $DBNAME"

# Step 3: Create database user
echo "[3/5] Creating database user..."
RESULT=$(curl -s -X POST "$API_URL/usermysql" \
    -d "key=$API_KEY" \
    -d "action=add" \
    -d "username=$USERNAME" \
    -d "dbname=$DBNAME" \
    -d "dbuser=$DBUSER" \
    -d "dbpass=$DBPASS")

echo "  DB User: $DBUSER"

# Step 4: Enable AutoSSL
echo "[4/5] Enabling AutoSSL..."
RESULT=$(curl -s -X POST "$API_URL/autossl" \
    -d "key=$API_KEY" \
    -d "action=add" \
    -d "domain=$DOMAIN")

echo "  AutoSSL enabled for $DOMAIN"

# Step 5: Verify account
echo "[5/5] Verifying account..."
RESULT=$(curl -s -X POST "$API_URL/account" \
    -d "key=$API_KEY" \
    -d "action=list")

echo ""
echo "=== Provisioning Complete ==="
echo "Domain: https://$DOMAIN"
echo "Panel: https://$(hostname -I | awk '{print $1}'):2030"
echo "Database: $DBNAME"
echo "DB User: $DBUSER"
echo "DB Password: $DBPASS"
echo ""
echo "Save these credentials securely!"
