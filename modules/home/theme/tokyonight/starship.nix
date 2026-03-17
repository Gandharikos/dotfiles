{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (config.my.theme.general) pad;
  inherit (config.my.theme) tokyonight colorscheme;
  inherit (colorscheme) palette slug;
  cfg = tokyonight;
in
{
  config = mkIf cfg.enable {
    programs.starship.settings =
      let
        pad_style = "fg:gray";
        left_pad = "[${pad.left}](${pad_style})";
        right_pad = "[${pad.right} ](${pad_style})";
        inherit (builtins) concatStringsSep;
      in
      {
        palette = slug;
        palettes.${slug} = with palette; {
          inherit
            bg
            fg
            red
            green
            yellow
            blue
            magenta
            cyan
            white
            ;
          gray = bg_highlight;
        };
        username = {
          style_user = "bold blue";
          style_root = "bold red";
        };
        hostname = {
          style = "bold blue";
        };
        git_branch = {
          format = concatStringsSep "" [
            left_pad
            "[$symbol $branch ]($style)(:$remote_branch)"
          ];
          style = "bg:gray fg:green";
        };
        git_status = {
          format = concatStringsSep "" [
            "[$all_status$ahead_behind]($style)"
            right_pad
          ];
          style = "bg:gray fg:red";
        };
        directory = {
          format = concatStringsSep "" [
            left_pad
            "[$read_only]($read_only_style)"
            "[$path]($style)"
            right_pad
          ];
          style = "bg:gray fg:fg";
          read_only_style = "bg:gray fg:red";
        };
        nix_shell = {
          style = "fg:bold blue bg:gray";
          format = concatStringsSep "" [
            left_pad
            "[$symbol(\($name\))]($style)"
            right_pad
          ];
        };
        direnv = {
          style = "fg:bold yellow bg:gray";
          format = concatStringsSep "" [
            left_pad
            "[$symbol$loaded/$allowed]($style)"
            right_pad
          ];
        };
        conda = {
          style = "fg:bold blue bg:gray";
          format = concatStringsSep "" [
            right_pad
            "[$symbol$environment ]($style)"
            right_pad
          ];
        };
        container = {
          style = "fg:bold red dimmed bg:gray";
          format = concatStringsSep "" [
            left_pad
            "[$symbol \[$name\]]($style)"
            right_pad
          ];
        };
        cmd_duration = {
          format = "[$duration ](fg:yellow)";
        };
        status = {
          format = "[$symbol]($style)";
          success_style = "bold green";
        };
      };
  };
}
