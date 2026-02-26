#!/bin/bash
# Mole - Linux/WSL optimize command.
# Applies safe maintenance tasks by distro and runtime.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/core/common.sh"
source "$SCRIPT_DIR/../lib/manage/whitelist.sh"

DRY_RUN=false
ACTIONS_DONE=0
ACTIONS_SKIPPED=0
SUDO_AVAILABLE="unknown"

mem_gb() {
    local key="$1"
    local kb
    kb=$(awk -v k="$key" '$1==k":" {print $2; exit}' /proc/meminfo 2> /dev/null || echo "0")
    [[ "$kb" =~ ^[0-9]+$ ]] || kb=0
    awk "BEGIN {printf \"%.1f\", $kb/1024/1024}"
}

uptime_days() {
    local up
    up=$(awk '{print $1}' /proc/uptime 2> /dev/null || echo "0")
    awk "BEGIN {printf \"%.1f\", $up/86400}"
}

run_root_task() {
    local task_id="$1"
    local label="$2"
    shift 2

    if is_whitelisted "$task_id"; then
        echo -e "  ${GRAY}${ICON_WARNING}${NC} Skipped (whitelist): $label"
        ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}${ICON_DRY_RUN}${NC} Would run: $label"
        ACTIONS_DONE=$((ACTIONS_DONE + 1))
        return 0
    fi

    if [[ "$(id -u)" == "0" ]]; then
        if "$@" > /dev/null 2>&1; then
            echo -e "  ${GREEN}${ICON_SUCCESS}${NC} $label"
            ACTIONS_DONE=$((ACTIONS_DONE + 1))
        else
            echo -e "  ${GRAY}${ICON_WARNING}${NC} Failed: $label"
            ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
        fi
        return 0
    fi

    if [[ "$SUDO_AVAILABLE" == "unknown" ]]; then
        if sudo -n true 2> /dev/null; then
            SUDO_AVAILABLE="yes"
        elif [[ -t 0 ]]; then
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Admin access requested for maintenance tasks..."
            if sudo -v 2> /dev/null; then
                SUDO_AVAILABLE="yes"
            else
                SUDO_AVAILABLE="no"
            fi
        else
            SUDO_AVAILABLE="no"
        fi
    fi

    if [[ "$SUDO_AVAILABLE" == "yes" ]]; then
        if sudo "$@" > /dev/null 2>&1; then
            echo -e "  ${GREEN}${ICON_SUCCESS}${NC} $label"
            ACTIONS_DONE=$((ACTIONS_DONE + 1))
        else
            echo -e "  ${GRAY}${ICON_WARNING}${NC} Failed: $label"
            ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
        fi
    else
        echo -e "  ${GRAY}${ICON_REVIEW}${NC} Needs sudo: $label"
        ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
    fi
}

clean_stale_tmp() {
    local task_id="clean_tmp"
    local stale_count

    stale_count=$(find /tmp -mindepth 1 -maxdepth 1 -user "$(id -u)" -mtime +7 2> /dev/null | wc -l | awk '{print $1}')
    [[ "$stale_count" =~ ^[0-9]+$ ]] || stale_count=0

    if is_whitelisted "$task_id"; then
        echo -e "  ${GRAY}${ICON_WARNING}${NC} Skipped (whitelist): stale user /tmp cleanup"
        ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
        return 0
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}${ICON_DRY_RUN}${NC} /tmp stale user files (7+ days): ${stale_count}"
        ACTIONS_DONE=$((ACTIONS_DONE + 1))
        return 0
    fi

    if ((stale_count == 0)); then
        echo -e "  ${GREEN}${ICON_SUCCESS}${NC} /tmp is already optimized"
        return 0
    fi

    find /tmp -mindepth 1 -maxdepth 1 -user "$(id -u)" -mtime +7 -exec rm -rf {} + 2> /dev/null || true
    echo -e "  ${GREEN}${ICON_SUCCESS}${NC} Removed stale /tmp files: ${stale_count}"
    ACTIONS_DONE=$((ACTIONS_DONE + 1))
}

clean_pip_cache() {
    local task_id="clean_pip_cache"
    if is_whitelisted "$task_id"; then
        echo -e "  ${GRAY}${ICON_WARNING}${NC} Skipped (whitelist): pip cache cleanup"
        ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
        return 0
    fi

    if ! command -v pip > /dev/null 2>&1 && ! command -v pip3 > /dev/null 2>&1; then
        return 0
    fi

    local pip_cmd="pip"
    if ! command -v pip > /dev/null 2>&1; then
        pip_cmd="pip3"
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "  ${YELLOW}${ICON_DRY_RUN}${NC} Would purge Python package cache (${pip_cmd} cache purge)"
        ACTIONS_DONE=$((ACTIONS_DONE + 1))
        return 0
    fi

    if "$pip_cmd" cache purge > /dev/null 2>&1; then
        echo -e "  ${GREEN}${ICON_SUCCESS}${NC} Purged Python package cache"
        ACTIONS_DONE=$((ACTIONS_DONE + 1))
    fi
}

