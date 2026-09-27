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
  flypy = pkgs.fetchFromGitHub {
    owner = "cubercsl";
    repo = "rime-flypy";
    rev = "9ee464765e325dfd4b04926028d79d60882e653e";
    hash = "sha256-93LIHP1Ho/Jo2OOS0Dkmu+IFOJcUAFVxiKs3e5BxEK8=";
  };
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
      ${cfg.dir} = {
        source = "${pkgs.rime-ice}/share/rime-data";
        recursive = true;
      };

      "${cfg.dir}/flypy" = {
        source = "${flypy}/flypy";
        recursive = true;
      };
      "${cfg.dir}/flypy.schema.yaml".source = "${flypy}/flypy.schema.yaml";
      "${cfg.dir}/flypy.dict.yaml".source = "${flypy}/flypy.dict.yaml";
      "${cfg.dir}/flypydz.schema.yaml".source = "${flypy}/flypydz.schema.yaml";
      "${cfg.dir}/flypydz.dict.yaml".source = "${flypy}/flypydz.dict.yaml";
      "${cfg.dir}/flypyok.schema.yaml".source = "${flypy}/flypyok.schema.yaml";
      "${cfg.dir}/flypyok.dict.yaml".source = "${flypy}/flypyok.dict.yaml";
      "${cfg.dir}/lua/calculator_translator.lua".source = "${flypy}/lua/calculator_translator.lua";
      "${cfg.dir}/lua/flypy_date_translator.lua".source = "${flypy}/lua/flypy_date_translator.lua";
      "${cfg.dir}/lua/flypy_time_translator.lua".source = "${flypy}/lua/flypy_time_translator.lua";

      "${cfg.dir}/default.custom.yaml".text = ''
        patch:
          __include: rime_ice_suggestion:/
          "ascii_composer/switch_key/Shift_L": commit_code
          "ascii_composer/switch_key/Shift_R": noop
          schema_list:
            - schema: luna_pinyin
            - schema: double_pinyin_flypy
            - schema: rime_ice
            - schema: flypy
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
