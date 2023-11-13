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
    ./boot.nix
    ./console.nix
    ./display.nix
    ./environment.nix
    ./fonts.nix
    ./greetd.nix
    ./hardware.nix
    ./i18n.nix
    ./iwd.nix
    ./keyboard.nix
    ./networking.nix
    ./nix.nix
    ./openssh.nix
    ./printing.nix
    ./sound.nix
    ./time.nix
    ./touchpad.nix
    ./wayland.nix
    # ./xserver.nix
  ];
}
