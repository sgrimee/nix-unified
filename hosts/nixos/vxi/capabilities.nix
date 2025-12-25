# Capability Declaration for vxi
# Cisco VXC 6215 thin client with AMD G-T56N processor
# Minimal niri desktop environment for constrained hardware
{
  # Core platform information
  platform = "nixos";
  architecture = "x86_64";

  # Feature flags for major functionality groups
  features = {
    development = false; # No development tools (resource constrained)
    desktop = true; # niri Wayland desktop environment
    gaming = false; # No gaming-specific software
    multimedia = false; # Keep minimal for resources
    server = false; # Not a server host
    corporate = false; # No corporate tools
    ai = false; # No AI/ML specific setup
    gnome = false; # No GNOME
  };

  # Hardware-specific capabilities
  hardware = {
    cpu = "amd"; # AMD G-T56N processor
    gpu = null; # Auto-detect radeon driver (older AMD GPU)
    audio = "pipewire"; # Modern audio system for basic audio
    display = {
      hidpi = false; # Standard resolution display
      multimonitor = false; # Single display setup
    };
    bluetooth = true; # Built-in Bluetooth
    wifi = false; # Ethernet-only device (thin client)
    printer = true; # CUPS printing support
    keyboard = {
      remapping = true; # Kanata keyboard remapping with homerow mods
      swapAltCommand = false; # Standard PC keyboard (no Mac key swap)
      fnKeyProfile = "standard"; # Standard PC keyboard layout
      devices = []; # Auto-detect keyboard devices
    };
    # Resource capabilities for Nix configuration
    large-ram = false; # Limited memory, use smaller download buffers
    large-disk = false; # Limited storage, keep default settings
  };

  # Host roles and primary use cases
  roles = ["thin-client"];

  # Environment preferences
  environment = {
    desktops = {
      available = ["niri"]; # Only niri available
      default = "niri";
    };
    bars = {
      available = ["waybar"]; # Only waybar available
      default = "waybar";
    };
    shell = {
      primary = "zsh"; # Primary shell
      additional = ["fish"]; # Additional shells available
    };
    terminal = "foot"; # Lightweight terminal (ghostty crashes on old AMD GPU)
  };

  # Service configurations
  services = {
    distributedBuilds = {
      enabled = true; # Use cirice.local for heavy builds (essential for this CPU)
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
    firewall = true; # NixOS firewall enabled (default rules)
    secrets = true; # SOPS secret management
  };

  # Build machine configuration
  buildMachines = {
    enable = ["cirice"]; # Use cirice as remote build machine
  };
}
