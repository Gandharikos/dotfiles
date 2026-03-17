{
  # Tune keyboard behaviour on macOS while staying within what the system actually exposes.
  # Ideally we could globally remap the Option key to Alt, but macOS still does not provide
  # a supported API for that, so the module focuses on the settings that do exist.
  system = {
    keyboard = {
      # macOS needs this toggle on before it honours any of the per-key remappings below.
      enableKeyMapping = true;

      # NOTE: do NOT support remap capslock to both control and escape at the same time
      remapCapsLockToControl = false; # leave Control free so Escape-only mode wins
      remapCapsLockToEscape = true; # map Caps Lock to Escape for modal editors like Vim

      # swap left command and left alt
      # so it matches common keyboard layout: `ctrl | command | alt`
      # disabled as it only causes problems
      swapLeftCommandAndLeftAlt = false;
    };

    defaults = {
      # `com.apple.symbolichotkeys` stores hotkey metadata; disabling 64/65 keeps Mission Control
      # from binding Control+Arrow, and 60/61 below reassign the shortcuts we actually want.
      CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
        # 64 = Spotlight search shortcut
        # Disable it to prevent Cmd+Space conflicts
        "64" = {
          enabled = false;
        };
        # 65 = Finder search shortcut (or "Show Spotlight window", depending on macOS version)
        # Disable it to fully turn off Spotlight-related key bindings
        "65" = {
          enabled = false;
        };
        # Previous input source = Ctrl+F12
        "60" = {
          enabled = true;
          value = {
            type = "standard";
            parameters = [
              65535
              111
              8650752
            ];
            # 65535: special; 111: F12 keyCode; 8650752: 0x840000 = FnFlag + Ctrl
          };
        };

        # (Optional) Next input source = Ctrl+Shift+F12
        "61" = {
          enabled = true;
          value = {
            type = "standard";
            parameters = [
              65535
              111
              8781824
            ];
            # 0x860000 = FnFlag + Ctrl + Shift
          };
        };
      };
      NSGlobalDomain = {
        # Use F1, F2, etc. keys as standard function keys.
        "com.apple.keyboard.fnState" = true;

        AppleKeyboardUIMode = 3; # Mode 3 enables full keyboard control for dialogs and menus.

        # Don't keep native press-and-hold picker instead of forcing key-repeat.
        ApplePressAndHoldEnabled = false;
        # `InitialKeyRepeat` controls how long macOS waits (in 1/60s) before key repeat kicks in.
        # 15 ≈ 225 ms which feels fast while still staying within Apple’s supported range.
        InitialKeyRepeat = 15;
        # `KeyRepeat` defines the delay between repeats once they start. Lower is faster; 3 ≈ 45 ms.
        KeyRepeat = 3;
      };
    };
  };
}
