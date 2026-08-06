# =============================================================================
# Apache Virtual Host Template with PHP-FPM
# =============================================================================
# Variables (replace before use):
#   {{DOMAIN}}       - Primary domain name
#   {{ALIAS}}        - ServerAlias (e.g., www.domain.com)
#   {{DOCROOT}}      - Document root path
#   {{PHP_VERSION}}  - PHP version (e.g., 8.2)
#   {{USER}}         - System username
#   {{LOG_DIR}}      - Log directory path
#   {{ADMIN_EMAIL}}  - Server admin email
# =============================================================================

<VirtualHost *:80>
    ServerName {{DOMAIN}}
    ServerAlias {{ALIAS}}
    ServerAdmin {{ADMIN_EMAIL}}

    DocumentRoot {{DOCROOT}}

    # --- Directory Configuration ---
    <Directory {{DOCROOT}}>
        Options -Indexes +FollowSymLinks -ExecCGI
        AllowOverride All
        Require all granted

        # Rewrite engine for common frameworks
        <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteBase /
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^(.*)$ index.php/$1 [L,QSA]
        </IfModule>
    </Directory>

    # --- PHP-FPM Configuration ---
    <FilesMatch \.php$>
        SetHandler "proxy:unix:/opt/alt/php{{PHP_VERSION}}/usr/var/run/{{USER}}.sock|fcgi://localhost"
    </FilesMatch>

    # --- Security Headers ---
    <IfModule mod_headers.c>
        Header always set X-Content-Type-Options "nosniff"
        Header always set X-Frame-Options "SAMEORIGIN"
        Header always set X-XSS-Protection "1; mode=block"
        Header always set Referrer-Policy "strict-origin-when-cross-origin"
        Header always set Permissions-Policy "camera=(), microphone=(), geolocation=()"
        # Uncomment to enable HSTS (ensure SSL is configured first)
        # Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        # Uncomment for Content-Security-Policy
        # Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
    </IfModule>

    # --- Hide Server Version ---
    ServerTokens Prod
    ServerSignature Off

    # --- Block Sensitive Files ---
    <FilesMatch "\.(env|git|htpasswd|htaccess|ini|log|sql|bak|backup|swp|dist|sh)$">
        <IfModule mod_authz_core.c>
            Require all denied
        </IfModule>
    </FilesMatch>

    # Block access to hidden files except .well-known
    <DirectoryMatch "/\.(?!well-known)">
        <IfModule mod_authz_core.c>
            Require all denied
        </IfModule>
    </DirectoryMatch>

    # --- Logging ---
    ErrorLog {{LOG_DIR}}/{{DOMAIN}}_error.log
    CustomLog {{LOG_DIR}}/{{DOMAIN}}_access.log combined

    # Log level (adjust for debugging)
    LogLevel warn

    # --- Compression ---
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
        AddOutputFilterByType DEFLATE text/javascript application/javascript application/x-javascript
        AddOutputFilterByType DEFLATE application/json application/xml
        AddOutputFilterByType DEFLATE image/svg+xml
    </IfModule>

    # --- Browser Caching ---
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType text/css "access plus 1 year"
        ExpiresByType application/javascript "access plus 1 year"
        ExpiresByType application/x-javascript "access plus 1 year"
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/png "access plus 1 year"
        ExpiresByType image/gif "access plus 1 year"
        ExpiresByType image/svg+xml "access plus 1 year"
        ExpiresByType image/webp "access plus 1 year"
        ExpiresByType font/woff2 "access plus 1 year"
        ExpiresByType font/woff "access plus 1 year"
        ExpiresByType application/json "access plus 0 seconds"
        ExpiresByType text/html "access plus 0 seconds"
    </IfModule>

    # --- Upload Limits ---
    php_value upload_max_filesize 64M
    php_value post_max_size 64M
    php_value max_execution_time 300
    php_value max_input_time 300
    php_value memory_limit 256M
</VirtualHost>

# =============================================================================
# SSL Virtual Host (uncomment when SSL is configured)
# =============================================================================
# <VirtualHost *:443>
#     ServerName {{DOMAIN}}
#     ServerAlias {{ALIAS}}
#     ServerAdmin {{ADMIN_EMAIL}}
#
#     DocumentRoot {{DOCROOT}}
#
#     # SSL Configuration
#     SSLEngine on
#     SSLCertificateFile /etc/letsencrypt/live/{{DOMAIN}}/fullchain.pem
#     SSLCertificateKeyFile /etc/letsencrypt/live/{{DOMAIN}}/privkey.pem
#     SSLCertificateChainFile /etc/letsencrypt/live/{{DOMAIN}}/chain.pem
#
#     # SSL Protocol and Cipher Configuration
#     SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
#     SSLCipherSuite HIGH:!aNULL:!MD5:!3DES:!RC4
#     SSLHonorCipherOrder on
#
#     # HSTS Header
#     Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
#
#     # Same directory and security config as port 80
#     <Directory {{DOCROOT}}>
#         Options -Indexes +FollowSymLinks
#         AllowOverride All
#         Require all granted
#     </Directory>
#
#     <FilesMatch \.php$>
#         SetHandler "proxy:unix:/opt/alt/php{{PHP_VERSION}}/usr/var/run/{{USER}}.sock|fcgi://localhost"
#     </FilesMatch>
#
#     ErrorLog {{LOG_DIR}}/{{DOMAIN}}_ssl_error.log
#     CustomLog {{LOG_DIR}}/{{DOMAIN}}_ssl_access.log combined
# </VirtualHost>
