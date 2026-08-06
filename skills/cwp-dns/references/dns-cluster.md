# DNS Cluster Reference

## Overview

DNS clustering allows multiple CWP servers to share DNS zones, providing redundancy and geographic distribution for DNS resolution.

---

## DNS Cluster Types

### 1. CWP FreeDNS Cluster

Built-in CWP feature for synchronizing DNS between CWP servers.

### 2. BIND Zone Transfers (AXFR/IXFR)

Traditional DNS master-slave replication using BIND's native zone transfer mechanism.

### 3. External DNS Providers

Integration with third-party DNS services (Cloudflare, Route53, etc.).

---

## CWP FreeDNS Cluster

### Architecture

```
Master Server (Primary DNS)
  |
  +-- Slave Server 1 (Secondary DNS)
  +-- Slave Server 2 (Secondary DNS)
  +-- Slave Server N (Additional Slaves)
```

### Setup Master Server

1. Go to **DNS Functions > DNS Cluster**
2. Click "Add DNS Cluster Server"
3. Enter slave server details:
   - Server IP
   - CWP API Key
   - Server Name (optional)

### Setup Slave Server

1. Install CWP on the slave server
2. Go to **DNS Functions > DNS Cluster**
3. Add the master server's IP and API key
4. Enable "Slave Mode"

### Configuration

**Path:** `/usr/local/cwp/.conf/dns_cluster.conf`

```ini
# Master server settings
master_ip=192.168.1.10
master_api_key=YOUR_API_KEY
slave_mode=no

# Slave settings
slave_ip=192.168.1.11
slave_api_key=SLAVE_API_KEY
sync_interval=300
```

### Zone Synchronization

When a zone is added/modified on the master:
1. Master generates zone file
2. Master calls slave API to push zone
3. Slave receives and installs zone
4. Slave reloads BIND

```bash
# Manual sync
/scripts/dns_cluster_sync

# Check sync status
/scripts/dns_cluster_status
```

---

## BIND Zone Transfers (AXFR/IXFR)

### Master Configuration

**Path:** `/etc/named.conf` on master

```options {
    allow-transfer { 192.168.1.11; };  // Slave IP
    also-notify { 192.168.1.11; };     // Notify slave of changes
};

zone "example.com" IN {
    type master;
    file "example.com.db";
    allow-transfer { 192.168.1.11; };
    also-notify { 192.168.1.11; };
};
```

### Slave Configuration

**Path:** `/etc/named.conf` on slave

```zone "example.com" IN {
    type slave;
    file "slaves/example.com.db";
    masters { 192.168.1.10; };  // Master IP
};
```

### TSIG Authentication (Recommended)

Generate TSIG key:

```bash
tsig-keygen -a hmac-sha256 dns-transfer
```

Output:
```key "dns-transfer" {
    algorithm hmac-sha256;
    secret "base64_encoded_secret_here";
};
```

Add to both master and slave `named.conf`:

```key "dns-transfer" {
    algorithm hmac-sha256;
    secret "base64_encoded_secret_here";
};

options {
    allow-transfer { key "dns-transfer"; };
};

zone "example.com" IN {
    type master;
    file "example.com.db";
    allow-transfer { key "dns-transfer"; };
};
```

### Testing Zone Transfers

```bash
# Test AXFR from master
dig @192.168.1.10 example.com AXFR

# Test IXFR (incremental)
dig @192.168.1.10 example.com IXFR=2024010101

# Check slave zone
dig @192.168.1.11 example.com

# Verify serial numbers match
dig @192.168.1.10 example.com SOA +short
dig @192.168.1.11 example.com SOA +short
```

---

## Multi-Server DNS Setup

### Scenario: 3 DNS Servers

```
Server 1 (Master):  192.168.1.10  - ns1.example.com
Server 2 (Slave 1): 192.168.1.11  - ns2.example.com
Server 3 (Slave 2): 192.168.1.12  - ns3.example.com
```

### Master Configuration

```options {
    allow-transfer { 192.168.1.11; 192.168.1.12; };
    also-notify { 192.168.1.11; 192.168.1.12; };
};

# For each zone
zone "example.com" IN {
    type master;
    file "example.com.db";
    allow-transfer { key "dns-transfer"; };
    also-notify { 192.168.1.11; 192.168.1.12; };
};
```

### Slave Configuration (each slave)

```zone "example.com" IN {
    type slave;
    file "slaves/example.com.db";
    masters { 192.168.1.10; };
};
```

### Registrar Configuration

At your domain registrar, set nameservers:
```
ns1.example.com  -> 192.168.1.10
ns2.example.com  -> 192.168.1.11
ns3.example.com  -> 192.168.1.12
```

