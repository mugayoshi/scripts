#!/bin/bash

# Configuration
REPOS_DIR="${REPOS_DIR:-$HOME/repos}"
BACKUP_DIR="${BACKUP_DIR:-$HOME/.claude_backups}"
DRY_RUN=false
COMMAND=""

usage() {
    echo "Usage: $0 [--backup | --restore] [--dry-run]"
    echo ""
    echo "Options:"
    echo "  --backup    Copy CLAUDE.md files from repos to backup directory"
    echo "  --restore   Copy CLAUDE.md files from backup directory back to repos"
    echo "  --dry-run   Show what would be done without making any changes"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --backup) COMMAND="backup" ;;
        --restore) COMMAND="restore" ;;
        --dry-run) DRY_RUN=true ;;
        *) usage ;;
    esac
    shift
done

if [[ -z "$COMMAND" ]]; then
    usage
fi

# Ensure backup directory exists
if [[ "$DRY_RUN" = false ]]; then
    mkdir -p "$BACKUP_DIR"
fi

backup() {
    echo "Starting backup from $REPOS_DIR to $BACKUP_DIR..."
    for repo in "$REPOS_DIR"/*; do
        if [[ -d "$repo" && -f "$repo/CLAUDE.md" ]]; then
            repo_name=$(basename "$repo")
            target_dir="$BACKUP_DIR/$repo_name"
            
            if [[ "$DRY_RUN" = true ]]; then
                echo "[DRY-RUN] Would backup $repo/CLAUDE.md to $target_dir/CLAUDE.md"
            else
                mkdir -p "$target_dir"
                cp "$repo/CLAUDE.md" "$target_dir/CLAUDE.md"
                echo "Backed up $repo_name/CLAUDE.md"
            fi
        fi
    done
}

restore() {
    echo "Starting restore from $BACKUP_DIR to $REPOS_DIR..."
    for backup_item in "$BACKUP_DIR"/*; do
        if [[ -d "$backup_item" && -f "$backup_item/CLAUDE.md" ]]; then
            repo_name=$(basename "$backup_item")
            target_repo="$REPOS_DIR/$repo_name"
            
            if [[ -d "$target_repo" ]]; then
                if [[ "$DRY_RUN" = true ]]; then
                    echo "[DRY-RUN] Would restore $backup_item/CLAUDE.md to $target_repo/CLAUDE.md"
                else
                    cp "$backup_item/CLAUDE.md" "$target_repo/CLAUDE.md"
                    echo "Restored $repo_name/CLAUDE.md"
                fi
            else
                echo "Skipping $repo_name: Target repository directory does not exist at $target_repo"
            fi
        fi
    done
}

case $COMMAND in
    backup) backup ;;
    restore) restore ;;
esac

echo "Done."
