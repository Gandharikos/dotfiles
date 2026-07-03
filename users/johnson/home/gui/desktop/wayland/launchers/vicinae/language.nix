{
  config,
  osConfig,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.meta) getExe getExe';
  inherit (lib.modules) mkIf;
  inherit (config.my.gui) desktop;

  enable = osConfig.dot.gui.desktop.wayland.enable && desktop.launcher.default == "vicinae";
  trans = getExe pkgs.translate-shell;
  wlCopy = getExe' pkgs.wl-clipboard-rs "wl-copy";
  wlPaste = getExe' pkgs.wl-clipboard-rs "wl-paste";
in
{
  config = mkIf enable {
    xdg.dataFile = {
      "vicinae/scripts/translate-input.sh" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          # @vicinae.schemaVersion 1
          # @vicinae.title Translate Input
          # @vicinae.mode fullOutput
          # @vicinae.packageName Language
          # @vicinae.argument1 { "type": "text", "placeholder": "text" }
          # @vicinae.argument2 { "type": "text", "placeholder": "target language, default zh-CN", "optional": true }

          set -euo pipefail

          text="$1"
          target="''${2:-zh-CN}"

          if [ -z "$text" ]; then
            echo "No text provided" >&2
            exit 1
          fi

          ${trans} -brief ":$target" "$text"
        '';
      };

      "vicinae/scripts/translate-clipboard.sh" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          # @vicinae.schemaVersion 1
          # @vicinae.title Translate Clipboard
          # @vicinae.mode fullOutput
          # @vicinae.packageName Language
          # @vicinae.argument1 { "type": "text", "placeholder": "target language, default zh-CN", "optional": true }

          set -euo pipefail

          target="''${1:-zh-CN}"
          text="$(${wlPaste} --no-newline || true)"

          if [ -z "$text" ]; then
            echo "Clipboard is empty" >&2
            exit 1
          fi

          ${trans} -brief ":$target" "$text"
        '';
      };

      "vicinae/scripts/explain-language.sh" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          # @vicinae.schemaVersion 1
          # @vicinae.title Explain With AI
          # @vicinae.mode fullOutput
          # @vicinae.packageName Language
          # @vicinae.argument1 { "type": "text", "placeholder": "word, phrase, or sentence" }

          set -euo pipefail

          text="$1"
          codex_bin="$(command -v codex || true)"

          if [ -z "$text" ]; then
            echo "No text provided" >&2
            exit 1
          fi

          if [ -z "$codex_bin" ]; then
            echo "codex not found in PATH" >&2
            exit 1
          fi

          prompt="$(cat <<EOF
          You are a concise language-learning assistant for a Chinese speaker.
          Explain the text below with:
          - a Chinese translation
          - key words or phrases
          - grammar, nuance, or usage notes
          - one or two natural examples if helpful

          Text:
          $text
          EOF
          )"

          "$codex_bin" exec \
            --profile quick \
            --sandbox read-only \
            --skip-git-repo-check \
            --ephemeral \
            --ignore-rules \
            --cd "$HOME" \
            "$prompt"
        '';
      };

      "vicinae/scripts/anki-card-draft.sh" = {
        executable = true;
        text = ''
          #!${pkgs.runtimeShell}
          # @vicinae.schemaVersion 1
          # @vicinae.title Draft Anki Card
          # @vicinae.mode silent
          # @vicinae.packageName Language
          # @vicinae.argument1 { "type": "text", "placeholder": "front" }
          # @vicinae.argument2 { "type": "text", "placeholder": "example or context", "optional": true }

          set -euo pipefail

          front="$1"
          context="''${2:-}"

          if [ -z "$front" ]; then
            echo "No front text provided" >&2
            exit 1
          fi

          back="$(${trans} -brief :zh-CN "$front" 2>/dev/null | sed -n '1,8p' || true)"
          if [ -z "$back" ]; then
            back="Add definition"
          fi

          {
            printf 'Front:\n%s\n\n' "$front"
            printf 'Back:\n%s\n\n' "$back"

            if [ -n "$context" ]; then
              printf 'Context:\n%s\n\n' "$context"
            fi

            printf 'Tags:\nlanguage vicinae\n'
          } | ${wlCopy}

          echo "Anki card draft copied to clipboard"
        '';
      };
    };
  };
}
