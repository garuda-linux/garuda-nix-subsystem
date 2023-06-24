{ garuda-lib, pkgs, ... }:
with garuda-lib;
{
  options.garuda.excludes = gCreateExclusionOption "defaultpackages";
  config = {
    # Default applications
    environment.systemPackages = with pkgs; gExcludableArray "defaultpackages" [
      curl
      exa
      fastfetch
      git
      htop
      killall
      micro
      screen
      tldr
      ugrep
      wget
    ];

    # We want to be insulted on wrong passwords
    security.sudo = gDefault {
      extraConfig = ''
        Defaults pwfeedback
      '';
      package = pkgs.sudo.override { withInsults = true; };
    };

    # Type "fuck" to fix the last command that made you go "fuck"
    programs.thefuck.enable = gDefault true;
  };
}
