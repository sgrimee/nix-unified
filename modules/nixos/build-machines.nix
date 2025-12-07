{
  lib,
  hostCapabilities,
  ...
}: let
  cfg = hostCapabilities.buildMachines or {};
  buildMachinesLib = import ../shared/build-machines.nix {inherit lib;};

  enabledMachines = cfg.enable or [];
  hasEnabledMachines = enabledMachines != [];
in {
  config = lib.mkIf hasEnabledMachines {
    # Add SSH host keys for enabled build machines
    environment.etc."ssh/ssh_known_hosts".text =
      buildMachinesLib.mkHostKeys enabledMachines;

    # Configure Nix with remote builders
    nix = {
      settings = {
        builders-use-substitutes = true;
        # Short timeouts to avoid hanging on unreachable builders
        connect-timeout = 5; # 5 second connection timeout
        stalled-download-timeout = 10; # 10 second stalled download timeout
      };
      buildMachines = buildMachinesLib.mkNixOSBuildMachines enabledMachines;
    };
  };
}
