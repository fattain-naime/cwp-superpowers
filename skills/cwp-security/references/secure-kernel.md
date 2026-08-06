# CWP Secure Kernel Reference

## Overview

CWP Secure Kernel provides Mandatory Access Control (MAC) security hardening for the server. It restricts processes and users to minimum privileges, reducing the impact of potential compromises.

---

## What is MAC Security?

Mandatory Access Control (MAC) differs from standard Discretionary Access Control (DAC):

| Feature        | DAC (Standard)           | MAC (Secure Kernel)         |
|----------------|--------------------------|------------------------------|
| Access control | Owner-controlled         | Policy-controlled            |
| Enforcement    | File permissions only    | Kernel-level enforcement     |
| Scope          | Per-user                 | Per-process, per-file        |
| Flexibility    | High (users can change)  | Low (admin-defined policy)   |
| Security       | Basic                    | Advanced isolation           |

---

## CWP Secure Kernel Features

### Process Isolation

Each user's processes run in isolated environments:
- Separate memory space
- Restricted file access
- Limited network capabilities
- Controlled system calls

### File System Protection

- Prevents users from reading other users' files
- Restricts access to system directories
- Controls binary execution
- Protects critical system files

### Network Restrictions

- Per-user network access control
- Port binding restrictions
- Outgoing connection limits
- Protocol filtering

### Resource Limits

- CPU usage per user
- Memory limits
- Process count limits
- Disk I/O throttling

---

## Installation

### Via CWP Admin Panel

Navigate to: **Security > Secure Kernel > Install**

### Prerequisites

```bash
# Ensure kernel supports MAC
cat /proc/config.gz | zcat | grep SECURITY

# Required kernel options:
# CONFIG_SECURITY=y
# CONFIG_SECURITY_SELINUX=y
```

### Installation Steps

```bash
# CWP handles installation automatically
# Manual steps if needed:

# Install SELinux utilities
yum install policycoreutils-python-utils setools-console

# Set SELinux to enforcing
sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config

# Reboot to activate
reboot
```

---

## Configuration

### SELinux Modes

```bash
# Check current mode
getenforce

# Set to enforcing (full MAC)
setenforce 1

# Set to permissive (log only)
setenforce 0

# Disable (requires reboot)
# Edit /etc/selinux/config: SELINUX=disabled
```

### CWP Secure Kernel Config

**Path:** `/usr/local/cwp/.conf/secure_kernel.conf`

```ini
# Enable secure kernel
enabled=yes

# Mode: enforcing | permissive
mode=enforcing

# User isolation
user_isolation=yes

# Process restrictions
process_restrictions=yes

# Network restrictions
network_restrictions=yes

# File system protection
filesystem_protection=yes
```

---

## SELinux Contexts

### View Contexts

```bash
# File contexts
ls -Z /home/user/public_html/
# -rw-r--r--. user user unconfined_u:object_r:httpd_sys_content_t:s0 index.html

# Process contexts
ps auxZ | grep httpd

# Port contexts
semanage port -l | grep http
```

### Common Context Types

| Context                        | Description                    |
|--------------------------------|--------------------------------|
| `httpd_sys_content_t`          | Web content files              |
| `httpd_sys_rw_content_t`       | Web writable content           |
| `httpd_sys_script_exec_t`      | CGI/PHP scripts                |
| `user_home_dir_t`              | User home directories          |
| `mysqld_db_t`                  | MySQL data files               |
| `postfix_*`                    | Postfix mail files             |
| `named_*`                      | BIND DNS files                 |

### Set File Contexts

```bash
# Set context permanently
semanage fcontext -a -t httpd_sys_content_t "/home/user/public_html(/.*)?"
restorecon -Rv /home/user/public_html/

# Set context temporarily (lost on relabel)
chcon -t httpd_sys_content_t /home/user/public_html/index.html

# Restore default contexts
restorecon -Rv /home/user/
```

---

## SELinux Booleans

### Common Booleans for Web Servers

```bash
# List all booleans
getsebool -a

# Allow httpd to connect to network
setsebool -P httpd_can_network_connect on

# Allow httpd to send mail
setsebool -P httpd_can_sendmail on

# Allow httpd to use NFS
setsebool -P httpd_use_nfs on

# Allow httpd to use CGI
setsebool -P httpd_enable_cgi on

# Allow httpd to read user home directories
setsebool -P httpd_enable_homedirs on

# Allow httpd to connect to database
setsebool -P httpd_can_network_connect_db on

# Allow FTP access
setsebool -P ftpd_full_access on

# Allow mail delivery
setsebool -P postfix_local_write_mail_spool on
```

### CWP-Specific Booleans

