{ lib, isDarwin ? false }:

with lib;

{
  # Generate device filtering configuration for various remappers
  generate = cfg: {
    kanataFilter = generateKanataFilter cfg;
    karabinerFilter = generateKarabinerFilter cfg;
  };

  # Generate Kanata-specific device filtering
  generateKanataFilter = cfg:
    let

      # Filter keyboards that have names (required for macOS)
      namedKeyboards = filter (kb: kb.name != null) cfg.excludeKeyboards;

      # Extract device names for macOS filtering
      deviceNames = map (kb: ''"${kb.name}"'') namedKeyboards;

    in if cfg.excludeKeyboards == [ ] then
      ""
    else if isDarwin then
      if namedKeyboards == [ ] then
      # No valid names for macOS - emit comment with IDs
        let
          unnamedIds = map (kb:
            "product-id ${toString kb.vendor_id}:${toString kb.product_id}")
            cfg.excludeKeyboards;
        in ''
          ;; Device exclusions (IDs only - names required for actual filtering):
          ;; ${concatStringsSep "\n        ;; " unnamedIds}
        ''
      else ''
        macos-dev-names-exclude (
          ${concatStringsSep "\n    " deviceNames}
        )
      ''
    else
    # Linux - use device path exclusion (implementation depends on platform wrapper)
    ''
      ;; Linux device filtering handled by service configuration
    '';

  # Generate Karabiner-specific device filtering (future implementation)
  generateKarabinerFilter = cfg:
    let
      # Convert exclusion list to Karabiner device_unless conditions
      deviceConditions = map (kb: {
        vendor_id = kb.vendor_id;
        product_id = kb.product_id;
      }) cfg.excludeKeyboards;

    in {
      # Return structured data that platform wrapper can convert to JSON
      device_unless = deviceConditions;
      hasExclusions = cfg.excludeKeyboards != [ ];
    };

  # Utility functions for device discovery documentation
  discoveryMethods = {
    macos = [
      "Karabiner-EventViewer.app (recommended - real-time device info)"
      "ioreg -r -n IOHIDKeyboard -l | grep -E 'Product|VendorID|ProductID'"
      "system_profiler SPUSBDataType (USB devices only)"
    ];

    linux = [
      "ls -l /dev/input/by-id/ (stable device symlinks)"
      "udevadm info -a -n /dev/input/eventX | grep -E 'ATTRS{idVendor}|ATTRS{idProduct}|ATTRS{name}'"
      "cat /proc/bus/input/devices (shows NAME and device info)"
    ];
  };

  # Validation functions
  validateConfiguration = cfg:
    let
      isDarwin = builtins.currentSystem == "aarch64-darwin"
        || builtins.currentSystem == "x86_64-darwin";
      macosKanataIssues = if isDarwin && cfg.remapper == "kanata"
      && cfg.excludeKeyboards != [ ] then
        filter (kb: kb.name == null) cfg.excludeKeyboards
      else
        [ ];
    in {
      valid = macosKanataIssues == [ ];
      issues = macosKanataIssues;
      warnings = if macosKanataIssues != [ ] then
        [
          "macOS Kanata filtering requires device names for: ${
            concatMapStringsSep ", "
            (kb: "${toString kb.vendor_id}:${toString kb.product_id}")
            macosKanataIssues
          }"
        ]
      else
        [ ];
    };
}
