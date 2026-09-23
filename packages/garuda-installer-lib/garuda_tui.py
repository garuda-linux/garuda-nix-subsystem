#!/usr/bin/env python3
class Aborted(Exception):
    pass


def _ask(value):
    if value is None:
        raise Aborted("aborted by user")

    return value


def _pick_features(q, args, features, presets):
    import garuda_template as gt

    while True:
        if args.preset is None:
            picked = _ask(q.checkbox("Features (space to toggle):",
                                     choices=sorted(features)).ask())

        else:
            excluded = gt.PRESET_EXCLUDES.get(args.preset)
            picked = _ask(q.checkbox("Features (space to toggle):",
                                     choices=sorted(f for f in features
                                                    if f != excluded)).ask())

        if not picked:
            cont = _ask(q.confirm("No features selected. Continue?",
                                  default=True).ask())

            if not cont:
                continue

            return picked

        try:
            gt.check_feature_conflicts(picked)
        except ValueError as e:
            msg = str(e)

            if msg:
                msg = msg[0].upper() + msg[1:]

            retry = _ask(q.confirm(f"{msg}. Reselect?",
                                       default=True).ask())

            if not retry:
                raise Aborted(str(e))

            continue

        return picked


def run_wizard(q, args, editions, features, presets, disks):
    if args.edition is None:
        args.edition = _ask(q.select("Edition:", choices=list(editions)).ask())

    if args.preset is None and args.feature == []:
        picked = _ask(q.select("Preset:",
                               choices=["none"] + list(presets)).ask())
        args.preset = None if picked == "none" else picked

    if args.feature == []:
        args.feature = _pick_features(q, args, features, presets)

    if args.disk is None and not args.root_mounted:
        labels = [label for _, label in disks]
        choices = ["leave as-is"] + [
            label if labels.count(label) == 1 else f"{label} ({dev})"
            for dev, label in disks
        ]
        picked = _ask(q.select("Disk to install onto:",
                               choices=choices).ask())

        if picked != "leave as-is":
            args.disk = disks[choices.index(picked) - 1][0]

    if args.disk is not None and args.schema is None:
        import garuda_partition as gp

        args.schema = _ask(q.select("Partitioning schema:",
                                    choices=list(
                                        gp.schemas_for_features(args.feature))).ask())

    args.hostname = _ask(q.text("Hostname:", default=args.hostname).ask())
    args.username = _ask(q.text("Username:", default=args.username).ask())

    if args.password is None:
        for attempt in range(3):
            first = _ask(q.password(f"Password for {args.username}:").ask())
            second = _ask(q.password("Repeat password:").ask())

            if first and first == second:
                args.password = first
                break

            if attempt < 2:
                retry = q.confirm(
                    "Passwords do not match or are empty. Retry?",
                    default=True).ask()

                if not retry:
                    raise Aborted("passwords do not match or are empty")

            else:
                raise Aborted("passwords do not match or are empty")

    if args.disk is not None and not args.yes:
        ok = _ask(q.confirm(f"WIPE {args.disk} with schema "
                            f"'{args.schema}'?", default=False,
                            auto_enter=False).ask())

        if not ok:
            raise Aborted("aborted by user")

    return args
