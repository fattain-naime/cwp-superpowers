# Nginx Configuration Reference

## CWP Nginx Installation

CWP installs Nginx at `/usr/local/nginx/`.

```
Binary:    /usr/local/nginx/sbin/nginx
Config:    /usr/local/nginx/conf/nginx.conf
Modules:   /usr/local/nginx/modules/
Logs:      /usr/local/nginx/logs/
VHosts:    /etc/nginx/vhosts/
Conf.d:    /etc/nginx/conf.d/
```

---

## Main nginx.conf

```nginx
user nginx;
worker_processes auto;
worker_rlimit_nofile 65535;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 4096;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Logging
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log main;

    # Performance
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    # Buffers
    client_max_body_size 128m;
    client_body_buffer_size 128k;
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 256;
    gzip_types
        text/plain
        text/css
        text/javascript
        application/json
        application/javascript
        application/xml
        application/xml+rss
        image/svg+xml;

    # Includes
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/vhosts/*.conf;
}
```

---

## Server Blocks (VHosts)

Per-domain configs in `/etc/nginx/vhosts/{domain}.conf`.

### Standard VHost (Nginx Only)

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name domain.com www.domain.com;

    root /home/{username}/public_html;
    index index.php index.html index.htm;

    # Access/Error logs
    access_log /var/log/nginx/domains/{domain}.access.log;
    error_log /var/log/nginx/domains/{domain}.error.log;

    # Main location
    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    # PHP handling
    location ~ \.php$ {
        fastcgi_pass unix:/opt/alt/php{version}/usr/var/running/{username}.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Deny dotfiles
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Static file caching
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
```

### SSL VHost

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name domain.com www.domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name domain.com www.domain.com;

    root /home/{username}/public_html;
    index index.php index.html;

    # SSL
    ssl_certificate /etc/letsencrypt/live/domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;

    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/opt/alt/php{version}/usr/var/running/{username}.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

---

## Nginx as Reverse Proxy to Apache

When CWP uses `nginx_reverse` mode, Nginx proxies to Apache on a backend port.

```nginx
server {
    listen 80;
    server_name domain.com www.domain.com;

    root /home/{username}/public_html;
    index index.php index.html;

    # Serve static files directly via Nginx
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|pdf|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
        try_files $uri =404;
    }

    # Proxy everything else to Apache
    location / {
        proxy_pass http://127.0.0.1:{apache_port};
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Deny dotfiles
    location ~ /\. {
        deny all;
    }
}
```

Apache backend ports per user (set in CWP):
- Backend port range typically starts at 8000+
- Configured in `/usr/local/apache/conf/users/{username}.conf`

---

## Proxy Cache Configuration

```nginx
# In http{} block
proxy_cache_path /var/cache/nginx levels=1:2
    keys_zone=CACHE:10m
    max_size=1g
    inactive=60m
    use_temp_path=off;

server {
    # ...
    location / {
        proxy_cache CACHE;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout updating;
        proxy_pass http://127.0.0.1:8080;
    }
}
```

---

## Rate Limiting

```nginx
# In http{} block
limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=addr:10m;

server {
    # ...
    location / {
        limit_req zone=one burst=20 nodelay;
        limit_conn addr 10;
    }

    # Stricter limits on login pages
    location ~ ^/(wp-login|admin) {
        limit_req zone=one burst=5 nodelay;
    }
}
```

---

## Nginx FastCGI Cache

```nginx
# In http{} block
fastcgi_cache_path /var/cache/nginx/fastcgi levels=1:2
    keys_zone=WORDPRESS:100m
    inactive=60m
    max_size=500m;

server {
    # ...
    location ~ \.php$ {
        fastcgi_cache WORDPRESS;
        fastcgi_cache_valid 200 60m;
        fastcgi_cache_methods GET HEAD;
        fastcgi_cache_bypass $skip_cache;
        fastcgi_no_cache $skip_cache;
        add_header X-FastCGI-Cache $upstream_cache_status;

        fastcgi_pass unix:/opt/alt/php{version}/usr/var/running/{username}.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

# Cache skip conditions
map $request_method $skip_cache {
    default 0;
    POST 1;
}
map $request_uri $skip_cache {
    default 0;
    ~*/wp-admin 1;
    ~*/wp-login 1;
}
```

---

## Nginx Security

### Block common attacks
```nginx
# Block PHP execution in uploads
location ~* /uploads/.*\.php$ {
    deny all;
}

# Block access to sensitive files
location ~* \.(engine|inc|info|install|make|module|profile|test|po|sh|sql|theme|tpl|xtmpl|yml)$ {
    deny all;
}

# Block XML-RPC (WordPress)
location = /xmlrpc.php {
    deny all;
}

# Limit request methods
if ($request_method !~ ^(GET|HEAD|POST)$) {
    return 405;
}
```

### Basic Auth for admin
```nginx
location /wp-admin {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
    # ... proxy or fastcgi config
}
```

---

## Rebuilding Nginx Configs

```bash
# Test configuration
/usr/local/nginx/sbin/nginx -t

# Rebuild CWP-generated configs
/scripts/rebuild_nginx

# Reload
systemctl reload nginx
```

Or via CWP admin: **WebServer Settings > WebServers Conf > Rebuild Nginx Config**
