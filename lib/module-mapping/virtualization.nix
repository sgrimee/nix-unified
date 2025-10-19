# Virtualization Module Mappings
# Maps virtualization capabilities to module imports
{...}: {
  virtualizationModules = {
    windowsGpuPassthrough = {
      nixos = [../../modules/nixos/virtualization/windows-gpu-passthrough.nix];
      darwin = [];
    };
    baseVirtualization = {
      nixos = [../../modules/nixos/virtualization/base.nix];
      darwin = [];
    };
  };
}
