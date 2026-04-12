{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.my) capitalize;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.my.theme.tokyonight;
  inherit (config.my.theme.colorscheme) palette;

  enable = cfg.enable && config.my.gui.enable && isLinux;
  themeName = "Tokyonight-${capitalize cfg.style}";

  iniFormat = pkgs.formats.ini { };
  iniGlobalFormat = pkgs.formats.iniWithGlobalSection { };

  classicUiFile = iniGlobalFormat.generate "fcitx5-classicui.conf" {
    globalSection = {
      Theme = themeName;
      DarkTheme = themeName;
      # Font sizes based on catppuccin style (13 for input, 10 for menu)
      Font = "LXGW WenKai 13";
      MenuFont = "LXGW WenKai 10";
      TrayFont = "LXGW WenKai 10";
      UseDarkTheme = cfg.style != "day";
      UseAccentColor = false;
    };
  };

  # Catppuccin uses flat design without rounded corners or shadows by default
  # So we don't generate SVG files, just use solid colors

  themeFile = iniFormat.generate "fcitx5-${config.my.theme.colorscheme.slug}-theme.conf" {
    Metadata = {
      Name = themeName;
      Version = 0.1;
      Author = "Johnson Hu";
      Description = "Tokyo Night fcitx5 theme (Catppuccin-style layout)";
      ScaleWithDPI = true;
    };

    InputPanel = {
      # Keep tokyonight colors
      NormalColor = palette.fg;
      HighlightCandidateColor = palette.bg;
      HighlightColor = palette.blue;
      HighlightBackgroundColor = palette.bg_highlight;
      # Use catppuccin spacing
      Spacing = 3;
    };
    "InputPanel/Background" = {
      # Catppuccin style: flat design without rounded corners
      Color = palette.bg;
      BorderColor = palette.bg_highlight;
      BorderWidth = 0;
    };
    "InputPanel/Background/Margin" = {
      # Catppuccin uses 10 for all sides
      Left = 10;
      Right = 10;
      Top = 10;
      Bottom = 10;
    };
    "InputPanel/Highlight" = {
      # Catppuccin style: flat design without rounded corners
      Color = palette.blue;
      BorderColor = "${palette.blue}00";
      BorderWidth = 0;
    };
    "InputPanel/Highlight/Margin" = {
      # Catppuccin: 18, 18, 8, 8
      Left = 18;
      Right = 18;
      Top = 8;
      Bottom = 8;
    };
    "InputPanel/TextMargin" = {
      # Catppuccin: 18, 18, 8, 8
      Left = 18;
      Right = 18;
      Top = 8;
      Bottom = 8;
    };

    Menu = {
      # Keep tokyonight colors
      NormalColor = palette.fg;
      HighlightCandidateColor = palette.bg;
      # Use catppuccin spacing
      Spacing = 3;
    };
    "Menu/Background" = {
      # Catppuccin style: flat design without rounded corners
      Color = palette.bg;
      BorderColor = "${palette.bg_highlight}00";
      BorderWidth = 0;
    };
    "Menu/Background/Margin" = {
      # Catppuccin: 2 for all sides
      Left = 2;
      Right = 2;
      Top = 2;
      Bottom = 2;
    };
    "Menu/ContentMargin" = {
      # Catppuccin: 2 for all sides
      Left = 2;
      Right = 2;
      Top = 2;
      Bottom = 2;
    };
    "Menu/Highlight" = {
      # Catppuccin style: flat design without rounded corners
      Color = palette.blue;
      BorderColor = "${palette.blue}00";
      BorderWidth = 0;
    };
    "Menu/Highlight/Margin" = {
      # Catppuccin: 10, 10, 5, 5
      Left = 10;
      Right = 10;
      Top = 5;
      Bottom = 5;
    };
    "Menu/Separator" = {
      Color = palette.bg_highlight;
      BorderColor = "${palette.bg_highlight}00";
      BorderWidth = 0;
    };
  };
in
{
  config = mkIf enable {
    xdg.configFile."fcitx5/conf/classicui.conf".source = classicUiFile;

    # Catppuccin style: flat design, no SVG files needed
    xdg.dataFile."fcitx5/themes/${themeName}/theme.conf".source = themeFile;
  };
}
