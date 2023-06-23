{ garuda-lib, pkgs, ... }:
with garuda-lib;
{
  # We want to be insulted on wrong passwords
  security.sudo = gDefault {
    extraConfig = ''
      Defaults pwfeedback
    '';
    package = pkgs.sudo.override { withInsults = true; };
  };

  # Type "fuck" to fix the last command that made you go "fuck"
  programs.thefuck.enable = gDefault true;
}
