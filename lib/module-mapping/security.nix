# Security Module Mappings
# Maps security capabilities to module imports
{...}: {
  securityModules = {
    ssh = {
      server = {
        nixos = [
          ../../modules/nixos/openssh.nix
          ../../modules/nixos/authorized_keys.nix
        ];
        darwin = [];
      };
      client = {
        nixos = [];
        darwin = [../../modules/darwin/ssh.nix];
        homeManager = [];
      };
    };

    firewall = {
      nixos = [];
      darwin = [];
    };

    secrets = {
      nixos = [../../modules/nixos/sops.nix];
      darwin = [../../modules/darwin/sops.nix];
      homeManager = [];
    };

    vpn = {
      nixos = [../../modules/nixos/strongswan.nix];
      darwin = [];
    };
  };
}
