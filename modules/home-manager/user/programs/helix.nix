{
  programs.helix = {
    enable = true;
    # defaultEditor = true;
    settings = {
      theme = "monokai_aqua";
      editor = {
        bufferline = "always";
        file-picker.hidden = false;
        rulers = [80 120];
        line-number = "relative";
        lsp.display-messages = true;
        mouse = true;
        soft-wrap.enable = true;
      };
      keys.normal = {
        esc = ["collapse_selection" "keep_primary_selection"];
        space.q = ":q";
        space.space = "file_picker";
        space.w = ":w";
      };
    };
    languages = {
      language = [
        {
          auto-format = true;
          file-types = ["nix"];
          formatter.command = "alejandra";
          name = "nix";
        }
        {
          auto-format = true;
          file-types = ["rs"];
          injection-regex = "rust";
          indent = {
            tab-width = 4;
            unit = "    ";
          };
          name = "rust";
          roots = ["Cargo.toml" "Cargo.lock"];
          scope = "source.rust";
        }
      ];
    };
  };
}
