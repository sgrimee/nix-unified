{ config, lib, pkgs, hostCapabilities ? {}, ... }:

let
  # Extract keyboard devices from host capabilities
  keyboardDevices = 
    if hostCapabilities ? hardware 
    && hostCapabilities.hardware ? keyboard 
    && hostCapabilities.hardware.keyboard ? devices
    then hostCapabilities.hardware.keyboard.devices
    else [ "/dev/input/by-path/platform-i8042-serio-0-event-kbd" ]; # fallback
in

{

  config = {
  # Enable the uinput module
  boot.kernelModules = [ "uinput" ];

  # Enable uinput
  hardware.uinput.enable = true;

  # Set up udev rules for uinput
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';

  # Ensure the uinput group exists
  users.groups.uinput = { };

  # Add the Kanata service user to necessary groups
  systemd.services.kanata-internalKeyboard.serviceConfig = {
    SupplementaryGroups = [ "input" "uinput" ];
  };

  services.kanata = {
    enable = true;
    keyboards = {
      internalKeyboard = {
        devices = keyboardDevices;
        extraDefCfg = "process-unmapped-keys yes";
        config = ''
          ;; home row-mods

          ;; un-mapped keys behave as normally
          ;;(defcfg
          ;;  process-unmapped-keys yes
          ;;)

          ;; define the keys to remap
          (defsrc
           caps a s d f j k l ;
          )

          ;; define values for tap time and hold time
          (defvar
            tap-time 150
            hold-time 200
          )

          ;; alias definitions
          (defalias
            escctrl (tap-hold $tap-time $hold-time esc lctl)
            a (tap-hold $tap-time $hold-time a lctrl)
            s (tap-hold $tap-time $hold-time s lalt)
            d (tap-hold $tap-time $hold-time d lmet)
            f (tap-hold $tap-time $hold-time f lsft)
            j (tap-hold $tap-time $hold-time j rsft)
            k (tap-hold $tap-time $hold-time k rmet)
            l (tap-hold $tap-time $hold-time l ralt)
            ; (tap-hold $tap-time $hold-time ; rctrl)
          )

          (deflayer base
            @escctrl @a @s @d @f @j @k @l @;
          )
        '';
      };
    };
  };
  };
}
