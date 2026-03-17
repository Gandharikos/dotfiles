# modules/dev/shell.nix --- http://zsh.sourceforge.net/
#
# Shell script programmers are strange beasts. Writing programs in a language
# that wasn't intended as a programming language. Alas, it is not for us mere
# mortals to question the will of the ancient ones. If they want shell programs,
# they get shell programs.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.shell;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkMerge mkIf;
in
{
  options.my.langs.shell = {
    enable = mkEnableOption "Shell development environment";
    xdg.enable = mkEnableOption "Shell XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        shellcheck
      ];
    })

    (mkIf cfg.xdg.enable {
      # TODO
    })
  ];
}
