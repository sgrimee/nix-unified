{ pkgs, ... }: {
  home.packages = with pkgs; [
    # packages for this host
    chromium
    firefox
    interception-tools # map Caps to Ctrl+Esc

    # linux vpn
    networkmanagerapplet
    networkmanager-l2tp
    # networkmanager-vpnc
    strongswan
    xl2tpd
  ];
}
