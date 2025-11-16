# Environment Module Mappings
# Maps environment capabilities (desktop, shell, terminal, etc.) to module imports
{...}: {
  environmentModules = {
    desktop = {
      gnome = {
        nixos = [
          ../../modules/nixos/greetd.nix
          ../../modules/nixos/gnome.nix
        ];
        darwin = [];
        homeManager = [];
      };
      sway = {
        nixos = [
          ../../modules/nixos/greetd.nix
          ../../modules/nixos/sway.nix
        ];
        darwin = [];
        homeManager = [
          ../../modules/home-manager/wl-sway.nix
          ../../modules/home-manager/waybar.nix
          ../../modules/home-manager/quickshell.nix
          ../../modules/home-manager/user/rofi.nix
        ];
      };
      niri = {
        nixos = [
          ../../modules/nixos/greetd.nix
          ../../modules/nixos/niri.nix
        ];
        darwin = [];
        homeManager = [
          ../../modules/home-manager/niri.nix
          ../../modules/home-manager/waybar.nix
          ../../modules/home-manager/quickshell.nix
          ../../modules/home-manager/user/rofi.nix
        ];
      };
      kde = {
        nixos = [];
        darwin = [];
        homeManager = [];
      };
      darwin = {
        nixos = [];
        darwin = [
          ../../modules/darwin/dock.nix
          ../../modules/darwin/finder.nix
        ];
        homeManager = [];
      };
    };

    shell = {
      zsh = {
        nixos = [];
        darwin = [];
        homeManager = [];
      };
      fish = {
        nixos = [];
        darwin = [];
        homeManager = [];
      };
      bash = {
        nixos = [];
        darwin = [];
        homeManager = [];
      };
    };

    terminal = {
      alacritty = {
        nixos = [];
        darwin = [];
        homeManager = [];
      };
      ghostty = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/user/ghostty.nix];
      };
      foot = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/user/foot.nix];
      };
    };

    windowManager = {
      sway = {
        nixos = [];
        darwin = [];
        homeManager = [];
      };
      aerospace = {
        nixos = [];
        darwin = [../../modules/darwin/window-manager.nix];
        homeManager = [];
      };
    };

    bar = {
      waybar = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/waybar.nix];
      };
      quickshell = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/quickshell.nix];
      };
      caelestia = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/user/programs/caelestia.nix];
      };
    };
  };
}
