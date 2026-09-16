#!/usr/bin/env python3
import json
import subprocess
import sys

REPO_DIR = sys.argv[1] if len(sys.argv) > 1 else "/tmp/repo"

BASE = """{
  garuda.impermanence.enable = true;
  garuda.impermanence.tmpfsRoot = true;
  garuda.impermanence.persistentUsers = [ "test" ];
  users.users.test = { isNormalUser = true; };
  boot.loader.grub.enable = false;
  boot.initrd.systemd.enable = false;
  fileSystems."/" = { device = "/dev/vda1"; fsType = "ext4"; };
}"""

EXPR = """let
  f = builtins.getFlake "git+file://{repo}";
  sys = f.lib.garudaSystem {{
    system = "x86_64-linux";
    modules = [ {base} {extra} ];
  }};
  persist = sys.config.environment.persistence."/persist";
in {{
  dirs = map (d: d.dirPath) persist.directories;
  files = map (f: f.filePath) persist.files;
  users = builtins.mapAttrs
    (n: u: map (d: d.dirPath) u.directories)
    persist.users;
}}"""

TOPLEVEL = """let
  f = builtins.getFlake "git+file://{repo}";
  sys = f.lib.garudaSystem {{
    system = "x86_64-linux";
    modules = [ {base} {extra} ];
  }};
in sys.config.system.build.toplevel.drvPath"""

CHEAP_SERVICES = """{
  networking.networkmanager.enable = true;
  networking.wireless.iwd.enable = true;
  hardware.bluetooth.enable = true;
  programs.steam.enable = true;
  services.printing.enable = true;
  services.fprintd.enable = true;
  services.geoclue2.enable = true;
  services.chrony.enable = true;
  services.zerotierone.enable = true;
  garuda.samba.enable = true;
}"""

OPT_IN_APPS = (
    'garuda.impermanence.apps = [ "sops" "secureboot" "mysql" "wireguard"'
    ' "password-store" "tuwunel" "forgejo" "loki" "prometheus" "traefik"'
    ' "vaultwarden" "adguardhome" "lldap" "mastodon" "n8n" "vikunja" "wakapi"'
    ' "cryptpad" "nextcloud" "fail2ban" "acme" ];'
)

CASES = [
    {
        "name": "base",
        "extra": "",
        "dirs": [
            "/etc/nixos", "/var/lib/systemd", "/var/lib/nixos",
            "/var/lib/alsa", "/var/lib/colord", "/var/spool",
        ],
        "files": ["/etc/machine-id", "/etc/adjtime", "/etc/ssh/ssh_host_ed25519_key"],
        "user_dirs": [".config", ".local/share", ".local/state", ".ssh", ".gnupg"],
    },
    {
        "name": "services-auto",
        "extra": CHEAP_SERVICES,
        "dirs": [
            "/var/lib/NetworkManager", "/etc/NetworkManager/system-connections",
            "/var/lib/iwd", "/var/lib/bluetooth", "/etc/cups",
            "/var/lib/samba", "/var/lib/fprint", "/var/lib/geoclue",
            "/var/lib/zerotier-one",
        ],
        "user_dirs": [".steam"],
    },
    {
        "name": "apps-opt-in-services-off",
        "extra": "{ " + OPT_IN_APPS + " }",
        "dirs": [
            "/var/lib/sops-nix", "/etc/secureboot", "/var/lib/mysql",
            "/etc/wireguard", "/var/lib/tuwunel", "/var/lib/forgejo",
            "/var/lib/loki", "/var/lib/prometheus2", "/var/lib/traefik",
            "/var/lib/vaultwarden", "/var/lib/AdGuardHome", "/var/lib/lldap",
            "/var/lib/mastodon", "/var/lib/nextcloud", "/var/lib/fail2ban",
            "/var/lib/acme",
        ],
        "user_dirs": [".password-store"],
    },
]


def nix_eval(expr):
    return subprocess.run(
        ["nix", "--extra-experimental-features", "nix-command flakes",
         "eval", "--impure", "--json", "--expr", expr],
        capture_output=True, text=True, check=False)


def evaluate(extra):
    r = nix_eval(EXPR.format(repo=REPO_DIR, base=BASE, extra=extra))
    assert r.returncode == 0, r.stderr[-2000:]
    return json.loads(r.stdout)


def main():
    for case in CASES:
        got = evaluate(case["extra"])
        missing = [d for d in case.get("dirs", []) if d not in got["dirs"]]
        assert not missing, f"{case['name']}: missing dirs {missing}"
        missing = [fl for fl in case.get("files", []) if fl not in got["files"]]
        assert not missing, f"{case['name']}: missing files {missing}"
        user_dirs = got["users"]["test"]
        missing = [d for d in case.get("user_dirs", [])
                   if not any(d in u for u in user_dirs)]
        assert not missing, f"{case['name']}: missing user dirs {missing}"
        print(f"PASS {case['name']}")

    r = nix_eval(EXPR.format(repo=REPO_DIR, base=BASE,
                             extra='{ garuda.impermanence.apps = [ "nope" ]; }'))
    assert r.returncode != 0, "bogus app name evaluated successfully"
    print("PASS bogus-app-rejected")

    r = nix_eval(TOPLEVEL.format(repo=REPO_DIR, base=BASE, extra=""))
    assert r.returncode == 0, r.stderr[-2000:]
    print("PASS tmpfs-root-builds")

    ext4 = BASE.replace("  garuda.impermanence.tmpfsRoot = true;\n", "")
    r = nix_eval(TOPLEVEL.format(repo=REPO_DIR, base=ext4, extra=""))
    assert r.returncode != 0, "ext4 / without tmpfsRoot evaluated successfully"
    assert "garuda.impermanence" in r.stderr, r.stderr[-2000:]
    print("PASS ext4-root-rejected")

    print("impermanence-check OK")


if __name__ == "__main__":
    main()
