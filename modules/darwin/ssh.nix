# SSH configuration for Darwin systems
{ config, ... }: {
  # Configure SSH authorized keys for the primary user
  # May not have any effect on a corporate managed Mac
  users.users.${config.system.primaryUser}.openssh.authorizedKeys.keys =
    import ../../files/authorized_keys.nix;
}
