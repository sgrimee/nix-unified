{
  programs.ssh = {
    enable = true;

    extraConfig = ''
        ControlMaster no
        CanonicalizeHostname yes
        CanonicalDomains ampr.org
        CanonicalizeMaxDots 1
        CanonicalizeFallbackLocal yes
        PubkeyAcceptedKeyTypes +ssh-rsa
        UserKnownHostsFile ~/.ssh/known_hosts

        Host pi3b.local
            HostName pi3b.local

        Host hass.local
            HostName 10.0.1.5
            User hassio

        Host samael
            HostName 10.0.1.186
            RemoteCommand bash --login

        Host carnas
            HostName 10.1.1.18

        Host nms.lx9laru.ampr.org
            User librenms
            Port 22
            ForwardAgent yes
        Host lx9laru
            HostName 44.161.251.5
            User sgrimee
            Port 22
            ForwardAgent yes

        Host ampr-gw.lx0bgp

        Host rtr-16.lx2sg
            HostName 10.0.3.22
        Host rtr-16.lx2sg-dev
            HostName 10.0.3.24
        Host rtr-17.lx2sg
            HostName 44.161.251.228
            User sgrimee
        Host rtr-17.lx2sg-dev
            HostName 10.0.3.25

        Host ptp-lx0lwl.lx2sg
            HostName 10.0.1.78

        Host ptp-lx0dmx.lx0dmr
            HostName 44.161.238.203

        Host ptp-lx0dmr.lx0dmx
            HostName 44.161.238.134
        Host ptp-lx0lwl.lx0dmx
            HostName 44.161.238.133

        Host ptp-lx0dmx.lx0lwl
            HostName 44.161.240.123
        Host ptmp.lx0lwl
            HostName 44.161.240.126
        Host ptp-lx0ost.lx0lwl
            HostName 44.161.240.125

        Host ptp-lx0hyt.lx0ost
            HostName 44.161.240.178
        Host ptp-lx0lwl.lx0ost
            HostName 44.161.240.179

        Host rtr-16.lx0ost
            HostName 44.161.251.235
        Host rtr-old.lx0bgp
            HostName 44.161.251.224
        Host rtr-16.lx0ber
        Host rtr-16.lx0bgp
        Host rtr-16.lx0dmr
        Host rtr-16.lx0dmx
        Host rtr-18.lx0e
        Host rtr-16.lx0fsk
        Host rtr-16.lx0hyt
            HostName 44.161.251.236
        Host rtr-16.lx0laro
        Host rtr-16.lx0lwl
            HostName 44.161.240.113
        Host rtr-17.lx0dmr
            HostName 44.161.251.226
        Host rtr-17.lx0lwl
            HostName 44.161.240.124
        Host rtr-16.lx0nsr
        Host rtr-16.lx0sag
        Host rtr-16.lx1bv
            HostName 44.161.251.233
        Host rtr-16.lx1ge
        Host rtr-16.lx1sp
        Host rtr-16.lx2cs
            HostName 44.161.251.234
        Host rtr-16.lx3mfg
            HostName 44.161.251.227
        Host rtr-16.lx3x
        Host rtr-16.lx6alt
            HostName 44.161.251.232
        Host rtr-16.lx9lgk

        Host sxt-1.mobile
            HostName 44.161.222.252
        Host sxt-2.mobile
            HostName 44.161.222.253

        Host wap.lx0fsk
            HostName 44.161.241.33
        Host wap.lx0ber
            HostName 44.161.241.49

        Host wap.* rtr-* ptmp* ptp-* lx2sg-rtr-* sxt-* ampr-gw* *.lx1duc.radio
            User lx2sg
            Port 15722
            StrictHostKeyChecking no
            UserKnownHostsFile /dev/null
            IdentityFile /Users/sgrimee/.ssh/rsa-sha2-256

      #   Host *.github.com
      #       AddKeysToAgent yes
      #       UseKeychain yes
      #       IdentityFile ~/.ssh/github_peanutbother
    '';
  };
}
