# Hardware Module Mappings
# Maps hardware capabilities to module imports
{...}: {
  hardwareModules = {
    # CPU modules not implemented yet
    cpu = {};

    gpu = {
      nvidia = {
        nixos = [../../modules/nixos/nvidia.nix];
        darwin = [];
      };
      amd = {
        nixos = [../../modules/nixos/amd-graphics.nix];
        darwin = [];
      };
      # Other GPU types (intel, apple) not implemented yet
    };

    audio = {
      pipewire = {
        nixos = [../../modules/nixos/sound.nix];
        darwin = [];
      };
      pulseaudio = {
        nixos = [../../modules/nixos/sound.nix];
        darwin = [];
      };
      # coreaudio not implemented yet for Darwin
    };

    display = {
      hidpi = {
        nixos = [../../modules/nixos/display.nix];
        darwin = [];
      };
      multimonitor = {
        nixos = [../../modules/nixos/display.nix];
        darwin = [];
      };
      "benq-display" = {
        nixos = [];
        darwin = [../../modules/darwin/benq-display.nix];
      };
    };

    connectivity = {
      # bluetooth modules not implemented yet
      wifi = {
        nixos = [../../modules/nixos/iwd.nix];
        darwin = [];
      };
      printer = {
        nixos = [../../modules/nixos/printing.nix];
        darwin = [];
      };
    };

    keyboard = {
      remapping = {
        nixos = [../../modules/nixos/kanata.nix];
        darwin = [../../modules/darwin/keyboard.nix];
      };
    };
  };
}
