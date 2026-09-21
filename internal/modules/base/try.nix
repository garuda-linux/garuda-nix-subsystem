{
  config,
  lib,
  options,
  ...
}:
let
  cfg = config.garuda.try;

  hostDefs = builtins.filter (
    d: builtins.isAttrs d.value && builtins.hasAttr cfg.username d.value
  ) options.users.users.definitionsWithLocations;
in
{
  options.garuda.try = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Try Garuda without switching: adds a "garuda" boot specialisation
        that enables one edition and provides a dedicated trial user.
      '';
    };

    edition = lib.mkOption {
      type = lib.types.enum [
        "mokka"
        "dr460nized"
      ];
      default = "mokka";
      description = "Edition enabled inside the trial specialisation.";
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "garuda";
      description = "Trial user created inside the specialisation. Must not already exist on the host.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = builtins.all (d: d.file == toString ./try.nix) hostDefs;

        message = "garuda.try.username '${cfg.username}' is already defined on the host. Pick a different username to try out Garuda Nix.";
      }
    ];

    specialisation.garuda.configuration = {
      garuda.mokka.enable = lib.mkForce (cfg.edition == "mokka");
      garuda.dr460nized.enable = lib.mkForce (cfg.edition == "dr460nized");

      # Disable any potentially conflicting display managers in this specialisation.
      services.displayManager = {
        gdm.enable = lib.mkForce false;
        sddm.enable = lib.mkForce false;
        ly.enable = lib.mkForce false;
        lemurs.enable = lib.mkForce false;
        regreet.enable = lib.mkForce false;
        cosmic-greeter.enable = lib.mkForce false;
        dms-greeter.enable = lib.mkForce false;
        noctalia-greeter.enable = lib.mkForce false;
        generic.enable = lib.mkForce false;
      };
      services.greetd.enable = lib.mkForce false;
      services.xserver.displayManager.lightdm.enable = lib.mkForce false;

      users.users.${cfg.username} = {
        isNormalUser = true;
        description = "Garuda trial user";
        extraGroups = [ "wheel" ];
      };
    };
  };
}
