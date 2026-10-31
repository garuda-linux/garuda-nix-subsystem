{
  imports = [ ./lima.nix ];

  # Do not remove these subsystem settings
  garuda.subsystem.enable = true;
  garuda.managed.config = ./garuda-managed.json;

  system.stateVersion = "26.11";
}
