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
      "${cfg.dir}/cn_dicts".source = "${pkgs.rime-ice}/share/rime-data/cn_dicts";
      "${cfg.dir}/rime_ice.dict.yaml".source =
        pkgs.runCommand "rime_ice.dict.yaml" { preferLocalBuild = true; }
          ''
            sed '/^\.\.\.$/q' ${pkgs.rime-ice}/share/rime-data/rime_ice.dict.yaml > $out
          '';

      "${cfg.dir}/default.custom.yaml".text = ''
        patch:
          __include: rime_ice_suggestion:/
          schema_list:
            - schema: luna_pinyin
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

      # https://github.com/rime/librime/issues/972
      # patch:
      #   punctuator/digit_separators: ",.:" # default value, set "" to disable
      #   punctuator/digit_separator_action: "" # default not set, set "commit" to auto commit
      "${cfg.dir}/luna_pinyin.custom.yaml".text = ''
        patch:
          __include: grammar:/hans
          translator/dictionary: rime_ice
      '';
    };
  };
}
