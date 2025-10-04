final: prev: {
  update-coding-agents = prev.writeShellApplication {
    name = "update-coding-agents";
    runtimeInputs = [];
    text = ''
      # Check if npm is available
      if ! command -v npm >/dev/null 2>&1; then
        echo "Error: npm is not available in PATH"
        echo "On NixOS: Install nodejs via package manager"
        echo "On Darwin: Install via Homebrew (brew install node)"
        exit 1
      fi

      echo "========== Installed Versions =========="
      npm list -g --depth=0 | grep @anthropic-ai/claude-code || echo "@anthropic-ai/claude-code: not installed"
      npm list -g --depth=0 | grep opencode-ai || echo "opencode-ai: not installed"

      echo "========== Updating Packages =========="
      npm install -g @anthropic-ai/claude-code@latest opencode-ai@latest

      echo "========== Updated Versions =========="
      npm list -g --depth=0 | grep @anthropic-ai/claude-code
      npm list -g --depth=0 | grep opencode-ai
    '';
    meta = with final.lib; {
      description = "Update Claude Code and OpenCode AI packages to latest versions";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
}
