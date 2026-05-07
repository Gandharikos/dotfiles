{ lib, ... }:
let
  inherit (lib.attrsets) optionalAttrs;
  inherit (lib.filesystem) listFilesRecursive;
  inherit (lib.lists) forEach optionals;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.types)
    attrs
    coercedTo
    deferredModule
    enum
    int
    listOf
    nullOr
    package
    path
    singleLineStr
    str
    submodule
    ;
  cursorType = submodule {
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
      size = mkOption {
        description = "The cursor size.";
        type = nullOr int;
        default = null;
      };
      hyprcursor = mkOption {
        description = "Optional Hyprcursor theme for Hyprland sessions.";
        type = nullOr (submodule {
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
        });
        default = null;
      };
    };
  };
  mkThemeOptions = config: {
    default = mkOption {
      type = nullOr (enum [
        "tokyonight"
        "catppuccin"
      ]);
      default = "tokyonight";
      description = "The theme to use.";
    };
    colorscheme = {
      slug = mkOption {
        type = nullOr str;
        default = null;
        description = "The slug of the colorscheme.";
      };
      name = mkOption {
        type = nullOr str;
        default = null;
        description = "The name of the colorscheme.";
      };
      author = mkOption {
        type = nullOr str;
        default = null;
        description = "The author of the colorscheme.";
      };
      description = mkOption {
        type = nullOr str;
        default = null;
        description = "The description of the colorscheme.";
      };
      palette = mkOption {
        type = nullOr attrs;
        default = null;
        description = "The palette of the colorscheme.";
      };
    };
    avatar = mkOption {
      type = nullOr (coercedTo package toString path);
      default = null;
      description = "The avatar of the user.";
    };
    wallpaper = mkOption {
      type = nullOr (coercedTo package toString path);
      default = null;
      description = "The wallpaper of the user.";
    };
    cursor = mkOption {
      description = ''
        Attributes defining the XCursor theme, with an optional Hyprcursor
        theme for Hyprland.
      '';
      type = nullOr cursorType;
      default = null;
    };
    tokyonight = {
      enable = mkEnableOption "Tokyonight theme" // {
        default = config.default == "tokyonight";
      };
      style = mkOption {
        type = enum [
          "night"
          "storm"
          "day"
          "moon"
        ];
        default = "moon";
        description = "The style of tokyonight.";
      };
    };
    catppuccin = {
      enable = mkEnableOption "Catppuccin theme" // {
        default = config.default == "catppuccin";
      };
      flavor = mkOption {
        type = enum [
          "latte"
          "frappe"
          "macchiato"
          "mocha"
        ];
        default = "mocha";
        description = "The Catppuccin flavor to use.";
      };
      accent = mkOption {
        type = enum [
          "blue"
          "flamingo"
          "green"
          "lavender"
          "maroon"
          "mauve"
          "peach"
          "pink"
          "red"
          "rosewater"
          "sapphire"
          "sky"
          "teal"
          "yellow"
        ];
        default = "mauve";
        description = "The Catppuccin accent color to use.";
      };
    };
    general = {
      transparent = mkEnableOption "Enable transparent theme surfaces" // {
        default = true;
      };
      pad = {
        left = mkOption {
          type = str;
          default = "";
          description = "The left padding of status bar.";
        };
        right = mkOption {
          type = str;
          default = "";
          description = "The right padding of status bar.";
        };
      };
    };
  };
  themeType = submodule (
    { config, ... }:
    {
      options = mkThemeOptions config;
    }
  );
  mkUserOptions =
    {
      isLinux,
      inferName ? true,
      name,
      config,
    }:
    let
      regularKey = "${config.secretsCore}/id_ed25519.pub";
      extraKeysDir = "${config.secretsCore}/keys";
    in
    {
      name = mkOption (
        {
          readOnly = true;
          type = str;
          description = "The user's login name.";
        }
        // optionalAttrs inferName {
          default = name;
        }
      );
      enable = mkEnableOption "dot user ${name}";
      fullName = mkOption {
        type = str;
        default = config.name;
        description = "The user's full name.";
      };
      email = mkOption {
        type = str;
        description = "The user's email address.";
      };
      shell = mkOption {
        type = enum [
          "bash"
          "fish"
          "zsh"
          "nushell"
        ];
        default = "fish";
        description = "The user's login shell.";
      };
      initialHashedPassword = mkOption {
        internal = true;
        type = singleLineStr;
        description = "The user's initial hashed password.";
      };
      home = mkOption {
        internal = true;
        type = str;
        default = if isLinux then "/home/${config.name}" else "/Users/${config.name}";
        description = "The user's home directory.";
      };
      groups = mkOption {
        type = listOf str;
        default = [
          "wheel"
          config.name
          "users"
          "git"
          "networkmanager"
          "docker"
          "wireshark"
          "adbusers"
          "libvirtd"
        ];
        description = "System groups for this user.";
      };
      secretsCore = mkOption {
        type = nullOr path;
        default = null;
        description = "Directory containing this user's core public SSH keys.";
      };
      authorizedKeys = mkOption {
        type = listOf str;
        default =
          optionals (config.secretsCore != null && builtins.pathExists regularKey) [
            (builtins.readFile regularKey)
          ]
          ++ optionals (config.secretsCore != null && builtins.pathExists extraKeysDir) (
            forEach (lib.filter (path: lib.hasSuffix ".pub" (toString path)) (
              listFilesRecursive extraKeysDir
            )) (key: builtins.readFile key)
          );
        description = "SSH public keys authorized for this user.";
      };
      theme = mkThemeOptions config.theme;
      imports = mkOption {
        type = listOf deferredModule;
        default = [ ];
        description = "Home Manager modules imported for this user.";
      };
    };
in
{
  inherit mkThemeOptions mkUserOptions themeType;

  mkUserType =
    {
      isLinux,
      inferName ? true,
    }:
    submodule (
      { name, config, ... }:
      {
        options = mkUserOptions {
          inherit
            config
            inferName
            isLinux
            name
            ;
        };
      }
    );
}
