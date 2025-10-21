# Terminal Setup - ZSH Configuration

A comprehensive terminal setup for developers with modern tools, beautiful themes, and productivity enhancements. Works on both **macOS** and **Linux** (Debian/Ubuntu).

## Features

### Core Tools
- **zsh** - Modern shell with advanced features
- **Oh-My-Zsh** - Framework for managing zsh configuration
- **zsh-syntax-highlighting** - Fish shell-like syntax highlighting
- **z** - Smart directory jumping based on frecency

### Development Tools
- **GitHub CLI (gh)** - Interact with GitHub from the command line
- **git-delta** - Beautiful syntax-highlighted git diffs
- **fzf** - Fuzzy finder for interactive searching
- **pygments** - Syntax highlighting for code viewing

### Customizations
- **fino theme** - Clean, informative prompt with git status
- **pcat command** - Syntax-highlighted file viewer (`pcat file.py`)
- **GitHub PR workflows** - Interactive PR browsing and checkout

### GitHub CLI Custom Commands
Once installed, you'll have these powerful PR review commands:
- `gh co` - Interactively select and checkout a PR
- `gh patchdiff` - View a PR's diff with patch format
- `gh listdiff` - Browse PRs with live diff preview

## Requirements

### macOS
- macOS 10.14 or later
- Command Line Tools (installed automatically if needed)

### Linux
- Debian/Ubuntu-based distribution
- sudo access for package installation

## Installation

### Quick Install

```bash
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your operating system automatically
2. Install the appropriate package manager tools (Homebrew for macOS, apt for Linux)
3. Install all required tools and dependencies
4. Configure zsh as your default shell
5. Back up your existing configuration files (with timestamps)
6. Install customized configurations

### Manual Installation

If you prefer to install components individually:

```bash
# For macOS
brew install zsh gh git-delta fzf z
pip3 install pygments

# For Linux
sudo apt-get update
sudo apt-get install zsh fzf
pip3 install pygments
# See install.sh for gh and delta installation
```

Then copy the configuration files:
```bash
cp .vimrc ~/.vimrc
cp .zshrc ~/.zshrc
```

## Post-Installation

### 1. Activate Your New Shell
Log out and back in, or restart your terminal application.

### 2. Source Your Configuration
```bash
source ~/.zshrc
```

### 3. Authenticate GitHub CLI (Optional)
For the GitHub PR features to work:
```bash
gh auth login
```

### 4. Optional: Install Powerline Fonts (for better iTerm2 experience)
For macOS with iTerm2:
```bash
# Install Meslo LG S for Powerline
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font
```

Then import the iTerm2 profile:
1. Open iTerm2
2. Go to Preferences → Profiles
3. Click "Other Actions" → "Import JSON Profiles"
4. Select `iterm-asim.json`

## What Gets Installed

### Configuration Files
- `.zshrc` - Zsh configuration with plugins and aliases
- `.vimrc` - Vim configuration with sensible defaults
- `.zsh-update` - Oh-My-Zsh update tracker (auto-generated)

### Backup Files
Your existing configurations are backed up with timestamps:
- `.vimrc.backup.YYYYMMDD_HHMMSS`
- `.zshrc.backup.YYYYMMDD_HHMMSS`

## Usage Examples

### Syntax-Highlighted File Viewing
```bash
pcat script.py
pcat config.json
```

### Directory Jumping with z
```bash
# After visiting directories, jump to them quickly
z documents      # Jump to most frecent directory matching "documents"
z proj           # Jump to project directory
```

### GitHub PR Workflow
```bash
# Browse PRs with live preview
gh listdiff

# Checkout a PR interactively
gh co

# View detailed PR diff
gh patchdiff
```

### Fuzzy Finding
```bash
# Search command history
Ctrl+R

# Search files
fzf

# Use in commands
vim $(fzf)
```

## Customization

### Adding Zsh Plugins
Edit `~/.zshrc` and add plugins to the `plugins=()` array:
```bash
plugins=(
  git
  brew
  docker  # Add this
  # ... other plugins
)
```

Browse available plugins: `~/.oh-my-zsh/plugins/`

### Changing Zsh Theme
Edit `~/.zshrc`:
```bash
ZSH_THEME="agnoster"  # Change from "fino"
```

Browse themes: https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

### Vim Plugins
To add vim plugins using vim-plug:

1. Install vim-plug:
```bash
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

2. Edit `~/.vimrc` and uncomment the plugin section

3. Add plugins:
```vim
call plug#begin('~/.vim/plugged')
Plug 'tpope/vim-fugitive'
Plug 'scrooloose/nerdtree'
call plug#end()
```

4. Run `:PlugInstall` in vim

## Uninstallation

To remove all installed components and restore backups:

```bash
chmod +x uninstall.sh
./uninstall.sh
```

This will:
- Restore your original configuration files from the most recent backup
- Optionally remove installed packages
- Optionally revert your shell back to bash

## Troubleshooting

### Shell Not Changing
If zsh isn't your default shell after installation:
```bash
chsh -s $(which zsh)
```

### Oh-My-Zsh Not Loading
Ensure the path is correct in `~/.zshrc`:
```bash
export ZSH="$HOME/.oh-my-zsh"
```

### Syntax Highlighting Not Working
The plugin should be automatically loaded. Verify it's in your plugins list:
```bash
grep zsh-syntax-highlighting ~/.zshrc
```

### GitHub CLI Commands Not Working
1. Ensure you're authenticated: `gh auth status`
2. If not: `gh auth login`
3. Ensure fzf is installed: `which fzf`

### Pygments/pcat Not Working
Install or reinstall pygments:
```bash
pip3 install --user --upgrade pygments
```

### Permission Denied Errors
If running as root or using sudo, the script will prompt for the target username to configure.

## Platform-Specific Notes

### macOS
- Uses Homebrew for package management
- Supports both Intel and Apple Silicon Macs
- iTerm2 profile included for optimal experience

### Linux (Debian/Ubuntu)
- Uses apt for package management
- Some packages installed from official releases (delta, gh)
- Works on WSL2 (Windows Subsystem for Linux)

## Files in This Repository

```
.
├── install.sh              # Main installation script
├── uninstall.sh            # Uninstallation script
├── .zshrc                  # Zsh configuration
├── .vimrc                  # Vim configuration
├── .zsh-update             # Oh-My-Zsh update tracker
├── iterm-asim.json         # iTerm2 color profile (macOS)
├── terminal-asim.terminal  # macOS Terminal profile
├── vscode.code-profile     # VS Code settings profile
├── .gitignore              # Git ignore patterns
└── README.md               # This file
```

## Contributing

Feel free to fork and customize for your own use. Suggestions and improvements welcome!

## License

This configuration is provided as-is for personal use. Individual tools and packages are licensed under their respective licenses.

## Credits

- [Oh-My-Zsh](https://ohmyz.sh/)
- [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting)
- [z directory jumper](https://github.com/rupa/z)
- [GitHub CLI](https://cli.github.com/)
- [git-delta](https://github.com/dandavison/delta)
- [fzf](https://github.com/junegunn/fzf)

---

**Note**: Running the installer is idempotent - you can run it multiple times safely. It will skip already-installed components and create timestamped backups of configuration files.
