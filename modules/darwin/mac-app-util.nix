{
  pkgs,
  config,
  inputs,
  ...
}: {
  # https://github.com/hraban/mac-app-util
  imports = [
    inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    (
      {
        pkgs,
        config,
        inputs,
        ...
      }: {
        home-manager.sharedModules = [
          inputs.mac-app-util.homeManagerModules.default
        ];
      }
    )
  ];
}
