# packages/categories/k8s.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:
{
  core = with pkgs; [
    kubectl
    k9s
    kubectx
    kubelogin-oidc
  ];

  metadata = {
    description = "Kubernetes CLI and workflow tools";
    conflicts = [ ];
    requires = [ "development" ];
    size = "medium";
    priority = "medium";
  };
}
