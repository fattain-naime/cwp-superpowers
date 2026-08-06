# CWP Superpowers

AI-powered plugin for managing CWP (Control Web Panel) servers. Includes full CLI, REST API client, MCP server, 12 skills, 5 autonomous agents, 12 slash commands, 10 hook event types, 7 config templates, 8 utility scripts, and 5 working examples.

**Repository:** [github.com/fattain-naime/cwp-superpowers](https://github.com/fattain-naime/cwp-superpowers)

## What's Included

| Component | Count | Description |
|-----------|-------|-------------|
| Skills | 12 | Auto-activating knowledge for every CWP domain |
| Commands | 12 | Slash commands for common operations |
| Agents | 5 | Autonomous agents for security, performance, troubleshooting, migration, backups |
| MCP Tools | 17 | CWP REST API tools for AI assistants |
| CLI Subcommands | 14 | Full command-line interface |
| Hooks | 10 | Command validation, health checks, config verification |
| Templates | 7 | Apache, Nginx, Varnish, DNS, backup, email, PHP-FPM |
| Scripts | 8 | Installer, setup, API client, remote exec, security scan, health check |
| Examples | 5 | Installation, accounts, email, SSL, security hardening |

## Dynamic Version Detection

This plugin works across different CWP versions by dynamically detecting script names, paths, and service names at runtime. No configuration needed — the AI agent detects your server's setup automatically.

## Requirements

- **Server**: CWP running on AlmaLinux 8/9, CentOS 7/8, Rocky Linux 8/9, or RHEL 8/9
- **Local**: Bash 4+, SSH client, curl
- **Optional**: jq (for safe JSON handling), Node.js (for MCP server)

## Quick Start

### Installation

```bash
# Clone or download the plugin
cd cwp-pro-centos

# Run the installer
sudo bash scripts/install.sh

# Configure your server
cwp setup
```

### Manual Installation

```bash
# Copy CLI to PATH
sudo cp cli/cwp /usr/local/bin/cwp
sudo chmod 755 /usr/local/bin/cwp

# Install completions
sudo cp cli/cwp-completion.bash /etc/bash_completion.d/cwp

# Create config
cat > ~/.cwp-cli.conf <<'EOF'
CWP_HOST="your-server-ip"
CWP_API_KEY="your-api-key"
CWP_API_PORT="2304"
SSH_USER="root"
SSH_PORT="22"
EOF
chmod 600 ~/.cwp-cli.conf
```

## Configuration

### Config File

The CLI reads configuration from `~/.cwp-cli.conf`:

```bash
CWP_HOST="10.0.0.1"          # CWP server hostname or IP
CWP_API_KEY="your-api-key"   # CWP API key (from CWP Admin -> API Manager)
CWP_API_PORT="2304"           # CWP API port
SSH_USER="root"               # SSH username
SSH_PORT="22"                 # SSH port
SSH_KEY=""                    # SSH key file (optional)
```

### Environment Variables

Override config with environment variables:

```bash
export CWP_HOST="10.0.0.1"
export CWP_API_KEY="your-key"
cwp status
```

### Command-Line Options

```bash
cwp --host 10.0.0.1 --api-key KEY status
```

## CLI Reference

### Global Options

| Option | Description |
|--------|-------------|
| `--host <host>` | CWP server hostname or IP |
| `--api-key <key>` | CWP API key |
| `--api-port <port>` | CWP API port (default: 2304) |
| `--ssh-user <user>` | SSH username (default: root) |
| `--ssh-port <port>` | SSH port (default: 22) |
| `--ssh-key <path>` | SSH private key file |
| `--output <format>` | Output format: text, json |
| `--verbose` | Enable debug output |
| `-h, --help` | Show help |
| `-v, --version` | Show version |

### Commands

#### `cwp status`
Server status overview including services, resources, and recent activity.

```bash
cwp status
```

#### `cwp user`
Manage user accounts.

```bash
cwp user list                    # List all accounts
cwp user info username           # Account details
cwp user add username            # Create account
cwp user delete username         # Delete account (with confirmation)
cwp user suspend username        # Suspend account
cwp user unsuspend username      # Unsuspend account
cwp user password username       # Change password
```

#### `cwp database`
Manage MySQL/MariaDB databases.

```bash
cwp database list                # List databases
cwp database create mydb         # Create database
cwp database delete mydb         # Delete database
cwp database user-add user mydb  # Add user to database
cwp database backup mydb         # Backup database
cwp database restore mydb file   # Restore database
cwp database size                # Show database sizes
```

#### `cwp email`
Manage email accounts.

```bash
cwp email list                   # List mail domains
cwp email list domain.com        # List accounts for domain
cwp email create user@domain.com # Create email account
cwp email delete user@domain.com # Delete email account
cwp email forwarders domain.com  # List forwarders
cwp email queue                  # Show mail queue
cwp email flush                  # Flush mail queue
```

#### `cwp dns`
Manage DNS zones and records.

```bash
cwp dns list                     # List zones
cwp dns zone domain.com          # Show zone file
cwp dns add-record domain.com A @ 1.2.3.4  # Add record
cwp dns check domain.com         # Check DNS records
```

#### `cwp ssl`
Manage SSL certificates.

```bash
cwp ssl list                     # List certificates
cwp ssl info domain.com          # Certificate details
cwp ssl install domain.com       # Install Let's Encrypt SSL
cwp ssl renew                    # Renew certificates
cwp ssl check domain.com         # Check expiry
```

#### `cwp security`
Security management and scanning.

```bash
cwp security status              # Security overview
cwp security firewall list       # Firewall rules
cwp security firewall block IP   # Block IP address
cwp security ssh-hardening       # Apply SSH hardening
cwp security updates             # Check security updates
cwp security fail2ban status     # fail2ban status
```

#### `cwp backup`
Backup management.

```bash
cwp backup list                  # List backups
cwp backup create username       # Create backup
cwp backup restore username      # Restore from backup
cwp backup verify file.tar.gz    # Verify backup integrity
cwp backup cleanup 30            # Remove backups older than 30 days
cwp backup schedule username daily  # Schedule daily backups
```

#### `cwp service`
Service management.

```bash
cwp service list                 # List services and status
cwp service restart httpd        # Restart service
cwp service stop/start mysql     # Stop/start service
cwp service enable/disable nginx # Enable/disable at boot
cwp service logs httpd 100       # View last 100 log lines
```

#### `cwp php`
PHP version management.

```bash
cwp php list                     # List installed PHP versions
cwp php set username 8.2         # Set PHP version for user
cwp php info 8.2                 # PHP info for version
cwp php extensions 8.2           # List extensions
cwp php fpm-status               # PHP-FPM status
```

#### `cwp fix`
Fix common issues.

```bash
cwp fix auto                     # Run auto-fix diagnostics
cwp fix permissions username     # Fix file permissions
cwp fix ownership username       # Fix file ownership
cwp fix dns domain.com           # Rebuild DNS zone
cwp fix ssl domain.com           # Fix SSL certificate
cwp fix mail                     # Fix mail configuration
```

#### `cwp optimize`
Performance optimization.

```bash
cwp optimize all                 # Run all optimizations
cwp optimize mysql               # Optimize MySQL
cwp optimize php                 # Optimize PHP
cwp optimize apache              # Optimize Apache
cwp optimize nginx               # Optimize Nginx
cwp optimize opcache             # Reset OPcache
cwp optimize logs                # Clean old logs
```

#### `cwp migrate`
Server migration tools.

```bash
cwp migrate prepare username     # Prepare migration package
cwp migrate import username pkg  # Import migration
cwp migrate transfer username host  # Transfer to remote
```

#### `cwp logs`
View and search logs.

```bash
cwp logs tail access 100         # Tail access log
cwp logs tail error 50           # Tail error log
cwp logs search "404" access     # Search access log
cwp logs errors 2                # Errors from last 2 hours
```

## Scripts

### API Client

```bash
# Direct API calls
bash scripts/cwp-api-client.sh account list
bash scripts/cwp-api-client.sh database create mydb
bash scripts/cwp-api-client.sh email create user@domain.com
bash scripts/cwp-api-client.sh ssl letsencrypt domain.com
```

### Remote Execution

```bash
# Execute commands
bash scripts/cwp-remote-exec.sh 'systemctl status httpd'

# With sudo
bash scripts/cwp-remote-exec.sh --sudo 'yum update -y'

# Upload/download files
bash scripts/cwp-remote-exec.sh --upload ./file.txt /remote/path/
bash scripts/cwp-remote-exec.sh --download /remote/file ./local.txt

# Interactive shell
bash scripts/cwp-remote-exec.sh --shell
```

### Security Scanner

```bash
bash scripts/cwp-security-scan.sh --host 10.0.0.1
```

### Health Check

```bash
bash scripts/cwp-health-check.sh --host 10.0.0.1

# With notifications
bash scripts/cwp-health-check.sh --host 10.0.0.1 \
    --notify-email admin@example.com \
    --webhook https://hooks.slack.com/...
```

### Backup Verification

```bash
# Local backup
bash scripts/cwp-backup-verify.sh /backup/user_20260101.tar.gz

# Remote backup
bash scripts/cwp-backup-verify.sh --remote --host 10.0.0.1 /backup/file.tar.gz
```

## Templates

Configuration templates with placeholder variables (replace `{{VARIABLE}}` before use):

| Template | Description |
|----------|-------------|
| `templates/vhost-apache.tpl` | Apache vhost with PHP-FPM, security headers |
| `templates/vhost-nginx.tpl` | Nginx vhost with proxy to Apache |
| `templates/vhost-varnish.tpl` | Varnish caching config |
| `templates/dns-zone.tpl` | DNS zone with SOA, NS, A, MX, TXT, DKIM |
| `templates/backup-config.tpl` | Backup configuration with remote support |
| `templates/email-config.tpl` | Postfix + Dovecot + OpenDKIM config |
| `templates/php-fpm-pool.tpl` | PHP-FPM pool with ondemand PM |

## Examples

Working examples for common tasks:

```bash
# Install CWP on AlmaLinux 9
bash examples/install-cwp.sh

# Create hosting account
bash examples/create-account.sh example.com

# Setup email with DKIM/SPF
bash examples/setup-email.sh example.com

# Install SSL certificate
bash examples/configure-ssl.sh example.com

# Apply security hardening
bash examples/security-hardening.sh
```

## Testing

```bash
# CLI tests (no server required)
bash tests/test-cli.sh

# API tests (requires configured server)
bash tests/test-api.sh --host 10.0.0.1 --api-key KEY

# Integration tests (full workflow)
bash tests/test-integration.sh --host 10.0.0.1
```

## MCP Integration

This plugin includes MCP server configuration for AI-assisted server management. The MCP server exposes CWP operations as tools that can be used by AI assistants.

See `config.json` for MCP server configuration.

## Project Structure

```
cwp-pro-centos/
├── cli/                          # CLI tools
│   ├── cwp                       # Main CLI script
│   ├── cwp-completion.bash       # Bash completion
│   └── cwp-completion.zsh        # Zsh completion
├── scripts/                      # Utility scripts
│   ├── install.sh                # Installer
│   ├── uninstall.sh              # Uninstaller
│   ├── setup.sh                  # Setup wizard
│   ├── cwp-api-client.sh         # API client
│   ├── cwp-remote-exec.sh        # Remote execution
│   ├── cwp-backup-verify.sh      # Backup verification
│   ├── cwp-security-scan.sh      # Security scanner
│   └── cwp-health-check.sh       # Health monitoring
├── templates/                    # Config templates
│   ├── vhost-apache.tpl
│   ├── vhost-nginx.tpl
│   ├── vhost-varnish.tpl
│   ├── dns-zone.tpl
│   ├── backup-config.tpl
│   ├── email-config.tpl
│   └── php-fpm-pool.tpl
├── examples/                     # Working examples
│   ├── install-cwp.sh
│   ├── create-account.sh
│   ├── setup-email.sh
│   ├── configure-ssl.sh
│   └── security-hardening.sh
├── tests/                        # Test suite
│   ├── test-cli.sh
│   ├── test-api.sh
│   └── test-integration.sh
├── config.json                   # MCP configuration
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Support

- Issues: Report bugs and feature requests via GitHub Issues
- Documentation: See the `examples/` directory for working examples
- Security: Report security vulnerabilities privately to the maintainers
