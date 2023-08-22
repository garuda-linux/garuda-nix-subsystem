{ pkgs, ... }: {
  # Git shall be used a lot on flaky systems
  programs.git = {
    diff-so-fancy.enable = true;
    enable = true;
    extraConfig = {
      core = { editor = "micro"; };
      init = { defaultBranch = "main"; };
      pull = { rebase = true; };
    };
  };

  # Suggested GPG settings
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

  # Invididual terminal app configs
  programs = {
    # Common Bash aliases & tmux autostart
    bash.enable = true;

    # The better cat replacement
    bat = {
      enable = true;
      config.theme = "Dracula";
    };

    # Btop to view resource usage
    btop = {
      enable = true;
      settings = {
        color_theme = "TTY";
        proc_tree = true;
        theme_background = false;
      };
    };

    # Direnv for per-directory environment variables
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Exa as ls replacement
    exa = {
      enable = true;
      enableAliases = true;
    };

    # Fish shell
    fish.enable = true;

    # The starship prompt
    starship = {
      enable = true;
      settings = {
        username = {
          format = " [$user]($style)@";
          show_always = true;
          style_root = "bold red";
          style_user = "bold red";
        };
        hostname = {
          disabled = false;
          format = "[$hostname]($style) in ";
          ssh_only = false;
          style = "bold dimmed red";
          trim_at = "-";
        };
        scan_timeout = 10;
        directory = {
          style = "purple";
          truncate_to_repo = true;
          truncation_length = 0;
          truncation_symbol = "repo: ";
        };
        status = {
          disabled = false;
          map_symbol = true;
        };
        sudo = { disabled = false; };
        cmd_duration = {
          disabled = false;
          format = "took [$duration]($style)";
          min_time = 1;
        };
      };
    };
  };

  # Always use configured caches
  nix.extraOptions = ''
    extra-substituters = https://chaotic-nyx.cachix.org
    extra-trusted-public-keys = chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8=
  '';

  # Enable dircolors
  programs.dircolors.enable = true;

  # Show home-manager news
  news.display = "notify";

  # Disable manpages
  manual.manpages.enable = false;
}
