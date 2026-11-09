{
  config,
  lib,
  pkgs,
  ...
}:
let
  shellAliases = {
    "fetch" = "fastfetch";
  };
  inherit (config.programs) kitty ghostty rex;
  supportsKittyGraphics = kitty.enable || ghostty.enable || rex.enable;
  cfg = config.my.fastfetch;
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  logoDirectory = lib.dot.relativeToConfig (
    if pkgs.stdenv.hostPlatform.isDarwin then "fastfetch/apple_pngs" else "fastfetch/pngs"
  );
  fallbackLogo = if pkgs.stdenv.hostPlatform.isDarwin then "macos" else "nixos";
  logos = pkgs.runCommand "fastfetch-logos" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    mkdir -p "$out"
    for image in "${logoDirectory}"/*.png; do
      magick "$image" -auto-orient -resize 512x512 \
        -background none -gravity center -extent 512x512 -strip \
        "PNG32:$out/$(basename "$image")"
    done
  '';
  fetchGreeting = ''
    case $- in
      *i*)
        if [ -n "$TMUX" ] || [ -n "$ZELLIJ" ] || [ -n "$ZELLIJ_SESSION_NAME" ]; then
          fastfetch --logo-type builtin --logo ${fallbackLogo}
        else
          fastfetch
        fi
        ;;
    esac
  '';
  fishGreeting = ''
    if status is-interactive
      if test -n "$TMUX"; or test -n "$ZELLIJ"; or test -n "$ZELLIJ_SESSION_NAME"
        fastfetch --logo-type builtin --logo ${fallbackLogo}
      else
        fastfetch
      end
    end
  '';
  nushellGreeting = ''
    if $nu.is-interactive {
      if (not (($env.TMUX? | default "") | is-empty)) or (not (($env.ZELLIJ? | default "") | is-empty)) or (not (($env.ZELLIJ_SESSION_NAME? | default "") | is-empty)) {
        fastfetch --logo-type builtin --logo ${fallbackLogo}
      } else {
        fastfetch
      }
    }
  '';
in
{
  options.my.fastfetch = {
    enable = mkEnableOption "fastfetch";
    startOnLogin = mkEnableOption "Fastfetch at interactive shell startup" // {
      default = cfg.enable;
      defaultText = lib.literalExpression "config.my.fastfetch.enable";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      nushell.extraConfig = mkIf cfg.startOnLogin nushellGreeting;
      fish.functions.fish_greeting = mkIf cfg.startOnLogin {
        body = fishGreeting;
      };
      zsh.initContent = mkIf cfg.startOnLogin fetchGreeting;
      bash.initExtra = mkIf cfg.startOnLogin fetchGreeting;
      fastfetch = {
        enable = true;
        settings = {
          "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
          general = {
            detectVersion = false;
          };
          logo = {
            type = if supportsKittyGraphics then "kitty-direct" else "chafa";
            # Both dimensions avoid cursor-position queries during shell startup.
            width = 36;
            height = 18;
            printRemaining = false;
            source = "$(find $HOME/.config/fastfetch/pngs/ -name '*.png' | sort -R | head -n 1)";
            chafa = mkIf (!supportsKittyGraphics) {
              symbols = "vhalf";
            };
            padding = {
              top = 1;
              left = 2;
              right = 2;
              bottom = 0;
            };
          };
          display = {
            separator = " : ";
            # keyWidth = 15;
          };
          modules = [
            {
              type = "custom";
              format = " 󰊠  コンピューター";
            }
            {
              type = "custom";
              format = "┌──────────────────────────────────────────┐";
            }
            {
              type = "os";
              key = "   OS";
              keyColor = "red";
            }
            {
              type = "kernel";
              key = "   Kernel";
              keyColor = "red";
            }
            {
              type = "display";
              key = "  󰍹 Display";
              keyColor = "green";
            }
            {
              type = "wm";
              key = "   WM";
              keyColor = "yellow";
            }
            {
              type = "terminal";
              key = "   Terminal";
              keyColor = "yellow";
            }
            {
              type = "custom";
              format = "└──────────────────────────────────────────┘";
            }
            "break"
            {
              type = "title";
              key = "  ";
            }
            {
              type = "custom";
              format = "┌──────────────────────────────────────────┐";
            }
            {
              type = "cpu";
              format = "{1}";
              key = "  󰍛 CPU";
              keyColor = "blue";
            }
            {
              type = "gpu";
              format = "{2}";
              key = "   GPU";
              keyColor = "blue";
            }
            {
              type = "gpu";
              format = "{3}";
              key = "   GPU Driver";
              keyColor = "magenta";
            }
            {
              type = "memory";
              key = "   Memory";
              keyColor = "magenta";
            }
            {
              type = "command";
              key = "  󱦟 OS Age ";
              keyColor = "31";
              text = "birth_install=$(stat -c %W /); current=$(date +%s); time_progression=$((current - birth_install)); days_difference=$((time_progression / 86400)); echo $days_difference days";
            }
            {
              type = "uptime";
              key = "  󱫐 Uptime ";
              keyColor = "red";
            }
            {
              type = "custom";
              format = "└──────────────────────────────────────────┘";
            }
            {
              type = "colors";
              paddingLeft = 2;
              symbol = "circle";
            }
            "break"
          ];
        };
      };
    };

    home = {
      inherit shellAliases;
    };

    xdg.configFile."fastfetch/pngs".source = logos;
  };
}
