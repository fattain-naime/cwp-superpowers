# =============================================================================
# Nginx Virtual Host Template - Proxy to Apache
# =============================================================================
# Variables (replace before use):
#   {{DOMAIN}}       - Primary domain name
#   {{ALIAS}}        - Server alias (e.g., www.domain.com)
#   {{DOCROOT}}      - Document root path
#   {{USER}}         - System username
#   {{LOG_DIR}}      - Log directory path
#   {{PHP_VERSION}}  - PHP version (e.g., 8.2)
# =============================================================================

# HTTP -> HTTPS redirect (uncomment when SSL is configured)
# server {
#     listen 80;
#     listen [::]:80;
#     server_name {{DOMAIN}} {{ALIAS}};
#     return 301 https://$host$request_uri;
# }

server {
    listen 80;
    listen [::]:80;
    # Uncomment for SSL:
    # listen 443 ssl http2;
    # listen [::]:443 ssl http2;

    server_name {{DOMAIN}} {{ALIAS}};
    root {{DOCROOT}};
    index index.php index.html index.htm;

    # --- SSL Configuration (uncomment when ready) ---
    # ssl_certificate /etc/letsencrypt/live/{{DOMAIN}}/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/{{DOMAIN}}/privkey.pem;
    # ssl_protocols TLSv1.2 TLSv1.3;
    # ssl_ciphers HIGH:!aNULL:!MD5;
    # ssl_prefer_server_ciphers on;
    # ssl_session_cache shared:SSL:10m;
    # ssl_session_timeout 10m;

    # --- Security Headers ---
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    # add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Hide nginx version
    server_tokens off;

    # --- Logging ---
    access_log {{LOG_DIR}}/{{DOMAIN}}_nginx_access.log;
    error_log {{LOG_DIR}}/{{DOMAIN}}_nginx_error.log warn;

    # --- Static File Handling (serve directly, skip Apache) ---
    location ~* \.(jpg|jpeg|png|gif|ico|webp|svg|css|js|woff2|woff|ttf|eot|mp4|webm|ogg|mp3|wav|pdf|doc|docx|xls|xlsx|zip|tar|gz)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options "nosniff" always;
        access_log off;
        try_files $uri =404;
    }

    # --- Block Sensitive Files ---
    location ~ /\.(env|git|htpasswd|htaccess|ini|log|sql|bak|backup|swp|dist|sh)$ {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Block access to hidden directories except .well-known
    location ~ /\.(?!well-known) {
        deny all;
        access_log off;
        log_not_found off;
    }

    # --- WordPress / Common CMS Rules ---
    # Block xmlrpc.php (common attack vector)
    location = /xmlrpc.php {
        deny all;
        access_log off;
        log_not_found off;
    }

    # Block wp-config.php
    location = /wp-config.php {
        deny all;
        access_log off;
        log_not_found off;
    }

    # --- Let's Encrypt Challenge ---
    location /.well-known/acme-challenge/ {
        root /var/www/html;
        allow all;
    }

    # --- PHP Processing via Proxy to Apache ---
    location / {
        proxy_pass http://127.0.0.1:8181;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Port $server_port;

        # Proxy timeouts
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_read_timeout 300;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 16k;
        proxy_buffers 4 32k;
        proxy_busy_buffers_size 32k;
    }

    # --- Direct PHP-FPM (alternative to Apache proxy) ---
    # Uncomment to use PHP-FPM directly instead of proxying to Apache
    # location ~ \.php$ {
    #     try_files $uri =404;
    #     fastcgi_pass unix:/opt/alt/php{{PHP_VERSION}}/usr/var/run/{{USER}}.sock;
    #     fastcgi_index index.php;
    #     fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    #     include fastcgi_params;
    #     fastcgi_connect_timeout 300;
    #     fastcgi_send_timeout 300;
    #     fastcgi_read_timeout 300;
    #     fastcgi_buffer_size 16k;
    #     fastcgi_buffers 4 32k;
    # }

    # --- Gzip Compression ---
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 1000;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml
        application/xml+rss
        application/xhtml+xml
        image/svg+xml;

    # --- Client Upload Limits ---
    client_max_body_size 64M;

    # --- Rate Limiting (optional) ---
    # limit_req_zone $binary_remote_addr zone=one:10m rate=10r/s;
    # location / {
    #     limit_req zone=one burst=20 nodelay;
    #     proxy_pass http://127.0.0.1:8181;
    #     # ... rest of proxy config
    # }
}
