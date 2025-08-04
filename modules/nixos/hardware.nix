{ modulesPath, ... }: {
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  powerManagement.enable = true;

  # Enable FacetimeHD
  hardware.facetimehd.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Allow any version of insecure broadcom-sta package for older WiFi hardware
  # Using allowInsecurePredicate to match any broadcom-sta version
  nixpkgs.config.allowInsecurePredicate = pkg:
    builtins.match "broadcom-sta-.*" (pkg.pname or pkg.name or "") != null;
}
