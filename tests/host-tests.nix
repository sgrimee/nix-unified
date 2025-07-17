{ lib, pkgs, ... }: {
  # Test required host files exist
  testSGRIMEESystemFile = {
    expr = builtins.pathExists ../hosts/darwin/SGRIMEE-M-4HJT/system.nix;
    expected = true;
  };

  testSGRIMEEHomeFile = {
    expr = builtins.pathExists ../hosts/darwin/SGRIMEE-M-4HJT/home.nix;
    expected = true;
  };

  testSGRIMEEDefaultFile = {
    expr = builtins.pathExists ../hosts/darwin/SGRIMEE-M-4HJT/default.nix;
    expected = true;
  };

  testNixairSystemFile = {
    expr = builtins.pathExists ../hosts/nixos/nixair/system.nix;
    expected = true;
  };

  testNixairHomeFile = {
    expr = builtins.pathExists ../hosts/nixos/nixair/home.nix;
    expected = true;
  };

  testNixairDefaultFile = {
    expr = builtins.pathExists ../hosts/nixos/nixair/default.nix;
    expected = true;
  };

  testDraculaSystemFile = {
    expr = builtins.pathExists ../hosts/nixos/dracula/system.nix;
    expected = true;
  };

  testDraculaHomeFile = {
    expr = builtins.pathExists ../hosts/nixos/dracula/home.nix;
    expected = true;
  };

  testLegionSystemFile = {
    expr = builtins.pathExists ../hosts/nixos/legion/system.nix;
    expected = true;
  };

  testLegionHomeFile = {
    expr = builtins.pathExists ../hosts/nixos/legion/home.nix;
    expected = true;
  };

  # Test flake structure
  testFlakeExists = {
    expr = builtins.pathExists ../flake.nix;
    expected = true;
  };

  testFlakeLockExists = {
    expr = builtins.pathExists ../flake.lock;
    expected = true;
  };

  # Test secrets structure
  testSecretsExists = {
    expr = builtins.pathExists ../secrets/sgrimee.yaml;
    expected = true;
  };
}
