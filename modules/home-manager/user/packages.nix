{ inputs, pkgs, system, unstable, ... }: {
  # Reduced after migration of most packages into categorized package system.
  home.packages = with pkgs;
    [
      unstable.fish             # prefer unstable variant (category provides stable fish via none yet)
      hamlib_4                  # radio/ham tooling (left uncategorized intentionally)
      inputs.mactelnet.packages.${system}.mactelnet # external input package
      unstable.vscode-langservers-extracted # language servers (keep unstable)
    ] ++ lib.optionals pkgs.stdenv.isLinux [ ethtool unstable.qdmr spotifyd ];
}
