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
    gaming = true; # Gaming software including lunar-client
    multimedia = true; # Media players and codecs
    server = false; # Not a server host
    corporate = false; # No corporate tools
    ai = false; # No specialized AI/ML setup needed
    android = true; # Android development (ADB, fastboot, custom udev rules)
    ham = true; # Amateur radio tooling enabled
    gnome = false; # GNOME available but minimal packages
  };

  # Hardware-specific capabilities
  hardware = {
    cpu = "amd"; # AMD Ryzen AI 300 series
    gpu = "amd"; # AMD integrated graphics with AI acceleration
    audio = "pipewire"; # Modern audio system
    display = {
      hidpi = true; # High resolution Framework display
      multimonitor = false; # Single monitor setup with Looking Glass
    };
    bluetooth = true; # Built-in Bluetooth
    wifi = true; # Built-in WiFi
    printer = true; # CUPS printing support
    keyboard = {
      remapping = true; # Kanata keyboard remapping with homerow mods
      fnKeyProfile = "framework"; # Framework Laptop 13 US keyboard layout
      devices = ["/dev/input/by-path/platform-i8042-serio-0-event-kbd"];
    };
    # Resource capabilities for Nix configuration
    large-ram = true; # High memory system, use larger download buffers
    large-disk = true; # Ample storage, enable keep-outputs and keep-derivations
  };

  # Host roles and primary use cases
  roles = ["mobile" "workstation"];

  # Environment preferences
  environment = {
    desktops = {
      available = ["sway" "gnome" "niri"]; # All desktops available
      default = "niri"; # Default to niri
    };
    bars = {
      available = ["caelestia" "waybar" "quickshell"]; # All bars available
      default = "caelestia"; # Default bar
    };
    shell = {
      primary = "zsh"; # Primary shell
      additional = ["fish"]; # Additional shells available
    };
    terminal = "alacritty"; # Preferred terminal emulator
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
      databases = ["postgresql" "sqlite"]; # Common databases
    };
  };

  # Virtualization capabilities
  virtualization = {
    baseVirtualization = true; # Base libvirtd, QEMU, virt-manager
    windowsGpuPassthrough = true; # GPU passthrough with Looking Glass for Windows VMs
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

  # Build machine configuration
  buildMachines = {
    enable = []; # No remote builders - this is the primary build server
  };
}
