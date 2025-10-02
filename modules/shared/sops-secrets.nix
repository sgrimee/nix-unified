{ lib, pkgs, ... }: {
  sops.secrets = {
    "meraki/ipsec_psk" = { };
    "meraki/l2tp_username" = { };
    "meraki/l2tp_password" = { };
    "spotify_player_client_id" = {
      owner = "sgrimee";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };
    "webex_tui" = {
      owner = "sgrimee";
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    };
  };
}
