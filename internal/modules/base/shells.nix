{ garuda-lib
, pkgs
, ...
}:
with garuda-lib; {
  # Use micro as editor
  environment.sessionVariables = {
    EDITOR = gDefault "${pkgs.micro}/bin/micro";
    VISUAL = gDefault "${pkgs.micro}/bin/micro";
  };

  # Programs & global config
  programs = {
    bash.shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../../";
      "...." = "cd ../../../";
      "....." = "cd ../../../../";
      "......" = "cd ../../../../../";
      "bat" = "bat --style header --style snip --style changes";
      "cat" = "bat --style header --style snip --style changes";
      "cls" = "clear";
      "dd" = "dd progress=status";
      "dir" = "dir --color=auto";
      "egrep" = "egrep --color=auto";
      "fastfetch" = "fastfetch -l nixos";
      "fgrep" = "fgrep --color=auto";
      "gcommit" = "git commit -m";
      "gitlog" = "git log --oneline --graph --decorate --all";
      "glcone" = "git clone";
      "gpr" = "git pull --rebase";
      "gpull" = "git pull";
      "gpush" = "git push";
      "ip" = "ip --color=auto";
      "jctl" = "journalctl -p 3 -xb";
      "ls" = "eza -al --color=always --group-directories-first --icons";
      "psmem" = "ps auxf | sort -nr -k 4";
      "psmem10" = "ps auxf | sort -nr -k 4 | head -1";
      "su" = "sudo su -";
      "tarnow" = "tar acf ";
      "tree" = "eza --git --color always -T";
      "untar" = "tar zxvf ";
      "vdir" = "vdir --color=auto";
      "wget" = "wget -c";
    };

    # Direnv for per-directory environment variables
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # The fish shell, default for terminals
    fish = {
      enable = gDefault true;
      vendor = {
        completions.enable = gDefault true;
        config.enable = gDefault true;
      };
      shellAbbrs = {
        ".." = "cd ..";
        "..." = "cd ../../";
        "...." = "cd ../../../";
        "....." = "cd ../../../../";
        "......" = "cd ../../../../../";
        "cls" = "clear";
        "diffnix" = "nvd diff $(sh -c 'ls -d1v /nix/var/nix/profiles/system-*-link|tail -n 2')";
        "edit" = "sops";
        "gcommit" = "git commit -m";
        "glcone" = "git clone";
        "gpr" = "git pull --rebase";
        "gpull" = "git pull";
        "gpush" = "git push";
        "reb" = " sudo nixos-rebuild switch -L";
        "roll" = "sudo nixos-rebuild switch --rollback";
        "run" = "nix run nixpkgs#";
        "su" = "sudo su -";
        "tarnow" = "tar acf ";
        "test" = "sudo nixos-rebuild switch --test";
        "tree" = "eza --git --color always -T";
        "untar" = "tar zxvf ";
        "use" = "nix shell nixpkgs#";
      };
      shellAliases = {
        "bat" = "bat --style header --style snip --style changes";
        "cat" = "bat --style header --style snip --style changes";
        "dd" = "dd progress=status";
        "diffnix" = "nvd diff $(sh -c 'ls -d1v /nix/var/nix/profiles/system-*-link|tail -n 2')";
        "dir" = "dir --color=auto";
        "egrep" = "egrep --color=auto";
        "fastfetch" = "fastfetch -l nixos";
        "fgrep" = "fgrep --color=auto";
        "gitlog" = "git log --oneline --graph --decorate --all";
        "ip" = "ip --color=auto";
        "jctl" = "journalctl -p 3 -xb";
        "ls" = "eza -al --color=always --group-directories-first --icons";
        "psmem" = "ps auxf | sort -nr -k 4";
        "psmem10" = "ps auxf | sort -nr -k 4 | head -1";
        "vdir" = "vdir --color=auto";
        "wget" = "wget -c";
      };
      shellInit = gDefault ''
        set fish_greeting
        ${pkgs.fastfetch}/bin/fastfetch -L nixos --load-config paleofetch.jsonc
      '';
    };

    # The starship prompt
    starship = {
      enable = gDefault true;
      settings = {
        cmd_duration = {
          disabled = gDefault false;
          format = gDefault "took [$duration]($style)";
          min_time = gDefault 1;
        };
        directory = {
          style = gDefault "purple";
          truncate_to_repo = gDefault true;
          truncation_length = gDefault 0;
          truncation_symbol = gDefault "repo: ";
        };
        hostname = {
          disabled = gDefault false;
          format = gDefault "[$hostname]($style) in ";
          ssh_only = gDefault false;
          style = gDefault "bold dimmed red";
          trim_at = gDefault "-";
        };
        scan_timeout = gDefault 10;
        status = {
          disabled = gDefault false;
          map_symbol = gDefault true;
        };
        sudo.disabled = gDefault false;
        username = {
          format = gDefault " [$user]($style)@";
          show_always = gDefault true;
          style_root = gDefault "bold red";
          style_user = gDefault "bold red";
        };
      };
    };

    # Easy terminal tabbing
    tmux = {
      baseIndex = gDefault 1;
      clock24 = gDefault true;
      enable = gDefault true;
      extraConfig = gDefault ''
        set -g default-shell ${pkgs.fish}/bin/fish
        set -g default-terminal "screen-256color"
        set -g status-bg black
      '';
      historyLimit = gDefault 10000;
      newSession = gDefault true;
    };
  };
}
