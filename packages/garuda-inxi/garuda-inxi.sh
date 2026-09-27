#!/usr/bin/env bash

if [ -t 1 ]; then
  c_134=$'\033[1;34m'
  c_131=$'\033[1;31m'
  c_off=$'\033[0m'
else
  c_134=""
  c_131=""
  c_off=""
  c0="c0"
fi

OPTIONS_FILE="/etc/garuda-nix/enabled-options"

detect_dual_boot() {
  if [[ $EUID -eq 0 ]] && command -v os-prober &>/dev/null; then
    local out
    out="$(os-prober)" || {
      DUALBOOT="Os-prober error"
      return
    }
    echo "$out" | grep -q "Windows Boot Manager" &>/dev/null && DUALBOOT="Yes" || DUALBOOT="No/Undetected"
  elif command -v efibootmgr &>/dev/null && [ -d /boot/efi ]; then
    local out
    out="$(efibootmgr)" || {
      DUALBOOT="Efibootmgr error"
      return
    }
    echo "$out" | grep -q "Windows Boot Manager" &>/dev/null && DUALBOOT="Probably (Run as root to verify)" || DUALBOOT="No/Undetected"
  elif command -v os-prober &>/dev/null; then
    DUALBOOT="<superuser required>"
  else
    DUALBOOT="No detection tool installed"
  fi
}

detect_snapshots() {
  if [ -d /.snapshots ] || systemctl is-enabled snapper-timeline.timer &>/dev/null; then
    printf "snapper "
  fi
}

generate_relevant_software() {
  local RELEVANT=()
  systemctl is-active NetworkManager.service &>/dev/null && RELEVANT+=("NetworkManager")
  { [ -e /run/current-system/systemd/bin/systemd-boot ] || command -v grub-install &>/dev/null; } && RELEVANT+=("bootloader")
  lsmod 2>/dev/null | grep -q "^nvidia " && RELEVANT+=("nvidia")
  if [ -r "$OPTIONS_FILE" ]; then
    while IFS= read -r opt; do
      [ -n "$opt" ] && RELEVANT+=("$opt")
    done <"$OPTIONS_FILE"
  fi
  detect_snapshots
  local out="${RELEVANT[*]}"
  [ -z "$out" ] && out="None"
  echo "$out"
}

generate_system_info() {
  local gen gen_date flake_date reboot="" cur link n
  cur="$(readlink /run/current-system 2>/dev/null || true)"
  gen=""
  for link in /nix/var/nix/profiles/system-*-link; do
    [ -e "$link" ] || continue
    if [ "$(readlink "$link" 2>/dev/null)" = "$cur" ]; then
      n="${link##*/system-}"
      gen="${n%-link}"
    fi
  done
  gen_date="$(stat -c %y /run/current-system 2>/dev/null | cut -d' ' -f1 || echo Unknown)"
  if [ -f /etc/nixos/flake.lock ]; then
    flake_date="$(stat -c %y /etc/nixos/flake.lock 2>/dev/null | cut -d' ' -f1)"
  else
    flake_date="Unknown"
  fi
  if [ "$(readlink /run/booted-system 2>/dev/null)" != "$(readlink /run/current-system 2>/dev/null)" ]; then
    reboot=" ${c_131}↻${c_off}"
  fi
  echo -e "gen ${gen:-Unknown} (${gen_date})${reboot}, flake inputs updated: ${flake_date}"
}

inxi -Faz"${c0:-}" --zv

echo -e "${c_134}Garuda Nix (subsystem v$(cat /etc/garuda-nix/subsystem-version 2>/dev/null || echo "?")):${c_off}"
echo -e "${c_134}  System install date:${c_off}     $(stat -c %w / 2>/dev/null | cut -d' ' -f1 || tune2fs -l "$(findmnt -no SOURCE /)" 2>/dev/null | awk -F': *' '/Filesystem created/{print $2}' || echo Unknown)"
if [ -f /etc/os-release ]; then
  # shellcheck disable=SC1091
  echo -e "${c_134}  Garuda release:${c_off}          $({ . /etc/os-release && echo "$PRETTY_NAME $BUILD_ID"; } 2>/dev/null)"
fi
echo -e "${c_134}  Last full system update:${c_off} $(generate_system_info)"
echo -e "${c_134}  Relevant software:      ${c_off} $(generate_relevant_software)"
detect_dual_boot &>/dev/null
echo -e "${c_134}  Windows dual boot:      ${c_off} ${DUALBOOT}"
echo -e "${c_134}  Failed units:           ${c_off} $(systemctl list-units --failed --full --all --plain --no-legend | awk '{printf("%s ",$1)}')"
if [ "${1:-}" == "funstuff" ]; then
  count="$(nix-env -p /nix/var/nix/profiles/system --list-generations 2>/dev/null | wc -l)"
  echo -e "${c_134}  Total system generations:${c_off} ${count}"
fi
