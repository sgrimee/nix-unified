{ pkgs, ... }: {
  home.packages = with pkgs; [
    # packages for this host
    chromium
    firefox
    interception-tools # map Caps to Ctrl+Esc
    lunar-client # minecraft

    # linux vpn
    #networkmanager-applet
    # networkmanagerapplet
    # networkmanager-l2tp
    # networkmanager-vpnc
    # strongswan
    # xl2tpd
  ];
}
