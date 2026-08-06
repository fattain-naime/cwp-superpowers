#!/bin/bash
# CWP Backup Example: Backup Restoration Script
# This script demonstrates restoring from a CWP backup.

# Configuration
BACKUP_FILE="$1"
RESTORE_USER="$2"
RESTORE_TYPE="${3:-full}"  # full, files, database, email

if [ -z "$BACKUP_FILE" ] || [ -z "$RESTORE_USER" ]; then
    echo "Usage: $0 <backup_file> <username> [restore_type]"
    echo ""
    echo "Restore types:"
    echo "  full     - Restore everything (default)"
    echo "  files    - Restore only website files"
    echo "  database - Restore only databases"
    echo "  email    - Restore only email"
    echo ""
    echo "Example: /home/backup/backup-2024-01-15.tar.gz examuser full"
    exit 1
fi

echo "=== CWP Backup Restoration ==="
echo "Backup: $BACKUP_FILE"
echo "Username: $RESTORE_USER"
echo "Type: $RESTORE_TYPE"
echo ""

# Validate backup file
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file not found: $BACKUP_FILE"
    exit 1
fi

# Create temporary extraction directory
TEMP_DIR="/tmp/restore_$$"
mkdir -p "$TEMP_DIR"

echo "[1/5] Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"
echo "  Extracted to $TEMP_DIR"

# Find the backup contents
BACKUP_DIR=$(find "$TEMP_DIR" -maxdepth 1 -type d | tail -1)

case "$RESTORE_TYPE" in
    files)
        echo "[2/5] Restoring website files..."
        if [ -d "$BACKUP_DIR/home/$RESTORE_USER" ]; then
            cp -a "$BACKUP_DIR/home/$RESTORE_USER/"* /home/$RESTORE_USER/
            chown -R $RESTORE_USER:$RESTORE_USER /home/$RESTORE_USER/
            echo "  Files restored"
        else
            echo "  No home directory found in backup"
        fi
        ;;
    
    database)
        echo "[2/5] Restoring databases..."
        if [ -d "$BACKUP_DIR/mysql" ]; then
            for sql in "$BACKUP_DIR/mysql/"*.sql; do
                if [ -f "$sql" ]; then
                    DB_NAME=$(basename "$sql" .sql)
                    echo "  Importing $DB_NAME..."
                    mysql -u root "$DB_NAME" < "$sql"
                fi
            done
            echo "  Databases restored"
        else
            echo "  No database dumps found in backup"
        fi
        ;;
    
    email)
        echo "[2/5] Restoring email..."
        if [ -d "$BACKUP_DIR/var/vmail" ]; then
            cp -a "$BACKUP_DIR/var/vmail/"* /var/vmail/
            chown -R vmail:vmail /var/vmail/
            echo "  Email restored"
        else
            echo "  No email data found in backup"
        fi
        ;;
    
    full)
        echo "[2/5] Restoring full account..."
        
        # Restore home directory
        if [ -d "$BACKUP_DIR/home/$RESTORE_USER" ]; then
            echo "  Restoring files..."
            cp -a "$BACKUP_DIR/home/$RESTORE_USER/"* /home/$RESTORE_USER/
            chown -R $RESTORE_USER:$RESTORE_USER /home/$RESTORE_USER/
        fi
        
        # Restore databases
        if [ -d "$BACKUP_DIR/mysql" ]; then
            echo "  Restoring databases..."
            for sql in "$BACKUP_DIR/mysql/"*.sql; do
                if [ -f "$sql" ]; then
                    DB_NAME=$(basename "$sql" .sql)
                    mysql -u root "$DB_NAME" < "$sql"
                fi
            done
        fi
        
        # Restore email
        if [ -d "$BACKUP_DIR/var/vmail" ]; then
            echo "  Restoring email..."
            cp -a "$BACKUP_DIR/var/vmail/"* /var/vmail/
            chown -R vmail:vmail /var/vmail/
        fi
        
        echo "  Full restoration complete"
        ;;
    
    *)
        echo "Error: Unknown restore type: $RESTORE_TYPE"
        rm -rf "$TEMP_DIR"
        exit 1
        ;;
esac

# Cleanup
echo "[3/5] Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

# Rebuild configurations
echo "[4/5] Rebuilding configurations..."
/scripts/cwpsrv_rebuild_user_conf
/scripts/phpfpm_rebuild_user_conf

# Verify restoration
echo "[5/5] Verifying restoration..."
echo ""
echo "=== Restoration Complete ==="
echo "Account: $RESTORE_USER"
echo "Type: $RESTORE_TYPE"
echo ""
echo "Verification checklist:"
echo "  [ ] Website loads correctly"
echo "  [ ] Database connections work"
echo "  [ ] Email delivery works"
echo "  [ ] File permissions correct"
echo ""
echo "Run backup verification to confirm integrity."
