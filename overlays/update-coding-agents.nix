final: prev: {
  update-coding-agents = prev.writeShellApplication {
    name = "update-coding-agents";
    runtimeInputs = [];
    text = ''
      # Update Claude Code
      if ! command -v claude >/dev/null 2>&1; then
        echo "Warning: claude is not available in PATH"
        echo "Skipping Claude Code update"
      else
        echo "========== Updating Claude Code =========="
        claude update
      fi

      echo ""

      # Update OpenCode AI
      if ! command -v npm >/dev/null 2>&1; then
        echo "Warning: npm is not available in PATH"
        echo "Skipping OpenCode AI update"
      else
        echo "========== OpenCode AI: Installed Version =========="
        npm list -g --depth=0 | grep opencode-ai || echo "opencode-ai: not installed"

        echo "========== Updating OpenCode AI =========="
        npm install -g opencode-ai@latest

        echo "========== OpenCode AI: Updated Version =========="
        npm list -g --depth=0 | grep opencode-ai
      fi
    '';
    meta = with final.lib; {
      description = "Update Claude Code and OpenCode AI packages to latest versions";
      license = licenses.mit;
      platforms = platforms.all;
    };
  };
}
