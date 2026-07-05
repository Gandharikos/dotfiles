{
  inputs,
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:
let
  inherit (lib.modules)
    mkAfter
    mkForce
    mkIf
    mkMerge
    ;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  cfg = config.nixporn.colorschemes.catppuccin;
  guiLinux = osConfig.dot.gui.enable && isLinux;
  accent = cfg.palette.${cfg.accent};
  fishColor = lib.strings.removePrefix "#";
  fishThemeName = "catppuccin-${cfg.flavor}";
  yaziSlug = "catppuccin-${cfg.flavor}-${cfg.accent}";
  yaziFlavorName = lib.nixporn.yaziFlavorName yaziSlug;
  yaziFlavorSource = "${pkgs.nixporn.catppuccin.yazi}/themes/${cfg.flavor}/${yaziSlug}.toml";
  yaziTransparentFlavor = pkgs.runCommand "yazi-${yaziFlavorName}-transparent-flavor.toml" { } ''
    substitute ${yaziFlavorSource} $out \
      --replace 'name = "*"' 'url = "*"' \
      --replace 'name = "*/"' 'url = "*/"' \
      --replace 'overall = { bg = "${cfg.palette.base}" }' 'overall = { bg = "reset" }'
  '';
  noctaliaPalette = {
    mPrimary = accent;
    mOnPrimary = cfg.palette.base;
    mSecondary = cfg.palette.peach;
    mOnSecondary = cfg.palette.base;
    mTertiary = cfg.palette.teal;
    mOnTertiary = cfg.palette.base;
    mError = cfg.palette.red;
    mOnError = cfg.palette.base;
    mSurface = cfg.palette.base;
    mOnSurface = cfg.palette.text;
    mHover = cfg.palette.teal;
    mOnHover = cfg.palette.base;
    mSurfaceVariant = cfg.palette.surface0;
    mOnSurfaceVariant = cfg.palette.subtext1;
    mOutline = cfg.palette.surface2;
    mShadow = cfg.palette.crust;
    terminal = {
      normal = {
        black = cfg.palette.surface1;
        inherit (cfg.palette)
          red
          green
          yellow
          blue
          ;
        magenta = cfg.palette.pink;
        cyan = cfg.palette.teal;
        white = cfg.palette.subtext0;
      };
      bright = {
        black = cfg.palette.surface2;
        red = cfg.palette.red;
        green = cfg.palette.green;
        yellow = cfg.palette.yellow;
        blue = cfg.palette.sapphire;
        magenta = cfg.palette.pink;
        cyan = cfg.palette.teal;
        white = cfg.palette.subtext1;
      };
      foreground = cfg.palette.text;
      background = cfg.palette.base;
      cursor = cfg.palette.rosewater;
      cursorText = cfg.palette.crust;
      selectionFg = cfg.palette.text;
      selectionBg = cfg.palette.surface0;
    };
  };
in
{
  imports = lib.dot.scanPaths ./.;

  config = mkIf (config.nixporn.colorscheme == "catppuccin") (mkMerge [
    {
      home.sessionVariables = {
        COLORSCHEME_FLAVOR = cfg.flavor;
        COLORSCHEME_ACCENT = cfg.accent;
      };
    }

    (mkIf config.programs.fish.enable {
      xdg.configFile."fish/themes/${fishThemeName}.theme".source =
        mkForce "${pkgs.nixporn.catppuccin.fish}/themes/static/${fishThemeName}.theme";

      programs.fish.shellInit = mkAfter ''
        set -g fish_color_normal ${fishColor cfg.palette.text} --theme=${fishThemeName}
        set -g fish_color_command ${fishColor cfg.palette.blue} --theme=${fishThemeName}
        set -g fish_color_param ${fishColor cfg.palette.flamingo} --theme=${fishThemeName}
        set -g fish_color_keyword ${fishColor cfg.palette.mauve} --theme=${fishThemeName}
        set -g fish_color_quote ${fishColor cfg.palette.green} --theme=${fishThemeName}
        set -g fish_color_redirection ${fishColor cfg.palette.pink} --theme=${fishThemeName}
        set -g fish_color_end ${fishColor cfg.palette.peach} --theme=${fishThemeName}
        set -g fish_color_comment ${fishColor cfg.palette.overlay1} --theme=${fishThemeName}
        set -g fish_color_error ${fishColor cfg.palette.red} --theme=${fishThemeName}
        set -g fish_color_gray ${fishColor cfg.palette.overlay0} --theme=${fishThemeName}
        set -g fish_color_selection --background=${fishColor cfg.palette.surface0} --theme=${fishThemeName}
        set -g fish_color_search_match --background=${fishColor cfg.palette.surface0} --theme=${fishThemeName}
        set -g fish_color_option ${fishColor cfg.palette.green} --theme=${fishThemeName}
        set -g fish_color_operator ${fishColor cfg.palette.pink} --theme=${fishThemeName}
        set -g fish_color_escape ${fishColor cfg.palette.maroon} --theme=${fishThemeName}
        set -g fish_color_autosuggestion ${fishColor cfg.palette.overlay0} --theme=${fishThemeName}
        set -g fish_color_cancel ${fishColor cfg.palette.red} --theme=${fishThemeName}
        set -g fish_color_cwd ${fishColor cfg.palette.yellow} --theme=${fishThemeName}
        set -g fish_color_user ${fishColor cfg.palette.teal} --theme=${fishThemeName}
        set -g fish_color_host ${fishColor cfg.palette.blue} --theme=${fishThemeName}
        set -g fish_color_host_remote ${fishColor cfg.palette.green} --theme=${fishThemeName}
        set -g fish_color_status ${fishColor cfg.palette.red} --theme=${fishThemeName}
        set -g fish_pager_color_progress ${fishColor cfg.palette.overlay0} --theme=${fishThemeName}
        set -g fish_pager_color_prefix ${fishColor cfg.palette.pink} --theme=${fishThemeName}
        set -g fish_pager_color_completion ${fishColor cfg.palette.text} --theme=${fishThemeName}
        set -g fish_pager_color_description ${fishColor cfg.palette.overlay0} --theme=${fishThemeName}
      '';
    })

    (mkIf config.programs.lazygit.enable {
      home.sessionVariables.LG_CONFIG_FILE = mkForce "${config.xdg.configHome}/lazygit/config.yml";

      programs.lazygit.settings.gui = {
        authorColors."*" = cfg.palette.lavender;
        theme = {
          activeBorderColor = [
            accent
            "bold"
          ];
          inactiveBorderColor = [ cfg.palette.subtext0 ];
          searchingActiveBorderColor = [
            cfg.palette.yellow
            "bold"
          ];
          optionsTextColor = [ cfg.palette.blue ];
          selectedLineBgColor = [ cfg.palette.surface0 ];
          inactiveViewSelectedLineBgColor = [ cfg.palette.overlay0 ];
          cherryPickedCommitFgColor = [ accent ];
          cherryPickedCommitBgColor = [ cfg.palette.surface1 ];
          markedBaseCommitFgColor = [ cfg.palette.blue ];
          markedBaseCommitBgColor = [ cfg.palette.yellow ];
          unstagedChangesColor = [ cfg.palette.red ];
          defaultFgColor = [ cfg.palette.text ];
        };
      };
    })

    (mkIf config.programs.yazi.enable {
      xdg.configFile."yazi/flavors/${yaziFlavorName}.yazi/flavor.toml".source =
        mkForce yaziTransparentFlavor;
    })

    (mkIf config.programs.noctalia.enable {
      programs.noctalia = {
        customPalettes.nixporn = mkForce {
          dark = noctaliaPalette;
          light = noctaliaPalette;
        };

        settings.theme = {
          source = mkForce "custom";
          custom_palette = mkForce "nixporn";
          mode = mkForce cfg.polarity;
        };
      };
    })

    (mkIf guiLinux {
      nixporn = {
        avatar = lib.mkDefault osConfig.nixporn.avatar;
        wallpaper = lib.mkDefault inputs.wallpapers.catppuccin.anime-japan.path;
      };
      home.pointerCursor = {
        size = 24;
        gtk.enable = true;
        x11.enable = true;
      };
    })
  ]);
}
