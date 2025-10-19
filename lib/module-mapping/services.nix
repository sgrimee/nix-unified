# Service Module Mappings
# Maps service capabilities to module imports
{...}: {
  serviceModules = {
    distributedBuilds = {
      client = {
        nixos = [];
        darwin = [];
      };
      server = {
        nixos = [];
        darwin = [];
      };
      both = {
        nixos = [];
        darwin = [];
      };
    };

    homeAssistant = {
      nixos = [../../modules/nixos/homeassistant-user.nix];
      darwin = [];
    };

    development = {
      docker = {
        nixos = [];
        darwin = [];
      };
      databases = {
        postgresql = {
          nixos = [];
          darwin = [];
        };
        mysql = {
          nixos = [];
          darwin = [];
        };
      };
    };
  };
}
