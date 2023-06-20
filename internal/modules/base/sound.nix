{ config, lib, flake-inputs, garuda-lib, ... }:
let
  cfg = config.garuda.audio;
in
with lib;
with garuda-lib;
{
  options = {
    garuda.audio.pipewire.enable =
      mkOption {
        default = true;
        description = ''
          If set to true, a default configuration for Pipewire will be used.
        '';
      };
  };
  config = {
    # Pipewire & wireplumber configuration
    services.pipewire = mkIf cfg.pipewire.enable {
      alsa.enable = gDefault true;
      alsa.support32Bit = gDefault true;
      enable = gDefault true;
      pulse.enable = gDefault true;
      systemWide = gDefault false;
      wireplumber.enable = gDefault true;
    };

    # Enable the realtime kit
    security.rtkit.enable = mkIf cfg.pipewire.enable (gDefault true);

    # Disable PulseAudio
    hardware.pulseaudio.enable = mkIf cfg.pipewire.enable false;
  };
}
