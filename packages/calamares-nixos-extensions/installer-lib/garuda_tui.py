#!/usr/bin/env python3
class Aborted(Exception):
    pass


def _ask(value):
    if value is None:
        raise Aborted("aborted by user")
    return value


def run_wizard(q, args, editions, features, presets, disks, schemas):
    if args.edition is None:
        args.edition = _ask(q.select("Edition:", choices=list(editions)).ask())
    if args.preset is None and args.feature == []:
        picked = _ask(q.select("Preset:",
                               choices=["none"] + list(presets)).ask())
        args.preset = None if picked == "none" else picked
    if args.feature == [] and args.preset is None:
        args.feature = _ask(q.checkbox("Features (space to toggle):",
                                       choices=sorted(features)).ask())
    if args.disk is None and not args.root_mounted:
        choices = ["leave as-is"] + [label for _, label in disks]
        picked = _ask(q.select("Disk to install onto:",
                               choices=choices).ask())
        if picked != "leave as-is":
            args.disk = disks[choices.index(picked) - 1][0]
    if args.disk is not None and args.schema is None:
        args.schema = _ask(q.select("Partitioning schema:",
                                    choices=list(schemas)).ask())
    args.hostname = _ask(q.text("Hostname:", default=args.hostname).ask())
    args.username = _ask(q.text("Username:", default=args.username).ask())
    if args.password is None:
        first = _ask(q.password(f"Password for {args.username}:").ask())
        second = _ask(q.password("Repeat password:").ask())
        if not first or first != second:
            raise Aborted("passwords do not match or are empty")
        args.password = first
    if args.disk is not None and not args.yes:
        ok = _ask(q.confirm(f"WIPE {args.disk} with schema "
                            f"'{args.schema}'?", default=False).ask())
        if not ok:
            raise Aborted("aborted by user")
    return args
