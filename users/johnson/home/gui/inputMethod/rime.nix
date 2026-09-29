{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) str;

  cfg = config.my.gui.rime;
  rimeIceData = "${pkgs.dot.rime-ice-zhwiki}/share/rime-data";
  octagramData = "${pkgs.dot.rime-octagram-data}/share/rime-data";
  rimePackages = [
    pkgs.dot.rime-flypy
    pkgs.dot.rime-yuhao
  ];
  packageFiles = lib.concatMap (
    package:
    let
      dataDir = "${package}/share/rime-data";
      mkFile = path: {
        name = "${cfg.dir}/${path}";
        value.source = "${dataDir}/${path}";
      };
      mkDirectory = path: {
        name = "${cfg.dir}/${path}";
        value = {
          source = "${dataDir}/${path}";
          recursive = true;
        };
      };
    in
    map mkFile package.rimeFiles ++ map mkDirectory package.rimeDirectories
  ) rimePackages;
in
{
  options.my.gui.rime = {
    enable = mkEnableOption "rime" // {
      default = true;
    };

    dir = mkOption {
      type = str;
      default =
        {
          darwin = "Library/Rime";
          linux = ".local/share/fcitx5/rime";
        }
        .${pkgs.stdenv.hostPlatform.parsed.kernel.name};
    };
  };

  config = mkIf cfg.enable {
    home.file = {
      "${cfg.dir}/default.custom.yaml".text = ''
        patch:
          __include: rime_ice_suggestion:/
          "ascii_composer/switch_key/Shift_L": commit_code
          "ascii_composer/switch_key/Shift_R": noop
          schema_list:
            - schema: flypy
            - schema: rime_ice
            - schema: yustar
            - schema: yuming
      '';

      # These indexes match the pinned Flypy schema's second-candidate and simplification bindings.
      "${cfg.dir}/flypy.custom.yaml".text = ''
        patch:
          "key_binder/bindings/@4/accept": apostrophe
          "key_binder/bindings/@11/accept": "Control+apostrophe"
      '';

      "${cfg.dir}/grammar.yaml".source = "${octagramData}/grammar.yaml";
      "${cfg.dir}/zh-hans-t-essay-bgw.gram".source = "${octagramData}/zh-hans-t-essay-bgw.gram";

      "${cfg.dir}/rime_ice.custom.yaml".text = ''
        patch:
          __include: grammar:/hans
      '';
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
      ${cfg.dir} = {
        source = rimeIceData;
        recursive = true;
      };
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      "${cfg.dir}/rime_ice.dict.yaml".source = "${rimeIceData}/rime_ice.dict.yaml";
    }
    // lib.listToAttrs packageFiles;
  };
}
