{ pkgs, ... }: {
  home.packages = with pkgs; [
    k9s # Kubernetes CLI To Manage Your Clusters In Style
    kubectl # Kubernetes command-line tool
    kubectx # Fast way to switch between clusters and namespaces
    kubelogin-oidc # A kubectl plugin for Kubernetes OpenID Connect (OIDC) authentication
  ];
}
