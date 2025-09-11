# packages/categories/k8s-clients.nix
{ pkgs, lib, hostCapabilities ? { }, ... }:
{
  core = with pkgs; [
    kubectl
    k9s
    kubectx
    kubelogin-oidc
  ];

  metadata = {
    description = "Kubernetes client tools and workflow utilities";
    conflicts = [ ];
    requires = [ "development" ];
    size = "medium";
    priority = "medium";
  };
}
