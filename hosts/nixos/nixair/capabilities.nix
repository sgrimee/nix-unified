# Capability Declaration for nixair
# Apple MacBook Air 2011 running NixOS with Sway (Wayland) desktop
# Based on baseline analysis of current configuration
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
    ai = false; # No AI/ML specific setup (resource constrained)
  };

  # Hardware-specific capabilities
  hardware = {
    cpu = "intel"; # Intel Core i7 (2011 MacBook Air)
    gpu = "intel"; # Intel integrated graphics
    audio = "pipewire"; # Modern audio system
    display = {
      hidpi = false; # Standard resolution display
      multimonitor = false; # Single display setup (laptop)
    };
    bluetooth = true; # Built-in Bluetooth
    wifi = true; # Built-in WiFi
    printer = true; # CUPS printing support
    keyboard = {
      advanced = true; # Kanata keyboard remapping with home row mods
      swapAltCommand = true; # Swap Alt and Command keys (Mac keyboard on NixOS)
      devices = ["/dev/input/by-path/pci-0000:00:1a.7-usbv2-0:1.2:1.0-event-kbd"];
    };
    # Resource capabilities for Nix configuration
    large-ram = false; # Limited memory, use smaller download buffers
    large-disk = false; # Limited storage, keep default settings
  };

  # Host roles and primary use cases
  roles = ["mobile" "workstation"];

  # Environment preferences
  environment = {
    desktop = "sway"; # Sway Wayland compositor
    shell = {
      primary = "zsh"; # Primary shell
      additional = ["fish"]; # Additional shells available
    };
    terminal = "ghostty"; # Preferred terminal emulator
    windowManager = "sway"; # Sway is both desktop and window manager
  };

  # Service configurations
  services = {
    distributedBuilds = {
      enabled = true; # Uses legion.local for heavy builds
      role = "client"; # Client only (resource constrained)
    };
    homeAssistant = false; # No Home Assistant
    development = {
      docker = false; # No Docker setup (resource constrained)
      databases = []; # No database services
    };
  };

  # Security and access control
  security = {
    ssh = {
      server = true; # SSH server enabled
      client = true; # SSH client enabled
    };
    firewall = true; # Custom firewall rules enabled
    secrets = true; # SOPS secret management
    vpn = true; # StrongSwan L2TP/IPSec VPN client
  };

  # Build machine configuration
  buildMachines = {
    enable = ["cirice"]; # Use cirice as remote build machine
  };
}
