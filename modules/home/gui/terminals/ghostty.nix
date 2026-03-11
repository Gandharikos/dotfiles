{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.modules) mkIf;
  inherit (lib.types) str bool;
  inherit (pkgs.stdenv.hostPlatform) isLinux;
  inherit (config.my) gui;
  inherit (config.my.gui) terminal;
  cfg = config.my.gui.apps.ghostty;
  enable = gui.enable && cfg.enable;
  ghostty-shaders = pkgs.stdenv.mkDerivation {
    name = "ghostty-shaders";
    src = pkgs.fetchFromGitHub {
      owner = "0xhckr";
      repo = "ghostty-shaders";
      rev = "aa6121ba2ddd5251ac75b92729c758fe41256e55";
      hash = "sha256-2AeIjV59d/a+JdEbcPT1dLfUVdegRYIyFLI55daZ0LI=";
    };
    installPhase = ''
      mkdir -p $out
      mv *.glsl $out
    '';
  };
in {
  options.my.gui.apps.ghostty = {
    enable =
      mkEnableOption "ghostty"
      // {
        default = terminal.default == "ghostty";
      };

    enableShader = mkOption {
      type = bool;
      default = true;
      description = "Enable custom shader for ghostty terminal";
    };

    shader = mkOption {
      type = str;
      default = "cursor_blaze.glsl";
      description = "Shader file to use from ~/.config/ghostty/shaders";
      example = "underwater.glsl";
    };
  };

  config = mkIf enable {
    xdg.configFile."ghostty/shaders".source = ghostty-shaders;

    programs.ghostty = with config.my.keyboard.keys; {
      enable = true;
      # NOTE: It's broken on macOS, so you should to install it by brew.
      # See: https://github.com/NixOS/nixpkgs/issues/388984
      package =
        if isLinux
        then pkgs.ghostty
        else null;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableBashIntegration = true;
      settings = {
        # font-family = terminal.font;
        # font-family-bold = terminal.font;
        # font-family-italic = terminal.font-italic;
        # font-family-bold-italic = terminal.font-italic;
        font-family = terminal.font;
        font-size = terminal.size;

        adjust-underline-position = 4;
        # Mouse
        mouse-hide-while-typing = true;
        # Theme
        cursor-invert-fg-bg = true;
        background-opacity = terminal.opacity;
        background-blur = true;
        window-theme = "ghostty";
        # window
        gtk-single-instance = true;
        gtk-tabs-location = "bottom";
        gtk-wide-tabs = false;
        # gtk-toolbar-style = "flat";
        window-padding-x = terminal.padding;
        window-padding-y = terminal.padding;
        window-padding-balance = true;
        window-decoration = false;
        # macos
        macos-titlebar-style = "hidden";
        macos-option-as-alt = "left";
        macos-window-shadow = true;
        # shader
        custom-shader = mkIf cfg.enableShader "shaders/${cfg.shader}";
        custom-shader-animation = cfg.enableShader;
        # other
        copy-on-select = "clipboard";
        # shell-integration-features = "cursor,sudo,no-title,ssh-env";
        quit-after-last-window-closed = true;
        confirm-close-surface = false;
        app-notifications = "no-clipboard-copy";
        # keybinds
        keybind = [
          "clear"
          "ctrl+shift+${h}=goto_split:left"
          "ctrl+shift+${j}=goto_split:bottom"
          "ctrl+shift+${k}=goto_split:top"
          "ctrl+shift+${l}=goto_split:right"
          "ctrl+shift+t=new_tab"
          "ctrl+shift+left_bracket=previous_tab"
          "ctrl+shift+right_bracket=next_tab"
          "ctrl+shift+comma=move_tab:-1"
          "ctrl+shift+period=move_tab:1"
          "ctrl+shift+equal=increase_font_size:1"
          "ctrl+shift+minus=decrease_font_size:1"
          "ctrl+shift+kp_0=reset_font_size"
          "ctrl+shift+c=copy_to_clipboard"
          "ctrl+shift+v=paste_from_clipboard"
          "ctrl+shift+enter=new_split:auto"
          "ctrl+shift+x=inspector:toggle"
          "ctrl+shift+m=toggle_split_zoom"
          "ctrl+shift+r=reload_config"
          "ctrl+shift+s=write_screen_file:open"
          "ctrl+shift+w=close_surface"
        ];
      };
    };
  };
}
