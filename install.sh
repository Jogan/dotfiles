#!/bin/bash

# Claude Code Enhanced Dotfiles Installer
# This script sets up your dotfiles and Claude Code enhancements

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status "Starting Claude Code enhanced dotfiles installation..."
print_status "Dotfiles directory: $DOTFILES_DIR"

# Check if we're in the right directory
if [ ! -f "$DOTFILES_DIR/.gitconfig" ]; then
    print_error "This doesn't appear to be the dotfiles directory"
    print_error "Expected to find .gitconfig in: $DOTFILES_DIR"
    exit 1
fi

# Backup existing dotfiles
backup_file() {
    local file="$1"
    if [ -f "$HOME/$file" ] || [ -L "$HOME/$file" ]; then
        print_warning "Backing up existing $file to $file.backup"
        mv "$HOME/$file" "$HOME/$file.backup"
    fi
}

# Create symlink
create_symlink() {
    local source="$1"
    local target="$2"
    
    if [ -f "$DOTFILES_DIR/$source" ]; then
        backup_file "$target"
        ln -s "$DOTFILES_DIR/$source" "$HOME/$target"
        print_success "Linked $source -> ~/$target"
    else
        print_warning "Source file not found: $source"
    fi
}

# Install dotfiles
print_status "Installing dotfiles..."

# Git configuration
create_symlink ".gitconfig" ".gitconfig"

# Check for other common dotfiles
DOTFILES=(
    ".bashrc"
    ".bash_profile" 
    ".zshrc"
    ".vimrc"
    ".tmux.conf"
)

for dotfile in "${DOTFILES[@]}"; do
    if [ -f "$DOTFILES_DIR/$dotfile" ]; then
        create_symlink "$dotfile" "$dotfile"
    fi
done

# Install Claude Code enhancements
print_status "Installing Claude Code enhancements..."

# Create Claude directory in home if it doesn't exist
if [ ! -d "$HOME/.claude" ]; then
    mkdir -p "$HOME/.claude"
    print_success "Created ~/.claude directory"
fi

# Link Claude templates and prompts to a global location
CLAUDE_GLOBAL_DIR="$HOME/.dotfiles"
if [ ! -d "$CLAUDE_GLOBAL_DIR" ]; then
    mkdir -p "$CLAUDE_GLOBAL_DIR"
fi

# Create symlink to the entire claude directory
if [ -d "$DOTFILES_DIR/claude" ]; then
    if [ -L "$CLAUDE_GLOBAL_DIR/claude" ] || [ -d "$CLAUDE_GLOBAL_DIR/claude" ]; then
        print_warning "Backing up existing claude directory"
        mv "$CLAUDE_GLOBAL_DIR/claude" "$CLAUDE_GLOBAL_DIR/claude.backup"
    fi
    
    ln -s "$DOTFILES_DIR/claude" "$CLAUDE_GLOBAL_DIR/claude"
    print_success "Linked Claude enhancements to ~/.dotfiles/claude"
else
    print_error "Claude directory not found in dotfiles"
    exit 1
fi

# Make commands executable (in case they weren't already)
if [ -d "$DOTFILES_DIR/claude/.claude/commands" ]; then
    find "$DOTFILES_DIR/claude/.claude/commands" -type f -exec chmod +x {} \;
    print_success "Made Claude commands executable"
fi

# Add Claude commands to PATH (optional)
print_status "Setting up Claude commands..."

# Check if the commands directory is in PATH
CLAUDE_COMMANDS_DIR="$CLAUDE_GLOBAL_DIR/claude/.claude/commands"
if [[ ":$PATH:" != *":$CLAUDE_COMMANDS_DIR:"* ]]; then
    print_warning "Claude commands are not in PATH"
    print_status "To add them, add this line to your shell profile:"
    echo "export PATH=\"\$PATH:$CLAUDE_COMMANDS_DIR\""
fi

# Validate installation
print_status "Validating installation..."

VALIDATION_PASSED=true

# Check git config
if [ -L "$HOME/.gitconfig" ]; then
    print_success "Git configuration linked successfully"
else
    print_error "Git configuration not linked"
    VALIDATION_PASSED=false
fi

# Check Claude enhancements
if [ -L "$CLAUDE_GLOBAL_DIR/claude" ]; then
    print_success "Claude enhancements linked successfully"
else
    print_error "Claude enhancements not linked"
    VALIDATION_PASSED=false
fi

# Check CLAUDE.md template
if [ -f "$CLAUDE_GLOBAL_DIR/claude/templates/CLAUDE.md" ]; then
    print_success "CLAUDE.md template available"
else
    print_error "CLAUDE.md template not found"
    VALIDATION_PASSED=false
fi

# Check commands
COMMANDS=("init-project" "setup-testing" "quality-check" "deploy-prep")
for cmd in "${COMMANDS[@]}"; do
    if [ -x "$CLAUDE_GLOBAL_DIR/claude/.claude/commands/$cmd" ]; then
        print_success "Command '$cmd' is executable"
    else
        print_error "Command '$cmd' is not executable"
        VALIDATION_PASSED=false
    fi
done

# Final status
echo ""
if [ "$VALIDATION_PASSED" = true ]; then
    print_success "🎉 Installation completed successfully!"
    echo ""
    echo "Next steps:"
    echo "1. Reload your shell or source your profile"
    echo "2. Test Claude commands: init-project, setup-testing, quality-check, deploy-prep"
    echo "3. In new projects, run 'init-project' to set up Claude Code context"
    echo "4. Use the prompts in ~/.dotfiles/claude/prompts/ for consistent interactions"
    echo ""
    echo "Claude Code enhancements installed:"
    echo "📁 Templates: ~/.dotfiles/claude/templates/"
    echo "📝 Prompts: ~/.dotfiles/claude/prompts/"
    echo "⚡ Commands: ~/.dotfiles/claude/.claude/commands/"
else
    print_error "❌ Installation completed with errors"
    print_error "Please review the errors above and fix them manually"
    exit 1
fi