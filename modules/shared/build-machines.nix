{lib, ...}: let
  # Central registry of all available build machines
  registry = {
    cirice = {
      hostName = "cirice.local";
      sshUser = "sgrimee";
      hostKey = "cirice.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILl1KxPJWXWG6vNM0D1RdFYNXlzRsmhEorXciUxpDz3x";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 100;
      supportedFeatures = ["kvm" "nixos-test" "big-parallel"];
    };

    legion = {
      hostName = "legion.local";
      sshUser = "sgrimee";
      hostKey = "legion.local ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPrvPdkufPSh0AIZ/fIhtWnkwsjWlzjt9EjD+byl68gK";
      system = "x86_64-linux";
      maxJobs = 8;
      speedFactor = 50;
      supportedFeatures = ["kvm" "nixos-test" "big-parallel"];
    };
  };

  # Helper function to get enabled machines by name
  getEnabledMachines = enabledNames:
    lib.filter (machine: machine != null)
    (map (name: registry.${name} or null) enabledNames);

  # Generate NixOS buildMachines configuration
  mkNixOSBuildMachines = enabledNames: let
    machines = getEnabledMachines enabledNames;
  in
    map (machine: {
      hostName = machine.hostName;
      sshUser = machine.sshUser;
      sshKey = "/home/sgrimee/.ssh/id_rsa";
      # Extract just the key part for publicHostKey
      publicHostKey = let
        parts = lib.splitString " " machine.hostKey;
        keyPart = builtins.elemAt parts 2;
      in
        builtins.toString keyPart;
      system = machine.system;
      maxJobs = machine.maxJobs;
      speedFactor = machine.speedFactor;
      supportedFeatures = machine.supportedFeatures;
    })
    machines;

  # Generate Darwin builders string for Determinate Nix
  mkDarwinBuilders = enabledNames: let
    machines = getEnabledMachines enabledNames;
    machineStrings = map (machine: "ssh://${machine.sshUser}@${machine.hostName} ${machine.system} /Users/sgrimee/.ssh/id_ed25519 ${
        toString machine.maxJobs
      } ${toString machine.speedFactor} ${
        lib.concatStringsSep "," machine.supportedFeatures
      }") machines;
  in
    lib.concatStringsSep " ; " machineStrings;

  # Generate SSH known_hosts entries
  mkHostKeys = enabledNames: let
    machines = getEnabledMachines enabledNames;
  in
    lib.concatStringsSep "\n" (map (machine: machine.hostKey) machines);
in {
  # Export the registry and helper functions
  inherit registry;
  inherit mkNixOSBuildMachines mkDarwinBuilders mkHostKeys;

  # Convenience exports
  allMachineNames = builtins.attrNames registry;
}
