#!/bin/bash
# CWP Backup Example: Backup Verification Script
# This script verifies backup integrity and completeness.

# Configuration
BACKUP_DIR="/home/backup"
LOG_FILE="/var/log/backup-verify.log"
RETENTION_DAYS=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

echo "=== CWP Backup Verification ==="
echo "Date: $(date)"
echo "Backup Directory: $BACKUP_DIR"
echo ""

# Check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    error "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# Step 1: Check for recent backups
log "Step 1: Checking for recent backups..."
RECENT_BACKUPS=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime -1 | wc -l)
if [ "$RECENT_BACKUPS" -gt 0 ]; then
    success "Found $RECENT_BACKUPS backup(s) from last 24 hours"
else
    warn "No backups found from last 24 hours"
fi

# Step 2: Verify backup file integrity
log "Step 2: Verifying backup file integrity..."
TOTAL_FILES=0
CORRUPT_FILES=0

for backup in "$BACKUP_DIR"/*.tar.gz; do
    if [ -f "$backup" ]; then
        TOTAL_FILES=$((TOTAL_FILES + 1))
        if tar -tzf "$backup" > /dev/null 2>&1; then
            success "Valid: $(basename "$backup")"
        else
            error "Corrupt: $(basename "$backup")"
            CORRUPT_FILES=$((CORRUPT_FILES + 1))
        fi
    fi
done

echo ""
echo "Total backup files: $TOTAL_FILES"
echo "Valid: $((TOTAL_FILES - CORRUPT_FILES))"
echo "Corrupt: $CORRUPT_FILES"

# Step 3: Check backup contents
log "Step 3: Checking backup contents..."
for backup in "$BACKUP_DIR"/*.tar.gz; do
    if [ -f "$backup" ]; then
        echo ""
        echo "=== $(basename "$backup") ==="
        
        # List contents
        CONTENTS=$(tar -tzf "$backup" | head -20)
        echo "First 20 files:"
        echo "$CONTENTS"
        
        # Check for essential files
        HAS_HOME=$(tar -tzf "$backup" | grep -c "home/" || true)
        HAS_DB=$(tar -tzf "$backup" | grep -c "\.sql" || true)
        HAS_EMAIL=$(tar -tzf "$backup" | grep -c "mail/" || true)
        
        echo ""
        echo "Contents summary:"
        echo "  Home directories: $HAS_HOME entries"
        echo "  Database dumps: $HAS_DB entries"
        echo "  Email data: $HAS_EMAIL entries"
    fi
done

# Step 4: Check storage usage
log "Step 4: Checking storage usage..."
echo ""
echo "=== Storage Usage ==="
du -sh "$BACKUP_DIR"
echo ""
df -h "$BACKUP_DIR"

# Step 5: Check for old backups
log "Step 5: Checking for old backups..."
OLD_BACKUPS=$(find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$RETENTION_DAYS | wc -l)
if [ "$OLD_BACKUPS" -gt 0 ]; then
    warn "Found $OLD_BACKUPS backup(s) older than $RETENTION_DAYS days"
    echo "Consider cleaning up old backups:"
    echo "  find $BACKUP_DIR -name '*.tar.gz' -mtime +$RETENTION_DAYS -delete"
else
    success "No old backups found"
fi

# Summary
echo ""
echo "=== Verification Summary ==="
echo "Total backups: $TOTAL_FILES"
echo "Valid: $((TOTAL_FILES - CORRUPT_FILES))"
echo "Corrupt: $CORRUPT_FILES"
echo "Old (>$RETENTION_DAYS days): $OLD_BACKUPS"
echo ""
echo "Log file: $LOG_FILE"
