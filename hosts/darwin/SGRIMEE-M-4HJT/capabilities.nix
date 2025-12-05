# Capability Declaration for SGRIMEE-M-4HJT
# Darwin workstation with comprehensive corporate toolset
# Based on baseline analysis of current configuration
{
  # Core platform information
  platform = "darwin";
  architecture = "aarch64";

  # Feature flags for major functionality groups
  features = {
    development = true; # Full development environment
    desktop = true; # macOS GUI environment
    gaming = true; # Steam and gaming applications
    multimedia = true; # Ableton Live Suite, audio production
    server = false; # Not a server host
    corporate = true; # Microsoft Office, Teams, corporate tools
    ai = false; # No AI/ML specific setup
    ham = true; # Amateur radio tools for complete workstation
  };

  # Hardware-specific capabilities
  hardware = {
    cpu = "apple-silicon"; # Apple Silicon Mac
    gpu = null; # Integrated graphics
    audio = "coreaudio"; # macOS Core Audio
    display = {
      hidpi = true; # Retina display support
      multimonitor = true; # BenQ display support enabled
      "benq-display" = true;
    };
    bluetooth = true; # Built-in Bluetooth
    wifi = true; # Built-in WiFi
    printer = true; # CUPS printing support
    keyboard = {
      remapping = true; # Enable keyboard remapping with homerow mods
      remapper = "karabiner"; # Use Karabiner-Elements on macOS
    };
    # Resource capabilities for Nix configuration
    large-ram = true; # High memory system, use larger download buffers
    large-disk = false; # Standard SSD storage, keep default settings
  };

  # Host roles and primary use cases
  roles = ["mobile" "workstation"];

  # Environment preferences
  environment = {
    desktop = "darwin"; # Native macOS desktop
    shell = {
      primary = "zsh"; # Primary shell
      additional = ["fish"]; # Additional shells available
    };
    terminal = "ghostty"; # Preferred terminal emulator
    windowManager = "aerospace"; # Aerospace window manager
  };

  # Service configurations
  services = {
    distributedBuilds = {
      enabled = true; # Uses legion.local for Linux builds
      role = "client"; # Client only, not a build server
    };
    homeAssistant = false; # No Home Assistant
    development = {
      docker = true; # Docker Desktop via Homebrew
      databases = []; # MongoDB Compass available but no local DBs
    };
  };

  # Build machine configuration
  buildMachines = {
    enable = []; # Disabled: cirice is not always available on network
    # enable = ["cirice"]; # Use cirice as remote build machine
  };

  # Security and access control
  security = {
    ssh = {
      server = false; # No SSH server
      client = true; # SSH client enabled
    };
    firewall = true; # macOS firewall enabled
    secrets = true; # SOPS secret management
  };
}