```bash
# Allow CWP to manage web content
setsebool -P httpd_can_network_connect on
setsebool -P httpd_can_network_connect_db on
setsebool -P httpd_read_user_content on
setsebool -P httpd_enable_cgi on

# Allow PHP-FPM
setsebool -P httpd_execmem on

# Allow mail server
setsebool -P postfix_local_write_mail_spool on
setsebool -P postfix_postfix_local_write_mail_spool on
```

---

## SELinux Policy Modules

### Create Custom Module

```bash
# Generate policy from audit log
ausearch -m avc -ts recent | audit2allow -M my_policy

# Install module
semodule -i my_policy.pp

# View module
semodule -l | grep my_policy
```

### Common Custom Policies

#### Allow PHP to write uploads
```bash
ausearch -c 'php-fpm' --raw | audit2allow -M php_upload
semodule -i php_upload.pp
```

#### Allow custom application
```bash
ausearch -c 'myapp' --raw | audit2allow -M myapp_policy
semodule -i myapp_policy.pp
```

---

## Troubleshooting SELinux

### Check for Denials

```bash
# View recent denials
ausearch -m avc -ts recent

# View all denials
ausearch -m avc

# Check audit log
tail -100 /var/log/audit/audit.log | grep avc

# Use sealert for human-readable analysis
sealert -a /var/log/audit/audit.log
```

### Common Denial Patterns

```bash
# httpd can't read file
# Solution:
semanage fcontext -a -t httpd_sys_content_t "/path/to/file"
restorecon -v /path/to/file

# httpd can't write to directory
# Solution:
semanage fcontext -a -t httpd_sys_rw_content_t "/path/to/dir(/.*)?"
restorecon -Rv /path/to/dir

# httpd can't connect to network
# Solution:
setsebool -P httpd_can_network_connect on

# httpd can't connect to database
# Solution:
setsebool -P httpd_can_network_connect_db on

# MySQL can't write to data directory
# Solution:
restorecon -Rv /var/lib/mysql/
```

### Generate Policy from Denials

```bash
# Generate and install policy automatically
ausearch -m avc -ts recent | audit2allow -M fix_policy
semodule -i fix_policy.pp

# Review before installing
ausearch -m avc -ts recent | audit2allow
```

### Temporarily Disable for Testing

```bash
# Set to permissive (log only, don't enforce)
setenforce 0

# Test application
# If it works, the issue is SELinux policy

# Re-enable
setenforce 1

# Fix the specific denial
ausearch -m avc -ts recent | audit2allow -M fix
semodule -i fix.pp
```

---

## CWP Secure Kernel Commands

```bash
# Check status
/scripts/secure_kernel status

# Enable
/scripts/secure_kernel enable

# Disable
/scripts/secure_kernel disable

# Reload policies
/scripts/secure_kernel reload

# View security events
/scripts/secure_kernel logs
```

---

## Security Hardening Checklist

### Kernel Level

- [ ] SELinux in enforcing mode
- [ ] Kernel parameters hardened (`/etc/sysctl.conf`)
- [ ] Unused kernel modules disabled
- [ ] Core dumps disabled

### File System

- [ ] Proper file contexts set
- [ ] User home directories isolated
- [ ] Temporary directories restricted
- [ ] Critical files protected

### Network

- [ ] Unnecessary ports closed
- [ ] Network parameters hardened
- [ ] IPv6 disabled if not needed
- [ ] ICMP restricted

### Services

- [ ] Unused services disabled
- [ ] Service accounts have minimal privileges
- [ ] Configuration files protected
- [ ] Logs are secured

---

## Performance Considerations

### SELinux Overhead

SELinux adds minimal overhead:
- File access: ~1-2% slower
- Process creation: ~1-3% slower
- Network: negligible impact

### Optimizing Performance

```bash
# Disable audit of high-frequency events
semanage dontaudit -a -t httpd_t -c tcp_socket

# Use targeted policy (default)
# In /etc/selinux/config:
# SELINUXTYPE=targeted
```

---

## Common Issues

### Application not working after enabling SELinux

```bash
# Check denials
ausearch -m avc -ts recent

# Generate and apply fix
ausearch -m avc -ts recent | audit2allow -M app_fix
semodule -i app_fix.pp
```

### Cannot access web files

```bash
# Fix contexts
restorecon -Rv /home/user/public_html/

# Or set httpd to read user content
setsebool -P httpd_read_user_content on
```

### Database connection refused

```bash
# Allow httpd to connect to database
setsebool -P httpd_can_network_connect_db on
```

### FTP not working

```bash
# Allow FTP full access
setsebool -P ftpd_full_access on

# Or set specific contexts
semanage fcontext -a -t public_content_rw_t "/home/user/ftp(/.*)?"
restorecon -Rv /home/user/ftp/
```
