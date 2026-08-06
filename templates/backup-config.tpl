#!/usr/bin/env bash
# =============================================================================
# CWP Backup Configuration Template
# =============================================================================
# Customize backup settings for your server.
# Copy to: /etc/cwp/backup.conf or source from your backup scripts.
# =============================================================================

# ---------------------------------------------------------------------------
# General Settings
# ---------------------------------------------------------------------------
BACKUP_ROOT="/backup"
BACKUP_RETENTION_DAYS=30
BACKUP_COMPRESSION="gzip"           # gzip, bzip2, xz, none
BACKUP_DATE_FORMAT="%Y%m%d_%H%M%S"
BACKUP_LOG="/var/log/cwp-backup.log"

# ---------------------------------------------------------------------------
# What to backup
# ---------------------------------------------------------------------------
BACKUP_HOME=true                    # /home directories
BACKUP_DATABASES=true               # MySQL/MariaDB databases
BACKUP_EMAIL=true                   # Email accounts and data
BACKUP_DNS=true                     # DNS zone files
BACKUP_CRON=true                    # Cron jobs
BACKUP_SSL=true                     # SSL certificates
BACKUP_CONFIG=true                  # System configuration files
BACKUP_APACHE=true                  # Apache configuration
BACKUP_NGINX=true                   # Nginx configuration
BACKUP_PHP=true                     # PHP configuration
BACKUP_POSTFIX=true                 # Postfix configuration

# ---------------------------------------------------------------------------
# Database backup settings
# ---------------------------------------------------------------------------
DB_BACKUP_METHOD="mysqldump"        # mysqldump, xtrabackup
DB_BACKUP_ALL=true                  # Backup all databases
DB_BACKUP_INDIVIDUAL=true           # Also backup each database separately
DB_BACKUP_ADDITIONAL_OPTS="--single-transaction --routines --troutines --events"

# Exclude databases from backup
DB_EXCLUDE=(
    "information_schema"
    "performance_schema"
    "sys"
    "test"
)

# ---------------------------------------------------------------------------
# Home directory settings
# ---------------------------------------------------------------------------
HOME_EXCLUDE_DIRS=(
    "tmp"
    ".cache"
    "node_modules"
    ".npm"
    "__pycache__"
    "*.log"
)

HOME_MAX_SIZE="10G"                 # Skip dirs larger than this

# ---------------------------------------------------------------------------
# Remote backup (optional)
# ---------------------------------------------------------------------------
REMOTE_BACKUP_ENABLED=false
REMOTE_BACKUP_TYPE="s3"             # s3, ftp, sftp, rsync, rclone
REMOTE_BACKUP_HOST=""
REMOTE_BACKUP_PORT=""
REMOTE_BACKUP_USER=""
REMOTE_BACKUP_PATH=""
REMOTE_BACKUP_BUCKET=""

# AWS S3 settings (when type=s3)
AWS_ACCESS_KEY=""
AWS_SECRET_KEY=""
AWS_REGION="us-east-1"
AWS_S3_STORAGE_CLASS="STANDARD_IA"  # STANDARD, STANDARD_IA, GLACIER

# Rclone remote name (when type=rclone)
RCLONE_REMOTE="remote:bucket/path"

# ---------------------------------------------------------------------------
# Schedule settings
# ---------------------------------------------------------------------------
SCHEDULE_ENABLED=false
SCHEDULE_CRON_DAILY="0 2 * * *"     # 2:00 AM daily
SCHEDULE_CRON_WEEKLY="0 2 * * 0"    # 2:00 AM Sunday
SCHEDULE_CRON_MONTHLY="0 2 1 * *"   # 2:00 AM 1st of month

# ---------------------------------------------------------------------------
# Notification settings
# ---------------------------------------------------------------------------
NOTIFY_ON_SUCCESS=false
NOTIFY_ON_FAILURE=true
NOTIFY_EMAIL=""
NOTIFY_WEBHOOK=""

# ---------------------------------------------------------------------------
# Encryption (optional)
# ---------------------------------------------------------------------------
ENCRYPTION_ENABLED=false
ENCRYPTION_KEY_FILE="/etc/cwp/backup.key"
ENCRYPTION_CIPHER="aes-256-cbc"

# ---------------------------------------------------------------------------
# Parallel backup settings
# ---------------------------------------------------------------------------
PARALLEL_BACKUPS=2                  # Number of parallel backup jobs
NICE_LEVEL=10                       # Process nice level (0-19, higher = lower priority)
IONICE_CLASS=2                      # ionice class (1=realtime, 2=best-effort, 3=idle)
IONICE_PRIORITY=7                   # ionice priority (0-7, higher = lower priority)

# ---------------------------------------------------------------------------
# Functions (source this file to use)
# ---------------------------------------------------------------------------

log_backup() {
    local level="$1" message="$2"
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $message" >> "$BACKUP_LOG" 2>/dev/null
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [$level] $message"
}

get_backup_filename() {
    local prefix="$1"
    local date_str
    date_str=$(date +"$BACKUP_DATE_FORMAT")
    local ext="tar"
    case "$BACKUP_COMPRESSION" in
        gzip) ext="tar.gz" ;;
        bzip2) ext="tar.bz2" ;;
        xz) ext="tar.xz" ;;
    esac
    echo "${BACKUP_ROOT}/${prefix}_${date_str}.${ext}"
}

get_compression_cmd() {
    case "$BACKUP_COMPRESSION" in
        gzip)  echo "gzip" ;;
        bzip2) echo "bzip2" ;;
        xz)    echo "xz" ;;
        none)  echo "cat" ;;
        *)     echo "gzip" ;;
    esac
}

ensure_backup_dir() {
    mkdir -p "$BACKUP_ROOT"
    chmod 700 "$BACKUP_ROOT"
}

cleanup_old_backups() {
    local days="${1:-$BACKUP_RETENTION_DAYS}"
    find "$BACKUP_ROOT" -name "*.tar.*" -mtime +"$days" -delete 2>/dev/null
    log_backup "INFO" "Cleaned up backups older than $days days"
}
