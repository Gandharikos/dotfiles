{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  inherit (lib.my) rgba;
  inherit (config.my.theme.colorscheme) palette;
  cfg = config.my.theme.tokyonight;
in
{
  config = mkIf cfg.enable {
    # TODO: complete this
    programs.wlogout.style = with palette; ''
      * {
        background-image: none;
        box-shadow: none;
        font-family: "SFProDisplay Nerd Font", sans-serif;
        transition: 20ms;
      }

      window {
        background-color: ${rgba bg 0.5};
      }

      button {
        background-color: ${rgba bg_highlight 0.8};
        background-position: center;
        background-repeat: no-repeat;
        background-size: 25%;
        border-color: ${rgba border_highlight 0.8};
        border-radius: 10;
        border-style: solid;
        border-width: 2;
        color: ${rgba magenta2 0.8};
        margin: 5px;
        text-decoration-color: ${rgba blue 0.8};
      }

      button:active, button:hover {
        background-color: ${rgba bg_visual 0.8};
        outline-style: none;
      }

      #lock {
        background-image: image(url("${config.programs.wlogout.package}/share/wlogout/icons/lock.png"), url("/usr/local/share/wlogout/icons/lock.png"));
      }

      #logout {
        background-image: image(url("${config.programs.wlogout.package}/share/wlogout/icons/logout.png"), url("/usr/local/share/wlogout/icons/logout.png"));
      }

      #suspend {
        background-image: image(url("${config.programs.wlogout.package}/share/wlogout/icons/suspend.png"), url("/usr/local/share/wlogout/icons/suspend.png"));
      }

      #hibernate {
        background-image: image(url("${config.programs.wlogout.package}/share/wlogout/icons/hibernate.png"), url("/usr/local/share/wlogout/icons/hibernate.png"));
      }

      #shutdown {
        background-image: image(url("${config.programs.wlogout.package}/share/wlogout/icons/shutdown.png"), url("/usr/local/share/wlogout/icons/shutdown.png"));
      }

      #reboot {
        background-image: image(url("${config.programs.wlogout.package}/share/wlogout/icons/reboot.png"), url("/usr/local/share/wlogout/icons/reboot.png"));
      }

    '';
  };
}
