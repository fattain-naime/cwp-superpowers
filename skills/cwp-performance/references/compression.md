# Compression Reference

## Overview

Compression reduces file sizes for faster HTTP transfers. CWP supports Brotli, gzip, and deflate for both Apache and Nginx.

---

## Brotli

Brotli provides better compression ratios than gzip, especially for text content.

### Nginx Brotli

#### Installation

```bash
# Install ngx_brotli module
cd /usr/local/src
git clone https://github.com/google/ngx_brotli.git
cd ngx_brotli && git submodule update --init

# Recompile Nginx with Brotli
cd /usr/local/src/nginx-{version}
./configure --add-dynamic-module=/usr/local/src/ngx_brotli
make modules
cp objs/ngx_http_brotli*.so /usr/local/nginx/modules/
```

#### Configuration

**Path:** `/etc/nginx/nginx.conf`

```nginx
# Load Brotli modules
load_module modules/ngx_http_brotli_filter_module.so;
load_module modules/ngx_http_brotli_static_module.so;

http {
    # Brotli compression
    brotli on;
    brotli_comp_level 6;
    brotli_types
        text/plain
        text/css
        text/javascript
        text/xml
        application/json
        application/javascript
        application/xml
        application/xml+rss
        application/x-javascript
        image/svg+xml
        font/ttf
        font/otf
        font/woff
        font/woff2;

    # Brotli static (pre-compressed files)
    brotli_static on;
}
```

### Apache Brotli

#### Installation

```bash
# Install mod_brotli
yum install mod_brotli

# Or compile from source
cd /usr/local/src
git clone https://github.com/kjdev/apache-mod-brotli.git
cd apache-mod-brotli
/usr/local/apache/bin/apxs -i -c mod_brotli.c -lbrotlienc -lbrotlidec -lbrotlicommon
```

#### Configuration

```apache
# In httpd.conf
LoadModule brotli_module modules/mod_brotli.so

<IfModule mod_brotli.c>
    AddOutputFilterByType BROTLI_COMPRESS text/html text/plain text/xml
    AddOutputFilterByType BROTLI_COMPRESS text/css text/javascript
    AddOutputFilterByType BROTLI_COMPRESS application/javascript application/json
    AddOutputFilterByType BROTLI_COMPRESS application/xml application/xhtml+xml
    AddOutputFilterByType BROTLI_COMPRESS image/svg+xml
    AddOutputFilterByType BROTLI_COMPRESS font/ttf font/otf font/woff font/woff2

    BrotliCompressionQuality 6
    BrotliCompressionWindowSize 22
</IfModule>
```

---

## gzip

### Nginx gzip

```nginx
http {
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_min_length 256;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_types
        text/plain
        text/css
        text/javascript
        text/xml
        text/x-component
        application/json
        application/javascript
        application/x-javascript
        application/xml
        application/xml+rss
        application/atom+xml
        application/vnd.ms-fontobject
        application/x-font-ttf
        application/x-web-app-manifest+json
        font/opentype
        image/svg+xml
        image/x-icon;
}
```

### Apache gzip (mod_deflate)

```apache
<IfModule mod_deflate.c>
    # Compress HTML, CSS, JavaScript, Text, XML
    AddOutputFilterByType DEFLATE text/html
    AddOutputFilterByType DEFLATE text/css
    AddOutputFilterByType DEFLATE text/javascript
    AddOutputFilterByType DEFLATE text/xml
    AddOutputFilterByType DEFLATE text/plain
    AddOutputFilterByType DEFLATE text/x-component
    AddOutputFilterByType DEFLATE application/javascript
    AddOutputFilterByType DEFLATE application/x-javascript
    AddOutputFilterByType DEFLATE application/json
    AddOutputFilterByType DEFLATE application/xml
    AddOutputFilterByType DEFLATE application/rss+xml
    AddOutputFilterByType DEFLATE application/atom+xml
    AddOutputFilterByType DEFLATE image/svg+xml
    AddOutputFilterByType DEFLATE font/ttf
    AddOutputFilterByType DEFLATE font/otf
    AddOutputFilterByType DEFLATE font/woff
    AddOutputFilterByType DEFLATE application/vnd.ms-fontobject
    AddOutputFilterByType DEFLATE application/x-font-ttf

    # Remove browser bugs
    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSIE !no-gzip !gzip-only-text/html

    # Don't compress images
    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|webp)$ no-gzip dont-vary
</IfModule>
```

---

## deflate

deflate is an older compression method, largely replaced by gzip and Brotli.

### Apache deflate

