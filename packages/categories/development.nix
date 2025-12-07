# packages/categories/development.nix
{pkgs, ...}: {
  # Core development tools
  core = with pkgs; [
    git
    gh
    direnv
    just
    sonar-scanner-cli
    update-coding-agents # From overlay - updates Claude Code and OpenCode AI packages
    go
    ripgrep
    lazygit
    mdformat
    uv
    carapace
    joshuto
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

  # IDE and editors
  editors = with pkgs; [vim neovim];

  # Platform-specific development tools
  platformSpecific = {
    linux = with pkgs; [
      gdb
      valgrind
      strace
      # JavaScript/Node.js tools (Linux only - Darwin uses Homebrew)
      # nodejs, npm, yarn, typescript handled by modules/home-manager/user/programs/node.nix
      # VSCode (Linux only - Darwin uses Homebrew)
      vscode
    ];

    darwin = with pkgs; [
      # macOS-specific dev tools
      # Note: Node.js/npm and VSCode managed by Homebrew on Darwin
    ];
  };

  # Package metadata
  metadata = {
    description = "Development tools and programming languages";
    conflicts = [];
    requires = [];
    size = "large";
    priority = "high";
  };
}
