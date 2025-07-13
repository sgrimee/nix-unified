#!/usr/bin/env bash

# Install git hooks from hooks/ directory to .git/hooks/
# This script ensures all team members use the same git hooks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/hooks"
GIT_HOOKS_DIR="$REPO_ROOT/.git/hooks"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_status "$BLUE" "🔧 Installing git hooks..."

# Check if we're in a git repository
if [ ! -d "$REPO_ROOT/.git" ]; then
    print_status "$RED" "❌ Not in a git repository!"
    exit 1
fi

# Check if hooks directory exists
if [ ! -d "$HOOKS_DIR" ]; then
    print_status "$RED" "❌ hooks/ directory not found!"
    exit 1
fi

# Install each hook
for hook_file in "$HOOKS_DIR"/*; do
    if [ -f "$hook_file" ]; then
        hook_name=$(basename "$hook_file")
        target_file="$GIT_HOOKS_DIR/$hook_name"
        
        # Remove existing hook if it exists
        if [ -f "$target_file" ]; then
            rm "$target_file"
        fi
        
        # Create symlink with relative path
        relative_path="$(realpath --relative-to="$GIT_HOOKS_DIR" "$hook_file")"
        ln -s "$relative_path" "$target_file"
        chmod +x "$target_file"
        
        print_status "$GREEN" "✅ Installed $hook_name hook"
    fi
done

print_status "$BLUE" "🎉 Git hooks installation complete!"
print_status "$YELLOW" "Note: Hooks can be bypassed with --no-verify flag if needed"