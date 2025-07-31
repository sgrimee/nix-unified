# Host Configuration Baseline Analysis

**Date:** 2025-07-30  
**Purpose:** Establish comprehensive baseline of current host configurations before implementing capability system  

## Executive Summary

This analysis examines 4 hosts across 2 platforms:
- **Darwin (macOS):** 1 host (SGRIMEE-M-4HJT)  
- **NixOS (Linux):** 3 hosts (dracula, legion, nixair)

All hosts share common core functionality through modular architecture but have distinct specializations for desktop environments, hardware, and use cases.

## Host Inventory

### Darwin Hosts

#### SGRIMEE-M-4HJT (macOS Workstation)
- **Platform:** nix-darwin
- **State Version:** 4
- **Primary Use:** Development workstation with corporate tools
- **Key Features:**
  - Distributed builds to legion.local
  - BenQ display management
  - Comprehensive homebrew app ecosystem

### NixOS Hosts

#### dracula (Intel MacBook Pro - 2013)
- **Platform:** NixOS 23.05
- **Hardware:** Intel i7, Broadcom WiFi, SSD
- **Desktop:** GNOME with GDM
- **Key Features:**
  - Intel CPU optimizations
  - HiDPI support (commented out - causes console font issues)
  - GNOME desktop with sleep/suspend disabled
  - SSH agent enabled

#### legion (High-Performance Workstation)
- **Platform:** NixOS 23.11  
- **Hardware:** Intel CPU with NVIDIA GPU
- **Desktop:** GNOME with GDM
- **Key Features:**
  - NVIDIA GPU support (stable drivers)
  - Enhanced build capacity (8 jobs, 4 cores per job)
  - HomeAssistant user support
  - Serves as distributed build machine for other hosts

#### nixair (Intel MacBook Air - 2011)
- **Platform:** NixOS 23.05
- **Hardware:** Apple MacBook Air 4 (i7-1.8GHz)
- **Desktop:** Sway (Wayland) with custom components
- **Key Features:**
  - Sway wayland window manager
  - Custom greetd login manager
  - Waybar, rofi, i3status integration
  - Distributed builds to legion.local
  - Limited resources (2 cores, 2 jobs)

## Configuration Architecture Analysis

### Module Import Patterns

All hosts follow consistent modular architecture:

```
Host Configuration Structure:
├── hardware-configuration.nix (NixOS only)
├── boot.nix (NixOS only)
├── system.nix (host-specific settings)
├── home.nix (user configuration)
├── packages.nix (host-specific packages)
├── programs/ (host-specific program configs)
└── default.nix (imports orchestration)
```

### Global Module Dependencies

**All hosts import:**
- Platform-specific global modules (`modules/nixos/` or `modules/darwin/`)
- Home-manager configuration (`modules/home-manager/`)
- Hardware-specific nixos-hardware modules (NixOS only)

**Common NixOS Modules (29 modules):**
```
authorized_keys, console, display, environment, fonts, greetd, 
hardware, i18n, iwd, kanata, keyboard, mounts, networking, 
nix, nix-ld, openssh, polkit, printing, sound, sway, time, 
touchpad, vscode, x-gnome
```

**Common Darwin Modules (18 modules):**
```
benq-display, dock, environment, finder, fonts, homebrew, 
window-manager, keyboard, mac-app-util, music_app, networking, 
nix, screen, system, trackpad
```

**Common Home-Manager Modules (28 programs):**
```
aerc, alacritty, android-studio, bat, broot, btop, carapace, 
direnv, eza, fish, fzf, gh, git, gitui, helix, jq, kitty, 
neomutt, nushell, ssh, starship, yt-dlp, yazi, zsh, zoxide
```

## Desktop Environment Analysis

### Desktop Environment Distribution

| Host | Desktop Environment | Display Manager | Compositor |
|------|-------------------|-----------------|------------|
| SGRIMEE-M-4HJT | macOS native | - | Quartz |
| dracula | GNOME | GDM | Mutter |
| legion | GNOME | GDM | Mutter |  
| nixair | Sway | greetd | Sway (Wayland) |

### Desktop-Specific Features

**GNOME Hosts (dracula, legion):**
- X11-based desktop environment
- GDM display manager with auto-suspend disabled
- Sleep/suspend/hibernate disabled via systemd and polkit
- Standard GNOME applications and services

**Sway Host (nixair):**
- Wayland compositor
- Custom greetd display manager
- Integrated status bars (waybar, i3status)  
- Application launcher (rofi)
- Wayland-optimized applications

