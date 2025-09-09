# Minimal Module Mapping Configuration
# Maps capabilities to EXISTING module imports only
# This is a realistic version that matches the current module structure

{ lib, ... }:

{
  # Core modules that are always imported
  coreModules = {
    nixos = [
      ../modules/nixos/networking.nix
      ../modules/nixos/console.nix
      ../modules/nixos/environment.nix
      ../modules/nixos/hardware.nix
      ../modules/nixos/i18n.nix
      ../modules/nixos/nix.nix
      ../modules/nixos/time.nix
      ../modules/nixos/polkit.nix
    ];

    darwin = [
      ../modules/darwin/networking.nix
      ../modules/darwin/dock.nix
      ../modules/darwin/finder.nix
      # Other core modules don't exist yet - will be added incrementally
    ];

    shared = [
      # Home Manager is included via special modules
    ];
  };

  # Feature-based module mappings - only existing modules
  featureModules = {
    # Most feature modules don't exist yet - commenting out until they're created
    development = {
      nixos = [ ../modules/nixos/nix-ld.nix ../modules/nixos/vscode.nix ];
      darwin = [ ];
      homeManager = [ ];
    };

    desktop = {
      nixos = [
        ../modules/nixos/display.nix
        ../modules/nixos/fonts.nix
        ../modules/nixos/mounts.nix
        # Add more as they exist
      ];
      darwin = [ ];
      homeManager = [ ];
    };

    gaming = {
      nixos = [ ];
      darwin = [ ];
      homeManager = [ ];
    };

    multimedia = {
      nixos = [ ../modules/nixos/sound.nix ];
      darwin = [ ];
      homeManager = [ ];
    };

    server = {
      nixos = [ ];
      darwin = [ ];
      homeManager = [ ];
    };

    corporate = {
      nixos = [ ];
      darwin = [ ../modules/darwin/homebrew ];
      homeManager = [ ];
    };

    ai = {
      nixos = [ ../modules/nixos/nvidia.nix ];
      darwin = [ ];
      homeManager = [ ];
    };
  };

  # Hardware-specific module mappings - only existing modules
  hardwareModules = {
    cpu = {
      intel = {
        nixos = [ ];
        darwin = [ ];
      };
      amd = {
        nixos = [ ];
        darwin = [ ];
      };
      apple = {
        nixos = [ ];
        darwin = [ ];
      };
    };

    gpu = {
      nvidia = {
        nixos = [ ../modules/nixos/nvidia.nix ];
        darwin = [ ];
      };
      amd = {
        nixos = [ ];
        darwin = [ ];
      };
      intel = {
        nixos = [ ];
        darwin = [ ];
      };
      apple = {
        nixos = [ ];
        darwin = [ ];
      };
    };

    audio = {
      pipewire = {
        nixos = [ ../modules/nixos/sound.nix ];
        darwin = [ ];
      };
      pulseaudio = {
        nixos = [ ../modules/nixos/sound.nix ];
        darwin = [ ];
      };
      coreaudio = {
        nixos = [ ];
        darwin = [ ];
      };
    };

    display = {
      hidpi = {
        nixos = [ ../modules/nixos/display.nix ];
        darwin = [ ];
      };
      multimonitor = {
        nixos = [ ../modules/nixos/display.nix ];
        darwin = [ ];
      };
      "benq-display" = {
        nixos = [ ];
        darwin = [ ../modules/darwin/benq-display.nix ];
      };
    };

    connectivity = {
      bluetooth = {
        nixos = [ ];
        darwin = [ ];
      };
      wifi = {
        nixos = [ ../modules/nixos/iwd.nix ];
        darwin = [ ];
      };
      printer = {
        nixos = [ ../modules/nixos/printing.nix ];
        darwin = [ ];
      };
    };

    keyboard = {
      advanced = {
        nixos = [ ../modules/nixos/kanata.nix ];
        darwin = [ ];
      };
    };
  };

  # Role-based module mappings - mostly empty for now
  roleModules = {
    workstation = {
      nixos = [ ];
      darwin = [ ];
      homeManager = [ ];
    };

    "build-server" = {
      nixos = [ ];
      darwin = [ ];
      homeManager = [ ];
    };

    "gaming-rig" = {
      nixos = [ ../modules/nixos/nvidia.nix ];
      darwin = [ ];
      homeManager = [ ];
    };

    "media-center" = {
      nixos = [ ../modules/nixos/sound.nix ];
      darwin = [ ];
      homeManager = [ ];
    };

    "home-server" = {
      nixos = [ ];
      darwin = [ ];
      homeManager = [ ];
    };

    mobile = {
      nixos = [ ];
      darwin = [ ];
      homeManager = [ ];
    };
  };

  # Environment modules - only existing ones
  environmentModules = {
    desktop = {
      gnome = {
        nixos = [ ];
        darwin = [ ];
        homeManager = [ ];
      };
      sway = {
        nixos = [ ../modules/nixos/sway.nix ../modules/nixos/greetd.nix ];
        darwin = [ ];
        homeManager = [ ];
      };
      kde = {
        nixos = [ ];
        darwin = [ ];
        homeManager = [ ];
      };
      macos = {
        nixos = [ ];
        darwin = [ ../modules/darwin/dock.nix ../modules/darwin/finder.nix ];
        homeManager = [ ];
      };
    };

    shell = {
      zsh = {
        nixos = [ ];
        darwin = [ ];
        homeManager = [ ];
      };
      fish = {
        nixos = [ ];
        darwin = [ ];
        homeManager = [ ];
      };
      bash = {
        nixos = [ ];
        darwin = [ ];
        homeManager = [ ];
      };
    };

    terminal = {
      alacritty = {
        nixos = [ ];
        darwin = [ ];
        homeManager = [ ];
      };
    };

    windowManager = {
      sway = {
        nixos = [ ../modules/nixos/sway.nix ];
        darwin = [ ];
        homeManager = [ ];
      };
      aerospace = {
        nixos = [ ];
        darwin = [ ../modules/darwin/window-manager.nix ];
        homeManager = [ ];
      };
    };
  };

  # Service-specific module mappings - mostly empty
  serviceModules = {
    distributedBuilds = {
      client = {
        nixos = [ ];
        darwin = [ ];
      };
      server = {
        nixos = [ ];
        darwin = [ ];
      };
      both = {
        nixos = [ ];
        darwin = [ ];
      };
    };

    homeAssistant = {
      nixos = [ ];
      darwin = [ ];
    };

    development = {
      docker = {
        nixos = [ ];
        darwin = [ ];
      };
      databases = {
        postgresql = {
          nixos = [ ];
          darwin = [ ];
        };
        mysql = {
          nixos = [ ];
          darwin = [ ];
        };
      };
    };
  };

  # Security module mappings - mostly empty
  securityModules = {
    ssh = {
      server = {
        nixos = [ ../modules/nixos/openssh.nix ../modules/nixos/authorized_keys.nix ];
        darwin = [ ];
      };
      client = {
        nixos = [ ];
        darwin = [ ];
        homeManager = [ ];
      };
    };

    firewall = {
      nixos = [ ];
      darwin = [ ];
    };

    secrets = {
      nixos = [ ];
      darwin = [ ];
      homeManager = [ ];
    };

    vpn = {
      nixos = [ ../modules/nixos/strongswan.nix ];
      darwin = [ ];
    };
  };

  # Special module helpers for modules that require arguments
  specialModules = {
    homeManager = {
      path = ../modules/home-manager;
      requiresArgs = [ "inputs" "host" "user" ];
    };

    nixosBase = {
      path = ../modules/nixos;
      requiresArgs = [ "inputs" "host" "user" ];
    };

    darwinBase = {
      path = ../modules/darwin;
      requiresArgs = [ "inputs" "host" "user" ];
    };
  };
}
