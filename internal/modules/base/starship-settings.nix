{ lib, ... }:
let
  inherit (lib) mkDefault;
in
{
  aws.symbol = mkDefault "  ";
  buf.symbol = mkDefault " ";
  c.symbol = mkDefault " ";
  cmd_duration = {
    disabled = mkDefault false;
    format = mkDefault "took [$duration]($style)";
    min_time = mkDefault 1;
  };
  conda.symbol = mkDefault " ";
  crystal.symbol = mkDefault " ";
  dart.symbol = mkDefault " ";
  directory = {
    read_only = mkDefault " 󰌾";
    style = mkDefault "purple";
    truncate_to_repo = mkDefault true;
    truncation_length = mkDefault 0;
    truncation_symbol = mkDefault "repo: ";
  };
  docker_context.symbol = mkDefault " ";
  elixir.symbol = mkDefault " ";
  elm.symbol = mkDefault " ";
  fennel.symbol = mkDefault " ";
  fossil_branch.symbol = mkDefault " ";
  git_branch.symbol = mkDefault " ";
  golang.symbol = mkDefault " ";
  guix_shell.symbol = mkDefault " ";
  haskell.symbol = mkDefault " ";
  haxe.symbol = mkDefault " ";
  hg_branch.symbol = mkDefault " ";
  hostname = {
    disabled = mkDefault false;
    format = mkDefault "[$hostname]($style) in ";
    ssh_only = mkDefault false;
    ssh_symbol = mkDefault " ";
    style = mkDefault "bold dimmed red";
  };
  java.symbol = mkDefault " ";
  julia.symbol = mkDefault " ";
  kotlin.symbol = mkDefault " ";
  lua.symbol = mkDefault " ";
  memory_usage.symbol = mkDefault "󰍛 ";
  meson.symbol = mkDefault "󰔷 ";
  nim.symbol = mkDefault "󰆥 ";
  nix_shell.symbol = mkDefault " ";
  nodejs.symbol = mkDefault " ";
  ocaml.symbol = mkDefault " ";
  package.symbol = mkDefault "󰏗 ";
  perl.symbol = mkDefault " ";
  php.symbol = mkDefault " ";
  pijul_channel.symbol = " ";
  python.symbol = mkDefault " ";
  rlang.symbol = mkDefault "󰟔 ";
  ruby.symbol = mkDefault " ";
  rust.symbol = mkDefault " ";
  scala.symbol = mkDefault " ";
  scan_timeout = mkDefault 10;
  status = {
    disabled = mkDefault false;
    map_symbol = mkDefault true;
  };
  sudo.disabled = mkDefault false;
  swift.symbol = mkDefault " ";
  username = {
    format = mkDefault " [$user]($style)@";
    show_always = mkDefault true;
    style_root = mkDefault "bold red";
    style_user = mkDefault "bold red";
  };
  zig.symbol = mkDefault " ";
}
