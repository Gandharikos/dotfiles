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
  settingsFile = pkgs.writeText "karabiner.json" (builtins.toJSON settings);
  deployConfig = pkgs.writeShellApplication {
    name = "deploy-karabiner-config";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.diffutils
    ];
    text = ''
      directory="$1"
      target="$directory/karabiner.json"
      mkdir -p "$directory"
      if [[ ! -L "$target" && -f "$target" && -w "$target" ]] && cmp -s ${settingsFile} "$target"; then
        chmod 600 "$target"
        exit 0
      fi
      temporary=$(mktemp "$directory/.karabiner.json.XXXXXXXX")
      trap 'rm -f "$temporary"' EXIT
      cp ${settingsFile} "$temporary"
      chmod 600 "$temporary"
      mv -f "$temporary" "$target"
    '';
  };
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
    dot.users.${config.dot.primaryUser}.home =
      { config, ... }:
      {
        # Karabiner must be able to atomically replace this file when saving.
        # Reapply the declarative settings after Home Manager retires old links.
        home.activation.karabinerConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
          run ${lib.getExe deployConfig} ${lib.escapeShellArg "${config.xdg.configHome}/karabiner"}
        '';
      };
  };
}
