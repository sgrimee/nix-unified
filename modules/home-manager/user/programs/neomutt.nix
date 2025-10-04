{
  programs.neomutt = {
    enable = true;
    sidebar.enable = true;

    settings = {
      # Gmail IMAP settings
      imap_user = "sgrimee@gmail.com";
      imap_pass = ''`op item get "gmail aerc" --field password --reveal`'';
      folder = "imaps://imap.gmail.com:993";
      spoolfile = "+INBOX";
      postponed = "+[Gmail]/Drafts";
      record = "+[Gmail]/Sent Mail";
      trash = "+[Gmail]/Trash";

      # SMTP settings
      smtp_url = "smtps://sgrimee@gmail.com@smtp.gmail.com:587";
      smtp_pass = ''`op item get "gmail aerc" --field password --reveal`'';

      # SSL/TLS settings
      ssl_starttls = "yes";
      ssl_force_tls = "yes";

      # Cache settings
      header_cache = "~/.cache/neomutt/headers";
      message_cachedir = "~/.cache/neomutt/bodies";

      # Identity
      realname = "Sam Grimee";
      from = "sgrimee@gmail.com";

      # Interface settings
      sort = "reverse-date";
      sidebar_visible = "yes";
      sidebar_width = "30";
      sidebar_format = "%B%* %N";
      mail_check_stats = "yes";

      # Key bindings for sidebar
      bind_index = "\\Cp sidebar-prev";
      bind_index2 = "\\Cn sidebar-next";
      bind_index3 = "\\Co sidebar-open";

      # Colors
      color_normal = "white default";
      color_sidebar_new = "brightgreen default";
      color_sidebar_indicator = "black yellow";
    };

    macros = [
      {
        map = ["index" "pager"];
        key = "\\Cb";
        action = "<pipe-message> urlscan<Enter>";
      }
    ];
  };
}
