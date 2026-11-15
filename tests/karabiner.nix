# Pure evaluation: does not activate Karabiner or require flake inputs.
let
  generate = import ../modules/darwin/karabiner/config.nix;
  hhkb = {
    vendorId = 1278;
    productId = 33;
  };
  manipulators =
    settings:
    builtins.concatLists (
      map (rule: rule.manipulators) (builtins.head settings.profiles).complex_modifications.rules
    );
  scoped = manipulators (generate {
    devices = [ hhkb ];
  });
  internalOnly = manipulators (generate { });
  expectedCondition = {
    type = "device_if";
    identifiers = [
      { is_built_in_keyboard = true; }
      {
        vendor_id = 1278;
        product_id = 33;
        is_keyboard = true;
      }
    ];
  };
  caps = builtins.head scoped;
  control = builtins.elemAt scoped 1;
in
assert builtins.length scoped == 61;
assert builtins.all (m: builtins.elem expectedCondition m.conditions) scoped;
assert builtins.all (
  m:
  builtins.elem {
    type = "device_if";
    identifiers = [ { is_built_in_keyboard = true; } ];
  } m.conditions
) internalOnly;
assert caps.from.key_code == "caps_lock";
assert control.from.key_code == "left_control";
assert builtins.removeAttrs caps [ "from" ] == builtins.removeAttrs control [ "from" ];
assert caps.parameters."basic.to_if_alone_timeout_milliseconds" == 150;
assert caps.to == [ { key_code = "left_control"; } ];
assert caps.to_if_alone == [ { key_code = "escape"; } ];
assert builtins.all (m: builtins.length m.conditions == 2) (
  builtins.tail
    (builtins.elemAt (builtins.head (generate { }).profiles).complex_modifications.rules 3).manipulators
);
{
  deviceScope = true;
  tapHoldParity = true;
}
