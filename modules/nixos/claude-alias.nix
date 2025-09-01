{ ... }: {
  home-manager.sharedModules =
    [{ home.shellAliases.claude = "$HOME/.local/bin/claude"; }];
}
