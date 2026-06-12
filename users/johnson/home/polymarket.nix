{
  self,
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib.lists) optional;
  inherit (lib.meta) getExe;
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkEnableOption mkOption;
  inherit (lib.strings) concatMapStringsSep escapeShellArg;
  inherit (lib.types)
    bool
    listOf
    str
    ;

  cfg = config.my.polymarket;
  polyFile = "${self}/secrets/${config.my.name}/polymarket.yaml";
  mkPolymarketSecret = {
    sopsFile = polyFile;
    mode = "0400";
  };

  uvPackageArgs = concatMapStringsSep "\n" (package: ''
    --with
    ${escapeShellArg package}'') cfg.pythonPackages;

  uvBaseArgs = ''
    uv_args=(
      run
      --prerelease
      allow
      ${uvPackageArgs}
    )
  '';

  envSnippet = ''
    export POLYMARKET_CLOB_URL="${cfg.clobUrl}"
    export POLYMARKET_HOST="$POLYMARKET_CLOB_URL"
    export POLYMARKET_CHAIN_ID="${cfg.chainId}"

    POLYMARKET_PRIVATE_KEY="$(cat "${config.sops.secrets.polymarket_private_key.path}")"
    POLY_API_KEY="$(cat "${config.sops.secrets.poly_api_key.path}")"
    POLY_SECRET="$(cat "${config.sops.secrets.poly_secret.path}")"
    POLY_PASSPHRASE="$(cat "${config.sops.secrets.poly_passphrase.path}")"
    POLYMARKET_FUNDER_ADDRESS="$(cat "${config.sops.secrets.polymarket_funder_address.path}")"

    export POLYMARKET_PRIVATE_KEY
    export PRIVATE_KEY="$POLYMARKET_PRIVATE_KEY"
    export PK="$POLYMARKET_PRIVATE_KEY"

    export POLY_API_KEY
    export POLY_SECRET
    export POLY_PASSPHRASE

    export POLYMARKET_API_KEY="$POLY_API_KEY"
    export POLYMARKET_SECRET="$POLY_SECRET"
    export POLYMARKET_PASSPHRASE="$POLY_PASSPHRASE"

    export CLOB_API_KEY="$POLY_API_KEY"
    export CLOB_SECRET="$POLY_SECRET"
    export CLOB_PASS_PHRASE="$POLY_PASSPHRASE"

    export POLYMARKET_FUNDER_ADDRESS
    export FUNDER_ADDRESS="$POLYMARKET_FUNDER_ADDRESS"
  '';
in
{
  options.my.polymarket = {
    enable = mkEnableOption "Polymarket credentials and Python quant tooling";

    clobUrl = mkOption {
      type = str;
      default = "https://clob.polymarket.com";
      description = "Polymarket CLOB API URL.";
    };

    chainId = mkOption {
      type = str;
      default = "137";
      description = "Polymarket chain ID.";
    };

    enablePython = mkOption {
      type = bool;
      default = true;
      description = "Whether to install Python wrappers for Polymarket research and trading.";
    };

    pythonPackages = mkOption {
      type = listOf str;
      default = [
        # Polymarket APIs and SDKs
        "polymarket-client"
        "py-clob-client-v2"
        "polymarket-apis"

        # Chain/auth/signing clients
        "eth-account"
        "web3"

        # HTTP and websocket APIs
        "aiohttp"
        "httpx"
        "orjson"
        "pydantic"
        "python-dotenv"
        "requests"
        "websockets"

        # Quant research stack
        "duckdb"
        "matplotlib"
        "numba"
        "numpy"
        "pandas"
        "plotly"
        "polars"
        "pyarrow"
        "scikit-learn"
        "scipy"
        "statsmodels"
        "ta"

        # Interactive tooling
        "ipython"
        "jupyterlab"
        "rich"
        "typer"
      ];
      description = "PyPI packages loaded by the Polymarket uv wrappers.";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets = {
      polymarket_private_key = mkPolymarketSecret;
      poly_api_key = mkPolymarketSecret;
      poly_secret = mkPolymarketSecret;
      poly_passphrase = mkPolymarketSecret;
      polymarket_funder_address = mkPolymarketSecret // {
        key = "relayer_api_key_address";
      };
    };

    home.packages = [
      (pkgs.writeShellApplication {
        name = "poly-env";
        runtimeInputs = with pkgs; [
          coreutils
        ];
        text = ''
          ${envSnippet}

          if [ "$#" -eq 0 ]; then
            exec "$SHELL"
          fi

          exec "$@"
        '';
      })
    ]
    ++ optional cfg.enablePython (
      pkgs.writeShellApplication {
        name = "poly-python";
        runtimeInputs = with pkgs; [
          coreutils
          uv
        ];
        text = ''
          ${envSnippet}
          ${uvBaseArgs}

          exec ${getExe pkgs.uv} "''${uv_args[@]}" python "$@"
        '';
      }
    )
    ++ optional cfg.enablePython (
      pkgs.writeShellApplication {
        name = "poly-ipython";
        runtimeInputs = with pkgs; [
          coreutils
          uv
        ];
        text = ''
          ${envSnippet}
          ${uvBaseArgs}

          exec ${getExe pkgs.uv} "''${uv_args[@]}" ipython --no-banner "$@"
        '';
      }
    )
    ++ optional cfg.enablePython (
      pkgs.writeShellApplication {
        name = "poly-jupyter";
        runtimeInputs = with pkgs; [
          coreutils
          uv
        ];
        text = ''
          ${envSnippet}
          ${uvBaseArgs}

          exec ${getExe pkgs.uv} "''${uv_args[@]}" jupyter lab "$@"
        '';
      }
    );
  };
}
