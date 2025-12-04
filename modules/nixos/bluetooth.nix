{pkgs, ...}: {
  # Enable Bluetooth hardware
  hardware.bluetooth.enable = true;

  # Ensure Bluetooth service is enabled
  services.blueman.enable = false; # Using bluetoothctl instead of blueman GUI

  # udev rules for Bluetooth serial devices (rfcomm)
  # Allows users in 'dialout' group to access /dev/rfcomm* devices
  # Using very high priority (10-) to ensure it applies before any other rules
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "rfcomm-dialout-udev-rules";
      destination = "/etc/udev/rules.d/10-rfcomm-dialout.rules";
      text = ''
        # Allow dialout group to access rfcomm devices
        SUBSYSTEM=="tty", KERNEL=="rfcomm[0-9]*", GROUP="dialout", MODE="0660", OPTIONS+="static_node=rfcomm%n"
      '';
    })
  ];

  # Add primary user to dialout group for serial/rfcomm access
  users.users.sgrimee.extraGroups = ["dialout"];
}
