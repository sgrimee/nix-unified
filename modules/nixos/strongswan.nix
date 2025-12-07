{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    services.strongswan-senningerberg = {
      enable = mkEnableOption "L2TP/IPsec VPN client for Senningerberg";

      debug = mkOption {
        type = types.bool;
        default = true;
        description = "Enable maximum debug logging";
      };

      autoStart = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to start VPN services automatically at boot";
      };

      serverAddress = mkOption {
        type = types.str;
        default = "83.222.34.153";
        description = "Senningerberg VPN server IP address";
      };
    };
  };

  config = mkIf config.services.strongswan-senningerberg.enable {
    # Enable and configure StrongSwan service
    services.strongswan = {
      enable = true;

      secrets = ["/etc/ipsec.d/senningerberg.secrets"];

      ca = {};

      connections = {
        senningerberg-l2tp = {
          # L2TP/IPsec configuration
          keyexchange = "ikev1";
          auto = "add";

          type = "transport";

          # Authentication
          authby = "secret";

          # Local (client) configuration
          leftprotoport = "17/1701";
          left = "%defaultroute";

          # Remote (Senningerberg) configuration
          right = config.services.strongswan-senningerberg.serverAddress;
          rightprotoport = "17/1701";

          # Crypto and connection settings
          ike = "aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!";
          esp = "aes256-sha1,aes128-sha1,3des-sha1!";
          dpdaction = "restart";
          dpddelay = "30s";
          dpdtimeout = "150s";
          forceencaps = "yes";
          encapsulation = "yes";
          leftid = "%any";
          rightid = "%any";
          ikelifetime = "1440m";
          keylife = "60m";
          rekeymargin = "3m";
          keyingtries = "%forever";
        };
      };

      # StrongSwan setup configuration
      setup = {
        # Debug configuration
        charondebug =
          if config.services.strongswan-senningerberg.debug
          then "ike 4, knl 4, net 4, asn 4, enc 4, lib 4, esp 4, tls 4, tnc 4, imc 4, imv 4, pts 4"
          else "ike 1, knl 1";

        # Unique ID handling
        uniqueids = "yes";

        # Certificate and CRL policy
        strictcrlpolicy = "no";

        # NAT traversal and virtual networks
        nat_traversal = "yes";
        virtual_private = "%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12";
      };
    };

    # Override strongswan service to prevent auto-start unless configured
    systemd.services.strongswan.wantedBy = lib.mkForce (
      if config.services.strongswan-senningerberg.autoStart
      then ["multi-user.target"]
      else []
    );

    # Enable xl2tpd service (we'll override the config)
    services.xl2tpd.enable = true;

    # Override xl2tpd systemd service to use our config
    systemd.services.xl2tpd = {
      wantedBy = lib.mkForce (
        if config.services.strongswan-senningerberg.autoStart
        then ["multi-user.target"]
        else []
      );
      serviceConfig = {
        ExecStart =
          lib.mkForce
          "${pkgs.xl2tpd}/bin/xl2tpd -D -c /etc/xl2tpd/xl2tpd.conf -s /etc/xl2tpd/l2tp-secrets -p /run/xl2tpd/pid -C /run/xl2tpd/control";
      };
    };

    # Create xl2tpd configuration file at runtime using SOPS
    systemd.services.senningerberg-xl2tpd-config = {
      description = "Generate Senningerberg xl2tpd config with SOPS";
      wantedBy = lib.mkIf config.services.strongswan-senningerberg.autoStart ["xl2tpd.service"];
      before = ["xl2tpd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-xl2tpd-config" ''
          mkdir -p /etc/xl2tpd
          USERNAME="$(cat /run/secrets/senningerberg/l2tp_username)"

          cat > /etc/xl2tpd/xl2tpd.conf << EOF
          [global]
          ; Let strongSwan handle IPSec
          ipsec saref = no
          ${lib.optionalString config.services.strongswan-senningerberg.debug ''
            debug avp = yes
            debug network = yes
            debug packet = yes
            debug state = yes
            debug tunnel = yes''}

          [lac senningerberg]
          lns = ${config.services.strongswan-senningerberg.serverAddress}
          require chap = no
          require pap = yes
          require authentication = yes
          name = $USERNAME
          ppp debug = ${
            if config.services.strongswan-senningerberg.debug
            then "yes"
            else "no"
          }
          pppoptfile = /etc/ppp/options.l2tpd
          length bit = yes
          EOF
          chmod 644 /etc/xl2tpd/xl2tpd.conf
        '';
      };
    };

    # Ensure xl2tpd runtime directory exists
    systemd.tmpfiles.rules = ["d /run/xl2tpd 0755 root root -"];

    # Create PPP options file at runtime using SOPS
    systemd.services.senningerberg-ppp-options = {
      description = "Generate Senningerberg PPP options with SOPS";
      wantedBy = ["xl2tpd.service"];
      before = ["xl2tpd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-ppp-options" ''
          mkdir -p /etc/ppp
          USERNAME="$(cat /run/secrets/senningerberg/l2tp_username)"

          cat > /etc/ppp/options.l2tpd << EOF
          ipcp-accept-local
          ipcp-accept-remote
          refuse-eap
          refuse-chap
          require-pap
          noccp
          noauth
          noipdefault
          idle 1800
          mtu 1410
          mru 1410
          defaultroute
          replacedefaultroute
          usepeerdns
          connect-delay 5000
          name $USERNAME
          user $USERNAME
          ip-up-script /etc/ppp/ip-up.local
          EOF
          chmod 644 /etc/ppp/options.l2tpd
        '';
      };
    };

    # Create PPP ip-up script for routing
    systemd.services.senningerberg-ppp-ipup = {
      description = "Generate Senningerberg PPP ip-up script";
      wantedBy = ["xl2tpd.service"];
      before = ["xl2tpd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-ppp-ipup" ''
          mkdir -p /etc/ppp
          cat > /etc/ppp/ip-up.local << EOF
          #!/bin/bash
          # Configure routing when PPP interface comes up
          if [ "\$1" = "ppp0" ]; then
            # Route all traffic through VPN but preserve server route
            # The server route should already exist with higher priority (metric 1)
            ip route add default dev ppp0 metric 10 2>/dev/null || true
            logger "VPN connection established on ppp0: \$4"
          fi
          exit 0
          EOF
          chmod 755 /etc/ppp/ip-up.local
        '';
      };
    };

    # Create PPP secrets files at runtime using SOPS
    systemd.services.senningerberg-ppp-secrets = {
      description = "Generate Senningerberg PPP secrets with SOPS";
      wantedBy = ["xl2tpd.service"];
      before = ["xl2tpd.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-ppp-secrets" ''
          mkdir -p /etc/ppp
          USERNAME="$(cat /run/secrets/senningerberg/l2tp_username)"
          PASSWORD="$(cat /run/secrets/senningerberg/l2tp_password)"

          # Create PAP secrets file
          cat > /etc/ppp/pap-secrets << EOF
          # PPP PAP authentication secrets for L2TP
          "$USERNAME" * "$PASSWORD" *
          EOF
          chmod 600 /etc/ppp/pap-secrets

          # Create CHAP secrets file as fallback
          cat > /etc/ppp/chap-secrets << EOF
          # PPP CHAP authentication secrets for L2TP
          "$USERNAME" * "$PASSWORD" *
          EOF
          chmod 600 /etc/ppp/chap-secrets
        '';
      };
    };

    # Create the IPSec secrets file at runtime using SOPS
    systemd.services.senningerberg-ipsec-secrets = {
      description = "Generate Senningerberg IPsec secrets with SOPS";
      wantedBy = ["strongswan.service"];
      before = ["strongswan.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "create-ipsec-secrets" ''
          mkdir -p /etc/ipsec.d
          cat > /etc/ipsec.d/senningerberg.secrets << EOF
          # IPSec secrets for L2TP/IPSec VPN
          %any ${config.services.strongswan-senningerberg.serverAddress} : PSK "$(cat /run/secrets/senningerberg/ipsec_psk)"
          EOF
          chmod 600 /etc/ipsec.d/senningerberg.secrets
        '';
      };
    };

    # Firewall configuration for IPSec
    networking.firewall = {
      allowedUDPPorts = [500 4500]; # IKE and NAT-T
      allowedTCPPorts = [];

      # Enable connection tracking for IPSec
      connectionTrackingModules = ["nf_conntrack_netlink"];
    };

    # Create systemd service to maintain route to VPN server
    systemd.services.senningerberg-server-route = lib.mkIf config.services.strongswan-senningerberg.enable {
      description = "Maintain route to Senningerberg VPN server";
      after = ["network.target"];
      wantedBy = lib.mkIf config.services.strongswan-senningerberg.autoStart ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "add-server-route" ''
          export PATH=${pkgs.iproute2}/bin:${pkgs.gawk}/bin:${pkgs.util-linux}/bin:$PATH

          # Get the default gateway before VPN connects
          DEFAULT_GW=$(ip route | grep '^default' | grep -v ppp | head -1 | awk '{print $3}')
          DEFAULT_IFACE=$(ip route | grep '^default' | grep -v ppp | head -1 | awk '{print $5}')

          if [ -n "$DEFAULT_GW" ] && [ -n "$DEFAULT_IFACE" ]; then
            ip route add ${config.services.strongswan-senningerberg.serverAddress}/32 via $DEFAULT_GW dev $DEFAULT_IFACE metric 1
            logger "Added route to VPN server ${config.services.strongswan-senningerberg.serverAddress} via $DEFAULT_GW dev $DEFAULT_IFACE"
          fi
        '';
      };
    };

    # Enable IP forwarding for VPN routing
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv4.conf.all.accept_redirects" = 0;
      "net.ipv4.conf.all.send_redirects" = 0;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    # Load required kernel modules
    boot.kernelModules = ["af_key"];

    # Install packages for L2TP/IPSec VPN
    environment.systemPackages = with pkgs; [
      strongswan
      xl2tpd
      ppp

      (writeShellScriptBin "senningerberg-vpn-up" ''
        echo "Starting L2TP/IPSec VPN connection..."
        sudo systemctl start strongswan
        sudo systemctl start xl2tpd
        sleep 2
        sudo ipsec up senningerberg-l2tp
        sleep 3
        sudo xl2tpd-control -c /run/xl2tpd/control connect-lac senningerberg
        echo "VPN connection initiated. Check status with: senningerberg-vpn-status"
      '')

      (writeShellScriptBin "senningerberg-vpn-down" ''
        echo "Stopping L2TP/IPSec VPN connection..."
        sudo xl2tpd-control -c /run/xl2tpd/control disconnect-lac senningerberg 2>/dev/null || true
        sudo ipsec down senningerberg-l2tp
        sudo systemctl stop xl2tpd
        echo "VPN connection stopped."
      '')

      (writeShellScriptBin "senningerberg-vpn-status" ''
        echo "=== StrongSwan IPSec Status ==="
        sudo ipsec status
        echo ""
        echo "=== xl2tpd Status ==="
        sudo systemctl status xl2tpd --no-pager -l
        echo ""
        echo "=== PPP Interfaces ==="
        ip addr show | grep ppp || echo "No PPP interfaces found"
        echo ""
        echo "=== VPN Routes ==="
        ip route | grep ppp || echo "No VPN routes found"
      '')

      (writeShellScriptBin "senningerberg-vpn-logs" ''
        echo "=== Recent StrongSwan logs ==="
        journalctl -u strongswan -n 25 --no-pager
        echo ""
        echo "=== Recent xl2tpd logs ==="
        journalctl -u xl2tpd -n 25 --no-pager
      '')
    ];

    # Systemd service to ensure proper startup order
    systemd.services.strongswan-senningerberg-setup = {
      description = "Senningerberg VPN Setup";
      after = ["network.target" "strongswan.service"];
      wants = ["strongswan.service"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        # Wait for StrongSwan to be ready
        sleep 2
        echo "Senningerberg VPN configuration ready"
      '';
      wantedBy = lib.mkIf config.services.strongswan-senningerberg.autoStart ["multi-user.target"];
    };
  };
}
