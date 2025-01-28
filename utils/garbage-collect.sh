set -x 

nix-env --delete-generations old
nix-store --gc
nix-collect-garbage -d
sudo nix-collect-garbage -d
