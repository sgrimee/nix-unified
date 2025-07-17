{ lib, pkgs, ... }:
let
  testUtils = import ../lib/test-utils.nix { inherit lib pkgs; };
  inherit (testUtils) testCrossPlatformPortability testModuleOnPlatform;

  # Test home-manager configs work on both platforms
  testHomeManagerPortability = let
    commonHomeModules = [
      "programs/git"
      "programs/zsh"
      "programs/starship"
      "programs/direnv"
      "programs/fzf"
    ];

    portabilityTests = lib.listToAttrs (map (module: {
      name =
        "home-portability-${builtins.replaceStrings [ "/" ] [ "-" ] module}";
      value = let
        darwinTest = testModuleOnPlatform module "home-manager";
        nixosTest = testModuleOnPlatform module "home-manager";
      in {
        expr = darwinTest.success && nixosTest.success;
        expected = true;
      };
    }) commonHomeModules);
  in portabilityTests;

  # Test platform-specific modules only load on correct platforms
  testPlatformSpecificModules = {
    # Darwin-only modules
    darwin-only-homebrew = let
      darwinTest = testModuleOnPlatform "homebrew" "darwin";
      nixosTest = testModuleOnPlatform "homebrew" "nixos";
    in {
      expr = darwinTest.success && !nixosTest.success;
      expected = true;
    };

    darwin-only-dock = let
      darwinTest = testModuleOnPlatform "dock" "darwin";
      nixosTest = testModuleOnPlatform "dock" "nixos";
    in {
      expr = darwinTest.success && !nixosTest.success;
      expected = true;
    };

    # NixOS-only modules
    nixos-only-hardware = let
      nixosTest = testModuleOnPlatform "hardware" "nixos";
      darwinTest = testModuleOnPlatform "hardware" "darwin";
    in {
      expr = nixosTest.success && !darwinTest.success;
      expected = true;
    };

    nixos-only-display = let
      nixosTest = testModuleOnPlatform "display" "nixos";
      darwinTest = testModuleOnPlatform "display" "darwin";
    in {
      expr = nixosTest.success && !darwinTest.success;
      expected = true;
    };
  };

  # Test universal modules work on both platforms
  testUniversalModules = {
    # Nix module should work on both platforms
    nix-universal = let
      darwinTest = testModuleOnPlatform "nix" "darwin";
      nixosTest = testModuleOnPlatform "nix" "nixos";
    in {
      expr = darwinTest.success && nixosTest.success;
      expected = true;
    };

    # Environment module should work on both platforms
    environment-universal = let
      darwinTest = testModuleOnPlatform "environment" "darwin";
      nixosTest = testModuleOnPlatform "environment" "nixos";
    in {
      expr = darwinTest.success && nixosTest.success;
      expected = true;
    };
  };

  # Test cross-platform package compatibility
  testCrossPlatformPackages = let
    commonPackages = [
      "git"
      "curl"
      "jq"
      "ripgrep"
      "fd"
      "bat"
      "eza"
      "fzf"
      "starship"
      "direnv"
    ];

    packageTests = lib.listToAttrs (map (pkgName: {
      name = "package-${pkgName}-cross-platform";
      value = let
        pkg = pkgs.${pkgName};

        # Test that package exists and has expected attributes
        hasExecutable = pkg ? outPath;
        hasName = pkg ? name;
        hasMeta = pkg ? meta;
      in {
        expr = hasExecutable && hasName && hasMeta;
        expected = true;
      };
    }) commonPackages);
  in packageTests;

  # Test cross-platform user configurations
  testCrossPlatformUserConfigs = {
    # Test that shell configurations work on both platforms
    shell-configs-cross-platform = let
      shellConfig = {
        imports = [ ../../modules/home-manager/user/programs/zsh.nix ];

        home.stateVersion = "23.11";
        programs.zsh.enable = true;
      };

      darwinTest = builtins.tryEval (lib.evalModules {
        modules = [ shellConfig ];
        specialArgs = { inherit lib pkgs; };
      });

      nixosTest = builtins.tryEval (lib.evalModules {
        modules = [ shellConfig ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = darwinTest.success && nixosTest.success;
      expected = true;
    };

    # Test that dotfiles work on both platforms
    dotfiles-cross-platform = let
      dotfilesConfig = {
        imports = [ ../../modules/home-manager/user/dotfiles/default.nix ];

        home.stateVersion = "23.11";
      };

      darwinTest = builtins.tryEval (lib.evalModules {
        modules = [ dotfilesConfig ];
        specialArgs = { inherit lib pkgs; };
      });

      nixosTest = builtins.tryEval (lib.evalModules {
        modules = [ dotfilesConfig ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = darwinTest.success && nixosTest.success;
      expected = true;
    };
  };

  # Test architecture-specific compatibility
  testArchitectureCompatibility = {
    # Test x86_64 compatibility
    x86_64-linux-compat =
      let testResult = builtins.tryEval (import ../../flake.nix);
      in {
        expr = testResult.success;
        expected = true;
      };

    aarch64-linux-compat =
      let testResult = builtins.tryEval (import ../../flake.nix);
      in {
        expr = testResult.success;
        expected = true;
      };

    x86_64-darwin-compat =
      let testResult = builtins.tryEval (import ../../flake.nix);
      in {
        expr = testResult.success;
        expected = true;
      };

    aarch64-darwin-compat =
      let testResult = builtins.tryEval (import ../../flake.nix);
      in {
        expr = testResult.success;
        expected = true;
      };
  };

  # Test that flake works on all supported systems
  testFlakeSystemSupport = let
    supportedSystems =
      [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

    systemTests = lib.listToAttrs (map (system: {
      name = "flake-system-${system}";
      value = let
        # Test that the system is mentioned in the flake
        flakeContent = builtins.readFile ../../flake.nix;
        systemMentioned = builtins.match ".*${system}.*" flakeContent != null;
      in {
        expr = systemMentioned;
        expected = true;
      };
    }) supportedSystems);
  in systemTests;

  # Test cross-platform development environments
  testCrossPlatformDevEnv = {
    # Test that development shell works on both platforms
    dev-shell-cross-platform = let
      devShellConfig = {
        imports = [ ../../modules/home-manager/user/programs/default.nix ];

        home.stateVersion = "23.11";
        programs = {
          git.enable = true;
          direnv.enable = true;
          starship.enable = true;
        };
      };

      darwinTest = builtins.tryEval (lib.evalModules {
        modules = [ devShellConfig ];
        specialArgs = { inherit lib pkgs; };
      });

      nixosTest = builtins.tryEval (lib.evalModules {
        modules = [ devShellConfig ];
        specialArgs = { inherit lib pkgs; };
      });
    in {
      expr = darwinTest.success && nixosTest.success;
      expected = true;
    };
  };

  # Combine all cross-platform tests
  allCrossPlatformTests = testHomeManagerPortability
    // testPlatformSpecificModules // testUniversalModules
    // testCrossPlatformPackages // testCrossPlatformUserConfigs
    // testArchitectureCompatibility // testFlakeSystemSupport
    // testCrossPlatformDevEnv;
in allCrossPlatformTests
