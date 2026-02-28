{
  config,
  lib,
  garuda-lib,
  ...
}:
let
  cfg = config.garuda.audio;
in
with lib;
with garuda-lib;
{
  options = {
    garuda.audio.pipewire.enable = mkOption {
      default = config.garuda.system.isGui;
      type = types.bool;
      example = false;
      description = ''
        If set to true, a default configuration for Pipewire will be used.
      '';
    };
  };
  config = mkIf cfg.pipewire.enable {
    # Pipewire & wireplumber configuration
    services.pipewire = {
      alsa.enable = gDefault true;
      alsa.support32Bit = gDefault true;
      enable = gDefault true;
      pulse.enable = gDefault true;
      systemWide = gDefault false;
      wireplumber.enable = gDefault true;
    };

    # Enable the realtime kit
    security.rtkit.enable = gDefault true;

    # Disable PulseAudio
    services.pulseaudio.enable = gDefault false;
  };
}
