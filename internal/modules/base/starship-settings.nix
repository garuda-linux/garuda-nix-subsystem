{
  aws.symbol = "  ";
  buf.symbol = " ";
  c.symbol = " ";
  cmd_duration = {
    disabled = false;
    format = "took [$duration]($style)";
    min_time = 1;
  };
  conda.symbol = " ";
  crystal.symbol = " ";
  dart.symbol = " ";
  directory = {
    read_only = " 󰌾";
    style = "purple";
    truncate_to_repo = true;
    truncation_length = 0;
    truncation_symbol = "repo: ";
  };
  docker_context.symbol = " ";
  elixir.symbol = " ";
  elm.symbol = " ";
  fennel.symbol = " ";
  fossil_branch.symbol = " ";
  git_branch.symbol = " ";
  golang.symbol = " ";
  guix_shell.symbol = " ";
  haskell.symbol = " ";
  haxe.symbol = " ";
  hg_branch.symbol = " ";
  hostname = {
    disabled = false;
    format = "[$hostname]($style) in ";
    ssh_only = false;
    ssh_symbol = " ";
    style = "bold dimmed red";
  };
  java.symbol = " ";
  julia.symbol = " ";
  kotlin.symbol = " ";
  lua.symbol = " ";
  memory_usage.symbol = "󰍛 ";
  meson.symbol = "󰔷 ";
  nim.symbol = "󰆥 ";
  nix_shell.symbol = " ";
  nodejs.symbol = " ";
  ocaml.symbol = " ";
  package.symbol = "󰏗 ";
  perl.symbol = " ";
  php.symbol = " ";
  pijul_channel.symbol = " ";
  python.symbol = " ";
  rlang.symbol = "󰟔 ";
  ruby.symbol = " ";
  rust.symbol = " ";
  scala.symbol = " ";
  scan_timeout = 10;
  status = {
    disabled = false;
    map_symbol = true;
  };
  sudo.disabled = false;
  swift.symbol = " ";
  username = {
    format = " [$user]($style)@";
    show_always = true;
    style_root = "bold red";
    style_user = "bold red";
  };
  zig.symbol = " ";
}
