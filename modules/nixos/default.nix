{ host, inputs, user, }: {
  # the following variables are passed to the imports (when they accept arguments):
  # config inputs lib modulesPath options overlays specialArgs stateVersion system

  imports = [
    # All modules now loaded via capabilities - this file can be removed eventually
    # The following are now loaded via capabilities:
    # ./authorized_keys.nix - via security.ssh.server
    # ./console.nix - via coreModules
    # ./display.nix - via features.desktop
    # ./environment.nix - via coreModules
    # ./greetd.nix - via environment.desktop.sway
    # ./hardware.nix - via coreModules
    # ./i18n.nix - via coreModules
    # ./iwd.nix - via hardware.wifi
    # ./kanata.nix - via hardware.keyboard.advanced
    # ./mounts.nix - via features.desktop
    # ./networking.nix - via coreModules
    # ./nix.nix - via coreModules
    # ./nix-ld.nix - via features.development
    # ./openssh.nix - via security.ssh.server
    # ./polkit.nix - via coreModules
    # ./printing.nix - via hardware.printer
    # ./sound.nix - via features.multimedia + hardware.audio
    # ./strongswan.nix - via security.vpn
    # ./sway.nix - via environment.desktop.sway + environment.windowManager.sway
    # ./time.nix - via coreModules
    # ./vscode.nix - via features.development
    
    # Removed empty modules:
    # ./keyboard.nix - was empty/commented out
    # ./touchpad.nix - was empty/commented out
  ];
}