**Darwin Host (SGRIMEE-M-4HJT):**
- Native macOS interface
- Aerospace window manager
- JankyBorders for window decoration
- Homebrew for GUI applications

## Hardware Configuration Analysis

### CPU Architecture
- **All hosts:** x86_64 architecture
- **Intel optimization:** All NixOS hosts use `nixos-hardware.nixosModules.common-cpu-intel`

### Hardware-Specific Modules

**dracula (MacBook Pro 2013):**
```nix
nixos-hardware.nixosModules.common-cpu-intel
nixos-hardware.nixosModules.common-hidpi  # commented out
nixos-hardware.nixosModules.common-pc-ssd
```
- Broadcom WiFi driver (`broadcom_sta`)
- Intel microcode updates

**legion (Workstation):**
```nix  
nixos-hardware.nixosModules.common-cpu-intel
nixos-hardware.nixosModules.common-pc-ssd
```
- NVIDIA GPU support with stable drivers
- Hardware graphics acceleration
- Enhanced build capacity configuration

**nixair (MacBook Air 2011):**
```nix
nixos-hardware.nixosModules.apple-macbook-air-4
nixos-hardware.nixosModules.common-pc-ssd
```
- Apple MacBook Air specific optimizations
- Resource-constrained build settings

### Storage Configuration
- **All NixOS hosts:** SSD storage with appropriate optimizations
- **File systems:** ext4 root, vfat boot partitions
- **Swap:** Dedicated swap partitions on all NixOS hosts

## Package and Application Analysis

### Core Application Categories

**System Utilities (Common to all):**
```
coreutils-full, curl, wget, openssh, htop, killall, 
unzip, zip, ripgrep, less, just
```

**Development Tools (Common to all):**
```
age, gitleaks, lazygit, sops, ssh-to-age, nil (Nix LSP),
nixpkgs-fmt, alejandra, home-manager
```

**Terminal and Shell:**
```
zsh (system shell), fish, carapace (completions), 
starship (prompt), zoxide (cd replacement), fzf
```

**File Management:**
```
yazi, joshuto, broot, du-dust, eza (ls replacement)
```

**Multimedia:**
```
mpv, ffmpegthumbnailer, poppler (PDF)
```

**Network Tools:**
```
gping, trippy, rustscan, wakeonlan
```

### Platform-Specific Applications

**NixOS Hosts Only:**
```
chromium, firefox, interception-tools, ethtool, qdmr, spotifyd
```

**Darwin Host Only (via Homebrew):**
- **Development:** android-studio, docker-desktop, visual-studio-code, mongodb-compass
- **Productivity:** 1password, alfred, obsidian, omnifocus, devonthink
- **Communication:** discord, slack, microsoft-teams, signal, whatsapp
- **Media:** ableton-live-suite, spotify, vlc, plex
- **Utilities:** raycast, karabiner-elements, battery, daisydisk

### Development Environment Analysis

**Programming Languages & Runtimes:**
- **Node.js:** Installed via homebrew on Darwin
- **Python:** uv (Python package manager) on Darwin
- **Rust:** Cargo configuration in dotfiles
- **Nix:** Comprehensive tooling across all hosts

**Development Tools:**
- **Editors:** helix (terminal), vscode (GUI), android-studio
- **Version Control:** git, lazygit, gitui, gh (GitHub CLI)
- **Containers:** docker-desktop (Darwin), qemu (all hosts)
- **Terminals:** Multiple options per platform (ghostty, alacritty, kitty, iTerm2)

**Kubernetes Tools:**
```
kubectl, kubectx, k9s, kubelogin-oidc
```

### Build System Configuration

**Distributed Builds:**
- **Builder Host:** legion.local (8 jobs, high speed factor)
- **Client Hosts:** nixair, SGRIMEE-M-4HJT
- **Features:** KVM, nixos-test, big-parallel support
- **Authentication:** SSH key-based

**Build Optimization:**
```
legion:    8 jobs, 4 cores per job  (32 total cores)
nixair:    2 jobs, 2 cores per job  (4 total cores, uses remote)
dracula:   default settings
Darwin:    uses legion.local for Linux builds
```

## Service and Daemon Analysis

### System Services (NixOS)

**Common Services:**
- SSH daemon with key-based authentication
- NetworkManager for network connectivity  
- Audio system (PulseAudio/PipeWire)
- Printing support (CUPS)
- D-Bus message bus

