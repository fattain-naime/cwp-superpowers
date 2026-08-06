# ModSecurity Reference

## Overview

ModSecurity is a Web Application Firewall (WAF) that works with Apache and Nginx to detect and block malicious HTTP requests.

---

## Installation

### Via CWP Admin Panel

Navigate to: **Security > ModSecurity > Install**

### Manual Installation

```bash
# Install ModSecurity
yum install mod_security mod_security_crs
```

ModSecurity is installed and managed via the **CWP Admin panel** (Security > ModSecurity > Install). There is no `/scripts/modsec_install` CLI script.

For Nginx, ModSecurity v3 must be compiled from source with the ModSecurity module (see ModSecurity with Nginx section below).

---

## Directory Structure

| Item               | Path                                                    |
|--------------------|---------------------------------------------------------|
| Main config        | `/etc/httpd/conf.d/mod_security.conf`                   |
| Rules directory    | `/etc/httpd/modsecurity.d/`                             |
| OWASP CRS rules    | `/etc/httpd/modsecurity.d/owasp-modsecurity-crs/`       |
| Custom rules       | `/etc/httpd/modsecurity.d/custom_rules/`                |
| Audit log          | `/var/log/httpd/modsec_audit.log`                       |
| Debug log          | `/var/log/httpd/modsec_debug.log`                       |

---

## Main Configuration

**Path:** `/etc/httpd/conf.d/mod_security.conf`

```apache
# Enable ModSecurity
SecRuleEngine On

# Request body handling
SecRequestBodyAccess On
SecRequestBodyLimit 13107200
SecRequestBodyNoFilesLimit 131072
SecRequestBodyLimitAction Reject

# Response body handling
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml
SecResponseBodyLimit 524288
SecResponseBodyLimitAction ProcessPartial

# Temp files
SecTmpDir /var/lib/mod_security
SecDataDir /var/lib/mod_security
SecUploadDir /var/lib/mod_security

# Audit logging
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus "^(?:5|4(?!04))"
SecAuditLogParts ABIJDEFHZ
SecAuditLogType Serial
SecAuditLog /var/log/httpd/modsec_audit.log

# Debug logging (disable in production)
SecDebugLog /var/log/httpd/modsec_debug.log
SecDebugLogLevel 0

# Misc
SecArgumentSeparator &
SecCookieFormat 0
SecUnicodeMapFile unicode.mapping 20127
SecStatusEngine On
```

---

## OWASP Core Rule Set (CRS)

### Installation

```bash
# CWP installs CRS automatically
# Or manually:
cd /etc/httpd/modsecurity.d/
git clone https://github.com/coreruleset/coreruleset owasp-modsecurity-crs
cp owasp-modsecurity-crs/crs-setup.conf.example owasp-modsecurity-crs/crs-setup.conf
```

### CRS Configuration

**Path:** `/etc/httpd/modsecurity.d/owasp-modsecurity-crs/crs-setup.conf`

```ini
# Paranoia Level (1-4, higher = more strict)
SecAction "id:900000,phase:1,nolog,pass,t:none,setvar:tx.blocking_paranoia_level=1"

# Detection Paranoia Level
SecAction "id:900001,phase:1,nolog,pass,t:none,setvar:tx.detection_paranoia_level=1"

# Anomaly scoring thresholds
SecAction "id:900110,phase:1,pass,t:none,nolog,setvar:tx.inbound_anomaly_score_threshold=5,setvar:tx.outbound_anomaly_score_threshold=4"

# Allowed HTTP methods
SecAction "id:900200,phase:1,nolog,pass,t:none,setvar:'tx.allowed_methods=GET HEAD POST OPTIONS PUT PATCH DELETE'"

# Allowed request content types
SecAction "id:900220,phase:1,nolog,pass,t:none,setvar:'tx.allowed_request_content_type=|application/x-www-form-urlencoded| |multipart/form-data| |multipart/related| |text/xml| |application/xml| |application/soap+xml| |application/json| |application/cloudevents+json| |application/cloudevents-batch+json|'"

# Allowed HTTP versions
SecAction "id:900230,phase:1,nolog,pass,t:none,setvar:'tx.allowed_http_versions=HTTP/1.0 HTTP/1.1 HTTP/2 HTTP/2.0'"

# Enable sampling (for high traffic)
# SecAction "id:900400,phase:1,pass,t:none,nolog,setvar:tx.sampling_percentage=100"
```

