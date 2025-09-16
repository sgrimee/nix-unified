{
  system.stateVersion = 4;
  system.primaryUser = "sgrimee";

  # allowUnfree now handled centrally in flake
  networking = {
    computerName = "SGRIMEE-M-4HJT";
    hostName = "SGRIMEE-M-4HJT";
    localHostName = "SGRIMEE-M-4HJT";
  };

  # Host-specific Determinate Nix settings
  determinate-nix.customSettings = {
    # Distributed builds configuration
    builders-use-substitutes = true;
    builders =
      "ssh://sgrimee@cirice.local x86_64-linux /Users/sgrimee/.ssh/id_ed25519 8 100 kvm,nixos-test,big-parallel c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUxsMUt4UEpXWFdHNnZOTTBEMVJkRllOWGx6UnNtaEVvclhjaVV4cER6M3ggcm9vdEBjaXJpY2UK ssh://sgrimee@legion.local x86_64-linux /Users/sgrimee/.ssh/id_ed25519 8 50 kvm,nixos-test,big-parallel c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSVBydlBka3VmUFNoMEFJWi9mSWh0V25rd3NqV2x6anQ5RWpEK2J5bDY4Z0sgcm9vdEBuaXhvcwo=";
  };
}
