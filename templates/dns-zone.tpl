; =============================================================================
; DNS Zone Template
; =============================================================================
; Variables (replace before use):
;   {{DOMAIN}}       - Domain name (e.g., example.com)
;   {{SERIAL}}       - Zone serial (YYYYMMDDNN format)
;   {{NS1}}          - Primary nameserver
;   {{NS2}}          - Secondary nameserver
;   {{ADMIN_EMAIL}}  - Admin email (dot-encoded, e.g., admin.example.com)
;   {{IPV4}}         - Primary IPv4 address
;   {{IPV6}}         - Primary IPv6 address (optional)
;   {{MX_HOST}}      - Mail server hostname
;   {{DKIM_SELECTOR}} - DKIM selector (e.g., default)
;   {{DKIM_KEY}}     - DKIM public key
; =============================================================================
; Place at: /var/named/{{DOMAIN}}.db
; Restart: systemctl reload named
; =============================================================================

$TTL 14400
@   IN  SOA {{NS1}}. {{ADMIN_EMAIL}}. (
        {{SERIAL}}  ; Serial number (YYYYMMDDNN)
        3600        ; Refresh (1 hour)
        1800        ; Retry (30 minutes)
        1209600     ; Expire (2 weeks)
        86400       ; Minimum TTL (1 day)
)

; --- Nameservers ---
@           IN  NS      {{NS1}}.
@           IN  NS      {{NS2}}.

; --- A Records ---
@           IN  A       {{IPV4}}
www         IN  A       {{IPV4}}
mail        IN  A       {{IPV4}}
smtp        IN  A       {{IPV4}}
pop         IN  A       {{IPV4}}
imap        IN  A       {{IPV4}}
ftp         IN  A       {{IPV4}}
cpanel      IN  A       {{IPV4}}
webmail     IN  A       {{IPV4}}
ns1         IN  A       {{IPV4}}
ns2         IN  A       {{IPV4}}

; --- AAAA Records (IPv6) ---
; @           IN  AAAA    {{IPV6}}
; www         IN  AAAA    {{IPV6}}

; --- MX Records ---
@           IN  MX  10  mail.{{DOMAIN}}.
@           IN  MX  20  {{MX_HOST}}.

; --- CNAME Records ---
; autodiscover    IN  CNAME   mail.{{DOMAIN}}.
; autoconfig      IN  CNAME   mail.{{DOMAIN}}.
; cpcalendars     IN  CNAME   {{DOMAIN}}.
; cpcontacts      IN  CNAME   {{DOMAIN}}.

; --- TXT Records ---

; SPF Record
@           IN  TXT     "v=spf1 +a +mx +ip4:{{IPV4}} ~all"

; DKIM Record
{{DKIM_SELECTOR}}._domainkey  IN  TXT     "v=DKIM1; k=rsa; p={{DKIM_KEY}}"

; DMARC Record
_dmarc      IN  TXT     "v=DMARC1; p=quarantine; rua=mailto:dmarc@{{DOMAIN}}; ruf=mailto:dmarc@{{DOMAIN}}; fo=1; adkim=r; aspf=r"

; Domain Verification (uncomment as needed)
; @           IN  TXT     "google-site-verification=YOUR_VERIFICATION_CODE"
; @           IN  TXT     "v=verify1; verification=YOUR_VERIFICATION_CODE"

; --- SRV Records (uncomment as needed) ---
; _sip._tcp       IN  SRV 10 60 5060 sip.{{DOMAIN}}.
; _sip._udp       IN  SRV 10 60 5060 sip.{{DOMAIN}}.
; _xmpp-client._tcp   IN  SRV 5 0 5222 xmpp.{{DOMAIN}}.
; _xmpp-server._tcp   IN  SRV 5 0 5269 xmpp.{{DOMAIN}}.

; --- CAA Records (Certificate Authority Authorization) ---
; @           IN  CAA 0   issue "letsencrypt.org"
; @           IN  CAA 0   issuewild "letsencrypt.org"
; @           IN  CAA 0   iodef "mailto:security@{{DOMAIN}}"
