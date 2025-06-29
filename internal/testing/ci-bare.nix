{ ... }:
{
  imports = [ ./vm-dr460nized-bare.nix ];
  garuda.subsystem.enable = true;
  garuda.managed.config = ./garuda-managed.json;
}
