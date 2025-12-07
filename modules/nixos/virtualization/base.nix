{
  config,
  lib,
  pkgs,
  ...
}: {
  # Base virtualization support without GPU passthrough
  # This module provides libvirtd, QEMU, and basic VM capabilities
  # It can be used alongside gaming mode or for VMs without GPU passthrough

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      # OVMF is now enabled by default in NixOS 25.11
    };
  };

  # VM management tools
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
    spice
    spice-gtk
    spice-protocol
    virtio-win
    win-spice
    virtiofsd
  ];

  # User permissions for VM management
  users.users.sgrimee.extraGroups = ["libvirtd" "kvm"];

  # Ensure KVM device permissions
  services.udev.extraRules = ''
    KERNEL=="kvm", GROUP="kvm", MODE="0660"
  '';

  # Network bridge for VMs - libvirtd manages this automatically
  # The default libvirt network provides virbr0 with DHCP at 192.168.122.0/24

  # Firewall rules for VM network
  networking.firewall.trustedInterfaces = ["virbr0"];
}
