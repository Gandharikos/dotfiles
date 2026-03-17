{
  lib,
  config,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) str nullOr package submodule int;
in {
  options.my.theme.cursor = mkOption {
    description = ''
      Attributes defining the systemwide XCursor theme, with an optional
      Hyprcursor theme for Hyprland.
    '';
    type = nullOr (
      submodule {
        options = {
          name = mkOption {
            description = "The cursor name within the package.";
            type = nullOr str;
            default = null;
          };
          package = mkOption {
            description = "Package providing the cursor theme.";
            type = nullOr package;
            default = null;
          };
          size = lib.mkOption {
            description = "The cursor size.";
            type = nullOr int;
            default = null;
          };
          hyprcursor = mkOption {
            description = "Optional Hyprcursor theme for Hyprland sessions.";
            type = nullOr (
              submodule {
                options = {
                  name = mkOption {
                    description = "The Hyprcursor theme name within the package.";
                    type = nullOr str;
                    default = null;
                  };
                  package = mkOption {
                    description = "Package providing the Hyprcursor theme.";
                    type = nullOr package;
                    default = null;
                  };
                };
              }
            );
            default = null;
          };
        };
      }
    );
    default = null;
  };
  config.assertions = let
    inherit (config.my.theme) cursor;
  in [
    {
      assertion =
        cursor
        == null
        || (
          cursor.name
          != null
          && cursor.package != null
          && cursor.size != null
          && (
            cursor.hyprcursor
            == null
            || cursor.hyprcursor.name != null && cursor.hyprcursor.package != null
          )
        );
      message = ''
        Error: `my.theme.cursor` is only partially defined. Set either none or
        all of the base `my.theme.cursor` options, plus a complete optional
        `my.theme.cursor.hyprcursor` theme if you enable one.
      '';
    }
  ];
}
