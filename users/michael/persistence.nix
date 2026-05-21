{ config, lib, ... }:
let
  inherit (config.home-manager.users.johnson) my;
  inherit (lib.modules) mkIf mkMerge;
in
{
  dot.users.johnson.persistence = {
    directories = mkMerge [
      ".cache/Anki"
      ".local/share/Anki2"
      # keep-sorted start
      ".config/Discord"
      ".config/discord"
      ".config/vencord"
      ".config/vesktop"
      # keep-sorted end
      ".local/share/warp"
      ".cache/mozilla/firefox"
      ".mozilla/firefox"
      ".cache/google-chrome"
      ".config/google-chrome"
      ".cache/chromium"
      ".config/chromium"
      ".local/share/pki"
      ".config/obs-studio"
      ".cache/spotify"
      ".config/spotify"
      ".cache/spotify-player"
      ".cache/wezterm"
      ".local/share/wezterm"
      ".cache/zen"
      ".config/zen"
      ".config/vlc"
      ".local/share/atuin"
      ".cache/aerc"
      ".local/share/aerc"
      ".cache/bat"
      ".claude"
      "go"
      ".npm"
      ".cache/uv"
      ".local/pipx"
      ".local/share/uv"
      ".cargo"
      ".codex"
      ".local/share/direnv/allow"
      ".cache/fastfetch"
      ".gemini"
      ".config/gh"
      ".local/state/lazygit"
      ".local/share/navi"
      ".config/opencode"
      ".config/pet"
      {
        directory = ".gnupg";
        mode = "0700";
      }
      ".cache/tealdeer"
      ".tmux"
      ".local/share/tmux"
      ".local/state/yazi"
      ".cache/zellij"
      ".local/share/zellij"
      ".local/share/zoxide"
    ];

    files = mkIf my.claude-code.enable [
      ".claude.json"
    ];
  };
}
