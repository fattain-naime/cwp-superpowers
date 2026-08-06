---
description: Manage DNS zones and records on CWP (add-zone, delete-zone, add-record, delete-record, list, setup-ns)
argument-hint: "<action> [options]"
allowed-tools: Bash, Read, Write, Edit
---

# CWP DNS Management Command

You are managing DNS on a CWP server. Determine the action from `$1` and execute accordingly.

## Arguments

- `$1` — Action: `add-zone`, `delete-zone`, `add-record`, `delete-record`, `list`, `setup-ns`
- `$2` — Domain name or record details
- `$3` and beyond — Additional options (record type, value, TTL, priority)

## Step 1: Validate DNS Service

- Confirm BIND/named is running: `systemctl is-active named`.
- If not, attempt to start it. If it fails, check `/var/log/messages` for BIND errors.
- Confirm the zone directory exists: `ls /var/named/`.

## Step 2: Validate Action

Confirm `$1` is one of the supported actions. If not, display usage and stop.

## Step 3: Execute Action

### add-zone
- Require domain in `$2`.
- Confirm the zone does not already exist: test for `/var/named/$2.db`.
- Create the zone file from the CWP default template or generate a basic zone:
  - SOA record with the server hostname as primary NS.
  - NS records pointing to the configured nameservers.
  - A record for the domain pointing to the server IP.
  - MX record pointing to the domain.
- Add the zone to `/etc/named.conf` with a `zone` block.
- Run `named-checkzone $2 /var/named/$2.db` to validate.
- Reload BIND: `systemctl reload named`.

### delete-zone
- Require domain in `$2`.
- Confirm the zone exists.
- Remove the zone file: `rm /var/named/$2.db`.
- Remove the zone block from `/etc/named.conf`.
- Reload BIND.

### add-record
- Require domain in `$2`, record name in `$3`, type in `$4`, value in `$5`.
- Optional: TTL in `$6`, priority in `$7` (for MX records).
- Supported types: A, AAAA, CNAME, MX, TXT, NS, SRV.
- Add the record to `/var/named/$2.db` in the correct format.
- Increment the serial number in the SOA record.
- Validate: `named-checkzone $2 /var/named/$2.db`.
- Reload BIND.

### delete-record
- Require domain in `$2`, record name in `$3`, type in `$4`.
- Find and remove matching lines from `/var/named/$2.db`.
- Increment the SOA serial.
- Validate and reload.

### list
- If `$2` is provided, list all records for that domain from `/var/named/$2.db`.
- If no domain, list all zones: `ls /var/named/*.db | xargs -I{} basename {} .db`.
- Format records in a readable table.

### setup-ns
- Require domain in `$2` and nameserver IPs/names in `$3` and `$4`.
- Add NS records to the zone file.
- Add glue A records for the nameservers.
- Increment serial, validate, and reload.
- Remind the user to register the nameservers at the domain registrar.

## Step 4: Verify

After any change, verify DNS resolution:
- `dig @localhost $2 <type>` for the affected domain.
- Report the result and log the action to `/var/log/cwp/dns-actions.log`.
