{ pkgs, ... }: {
  home.packages = with pkgs; [
    # packages for this host
    chromium
    firefox
    interception-tools # map Caps to Ctrl+Esc
    mako # wayland notification daemon
    swayidle
    sway-launcher-desktop
    swaylock
    udiskie
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
