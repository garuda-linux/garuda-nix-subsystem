{ pkgs }:
let
  executable = builtins.readFile ./launch-terminal.bash;
in
pkgs.writeShellApplication {
  name = "launch-terminal";
  runtimeInputs = with pkgs; [ util-linux coreutils mktemp gnused xterm ];

  text = executable;
}
