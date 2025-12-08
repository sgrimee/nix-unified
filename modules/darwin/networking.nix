{
  # Application firewall configuration
  # system.defaults.alf.globalstate has been replaced with networking.applicationFirewall
  networking.applicationFirewall.enable = true;
  networking.applicationFirewall.blockAllIncoming = false;

  # Disabling because the /etc/hosts file is edited by VpnClient
  # environment.etc."hosts".text = ''
  #   ##
  #   # managed by nix

  #   # Host Database
  #   #
  #   # localhost is used to configure the loopback interface
  #   # when the system is booting.  Do not change this entry.
  #   ##
  #   127.0.0.1	localhost
  #   255.255.255.255	broadcasthost
  #   ::1             localhost

  #   10.0.1.186  samael
  #   10.1.1.18   carnas
  # '';
}
