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

  cfg = config.dot.gui.rime;
in
{
  options.dot.gui.rime = {
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
      ${cfg.dir} = {
        source = "${pkgs.rime-ice}/share/rime-data";
        recursive = true;
      };

      "${cfg.dir}/default.custom.yaml".text = ''
        patch:
          __include: rime_ice_suggestion:/
          schema_list:
            - schema: luna_pinyin
            - schema: double_pinyin_flypy
            - schema: rime_ice
      '';

      "${cfg.dir}/grammar.yaml".source = pkgs.fetchurl {
        url = "https://github.com/lotem/rime-octagram-data/raw/master/grammar.yaml";
        sha256 = "0aa14rvypnja38dm15hpq34xwvf06al6am9hxls6c4683ppyk355";
      };

      "${cfg.dir}/zh-hans-t-essay-bgw.gram".source = pkgs.fetchurl {
        url = "https://github.com/lotem/rime-octagram-data/raw/hans/zh-hans-t-essay-bgw.gram";
        sha256 = "0ygcpbhp00lb5ghi56kpxl1mg52i7hdlrznm2wkdq8g3hjxyxfqi";
      };

      "${cfg.dir}/luna_pinyin.custom.yaml".text = ''
        patch:
          __include: grammar:/hans
          translator/dictionary: rime_ice
      '';
    };
  };
}
