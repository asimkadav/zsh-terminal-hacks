#!/bin/bash
#
# Terminal Setup Uninstallation Script
# Safely removes configurations and optionally uninstalls packages
#

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_question() {
    echo -e "${BLUE}[QUESTION]${NC} $1"
}

# Ask yes/no question
ask_yes_no() {
    local question="$1"
    local default="${2:-n}"
    local prompt

    if [ "$default" = "y" ]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        read -p "$question $prompt " response
        response=${response:-$default}
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Get username
get_username() {
    if [ "$EUID" -eq 0 ]; then
        read -p "Enter the username to restore (current user is root): " target_user
        if id "$target_user" >/dev/null 2>&1; then
            echo "$target_user"
        else
            log_error "User $target_user does not exist"
            exit 1
        fi
    else
        echo "$USER"
    fi
}

# Find most recent backup
find_backup() {
    local file="$1"
    local backup

    # Find the most recent backup (sorted by timestamp)
    backup=$(ls -t "${file}.backup."* 2>/dev/null | head -n 1 || echo "")

    if [ -n "$backup" ]; then
        echo "$backup"
    else
        echo ""
    fi
}

# Restore configuration files
restore_configs() {
    local target_user="$1"
    local user_home

    user_home=$(eval echo "~$target_user")

    log_info "Restoring configuration files..."

    # Restore .vimrc
    local vimrc_backup
    vimrc_backup=$(find_backup "$user_home/.vimrc")
    if [ -n "$vimrc_backup" ]; then
        log_info "Restoring .vimrc from $vimrc_backup"
        cp "$vimrc_backup" "$user_home/.vimrc"
    else
        if ask_yes_no "No .vimrc backup found. Remove current .vimrc?" "n"; then
            rm -f "$user_home/.vimrc"
            log_info "Removed .vimrc"
        fi
    fi

    # Restore .zshrc
    local zshrc_backup
    zshrc_backup=$(find_backup "$user_home/.zshrc")
    if [ -n "$zshrc_backup" ]; then
        log_info "Restoring .zshrc from $zshrc_backup"
        cp "$zshrc_backup" "$user_home/.zshrc"
    else
        if ask_yes_no "No .zshrc backup found. Remove current .zshrc?" "n"; then
            rm -f "$user_home/.zshrc"
            log_info "Removed .zshrc"
        fi
    fi

    # Remove .zsh-update
    if [ -f "$user_home/.zsh-update" ]; then
        rm -f "$user_home/.zsh-update"
        log_info "Removed .zsh-update"
    fi

    # Set proper ownership if running as root
    if [ "$EUID" -eq 0 ]; then
        [ -f "$user_home/.vimrc" ] && chown "$target_user:$target_user" "$user_home/.vimrc"
        [ -f "$user_home/.zshrc" ] && chown "$target_user:$target_user" "$user_home/.zshrc"
    fi

    log_info "Configuration files restored"
}

# Remove Oh-My-Zsh
remove_ohmyzsh() {
    local target_user="$1"
    local user_home

    user_home=$(eval echo "~$target_user")

    if [ ! -d "$user_home/.oh-my-zsh" ]; then
        log_info "Oh-My-Zsh not installed, skipping"
        return
    fi

    if ask_yes_no "Remove Oh-My-Zsh installation?" "y"; then
        log_info "Removing Oh-My-Zsh..."
        rm -rf "$user_home/.oh-my-zsh"
        log_info "Oh-My-Zsh removed"
    fi
}

# Revert default shell
revert_shell() {
    local target_user="$1"
    local current_shell

    current_shell="$(getent passwd "$target_user" | cut -d: -f7)"

    if [[ "$current_shell" != *"zsh"* ]]; then
        log_info "Shell is not zsh, skipping"
        return
    fi

    if ask_yes_no "Revert shell back to bash?" "y"; then
        local bash_path
        bash_path="$(which bash)"

        log_info "Changing shell back to bash..."
        sudo chsh -s "$bash_path" "$target_user"
        log_info "Shell changed to bash. Log out and back in for changes to take effect."
    fi
}

# Remove installed packages
remove_packages() {
    local os="$1"

    if ! ask_yes_no "Remove installed packages (zsh, gh, delta, fzf, etc.)?" "n"; then
        log_info "Skipping package removal"
        return
    fi

    log_warn "This will remove packages that may be used by other tools"

    if [ "$os" = "macos" ]; then
        if command -v brew >/dev/null 2>&1; then
            log_info "Removing Homebrew packages..."
            brew uninstall --ignore-dependencies zsh gh git-delta fzf z 2>/dev/null || true
        fi
    elif [ "$os" = "linux" ]; then
        log_info "Removing apt packages..."
        sudo apt-get remove -y zsh gh git-delta fzf 2>/dev/null || true
        sudo rm -f /usr/local/bin/z.sh
    fi

    # Remove pygments
    if command -v pip3 >/dev/null 2>&1; then
        pip3 uninstall -y pygments 2>/dev/null || true
    elif command -v pip >/dev/null 2>&1; then
        pip uninstall -y pygments 2>/dev/null || true
    fi

    log_info "Packages removed"
}

# Clean up backups
cleanup_backups() {
    local target_user="$1"
    local user_home

    user_home=$(eval echo "~$target_user")

    if ask_yes_no "Remove all backup files?" "n"; then
        log_info "Removing backup files..."
        rm -f "$user_home/.vimrc.backup."* 2>/dev/null || true
        rm -f "$user_home/.zshrc.backup."* 2>/dev/null || true
        log_info "Backup files removed"
    else
        log_info "Keeping backup files"
    fi
}

# Main uninstallation
main() {
    log_info "=== Terminal Setup Uninstallation ==="
    echo

    # Detect OS
    local os
    os=$(detect_os)

    if [ "$os" = "unknown" ]; then
        log_error "Unsupported operating system: $OSTYPE"
        exit 1
    fi

    log_info "Detected OS: $os"

    # Get target username
    local target_user
    target_user=$(get_username)
    log_info "Uninstalling for user: $target_user"

    echo
    log_warn "This will remove terminal customizations and optionally uninstall packages"
    echo

    if ! ask_yes_no "Continue with uninstallation?" "n"; then
        log_info "Uninstallation cancelled"
        exit 0
    fi

    echo

    # Restore configuration files
    restore_configs "$target_user"

    # Remove Oh-My-Zsh
    remove_ohmyzsh "$target_user"

    # Revert shell
    revert_shell "$target_user"

    # Remove packages
    remove_packages "$os"

    # Clean up backups
    cleanup_backups "$target_user"

    echo
    log_info "=== Uninstallation Complete ==="
    echo
    log_info "Next steps:"
    log_info "1. Log out and back in (or restart your terminal)"
    log_info "2. If you kept backups, you can manually remove them from your home directory"
    echo
}

# Run main uninstallation
main "$@"
