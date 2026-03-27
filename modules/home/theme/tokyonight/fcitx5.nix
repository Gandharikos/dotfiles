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
      Font = "Noto Sans CJK SC 12";
      MenuFont = "Noto Sans CJK SC 12";
      TrayFont = "Noto Sans CJK SC 12";
      UseDarkTheme = cfg.style != "day";
      UseAccentColor = false;
    };
  };

  panelSvg = pkgs.writeText "fcitx5-${config.my.theme.colorscheme.slug}-panel.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
      <defs>
        <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
          <feDropShadow dx="2" dy="3" stdDeviation="3" flood-color="${palette.black}" flood-opacity="0.35"/>
        </filter>
      </defs>
      <rect
        x="8"
        y="8"
        width="44"
        height="44"
        rx="5"
        fill="${palette.bg}"
        stroke="${palette.bg_highlight}"
        stroke-width="1.5"
        filter="url(#shadow)"
      />
    </svg>
  '';

  highlightSvg = pkgs.writeText "fcitx5-${config.my.theme.colorscheme.slug}-highlight.svg" ''
    <svg xmlns="http://www.w3.org/2000/svg" width="60" height="60" viewBox="0 0 60 60">
      <rect
        x="10"
        y="10"
        width="40"
        height="40"
        rx="5"
        fill="${palette.blue}"
      />
    </svg>
  '';

  themeFile = iniFormat.generate "fcitx5-${config.my.theme.colorscheme.slug}-theme.conf" {
    Metadata = {
      Name = themeName;
      Version = 0.1;
      Author = "Johnson Hu";
      Description = "Tokyo Night fcitx5 theme";
    };

    InputPanel = {
      NormalColor = palette.fg;
      HighlightCandidateColor = palette.bg;
      HighlightColor = palette.bg;
      HighlightBackgroundColor = palette.blue;
      Spacing = 0;
    };
    "InputPanel/Background" = {
      Image = "panel.svg";
      Color = palette.bg;
      BorderColor = palette.bg_highlight;
      BorderWidth = 0;
    };
    "InputPanel/Background/Margin" = {
      Left = 14;
      Right = 14;
      Top = 14;
      Bottom = 14;
    };
    "InputPanel/Highlight" = {
      Image = "highlight.svg";
      Color = palette.blue;
      BorderColor = "${palette.blue}00";
      BorderWidth = 0;
    };
    "InputPanel/Highlight/Margin" = {
      Left = 14;
      Right = 14;
      Top = 8;
      Bottom = 8;
    };
    "InputPanel/ContentMargin" = {
      Left = 8;
      Right = 8;
      Top = 8;
      Bottom = 8;
    };
    "InputPanel/TextMargin" = {
      Left = 8;
      Right = 8;
      Top = 6;
      Bottom = 6;
    };

    Menu = {
      NormalColor = palette.fg;
      HighlightCandidateColor = palette.bg;
      Spacing = 0;
    };
    "Menu/Background" = {
      Image = "panel.svg";
      Color = palette.bg;
      BorderColor = "${palette.bg_highlight}00";
      BorderWidth = 0;
    };
    "Menu/Background/Margin" = {
      Left = 10;
      Right = 10;
      Top = 10;
      Bottom = 10;
    };
    "Menu/Highlight" = {
      Image = "highlight.svg";
      Color = palette.blue;
      BorderColor = "${palette.blue}00";
      BorderWidth = 0;
    };
    "Menu/Highlight/Margin" = {
      Left = 6;
      Right = 6;
      Top = 6;
      Bottom = 6;
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

    xdg.dataFile = {
      "fcitx5/themes/${themeName}/theme.conf".source = themeFile;
      "fcitx5/themes/${themeName}/panel.svg".source = panelSvg;
      "fcitx5/themes/${themeName}/highlight.svg".source = highlightSvg;
    };
  };
}
