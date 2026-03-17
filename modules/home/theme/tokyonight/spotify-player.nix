{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme.colorscheme) palette slug;
  cfg = config.my.theme.tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.spotify-player = {
      settings.theme = slug;
      themes = [
        {
          name = slug;
          palette = with palette; {
            background = bg;
            foreground = fg;
            inherit
              black
              red
              green
              yellow
              blue
              magenta
              cyan
              white
              bright_black
              bright_red
              bright_green
              bright_yellow
              bright_blue
              bright_magenta
              bright_cyan
              bright_white
              ;
          };
          component_style = {
            block_title = {
              fg = "BrightGreen";
              modifiers = [
                "Italic"
                "Bold"
              ];
            };
            like = {
              fg = "Red";
              modifiers = [ "Bold" ];
            };
            playback_track = {
              fg = "BrightMagenta";
              modifiers = [ "Italic" ];
            };
            playback_album = {
              fg = "BrightRed";
              modifiers = [ "Italic" ];
            };
            playback_artists = {
              fg = "BrightCyan";
              modifiers = [ ];
            };
            playback_metadata = {
              fg = "BrightBlue";
              modifiers = [ ];
            };
            playback_progress_bar = {
              fg = "BrightGreen";
              modifiers = [ "Italic" ];
            };
            current_playing = {
              fg = "Red";
              modifiers = [
                "Bold"
                "Italic"
              ];
            };
            playlist_desc = {
              fg = "White";
              modifiers = [ "Italic" ];
            };
            page_desc = {
              fg = "Magenta";
              modifiers = [
                "Bold"
                "Italic"
              ];
            };
            table_header = {
              fg = "Blue";
              modifiers = [ "Bold" ];
            };
            border = {
              fg = "BrightYellow";
            };
            selection = {
              fg = "Red";
              modifiers = [
                "Bold"
                "Reversed"
              ];
            };
            secondary_row = {
              bg = "BrightBlack";
            };
          };
        }
      ];
    };
  };
}
