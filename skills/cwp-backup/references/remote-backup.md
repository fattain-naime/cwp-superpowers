# Remote Backup Reference

## Overview

CWP supports multiple remote backup destinations including S3-compatible storage, Google Drive, SSH/SFTP, SMB/CIFS, and NFS mounts.

---

## Supported Remote Destinations

| Destination       | Protocol | CWP Pro Feature |
|-------------------|----------|-----------------|
| Amazon S3         | S3       | Yes             |
| Google Drive      | OAuth    | Yes             |
| SSH/SFTP          | SSH      | No              |
| SMB/CIFS          | SMB      | No              |
| NFS               | NFS      | No              |
| FTP               | FTP      | No              |
| Dropbox           | API      | Yes             |
| Backblaze B2      | S3       | Yes             |
| Wasabi            | S3       | Yes             |

---

## Amazon S3 Backup

### Configuration

**Admin Panel > Backup > Remote Backup > Amazon S3**

```ini
# S3 settings
remote_backup_type=s3
s3_bucket=your-backup-bucket
s3_region=us-east-1
s3_access_key=YOUR_ACCESS_KEY
s3_secret_key=YOUR_SECRET_KEY
s3_path=backups/server-name/
s3_storage_class=STANDARD
```

### Manual S3 Setup

```bash
# Install AWS CLI
pip3 install awscli

# Configure credentials
aws configure
# Enter: Access Key, Secret Key, Region, Output format
```

### S3 Backup Script

```bash
#!/bin/bash
# /scripts/s3_backup

BUCKET="your-backup-bucket"
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
SERVER=$(hostname)

# Upload to S3
aws s3 sync ${BACKUP_DIR}/ s3://${BUCKET}/${SERVER}/${DATE}/ \
    --storage-class STANDARD_IA

# Delete old backups (keep 30 days)
aws s3 ls s3://${BUCKET}/${SERVER}/ | while read -r line; do
    createDate=$(echo $line | awk '{print $1}')
    if [[ $(date -d "${createDate}" +%s) -lt $(date -d "30 days ago" +%s) ]]; then
        folder=$(echo $line | awk '{print $2}')
        aws s3 rm s3://${BUCKET}/${SERVER}/${folder} --recursive
    fi
done
```

### S3-Compatible Storage (MinIO, Wasabi, Backblaze)

```ini
# Wasabi
s3_endpoint=s3.wasabisys.com
s3_bucket=your-bucket
s3_region=us-east-1

# Backblaze B2
s3_endpoint=s3.us-west-002.backblazeb2.com
s3_bucket=your-bucket

# MinIO
s3_endpoint=minio.example.com:9000
s3_bucket=your-bucket
s3_use_ssl=yes
```

---

## Google Drive Backup

### Setup

1. Go to **Backup > Remote Backup > Google Drive**
2. Click "Authorize" to start OAuth flow
3. Log in with Google account
4. Grant permissions
5. Copy authorization code back to CWP

### Configuration

```ini
remote_backup_type=gdrive
gdrive_folder=CWP-Backups
gdrive_credentials=/usr/local/cwp/.conf/gdrive_credentials.json
```

### Manual rclone Setup

```bash
# Install rclone
curl https://rclone.org/install.sh | bash

# Configure Google Drive
rclone config
# Choose: New remote > Google Drive > Follow prompts

# Test connection
rclone lsd gdrive:Backup/

# Manual backup
rclone sync /backup/ gdrive:CWP-Backups/$(hostname)/$(date +%Y%m%d)/
```

### rclone Backup Script

```bash
#!/bin/bash
# /scripts/gdrive_backup

REMOTE="gdrive"
FOLDER="CWP-Backups/$(hostname)/$(date +%Y%m%d)"
BACKUP_DIR="/backup"

# Sync backups to Google Drive
rclone sync ${BACKUP_DIR}/ ${REMOTE}:${FOLDER}/ \
    --transfers 4 \
    --checkers 8 \
    --log-file=/var/log/gdrive_backup.log \
    --log-level INFO

# Delete old backups (keep 30 days)
rclone delete ${REMOTE}:CWP-Backups/$(hostname)/ \
    --min-age 30d
```

---

## SSH/SFTP Backup

### Configuration

**Admin Panel > Backup > Remote Backup > SSH**

```ini
remote_backup_type=ssh
ssh_host=backup.example.com
ssh_port=22
ssh_user=backupuser
ssh_key=/root/.ssh/backup_key
ssh_path=/backups/
```

### Setup SSH Key Authentication

```bash
# Generate SSH key
ssh-keygen -t ed25519 -f /root/.ssh/backup_key -N ""

# Copy public key to backup server
ssh-copy-id -i /root/.ssh/backup_key.pub backupuser@backup.example.com

# Test connection
ssh -i /root/.ssh/backup_key backupuser@backup.example.com "ls /backups/"
```

### SSH Backup Script

```bash
#!/bin/bash
# /scripts/ssh_backup

REMOTE_HOST="backup.example.com"
REMOTE_USER="backupuser"
REMOTE_PATH="/backups/$(hostname)/"
SSH_KEY="/root/.ssh/backup_key"
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d)

# Create remote directory
ssh -i ${SSH_KEY} ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_PATH}/${DATE}"

# Sync backups
rsync -avz --delete \
    -e "ssh -i ${SSH_KEY}" \
    ${BACKUP_DIR}/ \
    ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/${DATE}/

# Cleanup old backups (keep 30 days)
ssh -i ${SSH_KEY} ${REMOTE_USER}@${REMOTE_HOST} \
    "find ${REMOTE_PATH} -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;"
```

---

## SMB/CIFS Backup

### Install CIFS Utilities

```bash
yum install cifs-utils
```

