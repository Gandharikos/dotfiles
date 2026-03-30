{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (builtins) concatStringsSep;
  themeCfg = config.my.theme.catppuccin;
  enable = themeCfg.enable && config.my.starship.enable;
  greenModule = format: {
    style = "bg:green";
    inherit format;
  };
  sapphireModule = format: {
    style = "bg:sapphire";
    inherit format;
  };
in
{
  config = mkIf enable {
    programs.starship.settings = {
      add_newline = false;
      format = concatStringsSep "" [
        "[](red)"
        "$os"
        "$username"
        "[](bg:peach fg:red)"
        "$directory"
        "[](bg:yellow fg:peach)"
        "$git_branch"
        "$git_status"
        "[](fg:yellow bg:green)"
        "$c"
        "$rust"
        "$golang"
        "$nodejs"
        "$php"
        "$java"
        "$kotlin"
        "$haskell"
        "$python"
        "$nix_shell"
        "$direnv"
        "[](fg:green bg:sapphire)"
        "$conda"
        "$container"
        "$docker_context"
        "[](fg:sapphire bg:lavender)"
        "$time"
        "[ ](fg:lavender)"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];
      palette = "catppuccin_${themeCfg.flavor}";
      os = {
        disabled = false;
        style = "bg:red fg:crust";
        format = "[ $symbol ]($style)";
      };
      username = {
        show_always = true;
        style_user = "bg:red fg:crust";
        style_root = "bg:red fg:crust";
        format = "[ $user]($style)";
      };
      directory = {
        style = "bg:peach fg:crust";
        format = "[ $path ]($style)";
        truncation_length = 3;
        truncation_symbol = "…/";
      };
      git_branch = {
        style = "bg:yellow";
        format = "[[ $symbol $branch ](fg:crust bg:yellow)]($style)";
      };
      git_status = {
        style = "bg:yellow";
        format = "[[($all_status$ahead_behind )](fg:crust bg:yellow)]($style)";
      };
      c = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      rust = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      golang = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      nodejs = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      php = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      java = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      kotlin = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      haskell = greenModule "[[ $symbol( $version) ](fg:crust bg:green)]($style)";
      python = greenModule "[[ $symbol( $version)(\\(#$virtualenv\\)) ](fg:crust bg:green)]($style)";
      nix_shell = greenModule "[[ $symbol( $name) ](fg:crust bg:green)]($style)";
      direnv = greenModule "[[ $symbol$loaded/$allowed ](fg:crust bg:green)]($style)";
      conda = {
        symbol = "  ";
        style = "fg:crust bg:sapphire";
        format = "[$symbol$environment ]($style)";
        ignore_base = false;
      };
      container = sapphireModule "[[ $symbol\\[$name\\] ](fg:crust bg:sapphire)]($style)";
      docker_context = {
        symbol = "";
      }
      // sapphireModule "[[ $symbol( $context) ](fg:crust bg:sapphire)]($style)";
      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:lavender";
        format = "[[  $time ](fg:crust bg:lavender)]($style)";
      };
      line_break.disabled = false;
      character = {
        disabled = false;
        success_symbol = "[❯](bold fg:green)";
        error_symbol = "[❯](bold fg:red)";
        vicmd_symbol = "[❮](bold fg:green)";
        vimcmd_replace_one_symbol = "[❮](bold fg:lavender)";
        vimcmd_replace_symbol = "[❮](bold fg:lavender)";
        vimcmd_visual_symbol = "[❮](bold fg:yellow)";
      };
      cmd_duration = {
        show_milliseconds = true;
        format = " in $duration ";
        style = "bg:lavender";
        disabled = false;
        show_notifications = true;
        min_time_to_notify = 45000;
      };
    };
  };
}
