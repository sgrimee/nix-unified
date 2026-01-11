# Overlay to provide dgop package for dank-material-shell
# dgop (DANK GNOME Online Provider) integrates GNOME Online Accounts
final: prev: {
  dgop = prev.stdenv.mkDerivation {
    pname = "dgop-placeholder";
    version = "0.0.1";

    dontUnpack = true;

    installPhase = ''
            mkdir -p $out/bin
            cat > $out/bin/dgop <<EOF
      #!/bin/sh
      echo "dgop placeholder - GNOME Online Accounts integration not available"
      exit 0
      EOF
            chmod +x $out/bin/dgop
    '';

    meta = {
      description = "Placeholder for DANK GNOME Online Provider";
      platforms = prev.lib.platforms.all;
    };
  };
}
