{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.lists) optionals;
  inherit (lib.modules) mkIf;
  hasBluetoothAudio = config.services.pipewire.enable && config.my.machine.hasBluetooth;
  sonyLdacRule = productId: {
    matches = [
      {
        "device.name" = "~bluez_card.*";
        "device.product.id" = productId;
        "device.vendor.id" = "usb:054c";
      }
    ];
    actions.update-props."bluez5.a2dp.ldac.quality" = "hq";
  };
in
{
  config.services.pipewire.wireplumber = {
    inherit (config.services.pipewire) enable;

    configPackages = optionals hasBluetoothAudio [
      (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/11-bluetooth-policy.conf" ''
        wireplumber.settings = {
          bluetooth.autoswitch-to-headset-profile = false
        }
      '')
    ];

    extraConfig = mkIf hasBluetoothAudio {
      "wh-1000xm3-ldac-hq"."monitor.bluez.rules" = [ (sonyLdacRule "0x0cd3") ];
      "wh-1000xm4-ldac-hq"."monitor.bluez.rules" = [ (sonyLdacRule "0x0d58") ];
      "wh-1000xm6-ldac-hq"."monitor.bluez.rules" = [ (sonyLdacRule "0x0f8a") ];
    };
  };
}
