{
  config,
  lib,
  ...
}:
let
  inherit (lib.strings) optionalString;
in
{
  programs.less = {
    enable = true;

    config = ''
      #command
      # scroll a page down
      # Spacebar (40 in octal)
      \40         forw-screen-force

      #env
      # LESS=--RAW-CONTROL-CHARS --mouse -C --tilde --tabs=2 -W --status-column -i
      # LESSHISTFILE=-
      # LESSCOLORIZER=bat
    ''
    + optionalString (config.my.keyboard.layout == "colemak") ''
      #command
      n left-scroll
      o right-scroll
      i back-line
      I back-line-force
      ^I back-line
      E forw-line-force
      k repeat-search
      \ek repeat-search-all
      K reverse-search
      \eK reverse-search-all
      c clear-search
    '';
  };

  programs.lesspipe.enable = true;
}
