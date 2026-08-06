# CWP API Examples Reference

## Setup

### Generate API Key

Generate your API key via the CWP Admin panel:

**Admin Panel > CWP Settings > API Manager > Generate API Key**

Copy the key and set it as a variable for use in API calls.

### Set Variables

```bash
SERVER="https://your-server:2304"
API_KEY="your_api_key_here"
```

---

## Account Management Examples

### List All Users

```bash
curl -k -X GET "${SERVER}/api/?action=list_users&apikey=${API_KEY}"
```

**Response:**
```json
{"status":"success","users":["user1","user2","user3"]}
```

### Create User Account

```bash
curl -k -X POST "${SERVER}/api/?action=add_user&apikey=${API_KEY}" \
    -d "username=newuser" \
    -d "password=SecurePass123!" \
    -d "domain=example.com" \
    -d "email=admin@example.com" \
    -d "package=default"
```

### Delete User Account

```bash
curl -k -X POST "${SERVER}/api/?action=delete_user&apikey=${API_KEY}" \
    -d "username=olduser"
```

### Modify User Account

```bash
curl -k -X POST "${SERVER}/api/?action=modify_user&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "package=premium" \
    -d "disk_quota=5120"
```

### Suspend User

```bash
curl -k -X POST "${SERVER}/api/?action=suspend_user&apikey=${API_KEY}" \
    -d "username=baduser" \
    -d "reason=Payment overdue"
```

### Unsuspend User

```bash
curl -k -X POST "${SERVER}/api/?action=unsuspend_user&apikey=${API_KEY}" \
    -d "username=baduser"
```

---

## Domain Management Examples

### Add Domain

```bash
curl -k -X POST "${SERVER}/api/?action=add_domain&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "domain=newdomain.com"
```

### Delete Domain

```bash
curl -k -X POST "${SERVER}/api/?action=delete_domain&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "domain=olddomain.com"
```

### List Domains for User

```bash
curl -k -X GET "${SERVER}/api/?action=list_domains&username=user1&apikey=${API_KEY}"
```

### Add Subdomain

```bash
curl -k -X POST "${SERVER}/api/?action=add_subdomain&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "subdomain=blog" \
    -d "domain=example.com"
```

### Add Parked Domain

```bash
curl -k -X POST "${SERVER}/api/?action=add_parked_domain&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "domain=alias.com" \
    -d "target_domain=example.com"
```

---

## DNS Examples

### List DNS Zones

```bash
curl -k -X GET "${SERVER}/api/?action=list_dns_zones&apikey=${API_KEY}"
```

### Add DNS Zone

```bash
curl -k -X POST "${SERVER}/api/?action=add_dns_zone&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "ip=192.168.1.10"
```

### Delete DNS Zone

```bash
curl -k -X POST "${SERVER}/api/?action=delete_dns_zone&apikey=${API_KEY}" \
    -d "domain=example.com"
```

### Add A Record

```bash
curl -k -X POST "${SERVER}/api/?action=add_dns_record&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "type=A" \
    -d "name=www" \
    -d "value=192.168.1.10" \
    -d "ttl=14400"
```

### Add MX Record

```bash
curl -k -X POST "${SERVER}/api/?action=add_dns_record&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "type=MX" \
    -d "name=@" \
    -d "value=mail.example.com" \
    -d "priority=10" \
    -d "ttl=14400"
```

### Add CNAME Record

```bash
curl -k -X POST "${SERVER}/api/?action=add_dns_record&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "type=CNAME" \
    -d "name=www" \
    -d "value=example.com" \
    -d "ttl=14400"
```

### Add TXT Record (SPF)

```bash
curl -k -X POST "${SERVER}/api/?action=add_dns_record&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "type=TXT" \
    -d "name=@" \
    -d "value=v=spf1 +a +mx +ip4:192.168.1.10 ~all" \
    -d "ttl=14400"
```

### Delete DNS Record

```bash
curl -k -X POST "${SERVER}/api/?action=delete_dns_record&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "record_id=123"
```

---

## Database Examples

### Create Database

```bash
curl -k -X POST "${SERVER}/api/?action=add_database&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "database=myapp_db"
```

### Create Database User

```bash
curl -k -X POST "${SERVER}/api/?action=add_db_user&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "db_user=myapp_user" \
    -d "db_pass=SecureDbPass123!"
```

### Grant Database Access

```bash
curl -k -X POST "${SERVER}/api/?action=grant_database&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "db_user=myapp_user" \
    -d "database=myapp_db" \
    -d "privileges=ALL"
```

### Delete Database

```bash
curl -k -X POST "${SERVER}/api/?action=delete_database&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "database=myapp_db"
```

---

## Email Examples

### Create Mailbox

```bash
curl -k -X POST "${SERVER}/api/?action=add_mailbox&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "username=user" \
    -d "password=MailPass123!" \
    -d "quota=1024"
```

### Delete Mailbox

```bash
curl -k -X POST "${SERVER}/api/?action=delete_mailbox&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "username=user"
```

### Create Forwarder

```bash
curl -k -X POST "${SERVER}/api/?action=add_mailforward&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "source_user=info" \
    -d "target_email=admin@example.com"
```

