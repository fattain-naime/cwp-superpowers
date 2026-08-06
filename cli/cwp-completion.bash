#!/usr/bin/env bash
# =============================================================================
# Bash completion for CWP CLI
# =============================================================================
# Source this file or copy to /etc/bash_completion.d/cwp
# Usage: . cwp-completion.bash
# =============================================================================

_cwp_complete() {
    local cur prev commands
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    commands="status user database email dns ssl security backup service php fix optimize migrate logs setup"

    # Global options
    local global_opts="--host --api-key --api-port --ssh-user --ssh-port --ssh-key --output --verbose --help --version"

    # Subcommands for each command
    local user_subs="list info add delete suspend unsuspend password"
    local database_subs="list create delete user-add backup restore size"
    local email_subs="list create delete forwarders queue flush"
    local dns_subs="list zone add-record check"
    local ssl_subs="list info install renew check"
    local security_subs="status firewall ssh-hardening updates fail2ban"
    local backup_subs="list create restore verify cleanup schedule"
    local service_subs="list restart stop start enable disable logs"
    local php_subs="list set info ini extensions fpm-status"
    local fix_subs="auto permissions ownership dns ssl mail"
    local optimize_subs="all mysql php apache nginx opcache logs"
    local migrate_subs="prepare import transfer"
    local logs_subs="tail search errors"

    # Determine which command we're completing for
    local cmd=""
    local subcmd=""
    local i
    for ((i=1; i < COMP_CWORD; i++)); do
        local word="${COMP_WORDS[i]}"
        case "$word" in
            --host|--api-key|--api-port|--ssh-user|--ssh-port|--ssh-key|--output)
                ((i++))  # skip the value
                continue
                ;;
            --verbose|--help|--version)
                continue
                ;;
            -*)
                continue
                ;;
            *)
                if [[ -z "$cmd" ]]; then
                    cmd="$word"
                elif [[ -z "$subcmd" ]]; then
                    subcmd="$word"
                fi
                ;;
        esac
    done

    # Complete based on position
    if [[ "$prev" == "--host" || "$prev" == "--api-key" || "$prev" == "--api-port" || \
          "$prev" == "--ssh-user" || "$prev" == "--ssh-port" || "$prev" == "--ssh-key" ]]; then
        return 0
    fi

    if [[ "$prev" == "--output" ]]; then
        COMPREPLY=( $(compgen -W "text json" -- "$cur") )
        return 0
    fi

    # No command yet - complete commands and global options
    if [[ -z "$cmd" ]]; then
        COMPREPLY=( $(compgen -W "$commands $global_opts" -- "$cur") )
        return 0
    fi

    # Command given, complete subcommands
    case "$cmd" in
        user)       COMPREPLY=( $(compgen -W "$user_subs" -- "$cur") ) ;;
        database)   COMPREPLY=( $(compgen -W "$database_subs" -- "$cur") ) ;;
        email)      COMPREPLY=( $(compgen -W "$email_subs" -- "$cur") ) ;;
        dns)        COMPREPLY=( $(compgen -W "$dns_subs" -- "$cur") ) ;;
        ssl)        COMPREPLY=( $(compgen -W "$ssl_subs" -- "$cur") ) ;;
        security)
            if [[ -z "$subcmd" ]]; then
                COMPREPLY=( $(compgen -W "$security_subs" -- "$cur") )
            elif [[ "$subcmd" == "firewall" ]]; then
                COMPREPLY=( $(compgen -W "list block unblock" -- "$cur") )
            elif [[ "$subcmd" == "fail2ban" ]]; then
                COMPREPLY=( $(compgen -W "status restart" -- "$cur") )
            fi
            ;;
        backup)     COMPREPLY=( $(compgen -W "$backup_subs" -- "$cur") ) ;;
        service)    COMPREPLY=( $(compgen -W "$service_subs" -- "$cur") ) ;;
        php)        COMPREPLY=( $(compgen -W "$php_subs" -- "$cur") ) ;;
        fix)        COMPREPLY=( $(compgen -W "$fix_subs" -- "$cur") ) ;;
        optimize)   COMPREPLY=( $(compgen -W "$optimize_subs" -- "$cur") ) ;;
        migrate)    COMPREPLY=( $(compgen -W "$migrate_subs" -- "$cur") ) ;;
        logs)       COMPREPLY=( $(compgen -W "$logs_subs" -- "$cur") ) ;;
        status)     COMPREPLY=() ;;
        setup)      COMPREPLY=() ;;
        *)
            COMPREPLY=( $(compgen -W "$global_opts" -- "$cur") )
            ;;
    esac

    return 0
}

complete -F _cwp_complete cwp
