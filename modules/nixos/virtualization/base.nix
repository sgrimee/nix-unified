{pkgs, ...}: let
  # Default libvirt network XML definition
  defaultNetworkXml = pkgs.writeText "libvirt-default-network.xml" ''
    <network>
      <name>default</name>
      <forward mode='nat'>
        <nat>
          <port start='1024' end='65535'/>
        </nat>
      </forward>
      <bridge name='virbr0' stp='on' delay='0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.122.2' end='192.168.122.254'/>
        </dhcp>
      </ip>
    </network>
  '';
in {
  # Base virtualization support without GPU passthrough
  # This module provides libvirtd, QEMU, and basic VM capabilities
  # It can be used alongside gaming mode or for VMs without GPU passthrough

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      verbatimConfig = ''
        namespaces = []
      '';
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
    dnsmasq
  ];

  # User permissions for VM management
  users.users.sgrimee.extraGroups = ["libvirtd" "kvm"];

  # Ensure KVM device permissions
  services.udev.extraRules = ''
    KERNEL=="kvm", GROUP="kvm", MODE="0660"
  '';

  # Firewall rules for VM network
  networking.firewall.trustedInterfaces = ["virbr0"];

  # On-demand service to define and start the default libvirt network
  # Start manually with: sudo systemctl start libvirt-default-network
  systemd.services.libvirt-default-network = {
    description = "Define and start libvirt default network";
    after = ["libvirtd.service"];
    requires = ["libvirtd.service"];
    # No wantedBy - this is an on-demand service
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "libvirt-default-network" ''
        # Define network if it doesn't exist, then start it
        ${pkgs.libvirt}/bin/virsh net-info default >/dev/null 2>&1 || \
          ${pkgs.libvirt}/bin/virsh net-define ${defaultNetworkXml}
        ${pkgs.libvirt}/bin/virsh net-start default || true
      '';
    };
  };
}
