{
  lib,
  config,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.my.keyboard;
  userHome = config.users.users.${config.my.name}.home;
in
{
  config = mkIf (cfg.type == "karabiner") {
    environment.systemPackages = [ cfg.karabiner.package ];

    # Link karabiner config into the expected location at activation time.
    # Karabiner-Elements reads from ~/.config/karabiner/karabiner.json.
    # system.activationScripts runs as root, so we use the explicit user home path.
    system.activationScripts.karabiner-config.text = ''
      karabiner_dir="${userHome}/.config/karabiner"
      mkdir -p "$karabiner_dir"
      ln -sf "${cfg.karabiner.configFile}" "$karabiner_dir/karabiner.json"
    '';
  };
}
