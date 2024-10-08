{
  system = {
    keyboard = {
      enableKeyMapping = true;
      nonUS.remapTilde = true;
      remapCapsLockToControl = true;
    };
    defaults.NSGlobalDomain = {
      InitialKeyRepeat = 14;
      KeyRepeat = 1;
      "com.apple.keyboard.fnState" = true; # function keys without Fn
    };
  };
}
