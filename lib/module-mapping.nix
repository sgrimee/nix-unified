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
      ../modules/nixos/determinate.nix
      ../modules/nixos/time.nix
      ../modules/nixos/polkit.nix
      ../modules/nixos/build-machines.nix
    ];

    darwin = [
      ../modules/darwin/determinate.nix # MUST BE INCLUDED - disables nix-darwin's nix management
      ../modules/darwin/networking.nix
      ../modules/darwin/dock.nix
      ../modules/darwin/finder.nix
      ../modules/darwin/environment.nix
      ../modules/darwin/homebrew
      ../modules/darwin/keyboard.nix
      ../modules/darwin/mac-app-util.nix
      ../modules/darwin/music_app.nix
      ../modules/darwin/screen.nix
      ../modules/darwin/sudo.nix
      ../modules/darwin/system.nix
      ../modules/darwin/trackpad.nix
      ../modules/darwin/build-machines.nix
    ];

    shared = [
      # Home Manager is included via special modules
    ];

    homeManager = [ ../modules/home-manager/nixpkgs-config.nix ];
  };

  # Feature-based module mappings - only existing modules
  featureModules = {
    # Most feature modules don't exist yet - commenting out until they're created
    development = {
      nixos = [
        ../modules/nixos/nix-ld.nix
        ../modules/nixos/vscode.nix
        ../modules/nixos/development/rust.nix
      ];
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
      nixos = [
        ../modules/nixos/gaming.nix
        ../modules/nixos/gaming-graphics.nix
        ../modules/nixos/gaming-performance.nix
      ];
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
      nixos = [ ../modules/nixos/webex-tui.nix ];
      darwin = [ ../modules/darwin/webex-tui.nix ];
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
    # CPU modules not implemented yet - will add when specific CPU optimizations are needed
    cpu = { };

    gpu = {
      nvidia = {
        nixos = [ ../modules/nixos/nvidia.nix ];
        darwin = [ ];
      };
      amd = {
        nixos = [ ../modules/nixos/amd-graphics.nix ];
        darwin = [ ];
      };
      # Other GPU types (intel, apple) not implemented yet
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
      # coreaudio not implemented yet for Darwin
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
      # bluetooth modules not implemented yet
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
        nixos = [ ../modules/nixos/greetd.nix ../modules/nixos/gnome.nix ];
        darwin = [ ];
        homeManager = [ ];
      };
      sway = {
        nixos = [ ../modules/nixos/greetd.nix ../modules/nixos/sway.nix ];
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
        nixos = [ ];
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
      nixos = [ ../modules/nixos/homeassistant-user.nix ];
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
        nixos =
          [ ../modules/nixos/openssh.nix ../modules/nixos/authorized_keys.nix ];
        darwin = [ ];
      };
      client = {
        nixos = [ ];
        darwin = [ ../modules/darwin/ssh.nix ];
        homeManager = [ ];
      };
    };

    firewall = {
      nixos = [ ];
      darwin = [ ];
    };

    secrets = {
      nixos = [ ../modules/nixos/sops.nix ];
      darwin = [ ../modules/darwin/sops.nix ];
      homeManager = [ ];
    };

    vpn = {
      nixos = [ ../modules/nixos/strongswan.nix ];
      darwin = [ ];
    };
  };

  # Virtualization module mappings
  virtualizationModules = {
    windowsGpuPassthrough = {
      nixos = [ ../modules/nixos/virtualization/windows-gpu-passthrough.nix ];
      darwin = [ ];
    };
    baseVirtualization = {
      nixos = [ ../modules/nixos/virtualization/base.nix ];
      darwin = [ ];
    };
  };

  # Special module helpers for modules that require arguments
  specialModules = {
    homeManager = {
      path = ../modules/home-manager;
      requiresArgs = [ "inputs" "host" "user" ];
    };

    # nixosBase and darwinBase removed - individual modules are now imported directly
    # via coreModules and other capability-based mappings
  };
}
