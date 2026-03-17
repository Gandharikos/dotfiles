{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum str;
  inherit (config.xdg.userDirs.extraConfig) SCREENSHOTS;
  wl-copy' = getExe' pkgs.wl-clipboard-rs "wl-copy";
  screenshotPath = config.my.gui.desktop.shot.path;
in {
  imports = lib.my.scanPaths ./.;

  options.my.gui.desktop.shot = {
    default = mkOption {
      type = enum ["hyprshot" "grimblast" "dms"];
      default = "grimblast";
      description = "The screenshot tool to use.";
    };
    path = mkOption {
      type = str;
      default = "${SCREENSHOTS}/screenshot-%Y%m%d-%H%M%S.png";
      description = "Default output path template for desktop screenshots.";
    };
  };

  config = mkIf config.my.gui.desktop.wayland.enable {
    home = {
      file = {
        "${config.xdg.configHome}/satty/config.toml".text = ''
          [general]
          # Start Satty in fullscreen mode
          fullscreen = false
          # Exit directly after copy/save action
          early-exit = false
          # Select the tool on startup [possible values: pointer, crop, line, arrow, rectangle, text, marker, blur, brush]
          initial-tool = "pointer"
          # Configure the command to be called on copy, for example `wl-copy`
          copy-command = "${wl-copy'}"
          # Increase or decrease the size of the annotations
          annotation-size-factor = 1
          # Filename to use for saving action: https://docs.rs/chrono/latest/chrono/format/strftime/index.html
          output-filename = "${screenshotPath}"
          save-after-copy = false
          default-hide-toolbars = false
          # The primary highlighter: block, freehand
          primary-highlighter = "block"
          disable-notifications = false

          # Font to use for text annotations
          [font]
          family = "SFProDisplay Nerd Font"
          style = "Bold"
        '';
      };
      packages = with pkgs; [
        satty # screenshot editor
      ];
    };
  };
}
