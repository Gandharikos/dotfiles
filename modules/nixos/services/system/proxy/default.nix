{
  lib,
  config,
  ...
}:
# let
# inherit (lib.my) scanPaths;
# in
{
  # imports = scanPaths ./.;

  options.my.services.proxy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.time.timeZone == "Asia/Shanghai";
      description = "Enable the proxy service. Defaults to true if timezone is Asia/Shanghai.";
    };
  };
}
