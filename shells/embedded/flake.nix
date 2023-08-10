{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { nixpkgs, flake-utils, ... }: flake-utils.lib.eachDefaultSystem
    (system:
      let
        pkgs = import nixpkgs { inherit system; };
        packages = with pkgs; [
          avrdude
          rustup
        ];
      in
      {
        inherit packages;
        devShells.default = pkgs.mkShell {
          inherit packages;
          shellHook = ''
            if [ -f .env ] && [ -z "$__DIRENV_SOURCED" ]; then
              echo direnv: loading local .env
              export __DIRENV_SOURCED=1
              source .env
            fi
            
            avrdude 2>&1 1>/dev/null | tail -n 1
            rustc --version
          '';
        };
      }
    );
}
