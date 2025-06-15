{
  lib,
  pkgs,
  ...
}: {
  # Test required host files exist
  testSGRIMEESystemFile = {
    expr = builtins.pathExists ../modules/hosts/SGRIMEE-M-4HJT/system.nix;
    expected = true;
  };
  
  testSGRIMEEHomeFile = {
    expr = builtins.pathExists ../modules/hosts/SGRIMEE-M-4HJT/home.nix;
    expected = true;
  };
  
  testSGRIMEEDefaultFile = {
    expr = builtins.pathExists ../modules/hosts/SGRIMEE-M-4HJT/default.nix;
    expected = true;
  };
  
  testNixairSystemFile = {
    expr = builtins.pathExists ../modules/hosts/nixair/system.nix;
    expected = true;
  };
  
  testNixairHomeFile = {
    expr = builtins.pathExists ../modules/hosts/nixair/home.nix;
    expected = true;
  };
  
  testNixairDefaultFile = {
    expr = builtins.pathExists ../modules/hosts/nixair/default.nix;
    expected = true;
  };
  
  testDraculaSystemFile = {
    expr = builtins.pathExists ../modules/hosts/dracula/system.nix;
    expected = true;
  };
  
  testDraculaHomeFile = {
    expr = builtins.pathExists ../modules/hosts/dracula/home.nix;
    expected = true;
  };
  
  testLegionSystemFile = {
    expr = builtins.pathExists ../modules/hosts/legion/system.nix;
    expected = true;
  };
  
  testLegionHomeFile = {
    expr = builtins.pathExists ../modules/hosts/legion/home.nix;
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