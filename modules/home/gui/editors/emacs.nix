{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.emacs;
in {
  options.my.emacs = {
    enable =
      mkEnableOption "Enable Emacs"
      // {
        default = config.my.desktop.enable;
      };
  };

  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [
        binutils # native-comp needs 'as', provided by this

        sqlite # for org-roam
        emacs-all-the-icons-fonts
      ];
      sessionPath = ["${config.xdg.configHome}/emacs/bin"];
      sessionVariables = let
        editor = "emacsclient -t";
      in
        mkIf (config.my.editor == "emacs")
        {
          EDITOR = editor;
          VISUAL = editor;
          GIT_EDITOR = editor;
        };
    };

    services.emacs = {
      enable = true;
      # generate emacsclient desktop file
      client.enable = true;
      socketActivation.enable = true;
    };

    programs.emacs = {
      enable = true;
    };
  };
}
