{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.python;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption;
in
{
  options.my.langs.python = {
    enable = mkEnableOption "Python development environment";
    xdg.enable = mkEnableOption "Python XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = with pkgs; [
        uv
        (python3.withPackages (
          ps: with ps; [
            jupyterlab
            numpy
            pandas
            matplotlib
            scikit-learn
            sympy
            # FIXME: This is a workaround for a bug in the nixpkgs version of
            # plotly
            #line_profiler
            memory-profiler
            psutil
            ipywidgets
            scipy
          ]
        ))
      ];

      home.shellAliases = {
        py = "python";
        py2 = "python2";
        py3 = "python3";
        po = "poetry";
        ipy = "ipython --no-banner";
        ipylab = "ipython --pylab=qt5 --no-banner";
      };
    })

    (mkIf cfg.xdg.enable {
      home.sessionVariables = {
        # Internal
        PYTHONPYCACHEPREFIX = "${config.xdg.cacheHome}/python";
        PYTHONSTARTUP = "${config.xdg.configHome}/python/pythonrc";
        PYTHONUSERBASE = "${config.xdg.dataHome}/python";
        PYTHON_EGG_CACHE = "${config.xdg.cacheHome}/python-eggs";
        PYTHONHISTFILE = "${config.xdg.dataHome}/python/python_history"; # default value as of >=3.4

        # Tools
        IPYTHONDIR = "${config.xdg.configHome}/ipython";
        JUPYTER_CONFIG_DIR = "${config.xdg.configHome}/jupyter";
        PIP_CONFIG_FILE = "${config.xdg.configHome}/pip/pip.conf";
        PIP_LOG_FILE = "${config.xdg.stateHome}/pip/log";
        PYLINTHOME = "${config.xdg.dataHome}/pylint";
        PYLINTRC = "${config.xdg.configHome}/pylint/pylintrc";
        UV_CACHE_DIR = "${config.xdg.cacheHome}/uv";
        WORKON_HOME = "${config.xdg.dataHome}/virtualenvs";
      };
    })
  ];
}
