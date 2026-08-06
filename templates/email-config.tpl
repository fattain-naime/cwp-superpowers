# =============================================================================
# Email Server Configuration Template for CWP
# =============================================================================
# Variables (replace before use):
#   {{DOMAIN}}       - Primary domain
#   {{HOSTNAME}}     - Server hostname (e.g., mail.example.com)
#   {{IPV4}}         - Server IPv4 address
#   {{IPV6}}         - Server IPv6 address (optional)
# =============================================================================
# This template covers Postfix (SMTP) and Dovecot (IMAP/POP3) configuration
# for CWP servers with proper security and spam protection.
# =============================================================================

# // =========================================================================
# // POSTFIX MAIN.CF
# // Place at: /etc/postfix/main.cf
# // =========================================================================

# --- General Settings ---
smtpd_banner = $myhostname ESMTP
biff = no
append_dot_mydomain = no
readme_directory = no
compatibility_level = 2

# --- Hostname and Domain ---
myhostname = {{HOSTNAME}}
mydomain = {{DOMAIN}}
myorigin = $mydomain
mydestination = $myhostname, $mydomain, localhost.$mydomain, localhost
mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128

# --- Mailbox Settings ---
home_mailbox = Maildir/
mailbox_command =
mailbox_size_limit = 0
message_size_limit = 52428800
recipient_delimiter = +

# --- Network Settings ---
inet_interfaces = all
inet_protocols = all

# --- TLS Settings (Incoming) ---
smtpd_tls_cert_file = /etc/pki/tls/certs/{{HOSTNAME}}.pem
smtpd_tls_key_file = /etc/pki/tls/private/{{HOSTNAME}}.pem
smtpd_tls_security_level = may
smtpd_tls_auth_only = yes
smtpd_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtpd_tls_mandatory_ciphers = high
smtpd_tls_ciphers = high
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtpd_tls_received_header = yes

# --- TLS Settings (Outgoing) ---
smtp_tls_security_level = may
smtp_tls_mandatory_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_protocols = !SSLv2, !SSLv3, !TLSv1, !TLSv1.1
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

# --- SASL Authentication ---
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous, noplaintext
smtpd_sasl_tls_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname

# --- SMTP Restrictions ---
smtpd_helo_required = yes
smtpd_helo_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_invalid_helo_hostname,
    reject_non_fqdn_helo_hostname

smtpd_sender_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_non_fqdn_sender,
    reject_unknown_sender_domain

smtpd_recipient_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unauth_destination,
    reject_non_fqdn_recipient,
    reject_unknown_recipient_domain,
    reject_rbl_client zen.spamhaus.org,
    reject_rbl_client bl.spamcop.net,
    reject_rbl_client b.barracudacentral.org

smtpd_relay_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    defer_unauth_destination

# --- Anti-Spam Settings ---
smtpd_client_restrictions =
    permit_mynetworks,
    permit_sasl_authenticated,
    reject_unknown_client_hostname

# Rate limiting
smtpd_client_connection_rate_limit = 50
smtpd_client_message_rate_limit = 100

# --- Content Filtering ---
# content_filter = smtp-amavis:[127.0.0.1]:10024

# --- Virtual Mailbox Maps ---
virtual_mailbox_domains = proxy:mysql:/etc/postfix/mysql-virtual_domains.cf
virtual_mailbox_maps = proxy:mysql:/etc/postfix/mysql-virtual_mailboxes.cf
virtual_alias_maps = proxy:mysql:/etc/postfix/mysql-virtual_alias.cf
virtual_uid_maps = static:1000
virtual_gid_maps = static:1000
virtual_transport = dovecot

# --- Logging ---
maillog_file = /var/log/maillog

# =========================================================================
# DOVECOT CONF
# Place at: /etc/dovecot/dovecot.conf
# =========================================================================

protocols = imap pop3 lmtp
listen = *, ::

# --- Mail Location ---
mail_location = maildir:~/Maildir
mail_privileged_group = mail

# --- Authentication ---
auth_mechanisms = plain login

# --- SSL Configuration ---
ssl = required
ssl_cert = </etc/pki/tls/certs/{{HOSTNAME}}.pem
ssl_key = </etc/pki/tls/private/{{HOSTNAME}}.pem
ssl_min_protocol = TLSv1.2
ssl_cipher_list = HIGH:!aNULL:!MD5:!3DES:!RC4
ssl_prefer_server_ciphers = yes

# --- User Database ---
userdb {
    driver = passwd
}

passdb {
    driver = pam
}

# --- Service Configuration ---
service imap-login {
    inet_listener imap {
        port = 143
    }
    inet_listener imaps {
        port = 993
    }
}

service pop3-login {
    inet_listener pop3 {
        port = 110
    }
    inet_listener pop3s {
        port = 995
    }
}

service lmtp {
    unix_listener /var/spool/postfix/private/dovecot-lmtp {
        mode = 0600
        user = postfix
        group = postfix
    }
}

service auth {
    unix_listener /var/spool/postfix/private/auth {
        mode = 0660
        user = postfix
        group = postfix
    }
}

# --- Mailbox Settings ---
namespace inbox {
    mailbox Drafts {
        special_use = \Drafts
        auto = subscribe
    }
    mailbox Junk {
        special_use = \Junk
        auto = subscribe
    }
    mailbox Trash {
        special_use = \Trash
        auto = subscribe
    }
    mailbox Sent {
        special_use = \Sent
        auto = subscribe
    }
    mailbox "Sent Messages" {
        special_use = \Sent
    }
}

# --- Limits ---
mail_max_userip_connections = 50
mail_fsync = always

# --- Logging ---
log_path = /var/log/dovecot.log
auth_verbose = yes
auth_verbose_passwords = no

# =========================================================================
# OPENDKIM CONFIGURATION
# Place at: /etc/opendkim.conf
# =========================================================================

AutoRestart yes
AutoRestartRate 10/1h
Syslog yes
SyslogSuccess yes
LogWhy yes
Canonicalization relaxed/simple
ExternalIgnoreList refile:/etc/opendkim/TrustedHosts
InternalHosts refile:/etc/opendkim/TrustedHosts
KeyTable refile:/etc/opendkim/KeyTable
SigningTable refile:/etc/opendkim/SigningTable
Mode sv
PidFile /run/opendkim/opendkim.pid
SignatureAlgorithm rsa-sha256
UserID opendkim:opendkim
Socket inet:8891@localhost

# =========================================================================
# SPF / DKIM / DMARC Summary
# =========================================================================
# SPF:   v=spf1 +a +mx +ip4:{{IPV4}} ~all
# DKIM:  default._domainkey  v=DKIM1; k=rsa; p=<YOUR_KEY>
# DMARC: _dmarc  v=DMARC1; p=quarantine; rua=mailto:dmarc@{{DOMAIN}}
# =========================================================================
