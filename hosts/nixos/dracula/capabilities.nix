# Capability Declaration for dracula
# Intel MacBook Pro 2013 running NixOS with Sway desktop
# Based on baseline analysis of current configuration

{
  # Core platform information
  platform = "nixos";
  architecture = "x86_64";

  # Feature flags for major functionality groups
  features = {
    development = true; # Full development environment
    desktop = true; # GNOME desktop environment
    gaming = true; # Lunar Client (Minecraft)
    multimedia = true; # Media players and codecs
    server = false; # Not a server host
    corporate = false; # No corporate tools
    ai = false; # No AI/ML specific setup
  };

  # Hardware-specific capabilities
  hardware = {
    cpu = "intel"; # Intel Core i7
    gpu = "intel"; # Intel integrated graphics
    audio = "pipewire"; # Modern audio system
    display = {
      hidpi = true; # HiDPI capable (commented out due to console issues)
      multimonitor = false; # Single display setup
    };
    bluetooth = true; # Built-in Bluetooth
    wifi = true; # Broadcom WiFi with proprietary driver
    printer = true; # CUPS printing support
    keyboard = {
      advanced = true; # Kanata keyboard remapping with home row mods
      devices =
        [ "/dev/input/by-path/pci-0000:00:14.0-usbv2-0:12:1.0-event-kbd" ];
    };
    # Resource capabilities for Nix configuration
    large-ram = true; # Sufficient memory for larger download buffers
    large-disk = false; # Standard storage, keep default settings
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
    terminal = "alacritty"; # Default terminal emulator
    windowManager = "sway"; # Sway is both desktop and window manager
  };

  # Service configurations
  services = {
    distributedBuilds = {
      enabled = false; # No distributed builds configuration
      role = "client"; # Would be client if enabled
    };
    homeAssistant = false; # No Home Assistant
    development = {
      docker = false; # No Docker setup
      databases = [ ]; # No database services
    };
  };

  # Security and access control
  security = {
    ssh = {
      server = true; # SSH server enabled
      client = true; # SSH client enabled
    };
    firewall = true; # NixOS firewall enabled (default rules)
    secrets = true; # SOPS secret management
  };

  # Build machine configuration
  buildMachines = {
    enable = [ "cirice" ]; # Use cirice as remote build machine
  };
}
