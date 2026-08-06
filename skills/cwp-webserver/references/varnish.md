# Varnish Configuration Reference

## Overview

CWP supports Varnish as a caching HTTP reverse proxy in front of Nginx+Apache.
Traffic flow: **Client -> Varnish (port 82) -> Nginx (port 8181) -> Apache (backend)**

> **Note:** Port assignments vary by CWP version. Some older configurations use Varnish on port 80 and Nginx backend on port 8080. Detect the actual ports on your server:
> ```bash
> # Detect Varnish listen port
> VARNISH_PORT=$(ss -tlnp | grep varnish | grep -oP ':\K\d+' | head -1)
> echo "Varnish port: $VARNISH_PORT"
>
> # Detect backend port in VCL
> grep -E '\.port\s*=' /etc/varnish/default.vcl
> ```

---

## Varnish Installation in CWP

CWP manages Varnish installation. Enable via:
**Admin Panel > WebServer Settings > Varnish Cache**

```
Binary:    /usr/sbin/varnishd
Config:    /etc/varnish/default.vcl
Service:   systemctl {start|stop|restart} varnish
```

---

## default.vcl

**Path:** `/etc/varnish/default.vcl`

### Basic VCL for Apache Backend

> **Note:** The backend port varies by CWP version. Current CWP defaults to port 8181; older configurations may use 8080. Verify with `grep -E '\.port\s*=' /etc/varnish/default.vcl`.

```vcl
vcl 4.1;

backend default {
    .host = "127.0.0.1";
    .port = "8181";
    .connect_timeout = 60s;
    .first_byte_timeout = 60s;
    .between_bytes_timeout = 60s;
    .max_connections = 300;
}

sub vcl_recv {
    # Remove cookies for static files
    if (req.url ~ "\.(css|js|jpg|jpeg|gif|png|ico|gz|tgz|bz2|tbz|zip|mp3|mp4|ogg|swf|flv|pdf|svg|woff|woff2|ttf|eot)$") {
        unset req.http.Cookie;
        return (hash);
    }

    # Remove cookies for HTML pages (cache them)
    if (req.url ~ "\.(html|htm)$") {
        unset req.http.Cookie;
        return (hash);
    }

    # Pass POST requests directly
    if (req.method == "POST") {
        return (pass);
    }

    # Pass requests with cookies (logged-in users)
    if (req.http.Cookie ~ "wordpress_logged_in|PHPSESSID|session_id") {
        return (pass);
    }

    # Remove Google Analytics cookies
    set req.http.Cookie = regsuball(req.http.Cookie, "__utm.=[^;]+(; )?", "");
    set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");

    # Remove empty cookie header
    if (req.http.Cookie == "") {
        unset req.http.Cookie;
    }

    return (hash);
}

sub vcl_backend_response {
    # Cache static files for 30 days
    if (bereq.url ~ "\.(css|js|jpg|jpeg|gif|png|ico|gz|tgz|bz2|tbz|zip|mp3|mp4|ogg|swf|flv|pdf|svg|woff|woff2|ttf|eot)$") {
        unset beresp.http.Set-Cookie;
        set beresp.ttl = 30d;
        set beresp.beresp.do_stream = true;
    }

    # Don't cache error pages for long
    if (beresp.status >= 400) {
        set beresp.ttl = 5s;
    }

    # Don't cache pages with Set-Cookie
    if (beresp.http.Set-Cookie) {
        set beresp.uncacheable = true;
        set beresp.ttl = 120s;
        return (deliver);
    }

    # Cache HTML for 10 minutes
    if (beresp.http.Content-Type ~ "text/html") {
        set beresp.ttl = 10m;
    }

    # Grace period
    set beresp.grace = 1h;
}

sub vcl_deliver {
    # Add cache hit/miss header
    if (obj.hits > 0) {
        set resp.http.X-Cache = "HIT";
        set resp.http.X-Cache-Hits = obj.hits;
    } else {
        set resp.http.X-Cache = "MISS";
    }

    # Remove server identification
    unset resp.http.X-Powered-By;
    unset resp.http.Server;
}

sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }
    return (lookup);
}

sub vcl_pipe {
    set req.http.Connection = "close";
    return (pipe);
}
```

