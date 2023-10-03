{pkgs, ...}: {
  home.packages = with pkgs; [
    # packages for this host
    chromium
    firefox
    interception-tools # user to map Caps to Ctrl+Esc
    mako # wayland notification daemon
    wl-clipboard # wayland clipboard

    # linux vpn
    #networkmanager-applet
    # networkmanagerapplet
    # networkmanager-l2tp
    # networkmanager-vpnc
    # strongswan
    # xl2tpd
  ];
}
