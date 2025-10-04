{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.capabilities.features.gaming or false) {
    # CPU performance governor for gaming
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="cpu", KERNEL=="cpu[0-9]*", ATTR{cpufreq/scaling_governor}="performance"
    '';

    # Gaming-specific kernel parameters
    boot.kernelParams = [
      "amd_pstate=active"
      "processor.max_cstate=1" # Reduce CPU latency
    ];

    # System optimizations for gaming
    boot.kernel.sysctl = {
      "vm.swappiness" = 1;
      "vm.vfs_cache_pressure" = 50;
      "kernel.sched_autogroup_enabled" = 0;
    };

    # Enable gamemode for per-game optimizations
    programs.gamemode.enable = true;
  };
}
