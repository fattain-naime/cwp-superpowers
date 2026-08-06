#compdef cwp
# =============================================================================
# Zsh completion for CWP CLI
# =============================================================================
# Copy to a directory in $fpath, e.g.:
#   mkdir -p ~/.zsh/completions
#   cp cwp-completion.zsh ~/.zsh/completions/_cwp
#   echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
#   autoload -Uz compinit && compinit
# =============================================================================

_cwp() {
    local -a commands user_subs database_subs email_subs dns_subs ssl_subs
    local -a security_subs backup_subs service_subs php_subs fix_subs
    local -a optimize_subs migrate_subs logs_subs

    commands=(
        'status:Server status overview'
        'user:Manage user accounts'
        'database:Manage databases'
        'email:Manage email accounts'
        'dns:Manage DNS records'
        'ssl:Manage SSL certificates'
        'security:Security management'
        'backup:Backup management'
        'service:Service management'
        'php:PHP version management'
        'fix:Fix common issues'
        'optimize:Performance optimization'
        'migrate:Server migration tools'
        'logs:View and search logs'
        'setup:Interactive setup wizard'
    )

    user_subs=(
        'list:List all user accounts'
        'info:Get user account info'
        'add:Create a new user account'
        'delete:Delete a user account'
        'suspend:Suspend a user account'
        'unsuspend:Unsuspend a user account'
        'password:Change user password'
    )

    database_subs=(
        'list:List all databases'
        'create:Create a new database'
        'delete:Delete a database'
        'user-add:Add user to database'
        'backup:Backup a database'
        'restore:Restore a database'
        'size:Show database sizes'
    )

    email_subs=(
        'list:List email accounts'
        'create:Create email account'
        'delete:Delete email account'
        'forwarders:List email forwarders'
        'queue:Show mail queue'
        'flush:Flush mail queue'
    )

    dns_subs=(
        'list:List DNS zones'
        'zone:Show zone file'
        'add-record:Add DNS record'
        'check:Check DNS records'
    )

    ssl_subs=(
        'list:List SSL certificates'
        'info:Show certificate info'
        'install:Install SSL certificate'
        'renew:Renew certificates'
        'check:Check certificate expiry'
    )

    security_subs=(
        'status:Show security status'
        'firewall:Manage firewall rules'
        'ssh-hardening:Apply SSH hardening'
        'updates:Check security updates'
        'fail2ban:Manage fail2ban'
    )

    backup_subs=(
        'list:List backups'
        'create:Create backup'
        'restore:Restore from backup'
        'verify:Verify backup integrity'
        'cleanup:Remove old backups'
        'schedule:Schedule automatic backups'
    )

    service_subs=(
        'list:List service statuses'
        'restart:Restart a service'
        'stop:Stop a service'
        'start:Start a service'
        'enable:Enable service at boot'
        'disable:Disable service at boot'
        'logs:View service logs'
    )

    php_subs=(
        'list:List PHP versions'
        'set:Set PHP version for user'
        'info:Show PHP info'
        'ini:Show PHP ini location'
        'extensions:List PHP extensions'
        'fpm-status:Show PHP-FPM status'
    )

    fix_subs=(
        'auto:Run auto-fix diagnostics'
        'permissions:Fix file permissions'
        'ownership:Fix file ownership'
        'dns:Rebuild DNS zone'
        'ssl:Fix SSL certificate'
        'mail:Fix mail configuration'
    )

    optimize_subs=(
        'all:Run all optimizations'
        'mysql:Optimize MySQL'
        'php:Optimize PHP'
        'apache:Optimize Apache'
        'nginx:Optimize Nginx'
        'opcache:Reset OPcache'
        'logs:Clean old logs'
    )

    migrate_subs=(
        'prepare:Prepare migration package'
        'import:Import migration package'
        'transfer:Transfer to remote server'
    )

    logs_subs=(
        'tail:Tail log files'
        'search:Search in logs'
        'errors:Show recent errors'
    )

    _arguments -C \
        '(-h --help)'{-h,--help}'[Show help message]' \
        '(-v --version)'{-v,--version}'[Show version]' \
        '--host[CWP server hostname or IP]:host:' \
        '--api-key[CWP API key]:key:' \
        '--api-port[CWP API port]:port:' \
        '--ssh-user[SSH username]:user:' \
        '--ssh-port[SSH port]:port:' \
        '--ssh-key[SSH private key file]:key file:_files' \
        '--output[Output format]:format:(text json)' \
        '--verbose[Enable verbose output]' \
        '1:command:->command' \
        '*::subcommand:->subcommand'

    case $state in
        command)
            _describe 'command' commands
            ;;
        subcommand)
            case $words[1] in
                user)       _describe 'subcommand' user_subs ;;
                database)   _describe 'subcommand' database_subs ;;
                email)      _describe 'subcommand' email_subs ;;
                dns)        _describe 'subcommand' dns_subs ;;
                ssl)        _describe 'subcommand' ssl_subs ;;
                security)   _describe 'subcommand' security_subs ;;
                backup)     _describe 'subcommand' backup_subs ;;
                service)    _describe 'subcommand' service_subs ;;
                php)        _describe 'subcommand' php_subs ;;
                fix)        _describe 'subcommand' fix_subs ;;
                optimize)   _describe 'subcommand' optimize_subs ;;
                migrate)    _describe 'subcommand' migrate_subs ;;
                logs)       _describe 'subcommand' logs_subs ;;
            esac
            ;;
    esac
}

_cwp "$@"
