# 17. Sudo Touch ID + YubiKey/U2F Integration

## Implementation

The `modules/darwin/sudo.nix` module provides sudo authentication with Touch ID and YubiKey/U2F support:

### Configuration

```nix
{ lib, ... }:
let
  pamU2fPath = "/opt/homebrew/opt/pam-u2f/lib/pam/pam_u2f.so";
  pamU2fExists = builtins.pathExists pamU2fPath;
in
{
  # Install pam-u2f via homebrew for YubiKey support
  homebrew.brews = [ "pam-u2f" ];

  # Configure sudo with extended credential caching timeout (15 minutes)
  environment.etc."sudoers.d/timeout".text = ''
    Defaults timestamp_timeout=15
  '';

  # Authentication methods for sudo
  security.pam.services.sudo_local = {
    enable = true;
    reattach = true; # fixes Touch ID inside tmux and screen
    text = lib.optionalString pamU2fExists "auth sufficient ${pamU2fPath} debug";
    touchIdAuth = true;
    watchIdAuth = true;
  };
}
```

### Features

- **Touch ID**: Primary authentication method
- **YubiKey/U2F**: Hardware fallback (only configured if pam-u2f is installed)
- **Extended timeout**: 15-minute credential caching
- **tmux/screen compatibility**: Touch ID works inside terminal multiplexers

### Setup

1. The module automatically installs `pam-u2f` via Homebrew
1. Register your U2F key:
   ```bash
   pamu2fcfg > ~/.config/Yubico/u2f_keys
   ```
1. Rebuild your Darwin configuration
