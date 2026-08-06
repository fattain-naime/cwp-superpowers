#!/bin/bash
# CWP Migration Example: cPanel to CWP Migration
# This script demonstrates migrating a single account from cPanel to CWP.

# Configuration
CWP_API_URL="https://DEST_SERVER_IP:2304/v1"
CWP_API_KEY="${CWP_API_KEY}"
SOURCE_IP="$1"
SOURCE_USER="$2"
BACKUP_FILE="$3"

if [ -z "$SOURCE_IP" ] || [ -z "$SOURCE_USER" ]; then
    echo "Usage: $0 <source_ip> <username> [backup_file]"
    echo "Example: $0 192.168.1.100 examuser /path/to/backup.tar.gz"
    exit 1
fi

echo "=== cPanel to CWP Migration ==="
echo "Source: $SOURCE_IP"
echo "Username: $SOURCE_USER"
echo ""

# Step 1: Create cPanel backup on source (if no backup file provided)
if [ -z "$BACKUP_FILE" ]; then
    echo "[1/5] Creating backup on source server..."
    ssh root@$SOURCE_IP "/scripts/pkgacct $SOURCE_USER"
    BACKUP_FILE="/home/cpmove-${SOURCE_USER}.tar.gz"
    echo "  Backup created: $BACKUP_FILE"
else
    echo "[1/5] Using provided backup: $BACKUP_FILE"
fi

# Step 2: Transfer backup to CWP server
echo "[2/5] Transferring backup to CWP server..."
DEST_PATH="/home/${SOURCE_USER}"
mkdir -p "$DEST_PATH"

if [[ "$BACKUP_FILE" == /* ]]; then
    # Local file
    cp "$BACKUP_FILE" "$DEST_PATH/"
else
    # Remote file - transfer via SCP
    scp root@$SOURCE_IP:"$BACKUP_FILE" "$DEST_PATH/"
fi

echo "  Backup transferred to $DEST_PATH/"

# Step 3: Extract backup
echo "[3/5] Extracting backup..."
cd "$DEST_PATH"
BACKUP_NAME=$(basename "$BACKUP_FILE")

if [[ "$BACKUP_NAME" == *.tar.gz ]]; then
    tar -xzf "$BACKUP_NAME"
elif [[ "$BACKUP_NAME" == *.tar ]]; then
    tar -xf "$BACKUP_NAME"
fi

echo "  Backup extracted"

# Step 4: Restore account via CWP API
echo "[4/5] Restoring account in CWP..."
# Note: CWP has built-in restore functionality
# Navigate to CWP Admin -> User Accounts -> Restore Backup
# Or use the restore script:
/scripts/cwp_api account restore "$SOURCE_USER"

echo "  Account restored"

# Step 5: Verify migration
echo "[5/5] Verifying migration..."
echo ""
echo "=== Migration Complete ==="
echo "Account: $SOURCE_USER"
echo ""
echo "Verification checklist:"
echo "  [ ] Website loads correctly"
echo "  [ ] Database accessible"
echo "  [ ] Email delivery works"
echo "  [ ] DNS resolves correctly"
echo "  [ ] SSL certificate valid"
echo ""
echo "Access CWP panel to complete verification."