```apache
<IfModule mod_deflate.c>
    DeflateCompressionLevel 6
    DeflateMemLevel 8
    DeflateWindowSize 15

    AddOutputFilterByType DEFLATE text/html text/plain text/xml
    AddOutputFilterByType DEFLATE text/css text/javascript
    AddOutputFilterByType DEFLATE application/javascript application/json
</IfModule>
```

---

## Pre-compression

### Static Pre-compressed Files

For files that don't change often, pre-compress them:

```bash
# Pre-compress with gzip
find /home/user/public_html -name "*.css" -o -name "*.js" | while read file; do
    gzip -9 -k "$file"
done

# Pre-compress with Brotli
find /home/user/public_html -name "*.css" -o -name "*.js" | while read file; do
    brotli -f -o "${file}.br" "$file"
done
```

### Nginx Static Compression

```nginx
# Serve pre-compressed files
gzip_static on;
brotli_static on;
```

### Apache Pre-compression

```apache
# Serve .gz files
AddEncoding x-gzip .gz
AddType text/html .gz

# Serve .br files
AddEncoding br .br
```

---

## Compression Testing

### Test gzip

```bash
# Check if server sends compressed content
curl -H "Accept-Encoding: gzip" -I https://domain.com/style.css

# Look for: Content-Encoding: gzip

# Check compression ratio
curl -s -H "Accept-Encoding: gzip" https://domain.com/ -o /dev/null -w "Size: %{size_download}\n"
curl -s https://domain.com/ -o /dev/null -w "Size: %{size_download}\n"
```

### Test Brotli

```bash
curl -H "Accept-Encoding: br" -I https://domain.com/style.css
# Look for: Content-Encoding: br
```

### Online Testing Tools

- GTmetrix: https://gtmetrix.com
- Google PageSpeed Insights: https://pagespeed.web.dev
- WebPageTest: https://www.webpagetest.org

---

## Compression Level Recommendations

| Level | gzip Ratio | Speed   | Brotli Ratio | Speed   |
|-------|------------|---------|--------------|---------|
| 1     | Low        | Fastest | Low          | Fastest |
| 4     | Medium     | Fast    | Medium       | Fast    |
| 6     | Good       | Medium  | Good         | Medium  |
| 9     | Best       | Slow    | Best         | Slowest |
| 11    | N/A        | N/A     | Best+        | Slowest |

**Recommendation:** Use level 6 for dynamic content, level 9-11 for static files.

---

## Cache-Control Headers

### Nginx Cache Headers

```nginx
# Static assets
location ~* \.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary "Accept-Encoding";
}

# HTML
location ~* \.html$ {
    expires 10m;
    add_header Cache-Control "public, must-revalidate";
    add_header Vary "Accept-Encoding";
}
```

### Apache Cache Headers

```apache
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css "access plus 1 year"
    ExpiresByType application/javascript "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType image/png "access plus 1 year"
    ExpiresByType image/gif "access plus 1 year"
    ExpiresByType image/svg+xml "access plus 1 year"
    ExpiresByType font/woff2 "access plus 1 year"
    ExpiresByType text/html "access plus 0 seconds"
</IfModule>

<IfModule mod_headers.c>
    <FilesMatch "\.(css|js|jpg|jpeg|png|gif|ico|svg|woff|woff2|ttf|eot)$">
        Header set Cache-Control "public, immutable"
        Header set Vary "Accept-Encoding"
    </FilesMatch>
</IfModule>
```

---

## Vary Header

The `Vary` header tells caches which request headers affect the response:

```nginx
# Required when serving different compressed versions
add_header Vary "Accept-Encoding";
```

---

## Troubleshooting

### Compression not working

```bash
# Check module loaded
httpd -M | grep -E "deflate|brotli"
nginx -V 2>&1 | grep -E "gzip|brotli"

# Check configuration
httpd -t
nginx -t

# Test with curl
curl -H "Accept-Encoding: gzip, br" -v https://domain.com/ 2>&1 | grep "Content-Encoding"
```

### Double compression

Avoid compressing already-compressed files:
```nginx
# Don't compress these
gzip_min_length 256;
# Already compressed: images, videos, archives
```

### High CPU usage from compression

```nginx
# Reduce compression level
gzip_comp_level 4;

# Increase minimum size
gzip_min_length 1024;

# Disable for specific file types
gzip_types !image/jpeg !image/png !video/mp4;
```

### Compression causing issues with proxies

```nginx
# Add Vary header
add_header Vary "Accept-Encoding";

# Disable compression for proxied requests if needed
gzip_proxied no-cache no-store private expired auth;
```
