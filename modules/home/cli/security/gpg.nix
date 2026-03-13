{
  config,
  pkgs,
  lib,
  self,
  ...
}: let
  inherit (lib.modules) mkIf;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) str path;
  cfg = config.my.security.gpg;
in {
  options.my.security.gpg = {
    enable = mkEnableOption "my security gpg" // {default = config.my.security.enable;};
    signGitCommits = mkOption {
      type = lib.types.bool;
      default = true;
      description = "Sign git commits with gpg.";
    };

    key = mkOption {
      type = str;
      default = "776C7FC245E58F55";
      description = "The public key of my gpg.";
    };
    publicKeysPath = mkOption {
      type = path;
      default = "${self}/secrets/core/gpg-keys.pub";
      description = "The path to the public key of my gpg.";
    };
  };
  config = mkIf cfg.enable {
    programs = {
      git = {
        signing = {
          signByDefault = cfg.signGitCommits;
          inherit (cfg) key;
        };
      };
      gpg = {
        enable = true;
        homedir = "${config.home.homeDirectory}/.gnupg";
        #  $GNUPGHOME/trustdb.gpg stores all the trust level you specified in `programs.gpg.publicKeys` option.
        #
        # If set `mutableTrust` to false, the path $GNUPGHOME/trustdb.gpg will be overwritten on each activation.
        # Thus we can only update trsutedb.gpg via home-manager.
        mutableTrust = false;

        # $GNUPGHOME/pubring.kbx stores all the public keys you specified in `programs.gpg.publicKeys` option.
        #
        # If set `mutableKeys` to false, the path $GNUPGHOME/pubring.kbx will become an immutable link to the Nix store, denying modifications.
        # Thus we can only update pubring.kbx via home-manager
        mutableKeys = false;
        publicKeys = [
          # https://www.gnupg.org/pgh/en/manual/x334.html
          {
            source = cfg.publicKeysPath;
            trust = 5;
          } # ultimate trust, my own keys.
        ];

        # This configuration is based on the tutorial below, it allows for a robust setup
        # https://blog.eleven-labs.com/en/openpgp-almost-perfect-key-pair-part-1
        # ~/.gnupg/gpg.conf
        settings = {
          #keep-sorted start

          # Message digest algorithm used when signing a key
          cert-digest-algo = "SHA512";
          # Use the strongest cipher algorithm
          cipher-algo = "AES256";
          # Use RFC-1950 ZLIB compression
          compress-algo = "ZLIB";
          # This preference list is used for new keys and becomes the default for "setpref" in the edit menu
          default-preference-list = "SHA512 SHA384 SHA256 RIPEMD160 AES256 TWOFISH BLOWFISH ZLIB BZIP2 ZIP Uncompressed";
          # Use the strongest digest algorithm
          digest-algo = "SHA512";
          # Disable weak algorithm
          disable-cipher-algo = "3DES";
          # Export the smallest key possible
          # This removes all signatures except the most recent self-signature on each user ID
          export-options = "export-minimal";
          # Display long key IDs
          keyid-format = "0xlong";
          # Display the calculated validity of user IDs during key listings
          list-options = "show-uid-validity";
          # Ensure the PIN prompt is always shown for Yubikey
          no-allow-external-cache = true;
          # Do not write comment packets
          no-comments = false;
          # Disable inclusion of the version string in ASCII armored output
          no-emit-version = true;
          # Get rid of the copyright notice
          no-greeting = true;
          # Select the strongest cipher
          personal-cipher-preferences = "AES256";
          # Select the strongest digest
          personal-digest-preferences = "SHA512";
          # The cipher algorithm for symmetric encryption for symmetric encryption with a passphrase
          s2k-cipher-algo = "AES256";
          # Specify how many times the passphrases mangling for symmetric encryption is repeated
          s2k-count = "65011712";
          # The digest algorithm used to mangle the passphrases for symmetric encryption
          s2k-digest-algo = "SHA512";
          # Selects how passphrases for symmetric encryption are mangled
          s2k-mode = "3";
          verify-options = "show-uid-validity show-keyserver-urls";
          # Treat the specified digest algorithm as weak
          weak-digest = "SHA1";
          # List all keys (or the specified ones) along with their fingerprints
          with-fingerprint = true;
          # keep-sorted end
        };
      };
    };

    home = {
      packages = lib.optionals config.gtk.enable [pkgs.gcr] ++ lib.optional pkgs.stdenv.hostPlatform.isDarwin pkgs.pinentry-mac;
    };

    services.gpg-agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage =
        if pkgs.stdenv.hostPlatform.isDarwin
        then pkgs.pinentry-mac
        else if config.gtk.enable || config.qt.enable
        then pkgs.pinentry-qt
        else pkgs.pinentry-tty;
    };
  };
}
