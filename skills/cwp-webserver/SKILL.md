---
name: cwp-webserver
description: This skill should be used when the user asks to "configure Apache", "configure Nginx", "set up Varnish", "switch web server stack", "edit vhost template", "rebuild vhosts", "fix web server errors", "configure SSL for web server", "set up reverse proxy", "enable Brotli compression", "fix 502 bad gateway", "fix redirect loop", "manage web server modules", or needs to manage any CWP web server stack component.
version: 1.0.0
---

# CWP Web Server Management

Manage Apache, Nginx, Varnish, and LiteSpeed web server configurations within CWP. Handle vhost templates, module management, reverse proxy setups, and common web server issues.

## Overview

Choose from multiple web server stacks. The selected stack determines how requests are processed and which configuration files to edit.

| Stack | Description | Use Case |
|---|---|---|
| Apache + PHP-FPM | Standard configuration | General hosting |
| Nginx + PHP-FPM | High-performance | Static-heavy sites |
| Nginx -> Varnish -> Apache | Maximum performance | High-traffic sites |
| Apache + suPHP | Legacy compatibility | Legacy PHP apps |
| LiteSpeed Enterprise | Commercial option | Enterprise hosting |

## Service Detection

Detect which web servers are installed:

```bash
# Apache
systemctl is-active httpd 2>/dev/null && echo "Apache: active" || echo "Apache: not running"

# Nginx
systemctl is-active nginx 2>/dev/null && echo "Nginx: active" || echo "Nginx: not running"

# Varnish
systemctl is-active varnish 2>/dev/null && echo "Varnish: active" || echo "Varnish: not running"

# LiteSpeed (optional)
systemctl is-active lsws 2>/dev/null && echo "LiteSpeed: active" || echo "LiteSpeed: not installed"
```

## Port Mapping

| Port | Service |
|---|---|
| 80 | HTTP (Apache or Nginx) |
| 443 | HTTPS (Apache or Nginx) |
| 82 | Varnish cache |
| 8181 | Apache behind Nginx proxy |
| 8080 | Tomcat (if enabled) |

## Vhost Templates

**Location:** `/usr/local/cwpsrv/htdocs/resources/conf/web_servers/`

| Directory | Contents |
|---|---|
| `vhosts/httpd/` | Apache templates (main, php-fpm, proxy) |
| `vhosts/nginx/` | Nginx templates (main, php-fpm) |
| `vhosts/varnish/` | Varnish templates (main only) |

**Critical:** Never edit templates directly -- they are overwritten on CWP updates. Create custom copies with different names.

### Template Variables

Templates support these replacement variables:

- `%domain%` -- Domain name
- `%ip%` -- Server IP address
- `%user%` -- Username
- `%docroot%` -- Document root path

### Rebuilding Vhosts

```bash
# Rebuild all vhosts
/scripts/cwp_api webservers rebuild_all

# Rebuild for specific user
/scripts/cwp_api webservers rebuild_user USERNAME

# Rebuild user configs
/scripts/cwpsrv_rebuild_user_conf
```

## Apache Configuration

### Main Config Files

| File | Purpose |
|---|---|
| `/usr/local/apache/conf/httpd.conf` | Main Apache configuration |
| `/usr/local/apache/conf.d/` | Module and site configs |
| `/usr/local/apache/conf.d/ssl.conf` | SSL configuration |
| `/usr/local/apache/logs/` | Apache error/access logs |
| `/usr/local/apache/domlogs/` | Per-domain access logs |

### Apache Modules

| Module | Purpose |
|---|---|
| mod_xsendfile | X-SENDFILE header processing |
| mod_cloudflare | Real IP from Cloudflare |
| mod_brotli | Brotli compression |
| mod_pagespeed | Google page optimization |
| mod_limits | DDoS protection |
| mod_suexec | CGI scripts run as file owner |
| mod_cgid | CGI script execution |
| mod_userdir | Per-user web directories |

### Common Apache Operations

```bash
# Restart Apache
systemctl restart httpd

# Test configuration
apachectl configtest

# Check loaded modules
apachectl -M

# View error log
tail -f /usr/local/apache/logs/error_log

# View domain log
tail -f /usr/local/apache/domlogs/DOMAIN.log
```

### SSL Configuration

For SSL certificate management, AutoSSL, and TLS hardening, see the **cwp-security** skill (`references/ssl-tls.md`).

Improve SSL grade by editing `/usr/local/apache/conf.d/ssl.conf`:

```apache
SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
SSLHonorCipherOrder on
```

## Nginx Configuration

### Main Config Files

