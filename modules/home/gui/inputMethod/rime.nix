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

    deploy = {
      enable = mkEnableOption "auto deploy rime after rebuild" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    home.file = {
      # Copy all schema files from rime-ice
      "${cfg.dir}/cn_dicts".source = "${pkgs.rime-ice}/share/rime-data/cn_dicts";
      "${cfg.dir}/en_dicts".source = "${pkgs.rime-ice}/share/rime-data/en_dicts";
      "${cfg.dir}/opencc".source = "${pkgs.rime-ice}/share/rime-data/opencc";

      # Copy all .yaml schema files
      "${cfg.dir}/rime_ice.schema.yaml".source = "${pkgs.rime-ice}/share/rime-data/rime_ice.schema.yaml";
      "${cfg.dir}/melt_eng.schema.yaml".source = "${pkgs.rime-ice}/share/rime-data/melt_eng.schema.yaml";
      "${cfg.dir}/radical_pinyin.schema.yaml".source =
        "${pkgs.rime-ice}/share/rime-data/radical_pinyin.schema.yaml";
      "${cfg.dir}/rime_ice_suggestion.yaml".source =
        "${pkgs.rime-ice}/share/rime-data/rime_ice_suggestion.yaml";
      "${cfg.dir}/melt_eng.dict.yaml".source = "${pkgs.rime-ice}/share/rime-data/melt_eng.dict.yaml";
      "${cfg.dir}/radical_pinyin.dict.yaml".source =
        "${pkgs.rime-ice}/share/rime-data/radical_pinyin.dict.yaml";

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
            - schema: t9
            - schema: double_pinyin
            - schema: csp
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

    # Add activation script to deploy rime
    home.activation.deployRime = lib.mkIf cfg.deploy.enable (
      lib.hm.dag.entryAfter [ "writeBoundary" ] (
        if pkgs.stdenv.isDarwin then
          ''
            $DRY_RUN_CMD '/Library/Input Methods/Squirrel.app/Contents/MacOS/rime_deployer' --build $HOME/Library/Rime || true
          ''
        else
          ''
            $DRY_RUN_CMD ${pkgs.librime}/bin/rime_deployer --build $HOME/${cfg.dir} || true
          ''
      )
    );
  };
}
