# modules/dev/r.nix --- https://r-project.org/
#
# R’s ecosystem delights me. CRAN is a museum and a playground at once.
# But system libs, fonts, and geo deps can be… spicy. Let’s make it sane.
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.my.langs.r;
  inherit (lib.modules) mkIf mkMerge;
  inherit (lib.options) mkEnableOption;

  nvimcom = pkgs.rPackages.buildRPackage {
    name = "nvimcom";
    src =
      pkgs.fetchFromGitHub {
        owner = "R-nvim";
        repo = "R.nvim";
        rev = "382858fcf23aabbf47ff06279baf69d52260b939";
        hash = "sha256-j2rXXO7246Nh8U6XyX43nNTbrire9ta9Ono9Yr+Eh9M=";
      }
      + "/nvimcom/";
  };

  packages = with pkgs.rPackages; [
    tidyverse # Core Data Science (includes ggplot2, dplyr)
    tidymodels # Meta-package including rsample, recipes, parsnip, yardstick, broom, tune, etc.

    xts # From your list, for time series objects
    freqparcoord # From your list
    RANN # From your list; often used for recipes::step_impute_knn (KNN imputation)
    MASS # From your list; includes LDA/QDA and other classic stat models
    plotly # From your list, for interactive charts
    rmarkdown # From your list
    knitr # From your list
    quarto # R package for Quarto rendering
    languageserver # From your list, for RStudio/VSCode code completion etc.
    nvimcom # Neovim communication for R.nvim plugin

    Rcpp # Core Dependencies (from your list)

    ranger # For fast Random Forest (rand_forest)
    xgboost # For XGBoost (boost_tree)
    glmnet # For Lasso/Ridge regularized linear/logistic regression
    kknn # For K-Nearest Neighbors (k_nearest_neighbor)
    kernlab # For Support Vector Machines (svm_rbf, svm_linear)
    rpart # For Decision Trees (decision_tree)

    # timetk # "Tidy" style time series processing
    # modeltime # "Tidymodels" style time series forecasting

    rmarkdown
    quarto
    languageserver
    knitr
    titanic # Titanic dataset for practice
    ISLR # Datasets from "An Introduction to Statistical Learning"
    mlbench # Machine learning benchmark problems
    nycflights13 # Data on all flights that departed NYC in 2013 (great for dplyr)
    AER # Datasets from "Applied Econometrics with R"
  ];
in
{
  options.my.langs.r = {
    enable = mkEnableOption "R development environment";
    xdg.enable = mkEnableOption "R XDG environment variables";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # --- Packages ----------------------------------------------------------
      home.packages = with pkgs; [
        (rWrapper.override {
          inherit packages;
        })

        (rstudioWrapper.override {
          inherit packages;
        })
        # publisher tools
        pkgs.pandoc
        pkgs.quarto
      ];

      # --- Aliases -----------------------------------------------------------
      home.shellAliases = {
        r = "R";
        rs = "Rscript";
        rgd = "R -q -e 'httpgd::hgd()'"; # quick plot server
      };
    })

    (mkIf cfg.xdg.enable {
      # --- XDG mapping -------------------------------------------------------
      # Environment wiring for interop (only when enabled)
      home.sessionVariables = {
        # Prefer a consistent CRAN mirror; override per-project if needed
        R_REPOS = "https://cran.r-project.org";
        # Where user-installed R libs would go (if you ever install in R)
        R_LIBS_USER = "${config.xdg.dataHome}/R/library";

        # Config files
        R_PROFILE_USER = "${config.xdg.configHome}/R/Rprofile";
        R_ENVIRON_USER = "${config.xdg.configHome}/R/Renviron";

        # History (R >= 4.4 honors R_HISTFILE)
        R_HISTFILE = "${config.xdg.stateHome}/R/history";

        # Open things sanely
        R_BROWSER = "xdg-open";
        R_PDFVIEWER = "xdg-open";
      };
    })
  ];
}
