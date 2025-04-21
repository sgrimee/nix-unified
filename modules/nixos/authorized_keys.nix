{
  # TODO: find a way to inherit the user variable
  users.users.sgrimee.openssh.authorizedKeys.keys = import ../../files/authorized_keys.nix;
}
