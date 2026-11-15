{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkIf;
  cfg = config.dot.services.karabiner;
  kbCfg = config.dot.keyboard;
  settings = import cfg.configFile { inherit (cfg) devices; };
in
{
  options.dot.services.karabiner = {
    enable = mkOption {
      type = lib.types.bool;
      default = kbCfg.backend == "karabiner";
      internal = true;
      readOnly = true;
      description = "Whether to enable Karabiner keyboard remapping";
    };

    configFile = mkOption {
      type = lib.types.path;
      default = ./config.nix;
      description = "Path to a Nix function accepting devices and returning the Karabiner configuration.";
    };

    devices = mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            vendorId = mkOption {
              type = lib.types.ints.unsigned;
              description = "Keyboard vendor_id reported by Karabiner-EventViewer.";
            };
            productId = mkOption {
              type = lib.types.ints.unsigned;
              description = "Keyboard product_id reported by Karabiner-EventViewer.";
            };
          };
        }
      );
      default = [ ];
      description = "External keyboards allowed to use the shared remapping, in addition to built-in keyboards. Add separate entries if USB and Bluetooth report different IDs.";
    };
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "karabiner-elements" ];
    dot.users.${config.dot.primaryUser}.home.xdg.configFile."karabiner/karabiner.json".source =
      pkgs.writeText "karabiner.json" (builtins.toJSON settings);
  };
}
