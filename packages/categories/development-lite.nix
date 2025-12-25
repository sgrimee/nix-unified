# packages/categories/development-lite.nix
# Lightweight development category for resource-constrained hosts
# Excludes: heavy editors (vscode), specialized tools (sonar-scanner-cli)
{pkgs, ...}: {
  # Core development tools
  core = with pkgs; [
    gh
    direnv
    update-coding-agents # From overlay - updates Claude Code and OpenCode AI packages
    go
    lazygit
    mdformat
    uv
    espflash # ESP32/ESP8266 serial flasher (Rust-based alternative to esptool)
  ];

  # Language-specific packages
  languages = {
    nix = with pkgs; [nil nixpkgs-fmt alejandra deadnix];

    rust = with pkgs; [rustc cargo rustfmt clippy];

    python = with pkgs; [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      ruff
    ];
  };

  # IDE and editors (lightweight only)
  editors = with pkgs; [vim neovim];

  # Platform-specific development tools (lightweight)
  platformSpecific = {
    linux = with pkgs; [
      gdb
      valgrind
      strace
      # JavaScript/Node.js tools (Linux only - Darwin uses Homebrew)
      # nodejs, npm, yarn, typescript handled by modules/home-manager/user/programs/node.nix
      # vscode excluded from lite version
    ];

    darwin = with pkgs; [
      # macOS-specific dev tools
      # Note: Node.js/npm and VSCode managed by Homebrew on Darwin
    ];
  };

  # Package metadata
  metadata = {
    description = "Lightweight development tools for resource-constrained hosts";
    conflicts = [];
    requires = [];
    size = "medium";
    priority = "high";
  };
}