### List Mailboxes

```bash
curl -k -X GET "${SERVER}/api/?action=list_mailboxes&domain=example.com&apikey=${API_KEY}"
```

---

## SSL Examples

### Install Let's Encrypt Certificate

```bash
curl -k -X POST "${SERVER}/api/?action=install_letsencrypt&apikey=${API_KEY}" \
    -d "domain=example.com"
```

### Install Custom SSL

```bash
curl -k -X POST "${SERVER}/api/?action=install_ssl&apikey=${API_KEY}" \
    -d "domain=example.com" \
    -d "cert=$(cat /path/to/certificate.crt)" \
    -d "key=$(cat /path/to/private.key)" \
    -d "ca=$(cat /path/to/ca-bundle.crt)"
```

### List SSL Certificates

```bash
curl -k -X GET "${SERVER}/api/?action=list_ssl_certificates&apikey=${API_KEY}"
```

---

## System Examples

### Get Server Status

```bash
curl -k -X GET "${SERVER}/api/?action=server_status&apikey=${API_KEY}"
```

### List Services

```bash
curl -k -X GET "${SERVER}/api/?action=list_services&apikey=${API_KEY}"
```

### Restart Service

```bash
curl -k -X POST "${SERVER}/api/?action=restart_service&apikey=${API_KEY}" \
    -d "service=httpd"
```

### Backup User

```bash
curl -k -X POST "${SERVER}/api/?action=backup_user&apikey=${API_KEY}" \
    -d "username=user1"
```

### Restore User

```bash
curl -k -X POST "${SERVER}/api/?action=restore_user&apikey=${API_KEY}" \
    -d "username=user1" \
    -d "backup_file=/backup/user1/user1.tar.gz"
```

---

## PHP Examples

### Basic API Call

```php
<?php
$server = "https://your-server:2304";
$apiKey = "your_api_key";

// List users
$response = file_get_contents("${server}/api/?action=list_users&apikey=${apiKey}");
$data = json_decode($response, true);

if ($data['status'] === 'success') {
    print_r($data['users']);
}
```

### POST Request

```php
<?php
$server = "https://your-server:2304";
$apiKey = "your_api_key";

$data = [
    'username' => 'newuser',
    'password' => 'SecurePass123!',
    'domain' => 'example.com',
    'email' => 'admin@example.com',
    'package' => 'default',
];

$ch = curl_init("${server}/api/?action=add_user&apikey=${apiKey}");
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$response = curl_exec($ch);
curl_close($ch);

$result = json_decode($response, true);
echo $result['message'];
```

### Error Handling

```php
<?php
function cwpApiCall($action, $params = []) {
    $server = "https://your-server:2304";
    $apiKey = "your_api_key";

    $url = "${server}/api/?action=${action}&apikey=${apiKey}";

    $ch = curl_init($url);
    if (!empty($params)) {
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query($params));
    }
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode !== 200) {
        throw new Exception("API request failed with HTTP code: ${httpCode}");
    }

    $data = json_decode($response, true);
    if ($data['status'] === 'error') {
        throw new Exception("API error: " . $data['message']);
    }

    return $data;
}

// Usage
try {
    $result = cwpApiCall('list_users');
    print_r($result['users']);
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
```

---

## Python Examples

```python
import requests
import json

SERVER = "https://your-server:2304"
API_KEY = "your_api_key"

def cwp_api(action, params=None):
    url = f"{SERVER}/api/?action={action}&apikey={API_KEY}"
    if params:
        response = requests.post(url, data=params, verify=False)
    else:
        response = requests.get(url, verify=False)
    return response.json()

# List users
result = cwp_api("list_users")
print(result["users"])

# Create user
result = cwp_api("add_user", {
    "username": "newuser",
    "password": "SecurePass123!",
    "domain": "example.com",
    "email": "admin@example.com",
    "package": "default"
})
print(result["message"])
```

---

## Batch Operations Script

```bash
#!/bin/bash
# /scripts/batch_operations

SERVER="https://your-server:2304"
API_KEY="your_api_key"

# Create multiple users
while IFS=: read -r username password domain email; do
    echo "Creating user: ${username}"
    curl -k -X POST "${SERVER}/api/?action=add_user&apikey=${API_KEY}" \
        -d "username=${username}" \
        -d "password=${password}" \
        -d "domain=${domain}" \
        -d "email=${email}" \
        -d "package=default"
    echo ""
done < users.txt

# users.txt format:
# user1:Pass1:domain1.com:email1@example.com
# user2:Pass2:domain2.com:email2@example.com
```

---

## Troubleshooting API Calls

### Test API Connectivity

```bash
curl -k -X GET "${SERVER}/api/?action=test&apikey=${API_KEY}"
```

### Debug API Call

```bash
curl -k -v -X GET "${SERVER}/api/?action=list_users&apikey=${API_KEY}"
```

### Check API Key

```bash
# Verify key in CWP panel
# Admin Panel > CWP Settings > API Manager
```

### Common Issues

```bash
# SSL certificate error - use -k flag
curl -k ...

# Connection refused - check port 2304
ss -tlnp | grep 2304

# Firewall blocking - allow port in CSF
csf -a your_ip "API Access"
```
