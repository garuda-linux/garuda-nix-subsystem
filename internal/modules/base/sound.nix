{ config, lib, flake-inputs, ... }:
let
  cfg = config.garuda.audio;
in
with lib;
{
  options = {
    garuda.audio.pipewire.enable =
      mkOption {
        default = true;
        description = ''
          If set to true, chaotic's nyx will have its binary cache automatically enabled and managed.
        '';
      };
  };
  config = {
    # Pipewire & wireplumber configuration
    services.pipewire = mkIf cfg.pipewire.enable {
      alsa.enable = mkDefault true;
      alsa.support32Bit = mkDefault true;
      enable = mkDefault true;
      pulse.enable = mkDefault true;
      systemWide = mkDefault false;
      wireplumber.enable = mkDefault true;
    };

    # Enable the realtime kit
    security.rtkit.enable = mkIf cfg.pipewire.enable true;

    # Disable PulseAudio
    hardware.pulseaudio.enable = mkIf cfg.pipewire.enable false;
  };
}
