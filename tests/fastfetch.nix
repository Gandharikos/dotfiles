# Evaluation only: no shell startup commands are executed.
let
  flake = builtins.getFlake ("git+file://" + toString ../.);
  lib = flake.inputs.nixpkgs.lib;
  check =
    enabled: startup:
    let
      host = flake.darwinConfigurations.eir.extendModules {
        modules = [
          {
            home-manager.users.johnson.my = {
              bash.enable = true;
              zsh.enable = true;
              fish.enable = true;
              nushell.enable = true;
              fastfetch = {
                enable = lib.mkForce enabled;
              }
              // lib.optionalAttrs (startup != null) { startOnLogin = startup; };
            };
          }
        ];
      };
      home = host.config.home-manager.users.johnson;
      shouldRun = enabled && (if startup == null then enabled else startup);
      greetings = {
        bash = lib.hasInfix "fastfetch --logo-type builtin --logo macos" home.programs.bash.initExtra;
        zsh = lib.hasInfix "fastfetch --logo-type builtin --logo macos" home.programs.zsh.initContent;
        fish = lib.hasInfix "fastfetch --logo-type builtin --logo macos" (
          home.programs.fish.functions.fish_greeting.body or ""
        );
        nushell = lib.hasInfix "fastfetch --logo-type builtin --logo macos" home.programs.nushell.extraConfig;
      };
    in
    assert home.programs.fastfetch.enable == enabled;
    assert enabled -> home.programs.fastfetch.settings.logo.width == 36;
    assert enabled -> home.programs.fastfetch.settings.logo.height == 18;
    assert home.my.fastfetch.startOnLogin == (if startup == null then enabled else startup);
    assert builtins.all (present: present == shouldRun) (builtins.attrValues greetings);
    true;
in
{
  enabledByDefault = check true null;
  explicitOptOut = check true false;
  disabled = check false null;
  disabledWithStartup = check false true;
}
