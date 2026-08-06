---
description: Manage CWP user accounts (create, delete, suspend, unsuspend, list, info)
argument-hint: "<action> <username> [options]"
allowed-tools: Bash, Read, Write
---

# CWP User Management Command

You are managing CWP user accounts. Determine the action from `$1` and execute the corresponding workflow.

## Arguments

- `$1` — Action: `create`, `delete`, `suspend`, `unsuspend`, `list`, `info`
- `$2` — Username (required for all actions except `list`)
- `$3` — Additional options (e.g., password, package, email)

## Step 1: Validate Action

Confirm `$1` is one of: `create`, `delete`, `suspend`, `unsuspend`, `list`, `info`. If not, display usage and stop.

## Step 2: Validate Username

For actions requiring a username (`create`, `delete`, `suspend`, `unsuspend`, `info`):
- Confirm `$2` is provided.
- Username must be 6-8 lowercase alphanumeric characters only.
- Reject usernames with special characters, uppercase letters, or spaces.
- For `create`: confirm the user does not already exist in `/etc/passwd`.
- For `delete`, `suspend`, `unsuspend`, `info`: confirm the user exists.

## Step 3: Execute Action

### create
- Require a password in `$3` or generate a random 16-character password.
- Run `/scripts/create_user $2 <password>` or use the CWP API.
- Optionally assign a hosting package if provided.
- Display the created username, password, and home directory.

### delete
- Warn the user this will remove all data for `$2`.
- Confirm by asking "Are you sure? Type the username to confirm."
- After confirmation, run `/scripts/delete_user $2`.
- Verify removal from `/etc/passwd`.

### suspend
- Run `/scripts/suspend_user $2` or touch `/var/cwp_users/$2/suspended`.
- Confirm suspension with a timestamp.

### unsuspend
- Run `/scripts/unsuspend_user $2` or remove `/var/cwp_users/$2/suspended`.
- Confirm the account is active.

### list
- List all CWP users: `awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd`.
- For each user, check if suspended: test for `/var/cwp_users/<user>/suspended`.
- Display in a formatted table: Username, Status, Home Directory, UID.

### info
- Display user details: home directory, shell, UID, GID, disk usage.
- Check quota: `repquota -u $2 2>/dev/null` or `quota -u $2`.
- List domains assigned to the user from `/var/cwp_users/$2/domains` if it exists.
- Check suspension status.

## Step 4: Confirm and Log

After any modification action (create, delete, suspend, unsuspend), log the action to `/var/log/cwp/user-actions.log` with a timestamp.