---

## Cache Purge Methods

### Manual Purge (CLI)

```bash
# Purge a single URL
varnishadm "ban req.url == /path/to/page"

# Purge everything for a domain
varnishadm "ban req.http.host == domain.com"

# Purge all cached content
varnishadm "ban req.url ~ ."

# Purge by regex
varnishadm "ban req.url ~ \.(jpg|png|gif)$"
```

### Purge via CWP Panel

Navigate to: **WebServer Settings > Varnish Cache > Purge Cache**

### Purge Script

```bash
#!/bin/bash
# /scripts/purge_varnish
varnishadm "ban req.url ~ ."
echo "Varnish cache purged."
```

### Purge on Deploy (via hook)

```bash
# In a post-deploy hook
varnishadm "ban req.http.host == ${DOMAIN} && req.url ~ \.(css|js)$"
```

---

## Varnish CLI Management

```bash
# Connect to Varnish admin console
varnishadm

# Common commands
varnishadm status              # Check status
varnishadm ban.list            # List ban rules
varnishadm ban.url /path       # Ban a URL
varnishadm param.show          # Show parameters
varnishadm param.set <p> <v>   # Set parameter
varnishadm vcl.list            # List VCL configs
varnishadm vcl.load <n> <f>    # Load new VCL
varnishadm vcl.use <name>      # Activate VCL
varnishadm panic.show          # Show panic info
varnishadm panic.clear         # Clear panic
```

---

## Varnish Statistics

```bash
# Real-time stats
varnishstat

# Top URLs
varnishtop -i URL

# Request log
varnishlog -g request

# Backend health
varnishlog -g raw -i Backend_health
```

---

## Varnish Memory Configuration

**Path:** `/etc/varnish/varnish.params` (RHEL/CentOS)

```bash
VARNISH_VCL_CONF=/etc/varnish/default.vcl
VARNISH_LISTEN_PORT=82
VARNISH_ADMIN_LISTEN_ADDRESS=127.0.0.1
VARNISH_ADMIN_LISTEN_PORT=6082
VARNISH_SECRET_FILE=/etc/varnish/secret
VARNISH_STORAGE="malloc,1G"
VARNISH_STORAGE_FILE="/var/lib/varnish/varnish_storage.bin,1G"
VARNISH_TTL=120
VARNISH_USER=varnish
VARNISH_GROUP=varnish
```

**Storage options:**
- `malloc,1G` - In-memory (fastest, limited by RAM)
- `file,/path,1G` - File-based (larger, uses disk)

---

## Varnish + SSL Considerations

Varnish does not handle SSL/HTTPS directly. The architecture must be:

```
Client (443) -> Nginx (SSL termination) -> Varnish (82) -> Nginx/Apache (backend)
```

Or:

```
Client (443) -> Hitch/Haproxy (SSL) -> Varnish (82) -> Backend (8181)
```

CWP typically uses Nginx for SSL termination when Varnish is enabled.

---

## Varnish Health Checks

```vcl
backend default {
    .host = "127.0.0.1";
    .port = "8181";
    .probe = {
        .url = "/";
        .timeout = 5s;
        .interval = 10s;
        .window = 5;
        .threshold = 3;
    }
}
```

---

## Common Issues

### Varnish not caching
- Check for cookies in requests (`varnishlog -g request -i RxHeader`)
- Verify backend is responding (`varnishlog -g raw -i Backend_health`)
- Check VCL logic for `return (pass)` conditions

### Cache not purging
- Verify admin socket is accessible: `varnishadm status`
- Check ban list: `varnishadm ban.list`

### High memory usage
- Reduce storage allocation in varnish.params
- Tune TTL values in VCL
- Use `file` storage instead of `malloc`

### Varnish service won't start
- Check Varnish port is not in use: `VARNISH_PORT=$(ss -tlnp | grep varnish | grep -oP ':\K\d+' | head -1); ss -tlnp | grep :${VARNISH_PORT:-82}`
- Verify VCL syntax: `varnishd -C -f /etc/varnish/default.vcl`
- Check logs: `journalctl -u varnish`
