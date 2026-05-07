{
  osConfig,
  ...
}:
{
  home.sessionVariables = {
    SYSTEMD_PAGERSECURE = "true";
    FLAKE = osConfig.my.flakePath;
    DO_NOT_TRACK = 1;
  };
}
