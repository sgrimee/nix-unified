# Special Module Mappings
# Modules that require special handling or arguments
{...}: {
  specialModules = {
    homeManager = {
      path = ../../modules/home-manager;
      requiresArgs = ["inputs" "host" "user"];
    };
  };
}
