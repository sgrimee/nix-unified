{
  programs.aerc = {
    enable = true;
    extraConfig = {general = {unsafe-accounts-conf = true;};};
    extraAccounts = ''
      [Gmail]
      source        = imaps://sgrimee%40gmail.com@imap.gmail.com:993
      source-cred-cmd = op item get "gmail aerc" --field password --reveal
      outgoing      = smtps://sgrimee%40gmail.com@smtp.gmail.com:587
      outgoing-cred-cmd = op item get "gmail aerc" --field password --reveal
      default = INBOX
      from    = Sam Grimee <sgrimee@gmail.com>
      copy-to = Sent
      cache-headers = true
    '';
  };
}
