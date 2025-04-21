{
  system = {
    keyboard = {
      enableKeyMapping = true;
      nonUS.remapTilde = false;
      remapCapsLockToControl = true;
    };
    defaults.NSGlobalDomain = {
      InitialKeyRepeat = 30;
      KeyRepeat = 2;
      "com.apple.keyboard.fnState" = true; # function keys without Fn
    };
  };
}
