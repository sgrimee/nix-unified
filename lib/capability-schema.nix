# Capability Schema Definition
# Defines the standard structure for host capability declarations
# Based on comprehensive analysis of existing host configurations

{ lib, ... }:

{
  # Standard capability schema that all hosts must conform to
  capabilitySchema = {
    # Core platform information
    platform = {
      type = lib.types.enum [ "nixos" "darwin" ];
      description = "Host platform type";
      required = true;
    };

    architecture = {
      type = lib.types.enum [ "x86_64" "aarch64" ];
      description = "CPU architecture";
      required = true;
    };

    # Feature flags for major functionality groups
    features = {
      # Development and productivity
      development = {
        type = lib.types.bool;
        default = true;
        description = "Development tools and programming languages";
      };

      # Desktop environments and GUI
      desktop = {
        type = lib.types.bool;
        default = false;
        description = "GUI desktop environment";
      };

      # Gaming and entertainment
      gaming = {
        type = lib.types.bool;
        default = false;
        description = "Gaming software and optimizations";
      };

      # Multimedia content creation
      multimedia = {
        type = lib.types.bool;
        default = false;
        description = "Video/audio editing and content creation";
      };

      # Server and daemon services
      server = {
        type = lib.types.bool;
        default = false;
        description = "Server services and daemon configurations";
      };

      # Corporate/enterprise tools
      corporate = {
        type = lib.types.bool;
        default = false;
        description = "Corporate productivity and collaboration tools";
      };

      # AI and machine learning
      ai = {
        type = lib.types.bool;
        default = false;
        description = "AI/ML frameworks and GPU compute";
      };

      # Amateur radio / ham
      ham = {
        type = lib.types.bool;
        default = false;
        description = "Amateur (ham) radio tools";
      };
    };

    # Hardware-specific capabilities
    hardware = {
      # CPU vendor and optimizations
      cpu = {
        type = lib.types.enum [ "intel" "amd" "apple" ];
        description = "CPU vendor for optimization";
        required = true;
      };

      # GPU configuration
      gpu = {
        type =
          lib.types.nullOr (lib.types.enum [ "nvidia" "amd" "intel" "apple" ]);
        default = null;
        description = "Dedicated GPU vendor";
      };

      # Audio system
      audio = {
        type = lib.types.enum [ "pipewire" "pulseaudio" "coreaudio" ];
        description = "Audio system backend";
        required = true;
      };

      # Display configuration
      display = {
        hidpi = {
          type = lib.types.bool;
          default = false;
          description = "High DPI display support";
        };

        multimonitor = {
          type = lib.types.bool;
          default = false;
          description = "Multiple monitor setup";
        };
      };

      # Connectivity features
      bluetooth = {
        type = lib.types.bool;
        default = false;
        description = "Bluetooth hardware support";
      };

      wifi = {
        type = lib.types.bool;
        default = false;
        description = "WiFi hardware support";
      };

      printer = {
        type = lib.types.bool;
        default = false;
        description = "Printer support";
      };

      keyboard = {
        swapAltCommand = {
          type = lib.types.bool;
          default = false;
          description = "Swap Alt and Command keys (useful for Mac keyboards on NixOS)";
        };
      };
    };

    # Role-based configurations
    roles = {
      type = lib.types.listOf (lib.types.enum [
        "workstation" # Primary development/work machine
        "build-server" # Distributed build server
        "gaming-rig" # Gaming-focused configuration
        "media-center" # Media streaming and content
        "home-server" # Home automation and services
        "mobile" # Laptop/portable device
      ]);
      default = [ "workstation" ];
      description = "Host roles and primary use cases";
    };

    # Environment preferences
    environment = {
      # Desktop environment selection
      desktop = {
        type =
          lib.types.nullOr (lib.types.enum [ "gnome" "sway" "kde" "macos" ]);
        default = null;
        description = "Desktop environment choice";
      };

      # Shell configuration
      shell = {
        primary = {
          type = lib.types.enum [ "zsh" "fish" "bash" ];
          default = "zsh";
          description = "Primary interactive shell";
        };

        additional = {
          type = lib.types.listOf (lib.types.enum [ "zsh" "fish" "bash" ]);
          default = [ ];
          description = "Additional shells to install";
        };
      };

      # Terminal emulator
      terminal = {
        type =
          lib.types.enum [ "alacritty" "wezterm" "kitty" "iterm2" "terminal" ];
        default = "alacritty";
        description = "Preferred terminal emulator";
      };

      # Window manager (for desktop environments that support it)
      windowManager = {
        type = lib.types.nullOr (lib.types.enum [ "aerospace" "i3" "sway" ]);
        default = null;
        description = "Window manager overlay";
      };
    };

    # Service configurations
    services = {
      # Distributed builds
      distributedBuilds = {
        enabled = {
          type = lib.types.bool;
          default = false;
          description = "Enable distributed build participation";
        };

        role = {
          type = lib.types.enum [ "client" "server" "both" ];
          default = "client";
          description = "Distributed build role";
        };
      };

      # Home automation
      homeAssistant = {
        type = lib.types.bool;
        default = false;
        description = "Home Assistant server";
      };

      # Development services
      development = {
        docker = {
          type = lib.types.bool;
          default = false;
          description = "Docker containerization";
        };

        databases = {
          type = lib.types.listOf
            (lib.types.enum [ "postgresql" "mysql" "sqlite" "redis" ]);
          default = [ ];
          description = "Database services to enable";
        };
      };
    };

    # Security and access control
    security = {
      # SSH configuration
      ssh = {
        server = {
          type = lib.types.bool;
          default = false;
          description = "Enable SSH server";
        };

        client = {
          type = lib.types.bool;
          default = true;
          description = "Enable SSH client";
        };
      };

      # Firewall configuration
      firewall = {
        type = lib.types.bool;
        default = true;
        description = "Enable host firewall";
      };

      # Secret management
      secrets = {
        type = lib.types.bool;
        default = true;
        description = "Enable SOPS secret management";
      };
      # VPN support
      vpn = {
        type = lib.types.bool;
        default = false;
        description = "Enable VPN client (StrongSwan L2TP/IPSec)";
      };
    };
  };

  # Validation function for capability declarations
  validateCapabilities = _capabilities:
    let
      errors = [ ];
      # Add validation logic here
    in {
      valid = errors == [ ];
      errors = errors;
    };

  # Helper function to extract capabilities from existing host config
  inferCapabilitiesFromConfig = _hostConfig:
    {
      # Return inferred capability structure
    };
}
