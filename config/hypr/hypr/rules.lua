local M = {}

function M.setup()
  local low_opacity_layers = "^(bar|calendar|notifications|system-menu)$"
  local high_opacity_layers = "^(osd|logout_dialog)$"
  hl.layer_rule({ match = { namespace = low_opacity_layers }, blur = true, ignore_alpha = 0.2 })
  hl.layer_rule({ match = { namespace = high_opacity_layers }, blur = true, ignore_alpha = 0.5 })
  hl.layer_rule({
    name = "noctalia",
    match = { namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$" },
    no_anim = true,
    ignore_alpha = 0.5,
    blur = true,
    blur_popups = true,
  })
  hl.layer_rule({ match = { namespace = "^bar$" }, xray = true })

  hl.window_rule({ match = { title = "^(1Password|Bitwarden)$" }, float = true, center = true })
  hl.window_rule({ match = { class = "^Bitwarden$" }, float = true, center = true })
  hl.window_rule({ match = { title = ".*[Vv]aultwarden.*" }, float = true })
  hl.window_rule({ match = { float = true }, border_size = 0 })
  hl.window_rule({ match = { class = "^(osu!|cs2)$" }, immediate = true })
  hl.window_rule({ match = { title = "^(Spotify( Premium)?)$" }, workspace = "9 silent" })
  hl.window_rule({ match = { title = "^(Picture-in-Picture)$" }, float = true, pin = true })
  hl.window_rule({ match = { class = "^(mpv|.+exe|celluloid)$" }, idle_inhibit = "focus" })
  hl.window_rule({ match = { class = "^firefox$", title = ".*YouTube.*" }, idle_inhibit = "focus" })
  hl.window_rule({ match = { class = "^firefox$" }, idle_inhibit = "fullscreen" })
  hl.window_rule({
    match = { class = "^(gcr-prompter|xdg-desktop-portal-gtk|Soteria|polkit-gnome-authentication-agent-1)$" },
    dim_around = true,
  })
  hl.window_rule({ match = { xwayland = true }, rounding = 0 })
  hl.window_rule({
    match = { class = ".*jetbrains.*", title = "^(Confirm Exit|Open Project|win424|win201|splash)$" },
    center = true,
  })
  hl.window_rule({ match = { class = ".*jetbrains.*", title = "^splash$" }, size = { 640, 400 } })
  hl.window_rule({ match = { class = "^(kitty|Alacritty|wezterm)$" }, opacity = "0.85 0.85" })
  hl.window_rule({ match = { class = "^Spotify$" }, opacity = "0.70 0.70" })
end

return M
