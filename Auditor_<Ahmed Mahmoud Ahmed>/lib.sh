Log_file="$(dirname "${BASH_SOURCE[0]}")/auditor.log"

log_info() {
    echo "[Info] $*" >&2
}

log_error() {
    echo "[Error] $*" >&2
}

log_action() {
    local action="$*"
    printf "%s %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$action" >> "$Log_file"
}

require_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_error "The directory doesn't exist: $dir"
        return 1
    fi
    return 0
}

