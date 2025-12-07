{...}: {
  # https://nixos.wiki/wiki/Iwd
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  # Enhanced IWD configuration for better iPhone Personal Hotspot connectivity
  # iPhone hotspots don't consistently broadcast their SSID, causing connection issues
  networking.wireless.iwd.settings = {
    Settings = {
      AutoConnect = true; # Automatically connect to known networks when found
      # Enable probing for hidden/intermittent networks (iPhone hotspot workaround)
      # This makes IWD send active probe requests with SSID instead of passive scanning
      Hidden = true;
    };
    Scan = {
      # More aggressive scanning when disconnected to find intermittent networks
      # Battery-conscious settings for laptop use (cirice is often on battery)
      DisablePeriodicScan = false;
      InitialPeriodicScanInterval = 10; # Start scanning 10s after disconnect (default: 10)
      MaximumPeriodicScanInterval = 90; # Max 90s between scans (default: 300, 5x faster)
    };
  };
}
