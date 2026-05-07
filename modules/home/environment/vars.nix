{
  osConfig,
  ...
}:
{
  home.sessionVariables = {
    SYSTEMD_PAGERSECURE = "true";
    FLAKE = osConfig.dot.flakePath;
    DO_NOT_TRACK = 1;
  };
}
