{ config, lib, flake-inputs, ... }:
let
  cfg = config.garuda.audio;
in
{
  options = {
    garuda.audio.pipewire.enable =
      lib.mkOption {
        default = true;
        description = ''
          If set to true, chaotic's nyx will have its binary cache automatically enabled and managed.
        '';
      };
  };
  config = {
    # Pipewire & wireplumber configuration
    services.pipewire = lib.mkIf cfg.pipewire.enable {
      alsa.enable = lib.mkDefault true;
      alsa.support32Bit = lib.mkDefault true;
      enable = lib.mkDefault true;
      pulse.enable = lib.mkDefault true;
      systemWide = lib.mkDefault false;
      wireplumber.enable = lib.mkDefault true;
    };
  };
}