**Desktop-Specific Services:**
- **GNOME hosts:** GDM, GNOME session services
- **Sway host:** greetd, Wayland portals, compositor services

**Security Services:**
- polkit authorization
- PAM configuration
- Yubikey support (fetchcjejtbu)

### Darwin Services
- homebrew package management
- aerospace window manager
- SSH agent
- BenQ display management

## User Environment Analysis

### Shell Configuration
- **Primary Shell:** zsh (all hosts)
- **Alternative Shells:** fish, nushell available
- **Prompt:** Starship cross-platform prompt
- **Completions:** Carapace for enhanced shell completions

### Common Shell Aliases
```bash
k="kubectl"                    # Kubernetes shorthand
gst="git status"              # Git status
cw="cargo watch -q -c -x check"  # Rust development
sudo="sudo "                  # Allow aliases with sudo
tree="broot"                  # Tree view with broot
```

### Environment Variables
```bash
EDITOR="hx"                   # Helix as default editor
PAGER="bat"                   # Bat as pager
HOMEBREW_NO_ANALYTICS=1       # Disable homebrew analytics
HOMEBREW_CASK_OPTS="--no-quarantine"  # Darwin only
```

## Security Configuration

### SSH Configuration
- **All hosts:** SSH agent enabled
- **Authentication:** Key-based authentication
- **Authorized Keys:** Centrally managed via `files/authorized_keys.nix`
- **Build Authentication:** Dedicated keys for distributed builds

### Secrets Management
- **SOPS:** Age-based secret encryption
- **Key Management:** ssh-to-age conversion
- **Yubikey Integration:** PAM support for hardware authentication

### Firewall Configuration
- **legion & nixair:** Custom firewall rules
- **dracula:** Default firewall settings
- **Darwin:** macOS built-in firewall

## Patterns and Commonalities

### Configuration Patterns

1. **Modular Architecture:** Consistent separation of concerns across all hosts
2. **Platform Abstraction:** Common home-manager configuration with platform-specific system layers
3. **Hardware Adaptation:** Automatic hardware detection with manual optimizations
4. **Build Distribution:** Central build server (legion) serving lightweight clients

### Package Management Strategies

1. **NixOS:** Pure Nix packages with minimal system-level installations
2. **Darwin:** Hybrid approach - Nix for CLI tools, Homebrew for GUI applications
3. **Development Tools:** Consistent toolchain across all platforms
4. **Language Runtimes:** Platform-appropriate installation methods

### Desktop Environment Choices

1. **High-Performance Hosts:** GNOME for full-featured desktop experience
2. **Resource-Constrained:** Sway for efficient Wayland compositing
3. **Corporate Environment:** macOS native with productivity enhancements

## Specialization Analysis

### Host Roles

**SGRIMEE-M-4HJT (Primary Workstation):**
- Corporate development environment
- Comprehensive GUI application suite
- Cross-platform build orchestration

**legion (Build Server & Workstation):**
- High-performance computing
- NVIDIA GPU workloads
- Central build distribution
- HomeAssistant integration

**dracula (General Purpose Desktop):**
- Standard Linux desktop experience
- Gaming capabilities (lunar-client)
- Stable GNOME environment

**nixair (Portable Development):**
- Lightweight resource usage
- Wayland-first environment
- Remote build capabilities
- Custom sway configuration

## Capability Implications

Based on this analysis, the capability system should support these configuration patterns:

### Core Capabilities
- **base-system:** Fundamental Nix configuration, shells, core utilities
- **development:** Programming tools, editors, version control, build systems
- **desktop-gnome:** X11-based GNOME desktop environment
- **desktop-sway:** Wayland-based Sway window manager  
- **desktop-macos:** Darwin-specific system enhancements
- **networking:** Network tools, SSH, remote access
- **multimedia:** Media players, codecs, content creation
- **security:** SSH keys, SOPS secrets, Yubikey support

### Hardware Capabilities  
- **intel-cpu:** Intel processor optimizations and microcode
- **nvidia-gpu:** NVIDIA graphics drivers and acceleration
- **apple-hardware:** Apple-specific hardware support
- **hidpi-display:** High-DPI display scaling and fonts

### Service Capabilities
- **distributed-builds:** Multi-host build coordination
- **homeassistant:** Home automation platform integration
- **corporate-tools:** Enterprise software and compliance
- **gaming:** Game platforms and performance optimizations

This baseline establishes the foundation for designing a capability system that can efficiently represent and manage the diverse configurations across all host types while maintaining the existing modular architecture and functionality.