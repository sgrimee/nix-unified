# packages/categories/k8s-clients.nix
{
  pkgs,
  lib,
  hostCapabilities ? {},
  ...
}: {
  core = with pkgs; [
    kubectl # Kubernetes command-line interface
    k9s # Terminal UI for Kubernetes clusters
    kubectx # Switch between kubectl contexts and namespaces
    kubelogin-oidc # OIDC authentication plugin for kubectl
  ];

  metadata = {
    description = "Kubernetes client tools and workflow utilities";
    conflicts = [];
    requires = ["development"];
    size = "medium";
    priority = "medium";
  };
}
