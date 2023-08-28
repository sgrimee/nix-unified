{inputs}:
with inputs; let
  user = "sgrimee";
  host = "sgrimee-mbp-18";
in [
  # system
  (import ../../darwin {inherit host user;})

  # home
  home-manager.darwinModule
  (import ../../home-manager {inherit host user;})
]
