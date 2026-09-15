{ lib, garuda-lib, ... }:
with garuda-lib;
{
  programs.git = {
    enable = gDefault true;
    settings = gDefault {
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
    enable = gDefault true;
    git.enable = gDefault true;
  };

  # Suggested GPG settings
  # https://github.com/drduh/YubiKey-Guide/tree/master#harden-configuration
  programs.gpg = {
    enable = gDefault true;
    settings = gDefault {
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

  programs = {
    bat.enable = gDefault true;

    btop = {
      enable = gDefault true;
      settings = {
        color_theme = gDefault "TTY";
        proc_tree = gDefault true;
        theme_background = gDefault false;
      };
    };

    micro = {
      enable = gDefault true;
      settings = gDefault {
        "autosu" = true;
        "mkparents" = true;
      };
    };

    starship = {
      enable = gDefault true;
      settings = lib.mapAttrsRecursive (_: gDefault) (import ../starship-settings.nix);
    };
  };

  nix = {
    extraOptions = gDefault ''
      warn-dirty = false
    '';
    settings.builders-use-substitutes = gDefault true;

    settings.experimental-features = gDefault [
      "nix-command"
      "flakes"
    ];

    settings.extra-substituters = gDefault [ "https://nyx-cache.chaotic.cx/" ];
    settings.extra-trusted-public-keys = gDefault [
      "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="
    ];

    settings.log-lines = gDefault 20;

    settings.max-jobs = gDefault "auto";
  };

  programs.dircolors.enable = gDefault true;

  programs.eza.enable = gDefault true;

  news.display = gDefault "notify";
}
