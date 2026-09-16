{
  lib,
  writeShellApplication,
  btrfs-progs,
}:

writeShellApplication {
  name = "garuda-fs-diff";

  runtimeInputs = [ btrfs-progs ];

  text = ''
    set -euo pipefail
    OLD_TRANSID=$(btrfs subvolume find-new /mnt/root-blank 9999999)
    OLD_TRANSID=''${OLD_TRANSID#transid marker was }

    btrfs subvolume find-new "/mnt/root" "$OLD_TRANSID" |
    sed '$d' |
    cut -f17- -d' ' |
    sort |
    uniq |
    while read -r path; do
      path="/$path"
      if [ -L "$path" ]; then
        :
      elif [ -d "$path" ]; then
        :
      else
        echo "$path"
      fi
    done
  '';

  meta = with lib; {
    description = "Diff btrfs root against the blank snapshot";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "garuda-fs-diff";
  };
}
