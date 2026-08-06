---
name: cwp-security
description: This skill should be used when the user asks to "configure CSF firewall", "set up ModSecurity", "install SSL certificate", "enable AutoSSL", "harden server security", "configure SSH security", "set up brute force protection", "block IP address", "whitelist IP", "install OWASP CRS", "check for hacks", "run security audit", "configure firewall rules", or needs to manage any security component on a CWP server.
version: 1.0.0
---

# CWP Security Management

If the user provides specific details via "$ARGUMENTS", focus the response on that security topic. For example: `/cwp-pro-centos:cwp-security block IP 1.2.3.4` will focus on blocking that specific IP.

Manage CSF Firewall, ModSecurity, SSL/TLS certificates, SSH hardening, and server security on CWP servers. Handle firewall rules, WAF configuration, certificate management, and security auditing.

## Security Components

| Component | Purpose | Status |
|---|---|---|
| CSF Firewall | Network firewall | Discontinued -- use Aetherinox fork |
| ModSecurity | Web application firewall | Active |
| Comodo WAF | ModSecurity ruleset | Abandoned -- use OWASP CRS |
| AutoSSL | Automatic SSL certificates | Active (CWP Pro) |
| Snuffleupagus | PHP security module | Active |
| CWP Secure Kernel | MAC-based kernel protection | Active (paid feature) |

## CSF Firewall

### Important Notice

The original CSF Firewall was discontinued in August 2025. Use the Aetherinox fork (v15.08+) for continued support and updates.

### Installation

```bash
# Install iptables on AlmaLinux (prerequisite)
yum install iptables
```

### Core Commands

```bash
# Enable/disable
csf -e          # Enable firewall
csf -x          # Disable firewall
csf -r          # Restart firewall

# IP management
csf -g IP       # Check why IP is blocked
csf -d IP       # Block IP permanently
csf -dr IP      # Unblock IP
csf -a IP       # Whitelist IP
csf -ta IP 86400 # Temporary whitelist (24h in seconds)

# Status
csf -t          # Show temporary blocks
csf -s          # Start firewall
```

### Configuration File

`/etc/csf/csf.conf`

### Required Ports

```
TCP_IN: 20,21,22,25,53,80,110,143,443,465,587,993,995,2030,2031,30000:50000,6666
TCP_OUT: 20,21,22,25,53,80,110,113,443,587,993,995
UDP_IN: 53
UDP_OUT: 53,113,123
```

Passive FTP ports (35000-50000) must be open for Pure-FTPd.

## ModSecurity

### Configuration

**Config file:** `/usr/local/apache/conf.d/mod_security.conf`

### OWASP CRS Setup

The Comodo WAF ruleset has been abandoned. Switch to OWASP CRS v4.27.0+:

1. Update ModSecurity to version 2.9.13
2. Install OWASP CRS v4.27.0
3. Lock the CRS directory: `chattr -R +i /path/to/crs/`
4. In CWP, select "OWASP old" (not "OWASP Latest") for compatibility

### ModSecurity Management

```bash
# Check ModSecurity status
apachectl -M | grep security

# View ModSecurity log
tail -f /usr/local/apache/logs/modsec_audit.log

# Restart Apache after changes
systemctl restart httpd
```

## SSL/TLS Certificates

### AutoSSL (CWP Pro)

AutoSSL automatically provisions Let's Encrypt certificates for all domains.

### ACME Client

Script names vary by CWP version:

```bash
# Install/reinstall ACME client (same on most versions)
/scripts/install_acme

# Generate hostname SSL (script name varies)
if [ -f /scripts/generate_hostname_ssl ]; then
    sh /scripts/generate_hostname_ssl
elif [ -f /scripts/generate_ssl ]; then
    sh /scripts/generate_ssl
fi

# Renew Let's Encrypt certificates (script name varies)
if [ -f /scripts/renew_lets_encrypt ]; then
    sh /scripts/renew_lets_encrypt
else
    # ACME renewal is typically automatic or via certbot
    certbot renew --quiet 2>/dev/null || acme.sh --renew-all
fi
```

### Manual SSL via Let's Encrypt

Store certificates in `/etc/letsencrypt/`.

### SSL Grade Improvement

Edit `/usr/local/apache/conf.d/ssl.conf`:

```apache
SSLCipherSuite ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:ECDH+3DES:DH+3DES:RSA+AESGCM:RSA+AES:RSA+3DES:!aNULL:!MD5:!DSS
SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLHonorCipherOrder on
```

```bash
# Restart Apache after SSL changes
systemctl restart httpd

# Fix AutoSSL temp path issues
/scripts/autossl_fix_tmp_path
```

## SSH Security

### Configuration File

`/etc/ssh/sshd_config`

### Hardening Steps

```bash
# Change SSH port
sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Disable root login (after creating sudo user)
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication (after setting up keys)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

# Restart SSH
systemctl restart sshd
```

**Important:** Always update CSF firewall with the new SSH port before restarting SSH.

## PHP Security

For complete PHP security configuration including disabling dangerous functions, open_basedir setup, and PHP Defender (Snuffleupagus), see the **cwp-php** skill (`references/php-security.md`).

Key security measures:
- Disable dangerous functions: `exec, system, popen, proc_open, shell_exec, passthru, show_source`
- Enable open_basedir per user to prevent directory traversal
- Configure PHP Defender (Snuffleupagus) rules at `/usr/local/cwp/.conf/phpdefender/`

## Brute Force Protection

```bash
# Enable CWP brute force protection
/scripts/cwp_bruteforce_protection
```

## Security Auditing

```bash
# CWP security audit
/scripts/cwp_security_audit

# Check for server compromises
/scripts/security_is_my_server_hacked

# Update ClamAV virus definitions
/scripts/freshclam

# Install Malware Detect
/scripts/install_maldet
```

## CWP Secure Kernel

Custom kernel with Mandatory Access Control (MAC):

- Default-deny policy
- Protects against symlink attacks and malware
- Supported: CentOS 7, AlmaLinux 8/9, Rocky Linux 8/9
- NOT supported: OpenVZ, CloudLinux, Docker
- Requires active CWP support service

## Security Best Practices Checklist

1. Enable AutoSSL for all domains
2. Activate CSF Firewall with proper rules
3. Enable ModSecurity with OWASP CRS
4. Change SSH port and update CSF
5. Disable dangerous PHP functions
6. Enable PHP open_basedir per user
7. Hide system processes
8. Enforce strong passwords
9. Implement IP whitelisting for admin access
10. Perform regular updates with backups first
11. Enable brute force protection
12. Monitor logs regularly

## Troubleshooting

| Issue | Solution |
|---|---|
| CSF blocking legitimate traffic | Check `csf -g IP` and whitelist if needed |
| ModSecurity blocking requests | Check audit log, add rule exceptions |
| SSL certificate not renewing | Run `/scripts/install_acme` and `/scripts/generate_hostname_ssl` |
| SSH locked out after port change | Use console access, verify CSF port |
| AutoSSL temp path errors | Run `/scripts/autossl_fix_tmp_path` |
| Firewall not starting | Check iptables: `yum install iptables` |

## Additional Resources

- `references/csf-firewall.md` -- Complete CSF configuration guide
- `references/mod-security.md` -- ModSecurity and OWASP CRS setup
- `references/ssl-tls.md` -- SSL/TLS certificate management and ACME setup
- `references/secure-kernel.md` -- CWP Secure Kernel and server hardening
