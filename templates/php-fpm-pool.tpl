; =============================================================================
; PHP-FPM Pool Configuration Template for CWP
; =============================================================================
; Variables (replace before use):
;   {{USER}}         - System username
;   {{DOMAIN}}       - Domain name
;   {{PHP_VERSION}}  - PHP version (e.g., 8.2)
;   {{DOCROOT}}      - Document root path
; =============================================================================
; Place at: /opt/alt/php{{PHP_VERSION}}/etc/php-fpm.d/{{USER}}.conf
; Restart: systemctl restart php-fpm-php{{PHP_VERSION}}
; =============================================================================

[{{USER}}]

; --- Process Manager ---
; 'ondemand' - spawns workers on demand (lowest memory)
; 'dynamic'  - maintains a pool between min and max
; 'static'   - always spawns max children
pm = ondemand

; Maximum number of children (for ondemand: max before killing idle)
; Adjust based on available RAM: ~30-50MB per process
pm.max_children = 10

; Only for 'dynamic' pm:
; pm.start_servers = 2
; pm.min_spare_servers = 1
; pm.max_spare_servers = 5

; Time (in seconds) after which idle process is killed (ondemand only)
pm.process_idle_timeout = 10s

; Maximum requests per child before respawn (0 = unlimited)
pm.max_requests = 500

; --- User/Group ---
user = {{USER}}
group = {{USER}}

; --- Listening ---
listen = /opt/alt/php{{PHP_VERSION}}/usr/var/run/{{USER}}.sock
listen.owner = {{USER}}
listen.group = {{USER}}
listen.mode = 0660
; For TCP listening instead of socket:
; listen = 127.0.0.1:90{{PHP_VERSION}}

; --- Status Page ---
pm.status_path = /fpm-status-{{USER}}
ping.path = /fpm-ping-{{USER}}
ping.response = pong

; --- Logging ---
; Error log for this pool
php_admin_value[error_log] = /var/log/php-fpm/{{USER}}_error.log
php_admin_flag[log_errors] = on

; Slow log (logs requests taking longer than threshold)
slowlog = /var/log/php-fpm/{{USER}}_slow.log
request_slowlog_timeout = 5s
request_terminate_timeout = 300s

; --- PHP Settings (per-pool overrides) ---

; Paths
php_admin_value[open_basedir] = {{DOCROOT}}:/tmp:/usr/share/php
php_admin_value[upload_tmp_dir] = /tmp

; Upload settings
php_value[upload_max_filesize] = 64M
php_value[post_max_size] = 64M
php_value[max_file_uploads] = 20

; Execution limits
php_value[max_execution_time] = 300
php_value[max_input_time] = 300
php_value[memory_limit] = 256M

; Error reporting (production)
php_admin_flag[display_errors] = off
php_admin_flag[display_startup_errors] = off
php_value[error_reporting] = E_ALL & ~E_DEPRECATED & ~E_STRICT
php_admin_value[error_log] = /var/log/php-fpm/{{USER}}_error.log

; Session configuration
php_value[session.save_handler] = files
php_value[session.save_path] = /tmp
php_value[session.gc_maxlifetime] = 1440
php_value[session.cookie_httponly] = 1
php_value[session.cookie_secure] = 1
php_value[session.use_strict_mode] = 1

; Security
php_admin_value[disable_functions] = exec,passthru,shell_exec,system,proc_open,popen,curl_multi_exec,parse_ini_file,show_source
php_admin_flag[allow_url_fopen] = on
php_admin_flag[allow_url_include] = off

; OPcache settings (per-pool)
; php_admin_flag[opcache.enable] = on
; php_admin_value[opcache.memory_consumption] = 128
; php_admin_value[opcache.interned_strings_buffer] = 8
; php_admin_value[opcache.max_accelerated_files] = 10000
; php_admin_value[opcache.revalidate_freq] = 2
; php_admin_value[opcache.fast_shutdown] = 1

; Date
php_value[date.timezone] = UTC

; Realpath cache
php_admin_value[realpath_cache_size] = 4096k
php_admin_value[realpath_cache_ttl] = 600

; --- Environment Variables ---
env[HOSTNAME] = $HOSTNAME
env[PATH] = /usr/local/bin:/usr/bin:/bin
env[TMP] = /tmp
env[TMPDIR] = /tmp
env[TEMP] = /tmp