clean_package_cache() {
    local pm
    pm=$(detect_package_manager)

    case "$pm" in
        apt)
            run_root_task "clean_package_cache" "Cleaned apt package cache" apt-get clean
            ;;
        dnf)
            run_root_task "clean_package_cache" "Cleaned dnf package cache" dnf clean all
            ;;
        yum)
            run_root_task "clean_package_cache" "Cleaned yum package cache" yum clean all
            ;;
        pacman)
            if command -v paccache > /dev/null 2>&1; then
                run_root_task "clean_package_cache" "Pruned pacman package cache" paccache -r
            else
                run_root_task "clean_package_cache" "Cleaned pacman package cache" pacman -Sc --noconfirm
            fi
            ;;
        zypper)
            run_root_task "clean_package_cache" "Cleaned zypper package cache" zypper --non-interactive clean --all
            ;;
        apk)
            run_root_task "clean_package_cache" "Cleaned apk package cache" apk cache clean
            ;;
        *)
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Package cache cleanup: unsupported distro package manager"
            ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
            ;;
    esac
}

vacuum_journal_logs() {
    if ! command -v journalctl > /dev/null 2>&1; then
        return 0
    fi

    if is_wsl; then
        echo -e "  ${GRAY}${ICON_REVIEW}${NC} journal cleanup skipped on WSL"
        ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
        return 0
    fi

    run_root_task "vacuum_journal" "Vacuumed systemd journal logs (7d)" journalctl --vacuum-time=7d
}

trim_filesystem() {
    if ! command -v fstrim > /dev/null 2>&1; then
        return 0
    fi

    if is_wsl; then
        echo -e "  ${GRAY}${ICON_REVIEW}${NC} TRIM skipped on WSL"
        ACTIONS_SKIPPED=$((ACTIONS_SKIPPED + 1))
        return 0
    fi

    run_root_task "trim_filesystem" "Trimmed mounted filesystems" fstrim -av
}

show_update_hint() {
    local pm
    pm=$(detect_package_manager)

    case "$pm" in
        apt)
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Package updates: ${GRAY}sudo apt update && sudo apt upgrade${NC}"
            ;;
        dnf)
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Package updates: ${GRAY}sudo dnf upgrade --refresh${NC}"
            ;;
        yum)
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Package updates: ${GRAY}sudo yum update${NC}"
            ;;
        pacman)
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Package updates: ${GRAY}sudo pacman -Syu${NC}"
            ;;
        zypper)
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Package updates: ${GRAY}sudo zypper update${NC}"
            ;;
        apk)
            echo -e "  ${GRAY}${ICON_REVIEW}${NC} Package updates: ${GRAY}sudo apk update && sudo apk upgrade${NC}"
            ;;
    esac
}

main() {
    for arg in "$@"; do
        case "$arg" in
            --help | -h)
                show_optimize_help
                exit 0
                ;;
            --debug)
                export MO_DEBUG=1
                ;;
            --dry-run)
                DRY_RUN=true
                ;;
            --whitelist)
                manage_whitelist "optimize"
                exit 0
                ;;
            *)
                log_error "Unknown option: $arg"
                exit 1
                ;;
        esac
    done

    load_whitelist "optimize"

    export MOLE_CURRENT_COMMAND="optimize"
    log_operation_session_start "optimize"

    local distro pm mode_label
    distro=$(get_linux_distro_id)
    pm=$(detect_package_manager)
    mode_label="Linux"
    if is_wsl; then
        mode_label="WSL"
    fi

    local mem_total mem_available mem_used disk_used disk_total disk_percent up_days
    mem_total=$(mem_gb "MemTotal")
    mem_available=$(mem_gb "MemAvailable")
    mem_used=$(awk "BEGIN {printf \"%.1f\", $mem_total-$mem_available}")
    read -r disk_used disk_total disk_percent <<< "$(df -BG / 2> /dev/null | awk 'NR==2{gsub("G","",$3); gsub("G","",$2); gsub("%","",$5); print $3, $2, $5}')"
    up_days=$(uptime_days)

    echo ""
    echo -e "${PURPLE_BOLD}Optimize and Check (${mode_label})${NC}"
    echo -e "${ICON_ADMIN} System  ${mem_used}/${mem_total} GB RAM | ${disk_used}/${disk_total} GB Disk | Uptime ${up_days}d"
    echo -e "${ICON_INFO} Distro  ${distro} | Package manager: ${pm}"
    echo ""

    if [[ "$DRY_RUN" == "true" ]]; then
        echo -e "${YELLOW}${ICON_DRY_RUN} DRY RUN MODE${NC}, No changes will be applied"
        echo ""
    fi

    clean_stale_tmp
    clean_pip_cache
    clean_package_cache
    vacuum_journal_logs
    trim_filesystem

    show_update_hint

    if [[ "$disk_percent" =~ ^[0-9]+$ ]] && ((disk_percent >= 85)); then
        echo -e "  ${YELLOW}${ICON_WARNING}${NC} Disk usage is high (${disk_percent}%), run ${GREEN}mo clean${NC}"
    else
        echo -e "  ${GREEN}${ICON_SUCCESS}${NC} Disk usage looks healthy (${disk_percent}%)"
    fi

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        print_summary_block "Dry run complete" "Would run ${ACTIONS_DONE} maintenance tasks" "Skipped ${ACTIONS_SKIPPED} tasks"
    else
        print_summary_block "Optimization complete" "Applied ${ACTIONS_DONE} maintenance tasks" "Skipped ${ACTIONS_SKIPPED} tasks"
    fi
    echo ""

    log_operation_session_end "optimize" "$ACTIONS_DONE" "0"
}

main "$@"
