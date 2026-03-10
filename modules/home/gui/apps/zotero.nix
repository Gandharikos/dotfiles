{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;
  cfg = config.my.gui.apps.zotero;
in {
  options.my.gui.apps.zotero = {
    enable = mkEnableOption "Zotero";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      zotero
      tesseract
    ];
  };
}
