{ ... }:
{
  imports = [ ./vm-catppuccin-full.nix ];
  garuda.subsystem.enable = true;
  garuda.managed.config = ./garuda-managed.json;
}
