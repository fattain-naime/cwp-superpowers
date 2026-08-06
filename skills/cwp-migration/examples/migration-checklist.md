# CWP Migration Checklist

Use this checklist when migrating accounts to CWP.

## Pre-Migration (24-48 hours before)

- [ ] Reduce DNS TTL to 300 seconds
- [ ] Verify destination server has sufficient resources
- [ ] Test SSH connectivity between servers
- [ ] Create full backup of source server
- [ ] Document all accounts, databases, and email accounts
- [ ] Notify affected users of planned migration window
- [ ] Verify CWP is up to date on destination

## Source Server Preparation

- [ ] Create cPanel backup: `/scripts/pkgacct USERNAME`
- [ ] Export all databases: `mysqldump --all-databases > all_dbs.sql`
- [ ] Backup DNS zones
- [ ] Document custom configurations
- [ ] Note PHP versions and extensions per account
- [ ] List SSL certificates and expiry dates

## Migration Execution

### Account Transfer
- [ ] Transfer backup files to CWP server
- [ ] Extract backups in `/home/USERNAME/`
- [ ] Restore account via CWP Admin or API
- [ ] Verify file ownership and permissions

### Database Restoration
- [ ] Import databases via phpMyAdmin or CLI
- [ ] Create database users and grant privileges
- [ ] Verify database connectivity

### Email Migration
- [ ] Transfer email data (`/var/vmail/`)
- [ ] Verify email accounts exist
- [ ] Test email delivery

### DNS Configuration
- [ ] Add DNS zones in CWP
- [ ] Verify MX records
- [ ] Verify SPF, DKIM, DMARC records
- [ ] Update nameservers (if applicable)

### SSL Certificates
- [ ] Enable AutoSSL for all domains
- [ ] Or transfer existing certificates
- [ ] Verify HTTPS works correctly

## Post-Migration Verification

### Per-Account Checks
- [ ] Website loads correctly
- [ ] Database connections work
- [ ] Email sends and receives
- [ ] DNS resolves correctly
- [ ] SSL certificate valid
- [ ] Cron jobs configured
- [ ] FTP/SFTP access works

### Server-Level Checks
- [ ] All services running (Apache, Nginx, MariaDB, Postfix)
- [ ] Firewall rules configured
- [ ] Backups configured
- [ ] Monitoring active
- [ ] Logs being written

## DNS Cutover

- [ ] Update DNS records to point to new server
- [ ] Update nameservers at registrar
- [ ] Monitor DNS propagation
- [ ] Keep old server running for 48-72 hours

## Post-Migration Cleanup

- [ ] Verify all accounts migrated successfully
- [ ] Update DNS TTL back to normal (3600+)
- [ ] Monitor for issues during propagation period
- [ ] Decommission old server after verification period
- [ ] Document migration for future reference

## Rollback Plan

If critical issues arise:

1. Revert DNS records to old server
2. Restore from backup if needed
3. Notify users of rollback
4. Investigate and resolve issues
5. Re-attempt migration with fixes