### Mount SMB Share

```bash
# Create mount point
mkdir -p /mnt/backup_share

# Mount with credentials
mount -t cifs //nas.example.com/backups /mnt/backup_share \
    -o username=backupuser,password=secure_pass,vers=3.0

# Mount with credentials file
mount -t cifs //nas.example.com/backups /mnt/backup_share \
    -o credentials=/root/.smb_credentials,vers=3.0
```

### Credentials File

**Path:** `/root/.smb_credentials`

```ini
username=backupuser
password=secure_pass
domain=WORKGROUP
```

```bash
chmod 600 /root/.smb_credentials
```

### Persistent Mount (fstab)

```bash
# Add to /etc/fstab
//nas.example.com/backups /mnt/backup_share cifs credentials=/root/.smb_credentials,vers=3.0,_netdev 0 0
```

### SMB Backup Script

```bash
#!/bin/bash
# /scripts/smb_backup

SMB_MOUNT="/mnt/backup_share"
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d)

# Check if mounted
if ! mountpoint -q ${SMB_MOUNT}; then
    mount -t cifs //nas.example.com/backups ${SMB_MOUNT} \
        -o credentials=/root/.smb_credentials,vers=3.0
fi

# Copy backups
rsync -avz ${BACKUP_DIR}/ ${SMB_MOUNT}/$(hostname)/${DATE}/

# Cleanup old backups
find ${SMB_MOUNT}/$(hostname) -maxdepth 1 -type d -mtime +30 -exec rm -rf {} \;
```

---

## NFS Backup

### Install NFS Client

```bash
yum install nfs-utils
```

### Mount NFS Share

```bash
# Create mount point
mkdir -p /mnt/nfs_backup

# Mount
mount -t nfs backupserver:/exports/backups /mnt/nfs_backup

# Add to /etc/fstab
backupserver:/exports/backups /mnt/nfs_backup nfs defaults,_netdev 0 0
```

### NFS Backup Script

```bash
#!/bin/bash
# /scripts/nfs_backup

NFS_MOUNT="/mnt/nfs_backup"
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d)

# Check mount
if ! mountpoint -q ${NFS_MOUNT}; then
    mount -t nfs backupserver:/exports/backups ${NFS_MOUNT}
fi

# Sync backups
rsync -avz ${BACKUP_DIR}/ ${NFS_MOUNT}/$(hostname)/${DATE}/
```

---

## Encrypted Backups

### Using GPG

```bash
# Generate GPG key
gpg --gen-key

# Encrypt backup
gpg --encrypt --recipient admin@example.com backup.tar.gz

# Decrypt backup
gpg --decrypt backup.tar.gz.gpg > backup.tar.gz
```

### Encrypted Backup Script

```bash
#!/bin/bash
# /scripts/encrypted_backup

BACKUP_DIR="/backup"
GPG_RECIPIENT="admin@example.com"
REMOTE_HOST="backup.example.com"

for file in ${BACKUP_DIR}/*.tar.gz; do
    # Encrypt
    gpg --encrypt --recipient ${GPG_RECIPIENT} ${file}

    # Upload encrypted file
    scp ${file}.gpg backupuser@${REMOTE_HOST}:/backups/

    # Remove local encrypted copy
    rm -f ${file}.gpg
done
```

---

## Remote Backup Monitoring

### Check Remote Backup Status

```bash
# View backup logs
tail -50 /var/log/remote_backup.log

# Check S3 uploads
aws s3 ls s3://your-bucket/your-server/ --recursive

# Check Google Drive
rclone lsd gdrive:CWP-Backups/$(hostname)/

# Check SSH/SFTP
ssh -i /root/.ssh/backup_key backupuser@backup.example.com "ls -la /backups/$(hostname)/"
```

### Monitoring Script

```bash
#!/bin/bash
# /scripts/remote_backup_check

REMOTE_TYPE="s3"
LAST_BACKUP=$(find /backup -name "*.tar.gz" -mtime -1 | head -1)

if [ -z "${LAST_BACKUP}" ]; then
    echo "WARNING: No recent local backups found" | mail -s "Backup Alert" admin@example.com
fi

# Check if remote sync is up to date
case ${REMOTE_TYPE} in
    s3)
        aws s3 ls s3://your-bucket/$(hostname)/ --recursive | tail -1
        ;;
    gdrive)
        rclone ls gdrive:CWP-Backups/$(hostname)/ | tail -1
        ;;
    ssh)
        ssh -i /root/.ssh/backup_key backupuser@backup.example.com "ls -lt /backups/$(hostname)/ | head -1"
        ;;
esac
```

---

## Troubleshooting

### S3 upload fails
```bash
# Test AWS credentials
aws s3 ls

# Check bucket access
aws s3 ls s3://your-bucket/

# Check IAM permissions
aws sts get-caller-identity

# Check network connectivity
ping s3.amazonaws.com
```

### Google Drive authorization expired
```bash
# Re-authorize
rclone config reconnect gdrive:

# Check token
cat ~/.config/rclone/rclone.conf | grep -A5 gdrive
```

### SSH backup fails
```bash
# Test SSH connection
ssh -i /root/.ssh/backup_key backupuser@backup.example.com

# Check key permissions
chmod 600 /root/.ssh/backup_key

# Check remote directory permissions
ssh -i /root/.ssh/backup_key backupuser@backup.example.com "ls -la /backups/"
```

### SMB mount fails
```bash
# Test SMB connection
smbclient -L //nas.example.com -U backupuser

# Check credentials
cat /root/.smb_credentials

# Check network connectivity
ping nas.example.com

# Try different SMB version
mount -t cifs //nas.example.com/backups /mnt/backup_share -o vers=2.0
```
