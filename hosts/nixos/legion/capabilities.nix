# Capability Declaration for legion
# High-performance Intel workstation with NVIDIA GPU and build server capabilities
# Based on baseline analysis of current configuration
{
  # Core platform information
  platform = "nixos";
  architecture = "x86_64";

  # Feature flags for major functionality groups
  features = {
    development = true; # Full development environment
    desktop = true; # GNOME desktop environment
    gaming = false; # No gaming-specific software installed
    multimedia = true; # Media players and codecs
    server = true; # Build server and HomeAssistant user
    corporate = false; # No corporate tools
    ai = true; # NVIDIA GPU for potential AI/ML workloads
  };

  # Hardware-specific capabilities
  hardware = {
    cpu = "intel"; # Intel CPU with optimizations
    gpu = "nvidia"; # NVIDIA GPU with proprietary drivers
    audio = "pipewire"; # Modern audio system
    display = {
      hidpi = false; # HiDPI support available but not enabled
      multimonitor = true; # Capable of multiple monitors
    };
    bluetooth = true; # Built-in Bluetooth
    wifi = true; # WiFi hardware support
    printer = true; # CUPS printing support
    keyboard = {
      advanced = true; # Kanata keyboard remapping with home row mods
      devices = ["/dev/input/by-path/pci-0000:00:14.0-usbv2-0:8:1.0-event-kbd"];
    };
    # Resource capabilities for Nix configuration
    large-ram = true; # High memory system, use larger download buffers
    large-disk = true; # Ample storage, enable keep-outputs and keep-derivations
  };

  # Host roles and primary use cases
  roles = ["workstation" "build-server"];

  # Environment preferences
  environment = {
    desktop = "gnome"; # GNOME desktop environment
    shell = {
      primary = "zsh"; # Primary shell
      additional = ["fish"]; # Additional shells available
    };
    terminal = "alacritty"; # Default terminal emulator
    windowManager = null; # Using GNOME's default window manager
  };

  # Service configurations
  services = {
    distributedBuilds = {
      enabled = true; # Secondary build server (lower priority than cirice)
      role = "server"; # Secondary build server
    };
    homeAssistant = true; # HomeAssistant user support enabled
    development = {
      docker = false; # No Docker setup
      databases = []; # No database services
    };
  };

  # Security and access control
  security = {
    ssh = {
      server = true; # SSH server enabled (for build clients)
      client = true; # SSH client enabled
    };
    firewall = true; # Custom firewall rules enabled
    secrets = true; # SOPS secret management
  };

  # Build machine configuration
  buildMachines = {
    enable = ["cirice"]; # Use cirice as remote build machine
  };
}
