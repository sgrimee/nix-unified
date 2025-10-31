{...}: {
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;

  powerManagement.enable = true;

  # Enable FacetimeHD
  hardware.facetimehd.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;

  # bios/firmware update
  services.fwupd.enable = true;
}