### CRS Rule Files

```
/etc/httpd/modsecurity.d/owasp-modsecurity-crs/rules/
  REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf
  REQUEST-901-INITIALIZATION.conf
  REQUEST-903.9001-DRUPAL-EXCLUSION-RULES.conf
  REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf
  REQUEST-905-COMMON-EXCEPTIONS.conf
  REQUEST-910-IP-REPUTATION.conf
  REQUEST-911-METHOD-ENFORCEMENT.conf
  REQUEST-912-DOS-PROTECTION.conf
  REQUEST-913-SCANNER-DETECTION.conf
  REQUEST-920-PROTOCOL-ENFORCEMENT.conf
  REQUEST-921-PROTOCOL-ATTACK.conf
  REQUEST-930-APPLICATION-ATTACK-LFI.conf
  REQUEST-931-APPLICATION-ATTACK-RFI.conf
  REQUEST-932-APPLICATION-ATTACK-RCE.conf
  REQUEST-933-APPLICATION-ATTACK-PHP.conf
  REQUEST-934-APPLICATION-ATTACK-NODEJS.conf
  REQUEST-941-APPLICATION-ATTACK-XSS.conf
  REQUEST-942-APPLICATION-ATTACK-SQLI.conf
  REQUEST-943-APPLICATION-ATTACK-SESSION-FIXATION.conf
  REQUEST-944-APPLICATION-ATTACK-JAVA.conf
  REQUEST-949-BLOCKING-EVALUATION.conf
  RESPONSE-950-DATA-LEAKAGES.conf
  RESPONSE-951-DATA-LEAKAGES-SQL.conf
  RESPONSE-952-DATA-LEAKAGES-JAVA.conf
  RESPONSE-953-DATA-LEAKAGES-PHP.conf
  RESPONSE-954-DATA-LEAKAGES-IIS.conf
  RESPONSE-959-BLOCKING-EVALUATION.conf
  RESPONSE-980-CORRELATION.conf
```

---

## Custom Rules

### Create Custom Rule File

**Path:** `/etc/httpd/modsecurity.d/custom_rules/custom.conf`

```apache
# Block specific user agent
SecRule REQUEST_HEADERS:User-Agent "malicious-bot" \
    "id:100001,phase:1,deny,status:403,\
    msg:'Blocked malicious user agent',\
    severity:CRITICAL"

# Block specific IP range
SecRule REMOTE_ADDR "@ipMatch 192.168.100.0/24" \
    "id:100002,phase:1,deny,status:403,\
    msg:'Blocked suspicious IP range'"

# Block requests to specific URI
SecRule REQUEST_URI "/admin/config\.php" \
    "id:100003,phase:1,deny,status:403,\
    msg:'Blocked access to admin config'"

# Rate limiting (requires mod_security v3+)
SecRule REQUEST_URI "@streq /login.php" \
    "id:100004,phase:1,pass,\
    setvar:'ip.login_counter=+1',\
    expirevar:'ip.login_counter=60'"
SecRule IP:LOGIN_COUNTER "@gt 5" \
    "id:100005,phase:1,deny,status:429,\
    msg:'Login rate limit exceeded'"
```

---

## Exclusion Rules

### Exclude Specific URL

```apache
# Exclude a URL from all rules
SecRule REQUEST_URI "^/api/webhook" \
    "id:200001,phase:1,pass,nolog,\
    ctl:ruleRemoveById=1-999999"

# Exclude specific rule for a URL
SecRule REQUEST_URI "^/admin/upload\.php" \
    "id:200002,phase:1,pass,nolog,\
    ctl:ruleRemoveById=920170"
```

### Exclude Specific Parameter

