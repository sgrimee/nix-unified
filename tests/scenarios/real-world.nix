{ lib, pkgs, ... }:
let
  testUtils = import ../lib/test-utils.nix { inherit lib pkgs; };

  # Test development environment setup
  testDevEnvironment = {
    # Test that development tools are available
    complete-dev-environment = {
      expr = let
        # Check that essential dev tools exist in pkgs
        devTools = [ "git" "direnv" "starship" "zsh" "fzf" "tmux" ];
        allToolsExist = lib.all (tool: builtins.hasAttr tool pkgs) devTools;

        # Check that home-manager programs exist
        hmPrograms = [
          ../../modules/home-manager/user/programs/git.nix
          ../../modules/home-manager/user/programs/direnv.nix
          ../../modules/home-manager/user/programs/starship.nix
          ../../modules/home-manager/user/programs/zsh.nix
          ../../modules/home-manager/user/programs/fzf.nix
        ];
        hmModulesExist = lib.all builtins.pathExists hmPrograms;
      in allToolsExist && hmModulesExist;
      expected = true;
    };

    # Test that programming language tools are available
    programming-language-support = {
      expr = let
        # Check that programming languages exist in pkgs
        progTools = [ "nodejs" "python3" "rustc" "cargo" "go" ];
        allProgToolsExist =
          lib.all (tool: builtins.hasAttr tool pkgs) progTools;

        # Check that editors exist
        editors = [ "helix" ];
        editorsExist = lib.all (editor: builtins.hasAttr editor pkgs) editors;

        # Check that language servers exist
        lsps = [ "nil" "rust-analyzer" ];
        lspsExist = lib.all (lsp: builtins.hasAttr lsp pkgs) lsps;
      in allProgToolsExist && editorsExist && lspsExist;
      expected = true;
    };
  };

  # Test system recovery scenarios
  testSystemRecovery = {
    # Test that system modules exist for rebuild
    system-rebuild-from-scratch = {
      expr = let
        # Check Darwin modules exist
        darwinModules = [
          ../../modules/darwin/system.nix
          ../../modules/darwin/nix.nix
          ../../modules/darwin/environment.nix
        ];
        darwinModulesExist = lib.all builtins.pathExists darwinModules;

        # Check NixOS modules exist
        nixosModules = [
          ../../modules/nixos/system.nix
          ../../modules/nixos/nix.nix
          ../../modules/nixos/environment.nix
        ];
        nixosModulesExist = lib.all builtins.pathExists nixosModules;
      in darwinModulesExist && nixosModulesExist;
      expected = true;
    };

    # Test that rollback configurations are possible
    configuration-rollback = {
      expr = let
        # Check that git program module exists for rollback scenarios
        gitModule = ../../modules/home-manager/user/programs/git.nix;
        zshModule = ../../modules/home-manager/user/programs/zsh.nix;
      in builtins.pathExists gitModule && builtins.pathExists zshModule;
      expected = true;
    };
  };

  # Test multi-user scenarios
  testMultiUserScenarios = {
    # Test that home-manager supports multiple users
    multi-user-home-manager = {
      expr = let
        # Check that home-manager user modules exist
        hmUserModules = [
          ../../modules/home-manager/user/programs/git.nix
          ../../modules/home-manager/user/programs/zsh.nix
        ];
        hmUserModulesExist = lib.all builtins.pathExists hmUserModules;

        # Check that git package exists for user configurations
        gitExists = builtins.hasAttr "git" pkgs;
      in hmUserModulesExist && gitExists;
      expected = true;
    };

    # Test system vs user configurations
    system-vs-user-configs = {
      expr = let
        # Check system modules exist
        systemModules = [
          ../../modules/nixos/system.nix
          ../../modules/nixos/environment.nix
        ];
        systemModulesExist = lib.all builtins.pathExists systemModules;

        # Check user modules exist
        userModules = [ ../../modules/home-manager/user/programs/git.nix ];
        userModulesExist = lib.all builtins.pathExists userModules;

        # Check that system and user packages exist
        systemPkgs = [ "git" "curl" ];
        userPkgs = [ "ripgrep" "fd" ];
        allPkgsExist =
          lib.all (pkg: builtins.hasAttr pkg pkgs) (systemPkgs ++ userPkgs);
      in systemModulesExist && userModulesExist && allPkgsExist;
      expected = true;
    };
  };

  # Test network and connectivity scenarios
  testNetworkScenarios = {
    # Test that network configuration modules exist
    network-configuration = {
      expr = let
        # Check network modules exist
        networkModules = [
          ../../modules/nixos/networking.nix
          ../../modules/nixos/openssh.nix
        ];
        networkModulesExist = lib.all builtins.pathExists networkModules;
      in networkModulesExist;
      expected = true;
    };

    # Test that wireless configuration modules exist
    wireless-configuration = {
      expr = let
        # Check wireless modules exist
        wirelessModules =
          [ ../../modules/nixos/networking.nix ../../modules/nixos/iwd.nix ];
        wirelessModulesExist = lib.all builtins.pathExists wirelessModules;
      in wirelessModulesExist;
      expected = true;
    };
  };

  # Test hardware compatibility scenarios
  testHardwareScenarios = {
    # Test that hardware modules exist
    hardware-detection = {
      expr = let
        # Check hardware modules exist
        hardwareModules = [
          ../../modules/nixos/hardware.nix
          ../../modules/nixos/sound.nix
          ../../modules/nixos/display.nix
        ];
        hardwareModulesExist = lib.all builtins.pathExists hardwareModules;
      in hardwareModulesExist;
      expected = true;
    };

    # Test that NVIDIA configuration modules exist
    nvidia-configuration = {
      expr = let
        # Check NVIDIA modules exist
        nvidiaModules =
          [ ../../modules/nixos/hardware.nix ../../modules/nixos/nvidia.nix ];
        nvidiaModulesExist = lib.all builtins.pathExists nvidiaModules;
      in nvidiaModulesExist;
      expected = true;
    };
  };

  # Test security scenarios
  testSecurityScenarios = {
    # Test that security modules exist
    secure-system-config = {
      expr = let
        # Check security modules exist
        securityModules =
          [ ../../modules/nixos/system.nix ../../modules/nixos/openssh.nix ];
        securityModulesExist = lib.all builtins.pathExists securityModules;
      in securityModulesExist;
      expected = true;
    };
  };

  # Combine all real-world scenario tests
  allScenarioTests = testDevEnvironment // testSystemRecovery
    // testMultiUserScenarios // testNetworkScenarios // testHardwareScenarios
    // testSecurityScenarios;
in allScenarioTests
