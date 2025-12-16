{
  pkgs,
  lib,
  ...
}:
lib.mkIf pkgs.stdenv.isDarwin {
  home.file.".curlrc".text = ''
    # Managed by nix

    # Force IPv4 to workaround CSecure Endpoint IPv6 routing issues
    # that cause connections to Microsoft/Azure services to hang
    -4
  '';

  # Tell Homebrew to respect ~/.curlrc for curl options
  home.sessionVariables.HOMEBREW_CURLRC = "1";
}
