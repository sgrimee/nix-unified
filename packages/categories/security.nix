# packages/categories/security.nix
{
  pkgs,
  lib,
  hostCapabilities ? {},
  ...
}: {
  core = with pkgs; [
    age # Modern encryption tool with small explicit keys
    sops # Secrets OPerationS - encrypted file editor
    ssh-to-age # Convert SSH keys to age keys
    gitleaks # Detect and prevent secrets in git repos
    rustscan # Modern port scanner built in Rust
    tcpdump # Network packet analyzer
    _1password-cli # 1Password command-line interface
    trippy # Network path analysis tool with ping/traceroute
  ];

  metadata = {
    description = "Security packages";
    conflicts = [];
    requires = [];
    size = "medium";
    priority = "low";
  };
}
