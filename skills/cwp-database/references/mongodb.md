# MongoDB Reference

## Overview

MongoDB is available as an optional NoSQL database in CWP. It is used by applications that require document-oriented storage.

---

## Installation

### Via CWP Admin Panel

Navigate to: **SQL Services > MongoDB > Install**

### Manual Installation (MongoDB 7.0)

```bash
# Add MongoDB repository
cat > /etc/yum.repos.d/mongodb-org-7.0.repo << 'EOF'
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-7.0.asc
EOF

# Install
yum install mongodb-org

# Start and enable
systemctl start mongod
systemctl enable mongod
```

---

## Directory Structure

| Item               | Path                                    |
|--------------------|-----------------------------------------|
| Binary             | `/usr/bin/mongod`, `/usr/bin/mongosh`   |
| Data directory     | `/var/lib/mongo/`                       |
| Config             | `/etc/mongod.conf`                      |
| Log                | `/var/log/mongodb/mongod.log`           |
| PID file           | `/var/run/mongodb/mongod.pid`           |

---

## Configuration

### mongod.conf

**Path:** `/etc/mongod.conf`

```yaml
# Network
net:
  port: 27017
  bindIp: 127.0.0.1    # Change to 0.0.0.0 for remote access
  maxIncomingConnections: 65536

# Storage
storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 0.5    # Adjust based on available RAM
    collectionConfig:
      blockCompressor: snappy

# Logging
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Process
processManagement:
  fork: false
  pidFilePath: /var/run/mongodb/mongod.pid

# Security
security:
  authorization: enabled    # Enable after creating admin user

# Operation Profiling
operationProfiling:
  mode: slowOp
  slowOpThresholdMs: 100

# Replication (optional)
#replication:
#  replSetName: "rs0"
```

---

## User Management

### Create Admin User

```javascript
// Connect to MongoDB
mongosh

// Switch to admin database
use admin

// Create admin user
db.createUser({
  user: "admin",
  pwd: "secure_password",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "clusterAdmin", db: "admin" }
  ]
})
```

### Create Application User

```javascript
// Switch to application database
use myapp

// Create user with read/write access
db.createUser({
  user: "appuser",
  pwd: "app_password",
  roles: [
    { role: "readWrite", db: "myapp" }
  ]
})
```

### Common Roles

| Role                   | Description                          |
|------------------------|--------------------------------------|
| read                   | Read-only access to database         |
| readWrite              | Read and write access                |
| dbAdmin                | Database administration              |
| userAdmin              | User management for database         |
| clusterAdmin           | Cluster administration               |
| readAnyDatabase        | Read access to all databases         |
| readWriteAnyDatabase   | Read/write access to all databases   |
| userAdminAnyDatabase   | User management for all databases    |
| dbAdminAnyDatabase     | DB admin for all databases           |
| root                  | Superuser access                     |

---

## Common Operations

### Database Operations

```javascript
// Show databases
show dbs

// Create/switch database
use mydb

// Drop current database
db.dropDatabase()

// Show collections
show collections
```

### CRUD Operations

```javascript
// Insert document
db.users.insertOne({ name: "John", email: "john@example.com" })
db.users.insertMany([
  { name: "Jane", email: "jane@example.com" },
  { name: "Bob", email: "bob@example.com" }
])

// Find documents
db.users.find()
db.users.find({ name: "John" })
db.users.find({ age: { $gt: 25 } })
db.users.findOne({ name: "John" })

// Update documents
db.users.updateOne({ name: "John" }, { $set: { age: 30 } })
db.users.updateMany({}, { $inc: { age: 1 } })

// Delete documents
db.users.deleteOne({ name: "John" })
db.users.deleteMany({ age: { $lt: 18 } })
```

### Indexes

```javascript
// Create index
db.users.createIndex({ email: 1 }, { unique: true })
db.users.createIndex({ name: 1, age: -1 })

// List indexes
db.users.getIndexes()

// Drop index
db.users.dropIndex("email_1")

// Text index for search
db.articles.createIndex({ content: "text", title: "text" })
```

---

## Backup and Restore

