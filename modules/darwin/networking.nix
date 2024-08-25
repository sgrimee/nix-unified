{
  system.defaults.alf.globalstate = 1; # enable firewall

  environment.etc."hosts".text = ''
    ##
    # managed by nix

    # Host Database
    #
    # localhost is used to configure the loopback interface
    # when the system is booting.  Do not change this entry.
    ##
    127.0.0.1	localhost
    255.255.255.255	broadcasthost
    ::1             localhost

    10.0.1.186  samael
    10.1.1.18   carnas
  '';

  # networking = {
  #   # AdGuard DNS
  #   dns = [
  #     "94.140.14.14"
  #     "94.140.15.15"
  #   ];

  #   knownNetworkServices = [ "Wi-Fi" ];
  # };
}
