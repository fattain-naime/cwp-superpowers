#!/bin/bash
# CSF Firewall Rules Example
# Common firewall configurations for CWP servers

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== CSF Firewall Rules Configuration ==="
echo ""

# Function to check if CSF is running
check_csf() {
    if ! command -v csf &> /dev/null; then
        echo -e "${RED}[ERROR]${NC} CSF not installed"
        exit 1
    fi
    
    if ! csf -s | grep -q "Firewall is running"; then
        echo -e "${RED}[ERROR]${NC} CSF not running"
        exit 1
    fi
}

# Function to whitelist an IP
whitelist_ip() {
    local ip="$1"
    local comment="$2"
    echo "Whitelisting $ip: $comment"
    csf -a "$ip" "$comment"
}

# Function to block an IP
block_ip() {
    local ip="$1"
    local comment="$2"
    echo "Blocking $ip: $comment"
    csf -d "$ip" "$comment"
}

# Function to temporarily block an IP
temp_block_ip() {
    local ip="$1"
    local duration="$2"  # in seconds
    local comment="$3"
    echo "Temporarily blocking $ip for $duration seconds: $comment"
    csf -td "$ip" "$duration" "$comment"
}

# Function to allow a port
allow_port() {
    local port="$1"
    local protocol="$2"  # tcp or udp
    echo "Allowing port $port/$protocol"
    
    if [ "$protocol" = "tcp" ]; then
        sed -i "s/^TCP_IN = .*/&,${port}/" /etc/csf/csf.conf
    else
        sed -i "s/^UDP_IN = .*/&,${port}/" /etc/csf/csf.conf
    fi
}

# Function to block a country
block_country() {
    local country_code="$1"
    echo "Blocking country: $country_code"
    
    # Add to /etc/csf/csf.blocklist
    echo "cc_${country_code}" >> /etc/csf/csf.blocklist
}

# Main menu
case "$1" in
    whitelist)
        if [ -z "$2" ]; then
            echo "Usage: $0 whitelist <ip> [comment]"
            exit 1
        fi
        check_csf
        whitelist_ip "$2" "${3:-Manual whitelist}"
        ;;
    
    block)
        if [ -z "$2" ]; then
            echo "Usage: $0 block <ip> [comment]"
            exit 1
        fi
        check_csf
        block_ip "$2" "${3:-Manual block}"
        ;;
    
    tempblock)
        if [ -z "$2" ]; then
            echo "Usage: $0 tempblock <ip> [duration_seconds] [comment]"
            exit 1
        fi
        check_csf
        temp_block_ip "$2" "${3:-3600}" "${4:-Temporary block}"
        ;;
    
    allowport)
        if [ -z "$2" ]; then
            echo "Usage: $0 allowport <port> [tcp|udp]"
            exit 1
        fi
        check_csf
        allow_port "$2" "${3:-tcp}"
        ;;
    
    blockcountry)
        if [ -z "$2" ]; then
            echo "Usage: $0 blockcountry <country_code>"
            echo "Example: $0 blockcountry cn"
            exit 1
        fi
        check_csf
        block_country "$2"
        ;;
    
    status)
        check_csf
        echo "=== CSF Status ==="
        csf -s
        echo ""
        echo "=== Temporary Blocks ==="
        csf -t
        ;;
    
    *)
        echo "CSF Firewall Rules Configuration"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  whitelist <ip> [comment]           - Whitelist an IP"
        echo "  block <ip> [comment]               - Block an IP permanently"
        echo "  tempblock <ip> [duration] [comment] - Temporarily block an IP"
        echo "  allowport <port> [tcp|udp]         - Allow a port"
        echo "  blockcountry <code>                - Block a country"
        echo "  status                             - Show CSF status"
        ;;
esac
