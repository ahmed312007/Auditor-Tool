source "$(dirname "$0")/lib.sh"

scan_directory() {
    local f files=0 folders=0
    local dir="$1"
    for f in "$dir"/*; do
        [[ -e "$f" ]] || continue
        if [[ -d "$f" ]]; then
            echo "[dir] $(basename "$f")"
            ((folders++))
        elif [[ -f "$f" ]]; then
            echo "[file] $(basename "$f")"
            ((files++))
        fi
    done
    echo "Files: $files Folders: $folders"
    log_action "scan $dir"
}

permission_audit() {
    local dir="$1" f flags unreadable=0 executable=0
    for f in "$dir"/*; do
        [[ -f "$f" ]] || continue
        flags=""
        [[ -r "$f" ]] && flags+="r" || flags+="-"
        [[ -w "$f" ]] && flags+="w" || flags+="-"
        [[ -x "$f" ]] && flags+="x" || flags+="-"
        echo "$flags $(basename "$f")"
        [[ -r "$f" ]] || ((unreadable++))
        [[ -x "$f" ]] && ((executable++))
    done
    echo "Unreadable files: $unreadable Executable files: $executable"
    log_action "perm $dir"
}

extension_report() {
    local dir="$1" f base ext
    declare -A counts
    for f in "$dir"/*; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f")
        if [[ "$base" == *.* ]]; then
            ext="${base##*.}"
        else
            ext="other"
        fi
        case "$ext" in
            txt|log|sh|jpg) ;;
            *) ext="other" ;;
        esac
        counts["$ext"]=$(( ${counts["$ext"]:-0} + 1 ))
    done
    for ext in "${!counts[@]}"; do
        echo "$ext : ${counts[$ext]}"
    done
    log_action "ext $dir"
}

search_file() {
    local dir="$1" q f found=0
    read -rp "Enter text: " q || return 0
    for f in "$dir"/*; do
        [[ -e "$f" ]] || continue
        if [[ "$(basename "$f")" == *"$q"* ]]; then
            echo "$(basename "$f")"
            found=1
        fi
    done
    [[ $found -eq 1 ]] || echo "No matches."
    log_action "search $q in $dir"
}

backup_all() {
    local dir="$1" f ts base saved=0 skipped=0
    local bdir="$dir/backups"
    mkdir -p "$bdir"
    ts=$(date '+%Y%m%d_%H%M%S')
    for f in "$dir"/*; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f")
        if [[ ! -r "$f" ]]; then
            log_error "Skipping unreadable: $base"
            ((skipped++))
            continue
        fi
        cp "$f" "$bdir/${base}_${ts}.bak"
        ((saved++))
    done
    echo "Saved: $saved Skipped: $skipped"
    log_action "backup $dir"
}

list_backups() {
    local dir="$1"
    local bdir="$dir/backups"
    local count

    if [[ ! -d "$bdir" ]]; then
        echo "(no backups yet)"
        log_action "list backups $dir (no folder)"
        return 0
    fi

    count=$(find "$bdir" -maxdepth 1 -type f 2>/dev/null | wc -l)
    if [[ "$count" -eq 0 ]]; then
        echo "(no backups yet)"
        log_action "list backups $dir (empty)"
        return 0
    fi

    ls -1 "$bdir"
    log_action "list backups $dir"
}

restore_backup() {
    local dir="$1"
    local bdir="$dir/backups"
    local name src orig target

    if [[ -z "$dir" ]]; then
        log_error "Directory argument missing"
        return 1
    fi

    if [[ ! -d "$bdir" ]]; then
        log_error "Backups folder not found: $bdir"
        return 1
    fi

    read -rp "Backup name: " name || return 0

    name="${name#"${name%%[![:space:]]*}"}"
    name="${name%"${name##*[![:space:]]}"}"

    if [[ -z "$name" ]]; then
        log_error "No name entered"
        return 1
    fi

    name=$(basename "$name")
    src="$bdir/$name"
    if [[ ! -f "$src" ]]; then
        log_error "Backup not found: $name"
        log_error "Looked in: $src"
        return 1
    fi

    # notes.txt_20261115_143000.bak -> notes.txt (original name and extension)
    orig="${name%.bak}"
    orig="${orig%_*_*}"
    target="$dir/restored_$orig"

    if [[ -e "$target" ]]; then
        log_error "Target exists, not overwriting: $target"
        return 1
    fi

    cp "$src" "$target"
    echo "Restored to: $target"
    log_action "restore $name"
}

show_menu() {
    echo "       Choose one of the following actions      "
    echo "1- Scan directory"
    echo "2- Permission audit"
    echo "3- Extension report"
    echo "4- Search file"
    echo "5- Backup all"
    echo "6- List backups"
    echo "7- Restore backup"
    echo "8- Exit"
}

main() {
    local target_dir="${1:-.}"
    local action="${2:-}"
    local choice

    if ! require_dir "$target_dir"; then
        exit 1
    fi

    case "$action" in
        scan)   scan_directory "$target_dir"; exit 0 ;;
        prem)   permission_audit "$target_dir"; exit 0 ;;
        ext)    extension_report "$target_dir"; exit 0 ;;
        backup) backup_all "$target_dir"; exit 0 ;;
        "") : ;;
        *)      log_error "Unknown action: $action"; exit 1 ;;
    esac

    while true; do
        show_menu
        read -rp "choose: " choice || exit 0   # stop if stdin is closed
        case "$choice" in
            1) scan_directory "$target_dir" ;;
            2) permission_audit "$target_dir" ;;
            3) extension_report "$target_dir" ;;
            4) search_file "$target_dir" ;;
            5) backup_all "$target_dir" ;;
            6) list_backups "$target_dir" ;;
            7) restore_backup "$target_dir" ;;
            8) echo "okBye"; exit 0 ;;
            *) log_error "Wrong choice: $choice" ;;
        esac
    done
}

main "$@"

