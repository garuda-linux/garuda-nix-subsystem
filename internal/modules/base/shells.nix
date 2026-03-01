{
  config,
  garuda-lib,
  pkgs,
  lib,
  ...
}:
with garuda-lib;
{
  # Use micro as editor
  environment.sessionVariables = {
    EDITOR = gDefault "${pkgs.micro}/bin/micro";
    VISUAL = gDefault "${pkgs.micro}/bin/micro";
  };

  # Programs & global config
  programs = {
    bash = {
      # Execute fish in case we aren't using a login shell
      interactiveShellInit = ''
        if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
      shellAliases = {
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
      settings = lib.mapAttrsRecursive (_: gDefault) (import ./starship-settings.nix { inherit lib; });
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
