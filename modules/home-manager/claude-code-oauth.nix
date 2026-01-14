{
  config,
  osConfig,
  pkgs,
  lib,
  ...
}: {
  # Load Claude Code OAuth token from sops secret into environment
  # The secret is decrypted by sops-nix and available at runtime
  # osConfig provides access to system-level configuration (where sops secrets are defined)
  home.sessionVariablesExtra = lib.mkIf (osConfig ? sops.secrets.claude_code_oauth_token) ''
    # Load Claude Code OAuth token from sops secret
    if [ -r "${osConfig.sops.secrets.claude_code_oauth_token.path}" ]; then
      export CLAUDE_CODE_OAUTH_TOKEN="$(cat "${osConfig.sops.secrets.claude_code_oauth_token.path}")"
    fi
  '';
}
