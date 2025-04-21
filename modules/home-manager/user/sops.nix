{
  config,
  home,
  inputs,
  ...
}: let
  user_key_file = "${config.xdg.configHome}/sops/age/keys.txt";
in {
  imports = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  sops = {
    defaultSopsFile = ../../../secrets/sgrimee.yaml;
    defaultSopsFormat = "yaml";

    # this won't work because we are running as user and won't read the system file
    # age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];
    # TODO: see if we can use a host key instead of the user key

    # use the user file
    age.keyFile = user_key_file;

    secrets = {
      webex_tui.path = "${config.xdg.configHome}/webex-tui/client.yml";
    };
  };

  home.sessionVariables = {
    SOPS_AGE_KEY_FILE = user_key_file;
  };
}
# Troubleshooting: monitor the agent logs with
# cat ~/Library/LaunchAgents/org.nix-community.home.sops-nix.plist | grep std
# <string>/Users/sgrimee/Library/Logs/SopsNix/stderr</string>
# <string>/Users/sgrimee/Library/Logs/SopsNix/stdout</string>

