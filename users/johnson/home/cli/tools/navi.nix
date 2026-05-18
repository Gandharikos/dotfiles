{
  config,
  lib,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption;

  cfg = config.my.navi;
in
{
  options.my.navi = {
    enable = mkEnableOption "navi";
  };

  config = mkIf cfg.enable {
    programs.navi = {
      # Navi documentation
      # See: https://github.com/denisidoro/navi
      enable = true;

      settings = {
        style = {
          tag = {
            color = "blue"; # text color. possible values: https://bit.ly/3gloNNI
            # width_percentage = 26; # column width relative to the terminal window
            # min_width = 20; # minimum column width as number of characters
          };
          comment = {
            color = "white";
            # width_percentage = 42;
            # min_width = 45;
          };
          snippet = {
            color = "green";
          };
        };
      };
    };
  };
}
