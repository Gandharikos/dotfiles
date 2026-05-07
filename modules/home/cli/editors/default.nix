{
  lib,
  config,
  ...
}:
let
  inherit (lib.options) mkOption;
  inherit (lib.modules) mkDefault;
  inherit (lib.types) enum;
  inherit (config.my) editor;
in
{
  imports = lib.dot.scanPaths ./.;

  options.my.editor = mkOption {
    type = enum [
      "nvim"
      "helix"
      "vscode"
      "emacs"
    ];
    default = "nvim";
    description = "The editor to use";
  };

  config = {
    home.sessionVariables = {
      EDITOR = mkDefault "${editor}";
      VISUAL = mkDefault "${editor}";
      GIT_EDITOR = mkDefault "${editor}";
    };
  };
}