```apache
# Exclude a parameter from SQL injection rules
SecRule ARGS:content "@unconditionalMatch" \
    "id:200003,phase:1,pass,nolog,\
    ctl:ruleRemoveTargetById=942100;ARGS:content"
```

### WordPress Exclusions

CWP includes WordPress-specific exclusions:

```apache
# Already included in CRS:
# REQUEST-903.9002-WORDPRESS-EXCLUSION-RULES.conf

# Additional custom WordPress exclusions
SecRule REQUEST_URI "^/wp-admin/admin-ajax\.php" \
    "id:200010,phase:1,pass,nolog,\
    ctl:ruleRemoveById=941100,941160,942100"

SecRule REQUEST_URI "^/xmlrpc\.php" \
    "id:200011,phase:1,deny,status:403,\
    msg:'Blocked xmlrpc.php access'"
```

---

## Paranoia Levels

| Level | Description                                        |
|-------|----------------------------------------------------|
| 1     | Basic security, few false positives (default)      |
| 2     | More strict, may cause some false positives        |
| 3     | High security, significant false positives         |
| 4     | Maximum security, many false positives             |

### Adjust Paranoia Level

In `crs-setup.conf`:
```apache
SecAction "id:900000,phase:1,nolog,pass,t:none,setvar:tx.blocking_paranoia_level=2"
```

---

## Audit Log Analysis

### Log Format

```
--a]--
[22/Jan/2024:10:15:30 +0000] 192.168.1.100 192.168.1.10 80
--a]--
GET /index.php?id=1' OR 1=1-- HTTP/1.1
Host: example.com
User-Agent: Mozilla/5.0
--a]--
Message: Warning. detected SQL injection. [id "942100"]
--a]--
```

### Common Audit Log Commands

```bash
# View recent blocks
tail -100 /var/log/httpd/modsec_audit.log | grep -A5 "Message:"

# Count blocks by rule ID
grep -o 'id "[0-9]*"' /var/log/httpd/modsec_audit.log | sort | uniq -c | sort -rn

# Count blocks by IP
grep -o '[0-9]*\.[0-9]*\.[0-9]*\.[0-9]*' /var/log/httpd/modsec_audit.log | sort | uniq -c | sort -rn | head -20

# View blocks for specific rule
grep 'id "942100"' /var/log/httpd/modsec_audit.log
```

---

## ModSecurity with Nginx

Nginx requires the ModSecurity v3 module:

```bash
# Install libmodsecurity
cd /usr/local/src
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity.git
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make && make install

# Install Nginx ModSecurity connector
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git

# Recompile Nginx with ModSecurity module
cd /usr/local/src/nginx-{version}
./configure --add-dynamic-module=/path/to/ModSecurity-nginx
make modules
cp objs/ngx_http_modsecurity_module.so /usr/local/nginx/modules/
```

Nginx configuration:
```nginx
load_module modules/ngx_http_modsecurity_module.so;

server {
    modsecurity on;
    modsecurity_rules_file /etc/nginx/modsecurity/modsecurity.conf;
    # ...
}
```

---

## Troubleshooting

### Too many false positives
```bash
# Check audit log for blocked requests
tail -100 /var/log/httpd/modsec_audit.log

# Identify rule IDs causing issues
grep -o 'id "[0-9]*"' /var/log/httpd/modsec_audit.log | sort | uniq -c | sort -rn

# Add exclusions for specific rules
# In custom_rules/custom.conf:
# ctl:ruleRemoveById=RULE_ID
```

### ModSecurity blocking legitimate traffic
```bash
# Temporarily disable
# In mod_security.conf: SecRuleEngine Off

# Or switch to detection only
# SecRuleEngine DetectionOnly

# Restart Apache
systemctl restart httpd
```

### Performance impact
```bash
# Disable response body inspection
# SecResponseBodyAccess Off

# Reduce audit log verbosity
# SecAuditEngine RelevantOnly
# SecAuditLogRelevantStatus "^(?:5|4(?!04))"
```

### ModSecurity not loading
```bash
# Check Apache error log
tail -50 /var/log/httpd/error_log

# Verify module is loaded
httpd -M | grep security

# Check configuration syntax
httpd -t
```
