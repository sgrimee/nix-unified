# packages/versions.nix
{lib, ...}: let
  # Define package versions and channels
  packageVersions = {
    stable = {
      # Use stable nixpkgs for production packages
      firefox = "stable";
      git = "stable";
      vscode = "stable";
    };

    unstable = {
      # Use unstable for newer versions
      neovim = "unstable";
      rust = "unstable";
      nodejs = "unstable";
    };

    specific = {
      # Pin specific versions
      terraform = "1.5.0";
      kubernetes = "1.28.0";
    };
  };
in {
  inherit packageVersions;

  # Generate package with correct version
  getPackageVersion = pkgs: unstable: name: let
    versionType =
      if (packageVersions.stable or {}) ? ${name}
      then "stable"
      else if (packageVersions.unstable or {}) ? ${name}
      then "unstable"
      else if (packageVersions.specific or {}) ? ${name}
      then "specific"
      else "stable";
  in
    if versionType == "stable"
    then pkgs.${name}
    else if versionType == "unstable"
    then unstable.${name}
    else if versionType == "specific"
    then
      # Handle specific versions (would need overlay)
      pkgs.${name}
    else pkgs.${name};
}
