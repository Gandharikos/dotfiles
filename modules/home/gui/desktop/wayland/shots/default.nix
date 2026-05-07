{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe';
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption;
  inherit (lib.types) enum str nullOr;
  inherit (config.dot.gui) desktop;
  inherit (config.xdg.userDirs.extraConfig) SCREENSHOTS;
  wl-copy' = getExe' pkgs.wl-clipboard-rs "wl-copy";
  screenshotPath = config.dot.gui.desktop.shot.path;
in
{
  imports = lib.dot.scanPaths ./.;

  options.dot.gui.desktop.shot = {
    default = mkOption {
      type = nullOr (enum [
        "hyprshot"
        "grimblast"
        "dank-material-shell"
        "noctalia-shell"
      ]);
      default =
        if desktop.shell.default == "noctalia-shell" then
          "noctalia-shell"
        else if desktop.shell.default == "dank-material-shell" then
          "dank-material-shell"
        else if desktop.default == "hyprland" then
          "hyprshot"
        else if desktop.default == "niri" then
          "grimblast"
        else
          null;
      description = "The screenshot tool to use. Set to null to disable.";
    };
    path = mkOption {
      type = str;
      default = "${SCREENSHOTS}/screenshot-%Y%m%d-%H%M%S.png";
      description = "Default output path template for desktop screenshots.";
    };
  };

  config = mkIf config.dot.gui.desktop.wayland.enable {
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
