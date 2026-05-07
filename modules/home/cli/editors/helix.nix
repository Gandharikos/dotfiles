{
  config,
  osConfig,
  lib,
  ...
}:
let
  inherit (lib.options) mkEnableOption;
  inherit (lib.modules) mkIf;
  cfg = config.my.helix;
in
{
  options.my.helix = {
    enable = mkEnableOption "helix" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    programs.helix = {
      enable = true;
      settings = {
        editor = {
          line-number = "relative";
          mouse = true;
          cursorline = true;
          bufferline = "multiple";
          auto-pairs = true;
          whitespace = {
            render = {
              space = "all";
              tab = "all";
              newline = "none";
            };
            characters = {
              space = "·";
              nbsp = "⍽";
              tab = "→";
              newline = "⏎";
              tabpad = "·"; # Tabs will look like "→···" (depending on tab width)
            };
          };
          indent-guides = {
            render = true;
            character = "╎"; # Some characters that work well: "▏", "┆", "┊", "⸽"
            skip-levels = 1;
          };
          cursor-shape = {
            insert = "bar";
            normal = "block";
            select = "underline";
          };
          file-picker = {
            hidden = false;
          };
        };
        keys = mkIf (osConfig.dot.keyboard.layout == "colemak") {
          normal = {
            # motion
            n = "move_char_left";
            e = "move_visual_line_down";
            i = "move_visual_line_up";
            o = "move_char_right";
            j = "move_next_word_end";
            J = "move_next_long_word_end";
            "C-h" = "jump_forward";
            "C-l" = "jump_backward";

            # changes
            h = "insert_mode";
            H = "insert_at_line_start";
            l = "open_below";
            L = "open_above";
            E = "join_selections";
            "A-E" = "join_selections_space";
            I = "keep_selections";
            "A-I" = "remove_selections";
            # search
            k = "search_next";
            K = "search_prev";
          };
        };
      };
    };
  };
}
