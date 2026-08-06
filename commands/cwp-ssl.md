---
description: Manage SSL certificates on CWP (install, renew, list, hostname)
argument-hint: "<action> [domain]"
allowed-tools: Bash, Read, Write, Edit
---

# CWP SSL Management Command

You are managing SSL certificates on a CWP server. Determine the action from `$1` and execute accordingly.

## Arguments

- `$1` — Action: `install`, `renew`, `list`, `hostname`
- `$2` — Domain name (required for `install` and `renew`)

## Step 1: Validate Action

Confirm `$1` is one of: `install`, `renew`, `list`, `hostname`. If not, display usage and stop.

## Step 2: Check Prerequisites

- Confirm certbot is installed: `which certbot` or `which /usr/local/bin/certbot`. If missing, install via `yum install certbot` or the snap method.
- Confirm OpenSSL is available: `which openssl`.

## Step 3: Execute Action

### install
- Require domain in `$2`.
- Check if the domain resolves to this server: `dig +short $2` should match the server IP.
- Check if Apache or Nginx has a vhost for the domain.
- Run certbot: `certbot certonly --webroot -w /home/$2/public_html -d $2 -d www.$2 --non-interactive --agree-tos --email admin@$2`.
- If webroot fails, try standalone mode (temporarily stop the web server).
- After issuance, configure the web server to use the new certificate:
  - Update the Apache vhost SSL directives or Nginx ssl_certificate paths.
  - Set certificate paths: `/etc/letsencrypt/live/$2/fullchain.pem` and `/etc/letsencrypt/live/$2/privkey.pem`.
- Reload the web server.
- Verify: `echo | openssl s_client -connect $2:443 2>/dev/null | openssl x509 -noout -dates`.

### renew
- If `$2` is provided, renew for that specific domain: `certbot renew --cert-name $2`.
- If no domain, renew all: `certbot renew --quiet`.
- After renewal, reload Apache and Nginx to pick up new certificates.
- Check for errors in the certbot output.

### list
- List all certificates managed by certbot: `certbot certificates`.
- List any custom certificates in `/etc/ssl/certs/` and `/etc/pki/tls/certs/`.
- For each certificate, show: domain, issuer, expiry date, days remaining.
- Flag any certificates expiring within 30 days.

### hostname
- Check the current SSL certificate for the server hostname (CWP panel).
- The hostname certificate is typically at `/etc/ssl/certs/hostname.crt` and `/etc/ssl/private/hostname.key`.
- Display the current certificate details: subject, issuer, validity dates.
- If the hostname SSL needs renewal, run certbot for the server FQDN.
- Update CWP panel configuration to use the new certificate.
- Restart `cwpsrv`.

## Step 4: Post-Action Verification

- For install and renew actions, verify the certificate is valid and accessible on port 443.
- Check the certificate chain: `openssl verify -CAfile /etc/letsencrypt/live/$2/chain.pem /etc/letsencrypt/live/$2/cert.pem`.
- Log all SSL actions to `/var/log/cwp/ssl-actions.log`.
