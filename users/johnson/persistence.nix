{ config, lib, ... }:
let
  inherit (config.home-manager.users.johnson) my;
  inherit (lib.modules) mkIf mkMerge;
in
{
  dot.users.johnson.persistence = {
    directories = mkMerge [
      (mkIf config.dot.gui._1password.enable [
        ".1password"
      ])
      (mkIf my.gui.apps.anki.enable [
        ".cache/Anki"
        ".local/share/Anki2"
      ])
      (mkIf my.gui.apps.discord.enable [
        # keep-sorted start
        ".config/Discord"
        ".config/discord"
        ".config/vencord"
        ".config/vesktop"
        # keep-sorted end
      ])
      (mkIf my.gui.apps."cloudflare-warp".enable [
        ".local/share/warp"
      ])
      (mkIf my.gui.apps.firefox.enable [
        ".cache/mozilla/firefox"
        ".mozilla/firefox"
      ])
      (mkIf my.gui.apps.chrome.enable [
        ".cache/google-chrome"
        ".config/google-chrome"
        ".cache/chromium"
        ".config/chromium"
        ".local/share/pki"
      ])
      (mkIf my.gui.apps.obs.enable [
        ".config/obs-studio"
      ])
      (mkIf my.gui.apps.spotify.enable [
        ".cache/spotify"
        ".config/spotify"
      ])
      (mkIf my.gui.apps.spotify.spotify-player.enable [
        ".cache/spotify-player"
      ])
      (mkIf my.gui.apps.wezterm.enable [
        ".cache/wezterm"
        ".local/share/wezterm"
      ])
      (mkIf my.gui.apps.zen.enable [
        ".cache/zen"
        ".config/zen"
      ])
      (mkIf my.gui.apps.vlc.enable [
        ".config/vlc"
      ])
      (mkIf my.gui.apps.zed.enable [
        ".config/zed"
        ".local/share/zed"
      ])
      (mkIf my.atuin.enable [
        ".local/share/atuin"
      ])
      (mkIf my.aerc.enable [
        ".cache/aerc"
        ".local/share/aerc"
      ])
      (mkIf my.bat.enable [
        ".cache/bat"
      ])
      (mkIf my.claude-code.enable [
        ".claude"
      ])
      (mkIf my.langs.enable [
        "go"
      ])
      (mkIf my.langs.node.enable [
        ".npm"
      ])
      (mkIf my.langs.python.enable [
        ".cache/uv"
        ".local/pipx"
        ".local/share/uv"
      ])
      (mkIf my.langs.rust.enable [
        ".cargo"
      ])
      (mkIf my.codex.enable [
        ".codex"
      ])
      (mkIf my.direnv.enable [
        ".local/share/direnv/allow"
      ])
      (mkIf my.fastfetch.enable [
        ".cache/fastfetch"
      ])
      (mkIf my."antigravity-cli".enable [
        ".gemini"
      ])
      (mkIf my.gh.enable [
        ".config/gh"
      ])
      (mkIf my.lazygit.enable [
        ".local/state/lazygit"
      ])
      (mkIf my.navi.enable [
        ".local/share/navi"
      ])
      (mkIf my.opencode.enable [
        ".config/opencode"
      ])
      (mkIf my.pet.enable [
        ".config/pet"
      ])
      (mkIf my.security.gpg.enable [
        {
          directory = ".gnupg";
          mode = "0700";
        }
      ])
      (mkIf my.tealdeer.enable [
        ".cache/tealdeer"
      ])
      (mkIf my.tmux.enable [
        ".tmux"
        ".local/share/tmux"
      ])
      (mkIf my.yazi.enable [
        ".local/state/yazi"
      ])
      (mkIf my.zellij.enable [
        ".cache/zellij"
        ".local/share/zellij"
      ])
      (mkIf my.zoxide.enable [
        ".local/share/zoxide"
      ])
    ];

    files = mkIf my.claude-code.enable [
      ".claude.json"
    ];
  };
}
