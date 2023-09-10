# The smallest and KISSer continuos-deploy I was able to create.
{ all-packages
, garuda-lib
, self
, system
}:
let
  nixos = (garuda-lib.garudaSystem { inherit system; modules = [{ }]; }).config.system.build;
  version = builtins.toString garuda-lib.garuda-lib.version;
in
all-packages.writeShellApplication {
  name = "gns-update";
  runtimeInputs = with all-packages; [ util-linux btrfs-progs coreutils mktemp jq nixos.nixos-install nix ];

  text = ''
    function configureGNS {
      config="$(cat "$MNT_DIR/etc/nixos/garuda-managed.json")"

      if [ "$FROM_HOST" == "true" ]; then
        config="$(jq 'del(.v1.users) | del(.v1.locale) | del(.v1.keymap) | del(.v1.timezone)' <<<"$config")"
        # Loop over all users
        while IFS=: read -r user _ uid _ _ home _; do
          if [[ $uid -ge 1000 && $home == /home/* ]]; then
            hashed_password=$(grep "^$user:" /etc/shadow | cut -d: -f2)
            groups "$user" | grep -qE '\b(sudo|wheel)\b' && is_admin=true || is_admin=false
            config="$(jq --arg user "$user" --arg uid "$uid" --arg hashed_password "$hashed_password" --arg home "$home" --arg wheel "$is_admin" '.v1.users += [{"name":$user, "uid":$uid|tonumber, "hashed_password":$hashed_password, "home":$home, "wheel":$wheel | test("true")}]' <<<"$config")"
          fi
        done </etc/passwd

        if [ -f /etc/locale.conf ]; then
          while IFS= read -r line; do
            key=''${line%%=*}
            value=''${line#*=}
            config="$(jq --arg key "$key" --arg value "$value" '.v1.locale += {($key):$value}' <<<"$config")"
          done < <(grep -E '^[a-zA-Z_]+=.+$' /etc/locale.conf)
        fi
        # keymap
        if [ -f /etc/vconsole.conf ]; then
          keymap="$(grep '^KEYMAP=' /etc/vconsole.conf | cut -d= -f2)"
          if [ -n "$keymap" ]; then
            config="$(jq --arg keymap "$keymap" '.v1.keymap=$keymap' <<<"$config")"
          fi
        fi
        # timezone
        if [ -f /etc/timezone ]; then
          timezone="$(cat /etc/timezone)"
          if [ -n "$timezone" ]; then
            config="$(jq --arg timezone "$timezone" '.v1.timezone=$timezone' <<<"$config")"
          fi
        fi

        packages="$(pacman -Qq garuda-nvidia-config garuda-nvidia-prime-config 2> /dev/null | xargs || true)"
        if [[ "$packages" =~ (^| )garuda-nvidia-prime-config($| ) ]]; then
          config="$(jq '.v1.hardware.nvidia=prime' <<<"$config")"
        elif [[ "$packages" =~ (^| )garuda-nvidia-config($| ) ]]; then
          config="$(jq '.v1.hardware.nvidia=nvidia' <<<"$config")"
        fi
      fi

      VIRT="$(systemd-detect-virt || echo "none")"
      jq --arg UUID "$BTRFS_UUID" --arg VIRT "$VIRT" --arg version "${version}" '.version=($version|tonumber) | .v1.uuid=$UUID | .v1.hardware.virt=$VIRT' <<<"$config" >"$MNT_DIR/etc/nixos/garuda-managed.json"
    }

    if [[ $EUID -ne 0 ]]; then
      exec sudo "$0" "$@"
      exit 1
    fi

    unset TMPDIR

    INSTALLING="''${GNS_INSTALLING:-false}"
    if [[ $INSTALLING == "true" ]]; then
      GNS_FROM_HOST=true
    fi
    FROM_HOST="''${GNS_FROM_HOST:-false}"
    BTRFS_UUID="''${GNS_BTRFS_UUID:-}"
    MNT_DIR="''${GNS_MNT_DIR:-}"

    if [[ -v BTRFS_UUID ]]; then
      BTRFS_UUID="$(findmnt -n -o UUID /)"
    fi
    if [[ -v MNT_DIR ]] && [ "$FROM_HOST" == "true" ]; then
      echo -e "\033[1;33m-->\033[1;34m Mounting Garuda Nix Subsystem subvolumes\033[0m"
      MNT_DIR=$(mktemp -d)
      mount -o subvol=@nix-subsystem "UUID=$BTRFS_UUID" "$MNT_DIR"
      mkdir -p "$MNT_DIR/nix"
      mount -o subvol=@nix "UUID=$BTRFS_UUID" "$MNT_DIR/nix"
    fi

    MNT_DIR="''${MNT_DIR:-""}"

    if [ ! -f "$MNT_DIR/etc/nixos/garuda-managed.json" ]; then
      echo -e "\033[1;31mError: Garuda Nix Subsystem is not configured for automatic management. (Missing garuda-managed.json) ❌\033[0m";
      exit 1
    fi

    if [ -v HOSTNAME ]; then
      HOSTNAME=$(jq -r '.hostname' "$MNT_DIR/etc/nixos/garuda-managed.json")
    fi

    echo -e "\033[1;33m-->\033[1;34m Configuring Garuda Nix Subsystem\033[0m"
    configureGNS

    if [ "$INSTALLING" == "true" ]; then
      echo -e "\033[1;33m-->\033[1;34m Installing Garuda Nix Subsystem 🍵\033[0m"
    else
      echo -e "\033[1;33m-->\033[1;34m Updating Garuda Nix Subsystem 🍵\033[0m"
    fi
    nix flake update "$MNT_DIR/etc/nixos" --override-input garuda "${self}"
    if [ "$FROM_HOST" == "true" ]; then
      nixos-install -j auto --no-root-password --root "$MNT_DIR" --flake "$MNT_DIR/etc/nixos#$HOSTNAME"
    elif [ "$INSTALLING" == "false" ]; then
      nixos-rebuild -j auto --flake "$MNT_DIR/etc/nixos#$HOSTNAME" boot
    else
      echo ..What?
      exit 1
    fi

    if [ "$FROM_HOST" == "true" ]; then
      echo -e "\n\033[1;33m-->\033[1;34m Unmounting Garuda Nix Subsystem subvolumes\033[0m\n"
      umount "$MNT_DIR/nix"
      umount "$MNT_DIR"
      rmdir "$MNT_DIR"
    fi

    if [ "$FROM_HOST" == "true" ]; then
      cat >"/etc/grub.d/25-garudanix" <<-EOF
    #!/bin/sh
    exec tail -n +3 \$0

    menuentry 'Garuda Linux Nix Subsystem' --class garuda --class gnu-linux --class gnu --class os {
      configfile /@nix-subsystem/boot/grub/grub.cfg
    }
    EOF
      chmod +x "/etc/grub.d/25-garudanix"
      /usr/bin/update-grub
    fi
  '';
}
