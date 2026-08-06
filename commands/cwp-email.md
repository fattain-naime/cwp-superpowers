---
description: Manage email accounts on CWP (create, delete, list, forwarder, rebuild)
argument-hint: "<action> [options]"
allowed-tools: Bash, Read, Write
---

# CWP Email Management Command

You are managing email on a CWP server. Determine the action from `$1` and execute accordingly.

## Arguments

- `$1` — Action: `create`, `delete`, `list`, `forwarder`, `rebuild`
- `$2` — Email address or domain (varies by action)
- `$3` — Additional options (e.g., password, quota, forward target)

## Step 1: Validate Email Services

- Confirm Postfix is running: `systemctl is-active postfix`.
- Confirm Dovecot is running: `systemctl is-active dovecot`.
- If either is down, attempt to start it and report the result.

## Step 2: Validate Action

Confirm `$1` is one of the supported actions. If not, display usage and stop.

## Step 3: Execute Action

### create
- Require full email address in `$2` (e.g., `user@domain.com`).
- Extract username and domain from the email address.
- Validate the domain exists in CWP: check `/etc/postfix/virtual_domains` or the CWP user's domain list.
- Require password in `$3` or generate a random 12-character password.
- Create the mailbox: add entry to `/etc/postfix/virtual_users` and set quota if applicable.
- Create the maildir: `mkdir -p /var/vmail/<domain>/<username>`.
- Set ownership: `chown -R vmail:vmail /var/vmail/<domain>/<username>`.
- Reload Postfix: `postfix reload`.
- Display the email address, password, and IMAP/POP3/SMTP settings.

### delete
- Require full email address in `$2`.
- Confirm the account exists.
- Remove entries from `/etc/postfix/virtual_users` and `/etc/postfix/virtual`.
- Remove the maildir: `rm -rf /var/vmail/<domain>/<username>`.
- Reload Postfix.

### list
- Require domain in `$2`, or list all if not provided.
- Parse `/etc/postfix/virtual_users` for matching accounts.
- Display: Email Address, Quota, Disk Usage.
- For each account, calculate disk usage: `du -sh /var/vmail/<domain>/<username>`.

### forwarder
- Sub-action determined by `$2`:
  - If `$2` is an email address, list forwarders for that address.
  - If `$3` is provided, create a forwarder from `$2` to `$3`.
- Manage forwarders in `/etc/postfix/virtual`.
- Reload Postfix after changes.

### rebuild
- Require domain in `$2`.
- Rebuild the Postfix virtual maps: `postmap /etc/postfix/virtual_users`.
- Rebuild the virtual domains: `postmap /etc/postfix/virtual_domains`.
- Reload Postfix.
- Verify mail directories exist for each account in the domain.

## Step 4: Verify

After any modification, verify the change took effect:
- For create/delete: confirm the entry exists/does not exist in the relevant file.
- For forwarder: test with `postmap -q <address> /etc/postfix/virtual`.
- Log the action to `/var/log/cwp/email-actions.log`.
