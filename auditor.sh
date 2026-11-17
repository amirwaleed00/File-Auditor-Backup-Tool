#!/bin/bash

source "$(dirname "$0")/lib.sh"

TARGET_DIR="${1:-.}"
LOG_FILE="auditor.log"

require_dir "$TARGET_DIR"


# List files and folders in the directory.
# Count the number of files and folders.
scan_directory() {
    local files=0
    local folders=0
    local f

    for f in "$TARGET_DIR"/*; do
        if [ -f "$f" ]; then
            echo "[file] $(basename "$f")"
            files=$((files + 1))
        elif [ -d "$f" ]; then
            echo "[dir ] $(basename "$f")"
            folders=$((folders + 1))
        fi
    done

    echo "Files: $files"
    echo "Folders: $folders"

    log_action "Scan directory"
}



# Check read, write and execute permissions.
# Count unreadable and executable files.
permission_audit() {
    local unreadable=0
    local executable=0
    local f
    local perms

    for f in "$TARGET_DIR"/*; do
        if [ -f "$f" ]; then
            perms=""

            if [ -r "$f" ]; then
                perms="${perms}r"
            else
                perms="${perms}-"
                unreadable=$((unreadable + 1))
            fi

            if [ -w "$f" ]; then
                perms="${perms}w"
            else
                perms="${perms}-"
            fi

            if [ -x "$f" ]; then
                perms="${perms}x"
                executable=$((executable + 1))
            else
                perms="${perms}-"
            fi

            echo "$perms  $(basename "$f")"
        fi
    done

    echo "Unreadable files: $unreadable"
    echo "Executable files: $executable"

    log_action "Permission audit"
}


# Count files based on their extensions.
# Use an associative array to store the counts.
extension_report() {
    local f
    local name
    local ext
    declare -A counts=([txt]=0 [log]=0 [sh]=0 [jpg]=0 [other]=0)

    for f in "$TARGET_DIR"/*; do
        if [ -f "$f" ]; then
            name=$(basename "$f")
            ext="${name##*.}"

            if [ "$ext" = "txt" ]; then
                counts[txt]=$((counts[txt] + 1))
            elif [ "$ext" = "log" ]; then
                counts[log]=$((counts[log] + 1))
            elif [ "$ext" = "sh" ]; then
                counts[sh]=$((counts[sh] + 1))
            elif [ "$ext" = "jpg" ]; then
                counts[jpg]=$((counts[jpg] + 1))
            else
                counts[other]=$((counts[other] + 1))
            fi
        fi
    done

    for ext in txt log sh jpg other; do
        echo "$ext : ${counts[$ext]}"
    done

    log_action "Extension report"
}



# Search for files by their names.
# Display matching files or a message if none are found.
search_file() {
    local search
    local f
    local name
    local found=0

    read -p "Enter file name to search: " search

    for f in "$TARGET_DIR"/*; do
        if [ -f "$f" ]; then
            name=$(basename "$f")

            if [[ "$name" == *"$search"* ]]; then
                echo "$name"
                found=1
            fi
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "No matching files found."
    fi

    log_action "Search file"
}


# Copy readable files to the backups folder.
# Skip unreadable files and count the results.
backup_all() {
    local backup_dir="$TARGET_DIR/backups"
    local saved=0
    local skipped=0
    local f
    local name
    local timestamp

    mkdir -p "$backup_dir"
    timestamp=$(date '+%Y%m%d_%H%M%S')

    for f in "$TARGET_DIR"/*; do
        if [ -f "$f" ]; then
            if [ -r "$f" ]; then
                name=$(basename "$f")

                if [ ! -e "$backup_dir/${name}_${timestamp}.bak" ] && cp "$f" "$backup_dir/${name}_${timestamp}.bak"; then
                    saved=$((saved + 1))
                else
                    log_error "Could not backup: $f"
                    skipped=$((skipped + 1))
                fi
            else
                log_error "Unreadable file: $f"
                skipped=$((skipped + 1))
            fi
        fi
    done

    echo "Saved files: $saved"
    echo "Skipped files: $skipped"

    log_action "Backup files"
}


# Display all saved backup files.
# Show a message if no backups exist.
list_backups() {
    local backup_dir="$TARGET_DIR/backups"
    local f
    local found=0

    if [ -d "$backup_dir" ]; then
        for f in "$backup_dir"/*.bak; do
            if [ -f "$f" ]; then
                echo "$(basename "$f")"
                found=1
            fi
        done
    fi

    if [ "$found" -eq 0 ]; then
        echo "(no backups yet)"
    fi

    log_action "List backups"
}


# Restore a selected backup file.
# Never overwrite an existing file.
restore_backup() {
    local backup_dir="$TARGET_DIR/backups"
    local name
    local original
    local destination

    read -p "Enter backup name: " name

    if [ ! -f "$backup_dir/$name" ]; then
        log_error "Backup not found"
        log_action "Restore failed"
        return 1
    fi

    original="${name%.bak}"
    original="${original%_????????_??????}"
    destination="$TARGET_DIR/restored_$original"

    if [ -e "$destination" ]; then
        log_error "Restored file already exists"
        log_action "Restore failed"
        return 1
    fi

    if cp "$backup_dir/$name" "$destination"; then
        echo "File restored: restored_$original"
        log_action "Restore backup"
    else
        log_error "Restore failed"
        log_action "Restore failed"
        return 1
    fi
}


# Display the main menu.
# Keep showing the menu until the user exits.
show_menu() {
    local choice

    while true; do
        echo ""
        echo "===== File Auditor & Backup Tool ====="
        echo "1. Scan Directory"
        echo "2. Permission Audit"
        echo "3. Extension Report"
        echo "4. Search File"
        echo "5. Backup Files"
        echo "6. List Backups"
        echo "7. Restore Backup"
        echo "8. Exit"

        read -p "Enter your choice: " choice

        case "$choice" in
            1) scan_directory ;;
            2) permission_audit ;;
            3) extension_report ;;
            4) search_file ;;
            5) backup_all ;;
            6) list_backups ;;
            7) restore_backup ;;
            8) echo "Goodbye!"; break ;;
            *) echo "Invalid choice. Try again." ;;
        esac
    done
}


# Run an action directly or open the menu.
# Use the second argument to choose the action.
if [ -z "$2" ]; then
    show_menu
else
    case "$2" in
        scan) scan_directory ;;
        perms) permission_audit ;;
        ext) extension_report ;;
        backup) backup_all ;;
        *) echo "Invalid action"; exit 1 ;;
    esac
fi

