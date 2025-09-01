{ ... }: {
  home-manager.sharedModules =
    [{ home.shellAliases.claude = "$HOME/.claude/local/claude"; }];
}
