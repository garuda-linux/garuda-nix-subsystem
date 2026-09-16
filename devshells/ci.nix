{ pkgs }:
let
  ci = pkgs.writeShellScriptBin "ci" ''
    set -euo pipefail
    step=''${1:-all}
    edition=''${2:-all}

    drv() {
      local attr=$1 name=$2
      # nixos-test-driver puts VM state (qcow2 images, sockets) under
      # XDG_RUNTIME_DIR, which is tmpfs on most systems and too small.
      export XDG_RUNTIME_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/nixos-test"
      mkdir -p "$XDG_RUNTIME_DIR"
      nix build ".#internal.$attr.driver" -o "result-$name"
      "./result-$name/bin/nixos-test-driver"
    }

    boot_test_all() {
      for e in mokka dr460nized catppuccin; do drv "boot-test-$e" "boot-$e"; done
    }

    cheap() {
      nix flake check
      nix build .#internal.ci-bare -o result-bare
      nix build .#internal.ci-full -o result-full
      drv installer-test installer-test
    }

    heavy() {
      drv installer-eval-test installer-eval-test
      drv installer-install-test installer-install-test
      boot_test_all
    }

    case "$step" in
      check) nix flake check ;;
      bare) nix build .#internal.ci-bare -o result-bare ;;
      full) nix build .#internal.ci-full -o result-full ;;
      installer) drv installer-test installer-test ;;
      eval) drv installer-eval-test installer-eval-test ;;
      install) drv installer-install-test installer-install-test ;;
      cheap) cheap ;;
      heavy) heavy ;;
      boot)
        case "$edition" in
          all) boot_test_all ;;
          mokka|dr460nized|catppuccin) drv "boot-test-$edition" "boot-$edition" ;;
          *) echo "usage: ci boot [mokka|dr460nized|catppuccin|all]" >&2; exit 1 ;;
        esac ;;
      all)
        cheap
        heavy ;;
      *) echo "usage: ci [check|bare|full|installer|eval|install|cheap|heavy|boot [edition]|all]" >&2; exit 1 ;;
    esac
  '';

  flake-update = pkgs.writeShellScriptBin "flake-update" ''
    set -euo pipefail
    nix flake update
    nix flake update --flake ./internal/updater --inputs-from . --override-input nixpkgs "nixpkgs"
    if git diff --exit-code; then
      echo "No changes to flake.lock"
      exit 0
    fi
    git config --global user.name "$GIT_AUTHOR_NAME"
    git config --global user.email "$GIT_AUTHOR_EMAIL"
    git add flake.lock internal/updater/flake.lock
    git commit -m 'chore(flake.lock): bump flakes'
    git push "$CI_REPOSITORY_URL" HEAD:main
    nix run nixpkgs#curl -- -X POST \
      -F "token=$CI_JOB_TOKEN" \
      -F "ref=main" \
      -F "variables[UPDATE]=false" \
      "$CI_API_V4_URL/projects/$CI_PROJECT_ID/trigger/pipeline"
  '';
in
{
  inherit ci flake-update;
  shell = pkgs.mkShell {
    packages = [
      ci
      flake-update
    ];
  };
}
