# Garuda Nix Subsystem

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)
[![pipeline status](https://gitlab.com/garuda-linux/garuda-nix-subsystem/badges/main/pipeline.svg)](https://gitlab.com/garuda-linux/garuda-nix-subsystem/-/commits/main)

## General information

The Garuda Nix Subsystem is a Nix flake which allows easy dual boot with Garuda Linux. But it also provides a framework for pure NixOS, which provides opiniated defaults and a system which can be fully set up by toggling a few module options.

## Quick links

- [Using as subsystem to Garuda](./subsystem/quick-start.md)
- [Using as module for NixOS](./nixos-module/quick-start.md)
- ... coming soon™️

## Devshell and how to enter it

This NixOS flake provides a [devshell](https://github.com/numtide/devshell) which contains all deployment tools as well as handy aliases for common tasks.
The only requirement for using it is having the Nix package manager available. It can be installed on various distributions via the package manager or the following script ([click me for more information](https://zero-to-nix.com/start/install)):

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix -o nix-install.sh # Check its content afterwards
sh ./nix-install.sh install --diagnostic-endpoint=""
```

This installs the Nix packages with flakes already pre-enabled. After that, the shell can be invoked as follows:

```sh
nix develop # The intended way to use the devshell
nix-shell # Legacy, non-flakes way if flakes are not available for some reason
```

This also sets up pre-commit-hooks and shows the currently implemented tasks, which can be executed by running the command shown in the welcome message.
