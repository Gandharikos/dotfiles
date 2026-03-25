{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.lazyvim.yaml;
in
{
  options.my.lazyvim.yaml = {
    enable = mkEnableOption "language yaml";
  };

  config = mkIf cfg.enable {
    my.lazyvim = {
      extraPlugins = with pkgs.vimPlugins; [
        SchemaStore-nvim
      ];
      imports = [ "lazyvim.plugins.extras.lang.yaml" ];
      extraPackages = with pkgs; [
        yaml-language-server
      ];
    };
  };
}