### mongodump

```bash
# Backup all databases
mongodump --out /backup/mongodb/$(date +%Y%m%d)

# Backup specific database
mongodump --db mydb --out /backup/mongodb/

# Backup specific collection
mongodump --db mydb --collection users --out /backup/mongodb/

# Backup with authentication
mongodump --uri="mongodb://admin:password@localhost:27017" --out /backup/

# Backup with compression
mongodump --gzip --out /backup/mongodb/
```

### mongorestore

```bash
# Restore all databases
mongorestore /backup/mongodb/

# Restore specific database
mongorestore --db mydb /backup/mongodb/mydb/

# Restore specific collection
mongorestore --db mydb --collection users /backup/mongodb/mydb/users.bson

# Drop existing data before restore
mongorestore --drop /backup/mongodb/

# Restore with authentication
mongorestore --uri="mongodb://admin:password@localhost:27017" /backup/
```

### Automated Backup Script

```bash
#!/bin/bash
BACKUP_DIR="/backup/mongodb"
DATE=$(date +%Y%m%d_%H%M%S)
mongodump --gzip --out "${BACKUP_DIR}/${DATE}"
# Cleanup old backups (keep 7 days)
find ${BACKUP_DIR} -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;
```

---

## Security

### Enable Authentication

```yaml
# In mongod.conf
security:
  authorization: enabled
```

```bash
systemctl restart mongod
```

### Restrict Network Access

```yaml
# In mongod.conf
net:
  bindIp: 127.0.0.1    # Localhost only
  # Or specific IPs
  # bindIp: 127.0.0.1,192.168.1.100
```

### Enable TLS/SSL

```yaml
# In mongod.conf
net:
  ssl:
    mode: requireSSL
    PEMKeyFile: /etc/ssl/mongodb/server.pem
    CAFile: /etc/ssl/mongodb/ca.pem
```

### Firewall Rules (CSF)

```bash
# In /etc/csf/csf.conf
# MongoDB port 27017 should NOT be opened to the internet
# Only allow local or trusted IP access
TCP_IN = "...27017..."  # Only if remote access is needed
```

---

## Monitoring

### mongosh Commands

```javascript
// Server status
db.serverStatus()

// Current operations
db.currentOp()

// Kill operation
db.killOp(<opid>)

// Collection stats
db.users.stats()

// Database stats
db.stats()

// Replica set status
rs.status()
```

### Performance Monitoring

```javascript
// Enable profiler
db.setProfilingLevel(1, { slowms: 100 })

// View profile data
db.system.profile.find().sort({ts: -1}).limit(10)

// Disable profiler
db.setProfilingLevel(0)
```

---

## PHP MongoDB Extension

### Installation

```bash
# Install via PECL
pecl install mongodb

# Add to php.ini
echo "extension=mongodb.so" >> /usr/local/php81/lib/php.ini
```

### Connection String

```php
<?php
// Without authentication
$client = new MongoDB\Client("mongodb://localhost:27017");

// With authentication
$client = new MongoDB\Client("mongodb://admin:password@localhost:27017");

// With database in URI
$client = new MongoDB\Client("mongodb://appuser:password@localhost:27017/myapp");

// Select database and collection
$collection = $client->myapp->users;

// Insert
$collection->insertOne(['name' => 'John', 'email' => 'john@example.com']);

// Find
$result = $collection->find(['name' => 'John']);
```

---

## Troubleshooting

### Won't start
```bash
# Check logs
tail -50 /var/log/mongodb/mongod.log

# Check data directory permissions
ls -la /var/lib/mongo/

# Repair database
mongod --repair --dbpath /var/lib/mongo/

# Check disk space
df -h /var/lib/mongo/
```

### Connection refused
```bash
# Check if running
systemctl status mongod

# Check bind IP
grep bindIp /etc/mongod.conf

# Check port
ss -tlnp | grep 27017
```

### Slow queries
```javascript
// Check current operations
db.currentOp({"secs_running": {"$gt": 5}})

// Explain query
db.users.find({name: "John"}).explain("executionStats")

// Check indexes
db.users.getIndexes()
```