| File | Purpose |
|---|---|
| `/etc/nginx/nginx.conf` | Main Nginx configuration |
| `/etc/nginx/conf.d/` | Additional configs |
| `/etc/nginx/modules/` | Dynamic modules |

### Common Nginx Operations

```bash
# Restart Nginx
systemctl restart nginx

# Test configuration
nginx -t

# Reload without downtime
nginx -s reload

# Check version and modules
nginx -V
```

### Nginx as Reverse Proxy

When using Nginx -> Apache stack, Nginx handles static files and proxies dynamic requests to Apache on port 8181.

### Brotli Compression (Nginx)

For detailed Brotli compression setup and configuration, see the **cwp-performance** skill (`references/compression.md`).

```bash
cd /etc/nginx/modules
wget http://dl1.centos-webpanel.com/files/nginx/modules/nginx-brotli-modules.zip
unzip nginx-brotli-modules.zip
```

## Varnish Cache

### Configuration

| File | Purpose |
|---|---|
| `/etc/varnish/varnish.params` | Varnish parameters |
| `/etc/varnish/default.vcl` | VCL configuration |

### Common Varnish Operations

```bash
# Clear Varnish cache
/scripts/varnish_clear_cache

# Restart Varnish
systemctl restart varnish

# Check Varnish stats
varnishstat

# Check VCL syntax
varnishd -C -f /etc/varnish/default.vcl
```

### Varnish Port Configuration

Varnish port varies by CWP version (80 or 82). Detect the actual port:

```bash
# Detect Varnish listening port
VARNISH_PORT=$(ss -tlnp | grep varnish | grep -oP ':\K\d+' | head -1)
echo "Varnish port: ${VARNISH_PORT:-unknown}"

# Or check configuration
grep VARNISH_LISTEN_PORT /etc/varnish/varnish.params 2>/dev/null || \
grep listen /etc/varnish/varnish.params 2>/dev/null
```

Common Varnish ports:
- Port 82 -- Most common in newer CWP versions
- Port 80 -- Some older configurations

Configure in `/etc/varnish/varnish.params`:

```
VARNISH_LISTEN_PORT=82
```

### Varnish Backend Configuration

Backend port also varies. Check actual configuration:

```bash
# Detect Varnish backend port
grep -E '\.port\s*=' /etc/varnish/default.vcl 2>/dev/null
```

Common backend ports:
- 8181 -- Apache behind Nginx proxy (newer CWP)
- 8080 -- Apache behind Nginx proxy (older CWP)

## Brotli Compression (Apache)

For detailed Apache Brotli setup, see the **cwp-performance** skill (`references/compression.md`).

```bash
yum install pcre-devel cmake -y
cd /usr/local/src
git clone https://github.com/google/brotli.git
cd brotli && git checkout v1.0
./configure-cmake && make && make install
```

## Redirect and Proxy Headers

### ERR_TOO_MANY_REDIRECTS Fix

When using Nginx -> Varnish -> Apache, add to `.htaccess`:

```apache
SetEnvIf X-Forwarded-Proto "https" HTTPS=on
```

### Cloudflare Real IP

Ensure mod_cloudflare is loaded to see real visitor IPs instead of Cloudflare IPs.

## Troubleshooting

| Issue | Solution |
|---|---|
| ERR_TOO_MANY_REDIRECTS | Use `X-Forwarded-Proto` header in .htaccess |
| 502 Bad Gateway | Restart PHP-FPM, increase process limit |
| 503 Service Unavailable | Check port redirection, PHP-FPM socket |
| 504 Gateway Timeout | Restart Apache/PHP-FPM, increase limits |
| Apache proxy mutex | `ipcs -s \| awk -v user=nobody '$3==user {system("ipcrm -s "$2)}'` |
| Default page for all domains | Rebuild vHosts, check shared IP setting |
| Varnish fails on AlmaLinux 9 | Manual Varnish installation required |

### Quick Diagnostic Commands

```bash
# Check all web services
systemctl status httpd nginx varnish

# Check listening ports
ss -tlnp | grep -E ':(80|443|82|8181)\s'

# Check for configuration errors
apachectl configtest && nginx -t

# Recent error logs
tail -20 /usr/local/apache/logs/error_log
tail -20 /var/log/nginx/error.log
```

## Additional Resources

- `references/apache.md` -- Apache configuration and module details
- `references/nginx.md` -- Nginx configuration and reverse proxy setup
- `references/varnish.md` -- Varnish cache configuration and VCL
- `references/litespeed.md` -- LiteSpeed Enterprise setup
