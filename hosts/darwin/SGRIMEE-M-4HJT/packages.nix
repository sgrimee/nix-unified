{ pkgs, ... }: { home.packages = with pkgs; [ sonar-scanner-cli ]; }
