{
  all-packages,
  garuda-update,
}:
all-packages.writeShellApplication {
  name = "garuda-nix-subsystem";
  runtimeInputs = with all-packages; [
    garuda-update
    coreutils
  ];
  text = ''
    case "''${1:-}" in
      update)
        shift
        exec garuda-update "$@"
        ;;
      *)
        echo "garuda-nix-subsystem - Garuda NixOS Subsystem management tool"
        echo ""
        echo "Usage: garuda-nix-subsystem <command> [options]"
        echo ""
        echo "Commands:"
        echo "  update    Update the Garuda Nix Subsystem"
        exit 1
        ;;
    esac
  '';
}
