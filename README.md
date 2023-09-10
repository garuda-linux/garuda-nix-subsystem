# Garuda Nix Subsystem

[![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)](https://builtwithnix.org)
[![pipeline status](https://gitlab.com/garuda-linux/garuda-nix-subsystem/badges/main/pipeline.svg)](https://gitlab.com/garuda-linux/garuda-nix-subsystem/-/commits/main)

## General information

## Quick links

## Devshell and tooling

This NixOS flake provides a [devshell](https://github.com/numtide/devshell) which contains all deployment tools as well as handy aliases for common tasks.
The only requirement for using it is having the Nix package manager available and having flakes enabled. It can be installed on various distributions via the package manager or the following script:

```
sh <(curl -L https://nixos.org/nix/install) --daemon
```

After that, the shell can be invoked as follows:

```
nix-shell # Assuming flakes are not enabled, this bootstraps the needed files and sets up the pre-commit hook
nix develop # Contains our custom tools like `gns-update`
```

To enable flakes and the direct usage of `nix develop` follow this [wiki article](https://nixos.wiki/wiki/Flakes#Other_Distros:_Without_Home-Manager).

## General structure

A general overview of the folder structure can be found below:

```
├── devshell
├── internal
│   ├── modules
│   │   ├── base
│   │   │   ├── home-manager
│   │   │   └── subsystem
│   │   └── dr460nized
│   └── testing
└── lib
```

## Linting and formatting

We utilize [pre-commit-hooks](https://github.com/cachix/pre-commit-hooks.nix) to automatically set up the pre-commit-hook with all the tools once `nix-shell` is run for the first time. Checks can then be executed by running either

```
nix flake check # checks flake outputs and runs pre-commit at the end
pre-commit run --all-files # only runs the pre-commit tools on all files
```

Its configuration can be found in the `devshell` folder ([click me](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/devshell/flake-module.nix?ref_type=heads#L110)). At the time of writing, the following tools are being run:

- [commitizen](https://github.com/commitizen-tools/commitizen)
- [deadnix](https://github.com/astro/deadnix)
- [nil](https://github.com/oxalica/nil)
- [nixpkgs-fmt](https://github.com/nix-community/nixpkgs-fmt)
- [prettier](https://prettier.io/)
- [shellcheck](https://github.com/koalaman/shellcheck)
- [shfmt](https://github.com/mvdan/sh)
- [statix](https://github.com/nerdypepper/statix)
- [yamllint](https://github.com/adrienverge/yamllint)

It is recommended to run `pre-commit run --all-files` before commiting any files. Then use `cz commit` to generate a `commitizen` complying commit message.

## CI tooling
