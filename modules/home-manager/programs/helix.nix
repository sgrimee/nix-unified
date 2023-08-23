{
  programs.helix = {
    enable = true;
    # defaultEditor = true;
    settings = {
      #theme = "base16";
      theme = "monokai_pro_spectrum";
      editor = {
        rulers = [ 80 120 ];
        line-number = "relative";
        lsp.display-messages = true;
        mouse = true;
      };
      keys.normal = {
        esc = [ "collapse_selection" "keep_primary_selection" ];
        o = "file_picker_in_current_buffer_directory";
        #p = "paste_clipboard_before";
        space.q = ":q";
        space.space = "file_picker";
        space.w = ":w";
        #y = "yank_main_selection_to_clipboard";
      };
    };
    languages = {
      language = [
        {
          name = "nix";
          formatter.command = "alejandra";
          auto-format = true;
        }
      ];
    };
  };
}
