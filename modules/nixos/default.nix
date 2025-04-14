{
  host,
  inputs,
  user,
}: {
  # the following variables are passed to the imports (when they accept arguments):
  # config inputs lib modulesPath options overlays specialArgs stateVersion system

  imports = [
    ../hosts/${host}/system.nix
    ./authorized_keys.nix
    ./console.nix
    ./display.nix
    ./environment.nix
    ./fonts.nix
    ./greetd.nix
    ./hardware.nix
    ./i18n.nix
    ./iwd.nix
    ./kanata.nix
    ./keyboard.nix
    ./networking.nix
    ./nix.nix
    ./nix-ld.nix
    ./openssh.nix
    ./polkit.nix
    ./printing.nix
    ./sound.nix
    ./time.nix
    ./touchpad.nix
  ];
}
