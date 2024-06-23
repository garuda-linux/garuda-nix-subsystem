{ config
, garuda-lib
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
      "boot" = "nh os boot";
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
      "reb" = "nh os switch";
      "roll" = "nh os switch -- --rollback";
      "su" = "sudo su -";
      "tarnow" = "tar acf ";
      "testb" = "nh os test";
      "tree" = "eza --git --color always -T";
      "untar" = "tar zxvf ";
      "vdir" = "vdir --color=auto";
      "wget" = "wget -c";
    };

    # Direnv for per-directory environment variables
    direnv = {
      enable = config.garuda.system.isGui;
      nix-direnv.enable = config.garuda.system.isGui;
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
        "boot" = "nh os boot";
        "cls" = "clear";
        "diffnix" = "nvd diff $(sh -c 'ls -d1v /nix/var/nix/profiles/system-*-link|tail -n 2')";
        "edit" = "sops";
        "gcommit" = "git commit -m";
        "glcone" = "git clone";
        "gpr" = "git pull --rebase";
        "gpull" = "git pull";
        "gpush" = "git push";
        "reb" = "nh os switch";
        "roll" = "nh os switch -- --rollback";
        "run" = "comma ";
        "su" = "sudo su -";
        "tarnow" = "tar acf ";
        "testb" = "nh os test";
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
        ${pkgs.fastfetch}/bin/fastfetch
      '';
    };

    # The starship prompt
    starship = {
      enable = gDefault true;
      settings = {
        aws.symbol = gDefault "  ";
        buf.symbol = gDefault " ";
        c.symbol = gDefault " ";
        cmd_duration = {
          disabled = gDefault false;
          format = gDefault "took [$duration]($style)";
          min_time = gDefault 1;
        };
        conda.symbol = gDefault " ";
        crystal.symbol = gDefault " ";
        dart.symbol = gDefault " ";
        directory = {
          read_only = gDefault " 󰌾";
          style = gDefault "purple";
          truncate_to_repo = gDefault true;
          truncation_length = gDefault 0;
          truncation_symbol = gDefault "repo: ";
        };
        docker_context.symbol = gDefault " ";
        elixir.symbol = gDefault " ";
        elm.symbol = gDefault " ";
        fennel.symbol = gDefault " ";
        fossil_branch.symbol = gDefault " ";
        git_branch.symbol = gDefault " ";
        golang.symbol = gDefault " ";
        guix_shell.symbol = gDefault " ";
        haskell.symbol = gDefault " ";
        haxe.symbol = gDefault " ";
        hg_branch.symbol = gDefault " ";
        hostname = {
          disabled = gDefault false;
          format = gDefault "[$hostname]($style) in ";
          ssh_only = gDefault false;
          ssh_symbol = gDefault " ";
          style = gDefault "bold dimmed red";
          trim_at = gDefault "-";
        };
        java.symbol = gDefault " ";
        julia.symbol = gDefault " ";
        kotlin.symbol = gDefault " ";
        lua.symbol = gDefault " ";
        memory_usage.symbol = gDefault "󰍛 ";
        meson.symbol = gDefault "󰔷 ";
        nim.symbol = gDefault "󰆥 ";
        nix_shell.symbol = gDefault " ";
        nodejs.symbol = gDefault " ";
        ocaml.symbol = gDefault " ";
        package.symbol = gDefault "󰏗 ";
        perl.symbol = gDefault " ";
        php.symbol = gDefault " ";
        pijul_channel.symbol = " ";
        python.symbol = gDefault " ";
        rlang.symbol = gDefault "󰟔 ";
        ruby.symbol = gDefault " ";
        rust.symbol = gDefault " ";
        scala.symbol = gDefault " ";
        scan_timeout = gDefault 10;
        status = {
          disabled = gDefault false;
          map_symbol = gDefault true;
        };
        sudo.disabled = gDefault false;
        swift.symbol = gDefault " ";
        username = {
          format = gDefault " [$user]($style)@";
          show_always = gDefault true;
          style_root = gDefault "bold red";
          style_user = gDefault "bold red";
        };
        zig.symbol = gDefault " ";
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
