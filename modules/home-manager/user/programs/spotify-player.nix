{...}: {
  programs.spotify-player = {
    enable = true;

    settings = {
      client_id_command = {
        command = "cat";
        args = ["/run/secrets/spotify_player_client_id"];
      };
    };
  };
}
