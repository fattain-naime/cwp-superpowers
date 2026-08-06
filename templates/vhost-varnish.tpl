# =============================================================================
# Varnish VCL Template - Backend Apache with caching
# =============================================================================
# Variables (replace before use):
#   {{DOMAIN}}       - Primary domain name
#   {{BACKEND_HOST}} - Backend host (default: 127.0.0.1)
#   {{BACKEND_PORT}} - Backend port (default: 8181)
# =============================================================================
# Place at: /etc/varnish/default.vcl
# Restart: systemctl restart varnish
# =============================================================================

vcl 4.0;

# ---------------------------------------------------------------------------
# Backend (Apache)
# ---------------------------------------------------------------------------
backend default {
    .host = "{{BACKEND_HOST}}";
    .port = "{{BACKEND_PORT}}";
    .connect_timeout = 5s;
    .first_byte_timeout = 300s;
    .between_bytes_timeout = 60s;
    .max_connections = 300;

    # Health check
    .probe = {
        .url = "/";
        .timeout = 2s;
        .interval = 5s;
        .window = 5;
        .threshold = 3;
    }
}

# ---------------------------------------------------------------------------
# ACL for purging
# ---------------------------------------------------------------------------
acl purge {
    "localhost";
    "127.0.0.1";
    "::1";
    # Add your server IPs here
}

# ---------------------------------------------------------------------------
# Subroutine: vcl_recv
# ---------------------------------------------------------------------------
sub vcl_recv {
    # Set backend
    set req.backend_hint = default;

    # Purge handling
    if (req.method == "PURGE") {
        if (!client.ip ~ purge) {
            return (synth(405, "Not allowed."));
        }
        return (purge);
    }

    # Only cache GET and HEAD
    if (req.method != "GET" && req.method != "HEAD") {
        return (pass);
    }

    # Skip cache for admin panels
    if (req.url ~ "^/admin" || req.url ~ "^/wp-admin" || req.url ~ "^/cwp/") {
        return (pass);
    }

    # Skip cache for login/authentication
    if (req.url ~ "login" || req.url ~ "signin" || req.url ~ "register" || req.url ~ "password") {
        return (pass);
    }

    # Skip cache for AJAX/API
    if (req.url ~ "/api/" || req.url ~ "/wp-json/" || req.url ~ "/ajax/") {
        return (pass);
    }

    # Skip cache for e-commerce/cart
    if (req.url ~ "cart" || req.url ~ "checkout" || req.url ~ "my-account") {
        return (pass);
    }

    # Skip cache when cookies indicate logged-in user
    if (req.http.Cookie ~ "wordpress_logged_in|PHPSESSID|session_id|auth") {
        return (pass);
    }

    # Remove cookies for static assets
    if (req.url ~ "\.(css|js|jpg|jpeg|png|gif|ico|webp|svg|woff2|woff|ttf|eot|mp4|webm|pdf|zip)$") {
        unset req.http.Cookie;
        return (hash);
    }

    # Remove tracking cookies
    if (req.http.Cookie) {
        set req.http.Cookie = regsuball(req.http.Cookie, "__utm[a-z]+=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "_ga=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "_gid=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "has_js=[^;]+(; )?", "");
        set req.http.Cookie = regsuball(req.http.Cookie, "^\s*;\s*", "");
        if (req.http.Cookie == "") {
            unset req.http.Cookie;
        }
    }

    # Accept-Encoding normalization
    if (req.http.Accept-Encoding) {
        if (req.http.Accept-Encoding ~ "gzip") {
            set req.http.Accept-Encoding = "gzip";
        } elsif (req.http.Accept-Encoding ~ "deflate") {
            set req.http.Accept-Encoding = "deflate";
        } else {
            unset req.http.Accept-Encoding;
        }
    }

    return (hash);
}

# ---------------------------------------------------------------------------
# Subroutine: vcl_hash
# ---------------------------------------------------------------------------
sub vcl_hash {
    hash_data(req.url);
    if (req.http.host) {
        hash_data(req.http.host);
    } else {
        hash_data(server.ip);
    }

    # Hash by protocol
    if (req.http.X-Forwarded-Proto) {
        hash_data(req.http.X-Forwarded-Proto);
    }

    return (lookup);
}

# ---------------------------------------------------------------------------
# Subroutine: vcl_backend_response
# ---------------------------------------------------------------------------
sub vcl_backend_response {
    # Cache static assets for 1 year
    if (bereq.url ~ "\.(css|js|jpg|jpeg|png|gif|ico|webp|svg|woff2|woff|ttf|eot|mp4|webm|pdf|zip)$") {
        set beresp.ttl = 365d;
        unset beresp.http.Set-Cookie;
    }

    # Cache HTML pages for 10 minutes
    if (beresp.http.Content-Type ~ "text/html") {
        set beresp.ttl = 10m;
    }

    # Don't cache error pages
    if (beresp.status >= 400) {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Don't cache if backend says not to
    if (beresp.http.Cache-Control ~ "no-cache|no-store|private") {
        set beresp.ttl = 0s;
        set beresp.uncacheable = true;
        return (deliver);
    }

    # Grace period (serve stale content while revalidating)
    set beresp.grace = 6h;

    return (deliver);
}

# ---------------------------------------------------------------------------
# Subroutine: vcl_deliver
# ---------------------------------------------------------------------------
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

    # Remove Varnish identification
    unset resp.http.Via;
    unset resp.http.X-Varnish;

    return (deliver);
}

# ---------------------------------------------------------------------------
# Subroutine: vcl_synth
# ---------------------------------------------------------------------------
sub vcl_synth {
    if (resp.status == 750) {
        set resp.status = 301;
        set resp.http.Location = resp.reason;
        set resp.reason = "Moved";
        return (deliver);
    }
}

# ---------------------------------------------------------------------------
# Subroutine: vcl_backend_error
# ---------------------------------------------------------------------------
sub vcl_backend_error {
    set beresp.http.Content-Type = "text/html; charset=utf-8";
    synthetic({"<!DOCTYPE html>
<html>
<head><title>Service Unavailable</title></head>
<body>
<h1>Service Temporarily Unavailable</h1>
<p>Please try again later.</p>
</body>
</html>"});
    return (deliver);
}
