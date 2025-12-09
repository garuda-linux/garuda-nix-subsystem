To make use of this flake, you can use it as follows - [we assume flakes to be enabled](https://nixos.wiki/wiki/Flakes#Enable_flakes):

```nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    garuda.url = "gitlab:garuda-linux/garuda-nix-subsystem/stable";
  };

  outputs = { garuda, nixpkgs, ... }: {
    nixosConfigurations = {
      hostname = garuda.lib.garudaSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your system configuration.
        ];
      };
    };
  };
}
```

You may notice that we are using `garuda.lib.garudaSystem` to build the derivation. `garudaSystem` provides an opinionated system configuration similar to what Garuda Linux provides out of the box. It also exposes our modules which can then be referenced in our modules like `garuda.*`. Then, build your configuration as usual. GNS defaults are generally lower priority than your settings, therefore it's easy to override most settings if needed.

An exemplary `configuration.nix` could look as follows:

```nix
{ ... }: {
  # Your hardware configuration
  imports = [ ./hardware-configuration.nix ];

  # Hostname
  networking.hostName = "yourmachine";

  # Enabling the dr460nized desktop version
  # as well as the linux-cachyos kernel and gaming
  # options and applications
  garuda = {
    dr460nized.enable = true;
    gaming.enable = true;
    performance-tweaks = {
      cachyos-kernel = true;
      enable = true;
    };
  };
}
```
