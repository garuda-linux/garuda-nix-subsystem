{ lib, ... }:
{
  # Git shall be used a lot on flaky systems
  programs.git = {
    enable = true;
    settings = {
      core = {
        editor = "micro";
      };
      init = {
        defaultBranch = "main";
      };
      pull = {
        rebase = true;
      };
    };
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  # Suggested GPG settings
  # https://github.com/drduh/YubiKey-Guide/tree/master#harden-configuration
  programs.gpg = {
    enable = true;
    settings = {
      cert-digest-algo = "SHA512";
      charset = "utf-8";
      default-preference-list = "SHA512 SHA384 SHA256 AES256 AES192 AES ZLIB BZIP2 ZIP Uncompressed";
      fixed-list-mode = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      no-comments = true;
      no-emit-version = true;
      no-greeting = true;
      no-symkey-cache = true;
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      require-cross-certification = true;
      s2k-cipher-algo = "AES256";
      s2k-digest-algo = "SHA512";
      throw-keyids = true;
      verify-options = "show-uid-validity";
      with-fingerprint = true;
    };
  };

  # Individual terminal app configs
  programs = {
    # The better cat replacement
    bat.enable = true;

    # Btop to view resource usage
    btop = {
      enable = true;
      settings = {
        color_theme = lib.mkDefault "TTY";
        proc_tree = true;
        theme_background = false;
      };
    };

    # Micro, the editor
    micro = {
      enable = true;
      settings = {
        "autosu" = true;
        "mkparents" = true;
      };
    };
  };

  nix = {
    # Don't warn about dirty flakes and accept flake configs by default
    extraOptions = ''
      accept-flake-config = true
      warn-dirty = false
    '';
    settings = {
      # Use available binary caches, this is not Gentoo
      # this also allows us to use remote builders to reduce build times and batter usage
      builders-use-substitutes = true;

      # We are using flakes, so enable the experimental features
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Show more log lines for failed builds
      log-lines = 20;

      # Max number of parallel jobs
      max-jobs = "auto";
    };
  };

  # Enable dircolors
  programs.dircolors.enable = true;

  # Show home-manager news
  news.display = "notify";
}
