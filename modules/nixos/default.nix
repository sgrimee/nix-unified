{ host, inputs, user, }: {
  # the following variables are passed to the imports (when they accept arguments):
  # config inputs lib modulesPath options overlays specialArgs stateVersion system

  imports = [
    ./authorized_keys.nix
    ./console.nix
    ./display.nix
    ./environment.nix
    # ./fonts.nix # REMOVED - now using unified home-manager fonts configuration
    ./greetd.nix
    ./hardware.nix
    ./i18n.nix
    ./iwd.nix
    ./kanata.nix
    ./keyboard.nix
    ./mounts.nix
    ./networking.nix
    ./nix.nix
    ./nix-ld.nix
    ./openssh.nix
    ./polkit.nix
    ./printing.nix
    ./sound.nix
    ./strongswan.nix
    ./sway.nix
    ./time.nix
    ./touchpad.nix
    ./vscode.nix
  ];
}
