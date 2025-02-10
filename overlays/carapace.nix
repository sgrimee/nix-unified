final: prev: {
  carapace = prev.carapace.overrideAttrs (_: prev: rec {
    version = "1.2.1";

    src = final.fetchFromGitHub {
      owner = "carapace-sh";
      repo = "carapace-bin";
      rev = "v${version}";
      hash = "sha256-MGg0L+a4tYHwbJxrOQ9QotsfpOvxnL6K0QX6ayGGXpI=";
    };

    vendorHash = "sha256-kxd/bINrZxgEmgZ67KjTTfuIr9ekpd08s0/p0Sht5Ks=";
  });
}
