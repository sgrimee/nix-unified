# packages/categories/productivity.nix
{
  pkgs,
  lib,
  hostCapabilities ? {},
  ...
}: {
  core = with pkgs; [
    glow # Markdown viewer with syntax highlighting
    neofetch # System information display tool
    progress # Coreutils progress viewer (cp, mv, dd, tar, etc.)
    tldr # Simplified and community-driven man pages
    yazi # Blazing fast terminal file manager
    zellij # Terminal workspace multiplexer
    gping # Ping with a graph
  ];

  browsers = with pkgs;
    [
      firefox # Mozilla Firefox web browser
    ]
    ++
    # Chromium only available on Linux platforms
    (lib.optional pkgs.stdenv.isLinux chromium); # Open-source version of Chrome

  metadata = {
    description = "Productivity packages";
    conflicts = [];
    requires = [];
    size = "medium";
    priority = "medium";
  };
}
