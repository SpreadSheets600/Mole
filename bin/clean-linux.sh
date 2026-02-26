#!/bin/bash
# Mole - Linux/WSL clean command.
# Safe user-level cleanup for common cache/temp locations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/core/common.sh"
source "$SCRIPT_DIR/../lib/manage/whitelist.sh"

DRY_RUN=false

show_linux_clean_help() {
    show_clean_help
    echo ""
    echo "Linux/WSL targets:"
    echo "  ~/.cache, ~/.local/share/Trash/files, ~/.npm/_cacache, ~/.cargo/registry/cache, /tmp (user-owned only)"
}

clean_path_contents() {
    local path="$1"
    local label="$2"
    local user_owned_only="${3:-false}"

    [[ -d "$path" ]] || return 0

    local touched=false

    while IFS= read -r -d '' item; do
        if [[ "$user_owned_only" == "true" ]]; then
            [[ "$(get_file_uid "$item" 2> /dev/null || echo -1)" == "$(id -u)" ]] || continue
        fi

        if is_path_whitelisted "$item"; then
            continue
        fi

        local item_kb=0
        item_kb=$(get_path_size_kb "$item" 2> /dev/null || echo 0)
        [[ "$item_kb" =~ ^[0-9]+$ ]] || item_kb=0

        if [[ "$DRY_RUN" == "true" ]]; then
            DRY_RUN_TOTAL_KB=$((DRY_RUN_TOTAL_KB + item_kb))
            touched=true
            continue
        fi

        if safe_remove "$item" true; then
            CLEANED_TOTAL_KB=$((CLEANED_TOTAL_KB + item_kb))
            touched=true
        fi
    done < <(command find "$path" -mindepth 1 -maxdepth 1 -print0 2> /dev/null || true)

    if [[ "$touched" == "true" ]]; then
        if [[ "$DRY_RUN" == "true" ]]; then
            echo -e "  ${YELLOW}${ICON_DRY_RUN}${NC} $label"
            DRY_RUN_ITEMS=$((DRY_RUN_ITEMS + 1))
        else
            echo -e "  ${GREEN}${ICON_SUCCESS}${NC} $label"
            CLEANED_ITEMS=$((CLEANED_ITEMS + 1))
        fi
    fi
}

main() {
    for arg in "$@"; do
        case "$arg" in
            --help | -h)
                show_linux_clean_help
                exit 0
                ;;
            --debug)
                export MO_DEBUG=1
                ;;
            --dry-run | -n)
                DRY_RUN=true
                ;;
            --whitelist)
                manage_whitelist "clean"
                exit 0
                ;;
            *)
                log_error "Unknown option: $arg"
                exit 1
                ;;
        esac
    done

    load_whitelist "clean"
    WHITELIST_PATTERNS=("${CURRENT_WHITELIST_PATTERNS[@]}")

    export MOLE_CURRENT_COMMAND="clean"
    log_operation_session_start "clean"

    local mode_label="Linux"
    if is_wsl; then
        mode_label="WSL"
    fi

    echo ""
    echo -e "${PURPLE_BOLD}Clean Your System (${mode_label})${NC}"
    echo ""

    DRY_RUN_ITEMS=0
    DRY_RUN_TOTAL_KB=0
    CLEANED_ITEMS=0
    CLEANED_TOTAL_KB=0

    clean_path_contents "$HOME/.cache" "User cache"
    clean_path_contents "$HOME/.local/share/Trash/files" "Trash files"
    clean_path_contents "$HOME/.npm/_cacache" "npm cache"
    clean_path_contents "$HOME/.cargo/registry/cache" "Cargo registry cache"
    clean_path_contents "/tmp" "Temporary files (/tmp)" true

    local summary_kb
    local summary_items
    if [[ "$DRY_RUN" == "true" ]]; then
        summary_kb=$DRY_RUN_TOTAL_KB
        summary_items=$DRY_RUN_ITEMS
    else
        summary_kb=$CLEANED_TOTAL_KB
        summary_items=$CLEANED_ITEMS
    fi

    local summary_human
    summary_human=$(bytes_to_human "$((summary_kb * 1024))")

    echo ""
    if [[ "$DRY_RUN" == "true" ]]; then
        print_summary_block "Dry run complete" "Would clean ${summary_items} categories" "Estimated reclaim: ${summary_human}"
    else
        print_summary_block "Cleanup complete" "Cleaned ${summary_items} categories" "Freed: ${summary_human}"
    fi
    echo ""

    log_operation_session_end "clean" "$summary_items" "$summary_kb"
}

main "$@"
