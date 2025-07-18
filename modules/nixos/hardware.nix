{ modulesPath, ... }: {
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  powerManagement.enable = true;

  # Enable FacetimeHD
  hardware.facetimehd.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # Allow insecure broadcom-sta package for older WiFi hardware
  nixpkgs.config.permittedInsecurePackages =
    [ "broadcom-sta-6.30.223.271-57-6.12.38" ];
}
