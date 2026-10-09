{
  all-packages,
  gns-update,
}:
all-packages.writeShellApplication {
  name = "garuda-nix-subsystem";
  runtimeInputs = with all-packages; [
    gns-update
    coreutils
  ];
  text = ''
    case "''${1:-}" in
      update)
        shift
        exec gns-update "$@"
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
