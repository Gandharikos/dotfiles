{
  devices ? [ ],
}:
let
  key = key_code: { inherit key_code; };
  shifted = key_code: {
    inherit key_code;
    modifiers = [ "left_shift" ];
  };
  any = {
    optional = [ "any" ];
  };
  shift = {
    mandatory = [ "shift" ];
    optional = [ "any" ];
  };
  hyper = key_code: {
    inherit key_code;
    modifiers = [
      "left_control"
      "left_option"
      "left_command"
    ];
  };
  tabCondition = {
    type = "variable_if";
    name = "tab_layer";
    value = 1;
  };
  deviceCondition = {
    type = "device_if";
    identifiers = [
      { is_built_in_keyboard = true; }
    ]
    ++ map (device: {
      vendor_id = device.vendorId;
      product_id = device.productId;
      is_keyboard = true;
    }) devices;
  };
  basic = from: to: {
    type = "basic";
    inherit from to;
  };
  remap = from: to: basic ((key from) // { modifiers = any; }) [ to ];
  tapControl =
    from:
    (remap from (key "left_control"))
    // {
      parameters."basic.to_if_alone_timeout_milliseconds" = 150;
      to_if_alone = [ (key "escape") ];
    };
  chord =
    threshold: modifiers: keys: to:
    basic {
      simultaneous = map key keys;
      simultaneous_options = {
        key_down_order = "insensitive";
        key_up_order = "insensitive";
        key_up_when = "all";
      };
      inherit modifiers;
    } [ to ]
    // {
      parameters."basic.simultaneous_threshold_milliseconds" = threshold;
    };
  punctuation =
    from: modifiers: to:
    basic ((key from) // { inherit modifiers; }) [ to ];
  tabKey = from: to: basic (key from) [ to ];
  umlaut =
    letter: uppercase:
    basic ((key letter) // (if uppercase then { modifiers.mandatory = [ "shift" ]; } else { })) [
      {
        key_code = "u";
        modifiers = [ "left_option" ];
      }
      (if uppercase then shifted letter else key letter)
      (key "vk_none")
    ];
  rules = [
    {
      description = "Kanata base layer";
      manipulators = [
        (tapControl "caps_lock")
        (tapControl "left_control")
        (remap "left_option" (key "left_command"))
        (
          (remap "left_command" (key "left_option"))
          // {
            conditions = [
              {
                type = "variable_unless";
                name = "tab_layer";
                value = 1;
              }
            ];
          }
        )
        (remap "right_command" {
          key_code = "left_control";
          modifiers = [
            "left_option"
            "left_command"
          ];
        })
        (remap "right_option" (key "right_command"))
      ];
    }
    {
      description = "Kanata chords";
      manipulators = [
        (chord 45 shift [ "u" "i" ] (shifted "comma"))
        (chord 45 any [ "u" "i" ] (shifted "9"))
        (chord 45 shift [ "i" "o" ] (shifted "period"))
        (chord 45 any [ "i" "o" ] (shifted "0"))
        (chord 30 any [ "w" "e" ] (key "open_bracket"))
        (chord 30 any [ "e" "r" ] (key "close_bracket"))
        (chord 30 any [ "m" "comma" ] (shifted "hyphen"))
        (chord 30 any [ "comma" "period" ] (key "equal_sign"))
        (chord 30 any [ "j" "k" ] (key "hyphen"))
        (chord 30 any [ "k" "l" ] (shifted "equal_sign"))
        (chord 30 any [ "q" "a" ] (shifted "1"))
        (chord 30 any [ "w" "s" ] (shifted "2"))
        (chord 30 any [ "e" "d" ] (shifted "3"))
        (chord 30 any [ "r" "f" ] (shifted "4"))
        (chord 30 any [ "t" "g" ] (shifted "5"))
        (chord 30 any [ "y" "h" ] (shifted "6"))
        (chord 30 any [ "u" "j" ] (shifted "7"))
        (chord 30 any [ "i" "k" ] (shifted "8"))
        (chord 30 any [ "o" "l" ] (key "grave_accent_and_tilde"))
        (chord 30 any [ "p" "semicolon" ] (key "backslash"))
        (chord 30 any [ "q" "w" ] (key "escape"))
        (chord 30 any [ "a" "s" ] (key "tab"))
        (chord 30 any [ "l" "semicolon" ] (key "return_or_enter"))
        (chord 30 any [ "o" "p" ] (key "delete_or_backspace"))
        (chord 30 any [ "s" "d" ] (shifted "7"))
        (chord 30 any [ "d" "f" ] (shifted "backslash"))
        (chord 30 any [ "x" "c" ] (key "backslash"))
        (chord 30 any [ "c" "v" ] (shifted "1"))
      ];
    }
    {
      description = "Kanata base punctuation";
      manipulators = [
        (punctuation "semicolon" shift (shifted "quote"))
        (punctuation "semicolon" any (key "quote"))
        (punctuation "quote" shift (shifted "semicolon"))
        (punctuation "quote" any (key "semicolon"))
        (punctuation "comma" shift (key "semicolon"))
        (punctuation "period" shift (shifted "semicolon"))
      ];
    }
    {
      description = "Kanata tab layer";
      manipulators = [
        (
          (basic ((key "tab") // { modifiers = any; }) [
            {
              set_variable = {
                name = "tab_layer";
                value = 1;
              };
            }
          ])
          // {
            parameters."basic.to_if_alone_timeout_milliseconds" = 150;
            to_after_key_up = [
              {
                set_variable = {
                  name = "tab_layer";
                  value = 0;
                };
              }
            ];
            to_if_alone = [ (key "tab") ];
          }
        )
      ]
      ++ map (manipulator: manipulator // { conditions = [ tabCondition ]; }) [
        (remap "left_command" {
          key_code = "left_control";
          modifiers = [
            "left_option"
            "left_command"
          ];
        })
        (basic {
          key_code = "h";
          modifiers = {
            mandatory = [ "option" ];
            optional = [ "any" ];
          };
        } [ (hyper "left_arrow") ])
        (basic {
          key_code = "l";
          modifiers = {
            mandatory = [ "option" ];
            optional = [ "any" ];
          };
        } [ (hyper "right_arrow") ])
        (basic {
          key_code = "h";
          modifiers = {
            mandatory = [
              "control"
              "option"
              "command"
            ];
            optional = [ "any" ];
          };
        } [ (hyper "left_arrow") ])
        (basic {
          key_code = "l";
          modifiers = {
            mandatory = [
              "control"
              "option"
              "command"
            ];
            optional = [ "any" ];
          };
        } [ (hyper "right_arrow") ])
        (tabKey "q" {
          key_code = "f12";
          modifiers = [ "left_control" ];
        })
        (umlaut "u" true)
        (umlaut "u" false)
        (umlaut "o" true)
        (umlaut "o" false)
        (tabKey "p" (key "f13"))
        (tabKey "delete_or_backspace" (key "delete_forward"))
        (umlaut "a" true)
        (umlaut "a" false)
        (basic
          {
            key_code = "s";
            modifiers.mandatory = [ "shift" ];
          }
          [
            { shell_command = "/usr/bin/osascript -e 'tell application \"System Events\" to keystroke \"ẞ\"'"; }
          ]
        )
        (tabKey "s" {
          key_code = "s";
          modifiers = [ "left_option" ];
        })
        (tabKey "h" (key "left_arrow"))
        (tabKey "j" (key "down_arrow"))
        (tabKey "k" (key "up_arrow"))
        (tabKey "l" (key "right_arrow"))
      ];
    }
  ];
in
{
  profiles = [
    {
      name = "Default profile";
      selected = true;
      virtual_hid_keyboard.keyboard_type_v2 = "ansi";
      complex_modifications.rules = map (
        rule:
        rule
        // {
          manipulators = map (
            manipulator:
            manipulator
            // {
              conditions = (manipulator.conditions or [ ]) ++ [ deviceCondition ];
            }
          ) rule.manipulators;
        }
      ) rules;
    }
  ];
}
