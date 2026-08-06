#!/bin/bash
# CWP API Example: Bulk Operations
# This script demonstrates batch operations on multiple accounts.

# Configuration
API_URL="https://SERVER_IP:2304/v1"
API_KEY="${CWP_API_KEY}"

if [ -z "$API_KEY" ]; then
    echo "Error: CWP_API_KEY environment variable not set"
    exit 1
fi

# Function to suspend an account
suspend_account() {
    local username="$1"
    local reason="$2"
    echo "Suspending $username: $reason"
    curl -s -X POST "$API_URL/account" \
        -d "key=$API_KEY" \
        -d "action=suspend" \
        -d "username=$username" \
        -d "reason=$reason"
}

# Function to unsuspend an account
unsuspend_account() {
    local username="$1"
    echo "Unsuspending $username"
    curl -s -X POST "$API_URL/account" \
        -d "key=$API_KEY" \
        -d "action=unsuspend" \
        -d "username=$username"
}

# Function to change package
change_package() {
    local username="$1"
    local package="$2"
    echo "Changing $username to package $package"
    curl -s -X POST "$API_URL/changepack" \
        -d "key=$API_KEY" \
        -d "username=$username" \
        -d "package=$package"
}

# Function to list all accounts
list_accounts() {
    echo "Listing all accounts..."
    curl -s -X POST "$API_URL/account" \
        -d "key=$API_KEY" \
        -d "action=list"
}

# Function to rebuild user vhosts
rebuild_user() {
    local username="$1"
    echo "Rebuilding vhosts for $username"
    /scripts/cwp_api webservers rebuild_user "$username"
}

# Main menu
case "$1" in
    list)
        list_accounts
        ;;
    suspend)
        if [ -z "$2" ]; then
            echo "Usage: $0 suspend <username> [reason]"
            exit 1
        fi
        suspend_account "$2" "${3:-Manual suspension}"
        ;;
    unsuspend)
        if [ -z "$2" ]; then
            echo "Usage: $0 unsuspend <username>"
            exit 1
        fi
        unsuspend_account "$2"
        ;;
    package)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo "Usage: $0 package <username> <package>"
            exit 1
        fi
        change_package "$2" "$3"
        ;;
    rebuild)
        if [ -z "$2" ]; then
            echo "Usage: $0 rebuild <username>"
            exit 1
        fi
        rebuild_user "$2"
        ;;
    *)
        echo "CWP API Bulk Operations"
        echo ""
        echo "Usage: $0 <command> [arguments]"
        echo ""
        echo "Commands:"
        echo "  list                    - List all accounts"
        echo "  suspend <user> [reason] - Suspend account"
        echo "  unsuspend <user>        - Unsuspend account"
        echo "  package <user> <pkg>    - Change package"
        echo "  rebuild <user>          - Rebuild user vhosts"
        ;;
esac
