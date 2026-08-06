---
description: Install CWP (Control Web Panel) on a fresh CentOS/AlmaLinux/Rocky server
argument-hint: <os-version> <hostname> <ip-address>
allowed-tools: Bash, Read, Write, Edit
---

# CWP Installation Command

You are performing a fresh CWP installation on a server. Follow every step in order. Do not skip validation steps.

## Arguments

- `$1` — OS version (e.g., `centos7`, `almalinux8`, `almalinux9`, `rocky8`, `rocky9`)
- `$2` — Hostname (e.g., `server.example.com`)
- `$3` — Server IP address (e.g., `192.168.1.10`)

## Step 1: Validate Arguments

- Confirm `$1` is provided and matches a supported OS: `centos7`, `almalinux8`, `almalinux9`, `rocky8`, `rocky9`.
- Confirm `$2` is a valid FQDN containing at least one dot.
- Confirm `$3` is a valid IPv4 address.
- If any argument is missing or invalid, display usage: `Usage: /cwp-install <os-version> <hostname> <ip-address>` and stop.

## Step 2: Verify Fresh Server

- Run `rpm -q cwp` to confirm CWP is not already installed. If it returns a version, warn the user and stop.
- Check the OS version with `cat /etc/os-release` and confirm it matches `$1`.
- Confirm the server has at least 1 GB RAM and 10 GB free disk space.

## Step 3: Set Hostname

- Run `hostnamectl set-hostname $2`.
- Add the hostname to `/etc/hosts` with the format `$3 $2 $(echo $2 | cut -d. -f1)`.

## Step 4: Install Prerequisites

- Update all packages: `yum update -y` (CentOS 7) or `dnf update -y` (AlmaLinux/Rocky).
- Install required packages: `wget`, `perl`, `curl`, `net-tools`.
- Disable SELinux: set `SELINUX=disabled` in `/etc/selinux/config` and run `setenforce 0`.

## Step 5: Download and Run CWP Installer

- Download the installer:
  - CentOS 7: `wget http://centos-webpanel.com/cwp-el7-latest`
  - AlmaLinux/Rocky 8: `wget http://centos-webpanel.com/cwp-el8-latest`
  - AlmaLinux/Rocky 9: `wget http://centos-webpanel.com/cwp-el9-latest`
- Run the installer: `sh cwp-el*-latest`. This will take 15-30 minutes.
- Monitor output for errors. If the installer exits non-zero, report the last 20 lines and stop.

## Step 6: Display Results

- After installation completes, read the credentials file at `/root/.cwp_post` if it exists.
- Display:
  - CWP admin URL: `https://$3:2031`
  - MySQL root password (from the credentials file)
  - Admin password (from the credentials file)
- Remind the user to reboot the server: `reboot`.
- Warn: Change all default passwords immediately after first login.