---

## External DNS Integration

### Cloudflare

CWP can push DNS records to Cloudflare via API:

```bash
# Install Cloudflare sync module
/scripts/install_cloudflare_dns

# Configure API
# Add to /usr/local/cwp/.conf/cloudflare.conf
CF_API_KEY=your_api_key
CF_EMAIL=admin@example.com
```

### Route53 (AWS)

```bash
# Install AWS CLI
pip install awscli

# Configure credentials
aws configure

# Sync zones
/scripts/sync_route53
```

---

## DNS Cluster Monitoring

### Health Check Script

```bash
#!/bin/bash
# /scripts/dns_health_check

MASTERS=("192.168.1.10")
SLAVES=("192.168.1.11" "192.168.1.12")
DOMAIN="example.com"

echo "=== DNS Cluster Health Check ==="

for master in "${MASTERS[@]}"; do
    echo "Master: $master"
    dig @${master} ${DOMAIN} SOA +short
done

for slave in "${SLAVES[@]}"; do
    echo "Slave: $slave"
    dig @${slave} ${DOMAIN} SOA +short
done

# Check serial consistency
MASTER_SERIAL=$(dig @${MASTERS[0]} ${DOMAIN} SOA +short | awk '{print $3}')
for slave in "${SLAVES[@]}"; do
    SLAVE_SERIAL=$(dig @${slave} ${DOMAIN} SOA +short | awk '{print $3}')
    if [ "$MASTER_SERIAL" != "$SLAVE_SERIAL" ]; then
        echo "WARNING: Serial mismatch on $slave (master: $MASTER_SERIAL, slave: $SLAVE_SERIAL)"
    else
        echo "OK: $slave serial matches ($SLAVE_SERIAL)"
    fi
done
```

### Monitoring Commands

```bash
# Check zone transfer status
rndc zonestatus example.com

# View transfer log
grep "transfer" /var/log/named/named.run

# Check BIND statistics
rndc stats
cat /var/named/data/named_stats.txt

# Test resolution from each server
dig @192.168.1.10 example.com
dig @192.168.1.11 example.com
dig @192.168.1.12 example.com
```

---

## DNS Failover

### Automatic Failover with Health Checks

Use monitoring tools to detect failures and update DNS:

```bash
#!/bin/bash
# /scripts/dns_failover

PRIMARY="192.168.1.10"
SECONDARY="192.168.1.20"
DOMAIN="example.com"

# Check primary server
if ! curl -s --max-time 5 http://${PRIMARY} > /dev/null; then
    echo "Primary server down, updating DNS..."

    # Update A record to point to secondary
    # Using CWP API
    curl -X POST "https://server:2304/api/?action=dns.edit_record" \
        -d "domain=${DOMAIN}" \
        -d "record_id=1" \
        -d "value=${SECONDARY}" \
        -d "apikey=YOUR_KEY"

    # Notify
    echo "DNS failover activated for ${DOMAIN}" | mail -s "DNS Failover Alert" admin@example.com
fi
```

### Cloudflare Failover

Cloudflare provides automatic failover with load balancing:

```bash
# Cloudflare Load Balancer configuration
# Configure via Cloudflare dashboard or API
```

---

## Troubleshooting

### Zone transfer refused
```bash
# Check allow-transfer on master
grep "allow-transfer" /etc/named.conf

# Check firewall
iptables -L | grep 53
csf -t 53

# Test from slave
dig @master_ip domain.com AXFR

# Check slave IP in allow-transfer list
```

### Serial number mismatch
```bash
# Check master serial
dig @master domain.com SOA +short

# Check slave serial
dig @slave domain.com SOA +short

# Force transfer
rndc retransfer domain.com
```

### Slave not receiving updates
```bash
# Check master notify is configured
grep "also-notify" /etc/named.conf

# Check slave zone type
grep "type slave" /etc/named.conf

# Check logs on both servers
tail -50 /var/log/named/named.run

# Force reload
rndc reload domain.com
```

### DNS cluster sync fails
```bash
# Check API key validity
curl -k "https://master:2304/api/?action=test&apikey=YOUR_KEY"

# Check network connectivity
ping slave_ip
telnet slave_ip 2304

# Check CWP logs
tail -50 /usr/local/cwpsrv/logs/error.log
```

### High latency on DNS resolution
```bash
# Check server load
top
uptime

# Check query rate
rndc stats
grep "queries" /var/log/named/named.run | wc -l

# Consider enabling caching
# In named.conf:
# max-cache-size 256m;
# max-cache-ttl 3600;
```
