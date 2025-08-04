# packages/categories/development.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:

{
  # Core development tools
  core = with pkgs; [ git gh direnv just sonar-scanner-cli ];

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

    javascript = with pkgs; [
      nodejs
      nodePackages.npm
      nodePackages.yarn
      nodePackages.typescript
    ];
  };

  # IDE and editors
  editors = with pkgs; [ vscode vim neovim ];

  # Platform-specific development tools
  platformSpecific = {
    linux = with pkgs; [ gdb valgrind strace ];

    darwin = with pkgs;
      [
        # macOS-specific dev tools
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
