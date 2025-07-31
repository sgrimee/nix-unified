{ lib, pkgs, ... }:
let

  # Import all test suites
  allTests = import ./default.nix { inherit lib pkgs; };

  # Create a derivation that runs tests and outputs results
  testRunner = pkgs.writeShellScriptBin "run-tests" ''
    echo "Running Nix configuration tests..."

    # Run tests using nix-instantiate
    if nix-instantiate --eval --strict --expr '
      let
        pkgs = import <nixpkgs> {};
        lib = pkgs.lib;
        tests = import ./tests/default.nix { inherit lib pkgs; };
      in
        tests
    '; then
      echo "✅ All tests passed!"
      exit 0
    else
      echo "❌ Tests failed!"
      exit 1
    fi
  '';

  # Test output formatter
  formatTestResults = results:
    let
      passed = builtins.filter (test: test.success) results;
      failed = builtins.filter (test: !test.success) results;
    in {
      summary = {
        total = builtins.length results;
        passed = builtins.length passed;
        failed = builtins.length failed;
      };
      failures = failed;
    };
in {
  inherit testRunner formatTestResults;

  # Export test results for CI
  testResults = allTests;
}
