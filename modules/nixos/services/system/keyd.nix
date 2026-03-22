{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.keyboard;
in
{
  config = mkIf (cfg.type == "keyd") {
    services.keyd = {
      enable = true;
      keyboards.default = {
        ids = [ "*" ];
        extraConfig = builtins.readFile cfg.keyd.configFile;
      };
    };
  };
}
