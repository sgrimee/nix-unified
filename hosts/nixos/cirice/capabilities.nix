# Capability Declaration for cirice
# Framework AMD AI 300 series running NixOS with Sway (Wayland) desktop
# Cloned from nixair but with updated hardware capabilities

{
  # Core platform information
  platform = "nixos";
  architecture = "x86_64";

  # Feature flags for major functionality groups
  features = {
    development = true; # Full development environment
    desktop = true; # Sway Wayland desktop environment
    gaming = false; # No gaming-specific software installed
    multimedia = true; # Media players and codecs
    server = false; # Not a server host
    corporate = false; # No corporate tools
    ai = false; # No specialized AI/ML setup needed
  };

  # Hardware-specific capabilities
  hardware = {
    cpu = "amd"; # AMD Ryzen AI 300 series
    gpu = "amd"; # AMD integrated graphics with AI acceleration
    audio = "pipewire"; # Modern audio system
    display = {
      hidpi = true; # High resolution Framework display
      multimonitor = true; # Supports external monitors
    };
    bluetooth = true; # Built-in Bluetooth
    wifi = true; # Built-in WiFi
    printer = true; # CUPS printing support
    keyboard = {
      advanced = true; # Kanata keyboard remapping with home row mods
      devices = [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ];
    };
    # Resource capabilities for Nix configuration
    large-ram = true; # High memory system, use larger download buffers
    large-disk = true; # Ample storage, enable keep-outputs and keep-derivations
  };

  # Host roles and primary use cases
  roles = [ "mobile" "workstation" ];

  # Environment preferences
  environment = {
    desktop = "sway"; # Sway Wayland compositor
    shell = {
      primary = "zsh"; # Primary shell
      additional = [ "fish" ]; # Additional shells available
    };
    terminal = "alacritty"; # Preferred terminal emulator
    windowManager = "sway"; # Sway is both desktop and window manager
  };

  # Service configurations
  services = {
    distributedBuilds = {
      enabled = true; # Now serves as build server (faster than legion)
      role = "server"; # Primary build server
    };
    homeAssistant = false; # No Home Assistant
    development = {
      docker = true; # Enable Docker for development
      databases = [ "postgresql" "sqlite" ]; # Common databases
    };
  };

  # Security and access control
  security = {
    ssh = {
      server = true; # SSH server enabled
      client = true; # SSH client enabled
    };
    firewall = true; # Firewall enabled
    secrets = true; # SOPS secret management
    vpn = true; # StrongSwan L2TP/IPSec VPN client
  };
}
