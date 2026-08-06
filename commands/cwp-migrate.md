---
description: Migrate accounts to CWP from cPanel, other CWP servers, or Webuzo
argument-hint: "<source> [options]"
allowed-tools: Bash, Read, Write, Edit
---

# CWP Migration Command

You are migrating accounts to CWP from another control panel or server. Determine the source from `$1` and execute the appropriate migration workflow.

## Arguments

- `$1` — Source type: `cpanel-single`, `cpanel-full`, `cwp`, `webuzo`
- `$2` — Source details (IP, backup file path, or account name)
- `$3` and beyond — Additional options (credentials, specific accounts)

## Step 1: Validate Source Type

Confirm `$1` is one of: `cpanel-single`, `cpanel-full`, `cwp`, `webuzo`. If not, display usage and stop.

## Step 2: Pre-Migration Checks

- Confirm CWP is installed and running on this server.
- Check available disk space: ensure at least 2x the expected migration size is free.
- Confirm network connectivity to the source server (if remote): `ping -c 3 $2`.
- Check that required migration tools are available (rsync, scp, tar, mysql).

## Step 3: Execute Migration

### cpanel-single
- Migrate a single cPanel account from a cPanel backup file.
- `$2` should be the path to the cPanel backup `.tar.gz` file.
- If `$2` is a remote path, download it first: `scp user@source:$2 /tmp/`.
- Extract the backup: `tar xzf $2 -C /tmp/migration/`.
- Parse the backup metadata to get the account username, domain, databases, and email accounts.
- Create the user in CWP if it does not exist.
- Import website files to `/home/<username>/public_html/`.
- Import databases: find SQL dumps and restore them with `mysql`.
- Import email accounts and forwarders.
- Import DNS zones.
- Set correct ownership: `chown -R <username>:<username> /home/<username>/`.
- Generate a migration report.

### cpanel-full
- Migrate all accounts from a cPanel server.
- `$2` should be the source server IP.
- `$3` should be the SSH password or key path for root access.
- Connect to the source server via SSH.
- List all cPanel accounts: `whmapi1 listaccts | grep user`.
- For each account, create a cPanel backup remotely: `/scripts/pkgacct <user>`.
- Download each backup to `/tmp/migration/`.
- Process each backup using the `cpanel-single` workflow.
- Generate a summary report with success/failure per account.

### cwp
- Migrate accounts from another CWP server.
- `$2` should be the source server IP.
- `$3` should be the root password or SSH key.
- Connect via SSH and list CWP users from `/etc/passwd`.
- For each user, create a backup using CWP's backup scripts.
- Download backups and restore them locally.
- Alternatively, use rsync for direct transfer of home directories and databases.

### webuzo
- Migrate accounts from a Webuzo server.
- `$2` should be the path to a Webuzo backup file or the source server IP.
- Extract the backup and parse the structure.
- Map Webuzo components to CWP equivalents (files, databases, email).
- Import using the same approach as cpanel-single.

## Step 4: Post-Migration

- Verify each migrated account:
  - Check that the website loads.
  - Verify database connectivity.
  - Test email delivery.
- Update DNS if needed (point domains to the new server IP).
- Generate a final migration report with status per account.
- Log all actions to `/var/log/cwp/migration.log`.
