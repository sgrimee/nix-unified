# packages/categories/development.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
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
  ];

  # Language-specific packages
  languages = {
    nix = with pkgs; [ nil nixpkgs-fmt alejandra deadnix ];

    rust = with pkgs; [ rustc cargo rustfmt clippy ];

    python = with pkgs; [
      python3
      python3Packages.pip
      python3Packages.virtualenv
      ruff
    ];
  };

  # IDE and editors
  editors = with pkgs; [ vscode vim neovim ];

  # Platform-specific development tools
  platformSpecific = {
    linux = with pkgs; [
      gdb
      valgrind
      strace
      # JavaScript/Node.js tools (Linux only - Darwin uses Homebrew)
      nodejs
      nodePackages.npm
      nodePackages.yarn
      nodePackages.typescript
    ];

    darwin = with pkgs;
      [
        # macOS-specific dev tools
        # Note: Node.js/npm managed by Homebrew on Darwin
      ];
  };

  # Package metadata
  metadata = {
    description = "Development tools and programming languages";
    conflicts = [ ];
    requires = [ ];
    size = "large";
    priority = "high";
  };
}
