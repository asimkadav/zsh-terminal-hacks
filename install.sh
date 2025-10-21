#!/bin/bash
#
# Terminal Setup Installation Script
# Supports macOS and Linux (Debian/Ubuntu)
#

set -e  # Exit on any error
set -u  # Exit on undefined variables

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get username (prompt if running as root)
get_username() {
    if [ "$EUID" -eq 0 ]; then
        read -p "Enter the username to configure (current user is root): " target_user
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

# Backup file with timestamp
backup_file() {
    local file="$1"
    if [ -f "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

# Install package manager and update
setup_package_manager() {
    local os="$1"

    if [ "$os" = "macos" ]; then
        if ! command_exists brew; then
            log_info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            log_info "Homebrew already installed"
        fi
        log_info "Updating Homebrew..."
        brew update
    elif [ "$os" = "linux" ]; then
        log_info "Updating package lists..."
        sudo apt-get update
    fi
}

# Install zsh
install_zsh() {
    local os="$1"

    if command_exists zsh; then
        log_info "zsh already installed: $(zsh --version)"
        return
    fi

    log_info "Installing zsh..."
    if [ "$os" = "macos" ]; then
        brew install zsh
    elif [ "$os" = "linux" ]; then
        sudo apt-get install -y zsh
    fi
}

# Set zsh as default shell
set_default_shell() {
    local target_user="$1"
    local zsh_path

    zsh_path="$(which zsh)"

    # Add zsh to allowed shells if not present
    if ! grep -q "$zsh_path" /etc/shells; then
        log_info "Adding $zsh_path to /etc/shells"
        echo "$zsh_path" | sudo tee -a /etc/shells
    fi

    # Change shell if not already zsh
    local current_shell
    current_shell="$(getent passwd "$target_user" | cut -d: -f7)"

    if [ "$current_shell" != "$zsh_path" ]; then
        log_info "Setting zsh as default shell for $target_user..."
        sudo chsh -s "$zsh_path" "$target_user"
        log_info "Shell changed. Please log out and back in for changes to take effect."
    else
        log_info "zsh is already the default shell"
    fi
}

# Install oh-my-zsh
install_ohmyzsh() {
    local target_user="$1"
    local user_home

    user_home=$(eval echo "~$target_user")

    if [ -d "$user_home/.oh-my-zsh" ]; then
        log_info "oh-my-zsh already installed"
        return
    fi

    log_info "Installing oh-my-zsh..."
    # Use official HTTPS URL instead of HTTP
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
}

# Install zsh-syntax-highlighting
install_syntax_highlighting() {
    local target_user="$1"
    local user_home
    local plugin_dir

    user_home=$(eval echo "~$target_user")
    plugin_dir="$user_home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

    if [ -d "$plugin_dir" ]; then
        log_info "zsh-syntax-highlighting already installed"
        return
    fi

    log_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$plugin_dir"
}

# Install z (directory jumper)
install_z() {
    local os="$1"

    if command_exists z || [ -f /usr/local/etc/profile.d/z.sh ]; then
        log_info "z already installed"
        return
    fi

    log_info "Installing z..."
    if [ "$os" = "macos" ]; then
        brew install z
    elif [ "$os" = "linux" ]; then
        # For Linux, install from GitHub
        local install_dir="/usr/local/bin"
        sudo curl -fsSL https://raw.githubusercontent.com/rupa/z/master/z.sh -o "$install_dir/z.sh"
        sudo chmod +x "$install_dir/z.sh"
    fi
}

# Install pygments
install_pygments() {
    local os="$1"

    if command_exists pygmentize; then
        log_info "pygments already installed"
        return
    fi

    log_info "Installing pygments..."
    if command_exists pip3; then
        pip3 install --user pygments
    elif command_exists pip; then
        pip install --user pygments
    else
        log_warn "pip not found. Please install Python and pip manually."
        if [ "$os" = "linux" ]; then
            log_info "Try: sudo apt-get install -y python3-pip"
        fi
    fi
}

# Install GitHub CLI
install_gh() {
    local os="$1"

    if command_exists gh; then
        log_info "GitHub CLI already installed: $(gh --version | head -n1)"
        return
    fi

    log_info "Installing GitHub CLI..."
    if [ "$os" = "macos" ]; then
        brew install gh
    elif [ "$os" = "linux" ]; then
        # Official GitHub CLI installation for Debian/Ubuntu
        sudo apt-get install -y curl
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    fi
}

# Install git-delta
install_delta() {
    local os="$1"

    if command_exists delta; then
        log_info "git-delta already installed"
        return
    fi

    log_info "Installing git-delta..."
    if [ "$os" = "macos" ]; then
        brew install git-delta
    elif [ "$os" = "linux" ]; then
        # Install from GitHub releases
        local version="0.16.5"
        local deb_file="git-delta_${version}_amd64.deb"
        local download_url="https://github.com/dandavison/delta/releases/download/${version}/${deb_file}"

        curl -fsSL "$download_url" -o "/tmp/${deb_file}"
        sudo dpkg -i "/tmp/${deb_file}" || sudo apt-get install -f -y
        rm "/tmp/${deb_file}"
    fi
}

# Install fzf
install_fzf() {
    local os="$1"
    local target_user="$2"
    local user_home

    user_home=$(eval echo "~$target_user")

    if command_exists fzf; then
        log_info "fzf already installed"
        return
    fi

    log_info "Installing fzf..."
    if [ "$os" = "macos" ]; then
        brew install fzf
        # Install key bindings and fuzzy completion
        "$(brew --prefix)/opt/fzf/install" --all --no-bash --no-fish
    elif [ "$os" = "linux" ]; then
        sudo apt-get install -y fzf
    fi
}

# Setup GitHub CLI aliases
setup_gh_aliases() {
    if ! command_exists gh; then
        log_warn "GitHub CLI not installed, skipping alias setup"
        return
    fi

    log_info "Setting up GitHub CLI aliases..."

    # Set delta as pager
    gh config set pager 'delta -s' 2>/dev/null || true

    # Create PR diff alias
    gh alias set patchdiff --clobber --shell 'id="$(gh pr list -L100 | fzf | cut -f1)"; [ -n "$id" ] && gh pr diff "$id" --patch' 2>/dev/null || true

    # Create PR checkout alias
    gh alias set co --clobber --shell 'id="$(gh pr list -L100 | fzf | cut -f1)"; [ -n "$id" ] && gh pr checkout "$id"' 2>/dev/null || true

    # Create PR list with preview alias
    gh alias set listdiff --clobber --shell 'gh pr list | fzf --preview "gh pr diff --color=always {+1}"' 2>/dev/null || true

    log_info "GitHub CLI aliases configured: gh co, gh patchdiff, gh listdiff"
}

# Install claude-review tool
install_claude_review() {
    local script_dir="$1"
    local target_user="$2"
    local user_home

    user_home=$(eval echo "~$target_user")

    if [ ! -f "$script_dir/claude-review" ]; then
        log_warn "claude-review script not found, skipping"
        return
    fi

    log_info "Installing claude-review tool..."

    # Create local bin directory if it doesn't exist
    local bin_dir="$user_home/.local/bin"
    mkdir -p "$bin_dir"

    # Copy the script
    cp "$script_dir/claude-review" "$bin_dir/claude-review"
    chmod +x "$bin_dir/claude-review"

    # Set proper ownership if running as root
    if [ "$EUID" -eq 0 ]; then
        chown -R "$target_user:$target_user" "$bin_dir"
    fi

    # Add to PATH if not already there
    if ! grep -q ".local/bin" "$user_home/.zshrc" 2>/dev/null; then
        echo "" >> "$user_home/.zshrc"
        echo "# Add local bin to PATH for custom tools" >> "$user_home/.zshrc"
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$user_home/.zshrc"
    fi

    log_info "claude-review installed to $bin_dir"
}

# Copy configuration files
copy_configs() {
    local target_user="$1"
    local script_dir="$2"
    local user_home

    user_home=$(eval echo "~$target_user")

    log_info "Installing configuration files..."

    # Backup and copy .vimrc
    backup_file "$user_home/.vimrc"
    cp "$script_dir/.vimrc" "$user_home/.vimrc"

    # Backup and copy .zshrc
    backup_file "$user_home/.zshrc"
    cp "$script_dir/.zshrc" "$user_home/.zshrc"

    # Copy .zsh-update if present
    if [ -f "$script_dir/.zsh-update" ]; then
        cp "$script_dir/.zsh-update" "$user_home/.zsh-update"
    fi

    # Set proper ownership if running as root
    if [ "$EUID" -eq 0 ]; then
        chown "$target_user:$target_user" "$user_home/.vimrc" "$user_home/.zshrc"
        [ -f "$user_home/.zsh-update" ] && chown "$target_user:$target_user" "$user_home/.zsh-update"
    fi

    log_info "Configuration files installed"
}

# Main installation
main() {
    log_info "=== Terminal Setup Installation ==="
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
    log_info "Configuring for user: $target_user"

    # Get script directory
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    echo
    log_info "Starting installation..."
    echo

    # Setup package manager
    setup_package_manager "$os"

    # Install core tools
    install_zsh "$os"
    set_default_shell "$target_user"
    install_ohmyzsh "$target_user"
    install_syntax_highlighting "$target_user"
    install_z "$os"
    install_pygments "$os"

    # Install development tools
    install_gh "$os"
    install_delta "$os"
    install_fzf "$os" "$target_user"

    # Setup GitHub CLI
    setup_gh_aliases

    # Copy configuration files
    copy_configs "$target_user" "$script_dir"

    # Install claude-review tool
    install_claude_review "$script_dir" "$target_user"

    echo
    log_info "=== Installation Complete! ==="
    echo
    log_info "Next steps:"
    log_info "1. Log out and back in (or restart your terminal)"
    log_info "2. Run: source ~/.zshrc"
    log_info "3. For GitHub CLI features, authenticate with: gh auth login"
    log_info "4. Try: claude-review -i (interactive code review UI)"
    echo
    log_info "New commands available:"
    log_info "  - pcat <file>      : Syntax-highlighted file viewer"
    log_info "  - claude-review    : Interactive terminal UI for code review"
    log_info "  - gh co            : Interactively checkout a PR"
    log_info "  - gh patchdiff     : View PR diff with patches"
    log_info "  - gh listdiff      : Browse PRs with live diff preview"
    echo
}

# Run main installation
main "$@"
