{ pkgs, ... }:
let
  user = "sgrimee";
in
{
  home-manager.users.${user}.home = {

    sessionVariables = {
      HOMEBREW_CASK_OPTS = "--no-quarantine";
      ARCHFLAGS = "-arch x86_64";
      CLICOLOR = 1;
      LANG = "en_US.UTF-8";
    };

    shellAliases = {
      code = "env VSCODE_CWD=\"$PWD\" open -n -b \"com.microsoft.VSCode\" --args $*"; # create a shell alias for vs code
      cw = "cargo watch -q -c -x check";
      gst = "git status";
      history = "history 1";
      k = "kubectl";
      laru-ansible = "ANSIBLE_STDOUT_CALLBACK=json ansible -ulx2sg -e'ansible_connection=network_cli' -e'ansible_network_os=community.routeros.routeros' -m'routeros_command'";
      laru-ssh = "ssh -llx2sg -oport=15722";
      #nixswitch = "darwin-rebuild switch --flake .#";
      nixswitch = "nix run nix-darwin -- switch --flake .#"; # refresh nix env after config changes
      nixup = "nix flake update; nixswitch";
      path-lines = "echo $PATH | tr ':' '\n'";
      search = "rg -p --glob '!node_modules/*'  $@";
    };

    packages = with pkgs; [
      # macos packages
      bclm
    ];
  };
}
