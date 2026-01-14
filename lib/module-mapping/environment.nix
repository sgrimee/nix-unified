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
          ../../modules/home-manager/quickshell-custom.nix
          ../../modules/home-manager/user/programs/wayland/rofi.nix
          ../../modules/home-manager/user/programs/wayland/fuzzel.nix
          ../../modules/home-manager/user/programs/wayland/grim.nix
          ../../modules/home-manager/user/programs/wayland/slurp.nix
          ../../modules/home-manager/user/programs/wayland/swaylock.nix
          ../../modules/home-manager/user/programs/wayland/mako.nix
          ../../modules/home-manager/user/programs/wayland/wl-clipboard.nix
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
          ../../modules/home-manager/quickshell-custom.nix
          ../../modules/home-manager/user/programs/wayland/rofi.nix
          ../../modules/home-manager/user/programs/wayland/fuzzel.nix
          ../../modules/home-manager/user/programs/wayland/grim.nix
          ../../modules/home-manager/user/programs/wayland/slurp.nix
          ../../modules/home-manager/user/programs/wayland/swaylock.nix
          ../../modules/home-manager/user/programs/wayland/mako.nix
          ../../modules/home-manager/user/programs/wayland/wl-clipboard.nix
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
        homeManager = [../../modules/home-manager/user/programs/terminals/alacritty.nix];
      };
      ghostty = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/user/programs/terminals/ghostty.nix];
      };
      foot = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/user/programs/terminals/foot.nix];
      };
      kitty = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/user/programs/terminals/kitty.nix];
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
      omniwm = {
        nixos = [];
        darwin = [../../modules/darwin/omniwm.nix];
        homeManager = [];
      };
      yabai = {
        nixos = [];
        darwin = []; # Placeholder for future yabai support
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
        homeManager = [../../modules/home-manager/quickshell-custom.nix];
      };
      caelestia = {
        nixos = [];
        darwin = [];
        homeManager = [../../modules/home-manager/user/programs/caelestia.nix];
      };
    };
  };
}
