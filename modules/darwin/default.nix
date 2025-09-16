{ host, inputs, user, ... }: {
  imports = [
    ./benq-display.nix # BenQ display management tools
    ./determinate.nix # Determinate Nix configuration
    ./dock.nix # configure dock
    ./environment.nix # configure environment (e.g default shell)
    ./finder.nix # configure finder
    # ./fonts.nix # REMOVED - now using unified home-manager fonts configuration
    ./homebrew # install homebrew apps and configure homebrew itsef
    ./keyboard.nix # settings for key repeat etc
    ./mac-app-util.nix # tools to make apps launchable with spotlight and Alfred.app
    ./music_app.nix # set default music app instead of Apple music
    ./networking.nix # configure networking (e.g. hostname, dns, etc)
    ./screen.nix # configure display of fonts etc
    ./system.nix # configure system settings
    ./trackpad.nix # configure trackpad (e.g. force feedback)
    ./window-manager.nix # window manager (aerospace + jankyborders)
  ];

  # TODO: put this in a module once I find how to pass the user var
  # may not have any effect on a corporate managed mac
  users.users.${user}.openssh.authorizedKeys.keys =
    import ../../files/authorized_keys.nix;
}
