{inputs}:
with inputs; let
  user = "sgrimee";
  host = "SGRIMEE-M-J3HG";
in [
  # system
  (import ../../darwin {inherit inputs host user;})

  # home
  home-manager.darwinModule
  (import ../../home-manager {inherit inputs host user;})
]
