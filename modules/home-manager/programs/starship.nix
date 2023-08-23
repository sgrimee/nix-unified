{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = {
      #format = "[](#9A348E)$os$username[](bg:#DA627D fg:#9A348E)$directory[](fg:#DA627D bg:#FCA17D)$git_branch$git_status[](fg:#FCA17D bg:#86BBD8)$c$elixir$elm$golang$gradle$haskell$java$julia$nodejs$nim$rust$scala[](fg:#86BBD8 bg:#06969A)$docker_context[](fg:#06969A bg:#33658A)$custom[ ](fg:#33658A)";
      format = "$all$directory$character";

      # Change command timeout from 500 to 1000 ms
      command_timeout = 1000;

      continuation_prompt = "󱞩 ";

      custom.direnv = {
        format = "[  ](bg:#33658A)";
        when = "printenv DIRENV_FILE";
      };

      status.disabled = false;

      hostname = {
        ssh_only = false;
        format = "on [$hostname](bold yellow) ";
        disabled = false;
      };

      kubernetes = {
        format = "via [ ﴱ $context\($namespace\) ] (bold purple) ";
        disabled = false;
      };

      # You can also replace your username with a neat symbol like   or disable this
      # and use the os module below
      username = {
        show_always = true;
        style_user = "bg:#9A348E";
        style_root = "bg:#8E0606";
        format = "[$user ]($style)";
        disabled = false;
      };

      # An alternative to the username module which displays a symbol that
      # represents the current operating system
      os = {
        style = "bg:#9A348E";
        disabled = false; # Disabled by default
      };

      directory = {
        #format = "[ $path ]($style)";
        format = "at [$path]($style)[$read_only]($read_only_style) ";
        home_symbol = " ~";
        read_only = "  ";
        read_only_style = "197";
        style = "bg:#DA627D";
        truncate_to_repo = false;
        truncation_length = 3;
        truncation_symbol = "…/";
      };

      # Here is how you can shorten some long paths by text replacement
      # similar to mapped_locations in Oh My Posh:
      directory.substitutions = {
        "Documents" = "󰈙 ";
        "Downloads" = " ";
        "Music" = " ";
        "Pictures" = " ";
      };
      # Keep in mind that the order matters. For example:
      # "Important Documents" = " 󰈙 "
      # will not be replaced, because "Documents" was already substituted before.
      # So either put "Important Documents" before "Documents" or use the substituted version:
      # "Important 󰈙 " = " 󰈙 "

      c = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      docker_context = {
        symbol = " ";
        style = "bg:#06969A";
        format = "[ $symbol $context ]($style) $path";
      };

      elixir = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      elm = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      git_branch = {
        symbol = "";
        style = "bg:#FCA17D";
        format = "[ $symbol $branch ]($style)";
      };

      git_status = {
        style = "bg:#FCA17D";
        format = "[$all_status$ahead_behind ]($style)";
        ahead = "🏎💨";
        behind = "😰";
        conflicted = "🏳";
        deleted = "🗑";
        diverged = "😵";
        renamed = "�";
        staged = "[++\($count\)](green)";
        stashed = "📦";
        untracked = "🤷‍";
        up_to_date = "✓";
      };

      golang = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      gradle = {
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      haskell = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      java = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      julia = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nodejs = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nim = {
        symbol = "󰆥 ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      nix_shell = {
        symbol = " ";
      };

      python = {
        symbol = " ";
      };

      rust = {
        symbol = "";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };

      scala = {
        symbol = " ";
        style = "bg:#86BBD8";
        format = "[ $symbol ($version) ]($style)";
      };
    };
  };
}
