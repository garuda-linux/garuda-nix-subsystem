import json
import os
import select
import subprocess
import sys
import time
from collections import deque

SPINNER = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"
SPIN_EVERY = 0.1

NOISY_PREFIXES = ("warning: ",)


def new_state():
    return {"active": {}, "order": [], "done": 0, "current": "",
            "started": time.monotonic()}


def _clean(text, limit=100):
    text = " ".join(str(text).split())

    if len(text) > limit:
        text = text[: limit - 1] + "…"

    return text


def update(state, line, tail):
    if not line.startswith("@nix "):
        return None

    try:
        event = json.loads(line[5:])
    except ValueError:
        return None

    action = event.get("action")

    if action == "start":
        key = str(event.get("id"))
        state["active"][key] = event.get("text", "")

        if key not in state["order"]:
            state["order"].append(key)

        state["current"] = event.get("text", "")

    elif action in ("stop", "result"):
        key = str(event.get("id"))

        if key in state["active"]:
            del state["active"][key]
            state["done"] += 1

        for key in reversed(state["order"]):
            if key in state["active"]:
                state["current"] = state["active"][key]
                break

        else:
            state["current"] = ""

    elif action == "msg":
        msg = event.get("msg", "")
        state["current"] = msg

        if msg:
            tail.append(msg)

    else:
        return None

    return render(state)


def render(state):
    now = time.monotonic()
    elapsed = now - state.get("started", now)
    spin = SPINNER[int(elapsed / SPIN_EVERY) % len(SPINNER)]
    secs = int(elapsed)
    current = _clean(state.get("current", ""))
    head = f"{spin} {state['done']} done, {len(state['active'])} active [{secs // 60}:{secs % 60:02d}]"

    if current:
        return f"{head} {current}".rstrip()

    return head


def _clear_line():
    sys.stderr.write("\r\x1b[2K")


def _draw(text):
    _clear_line()
    try:
        width = os.get_terminal_size(sys.stderr.fileno()).columns
    except OSError:
        width = 80

    if len(text) > width:
        text = text[: max(width - 1, 1)] + "…"

    sys.stderr.write(text)
    sys.stderr.flush()


def run(cmd, throttle=0.1):
    state = new_state()
    tail = deque(maxlen=30)
    tty = sys.stderr.isatty()
    shown = ""
    last_draw = 0.0

    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace",
    )

    assert proc.stdout is not None

    def handle(line):
        nonlocal shown, last_draw

        line = line.rstrip("\n")
        status = update(state, line, tail)

        if status is None:
            tail.append(line)

            if any(line.lower().startswith(p) for p in NOISY_PREFIXES):
                return

            if tty:
                state["current"] = line
                now = time.monotonic()

                if now - last_draw >= throttle:
                    shown = render(state)
                    _draw(shown)
                    last_draw = now

                return

            sys.stderr.write(line + "\n")
            sys.stderr.flush()

            return

        now = time.monotonic()

        if tty:
            if status != shown or now - last_draw >= throttle:
                shown = render(state)
                _draw(shown)
                last_draw = now

        elif status != shown:
            print(status, flush=True, file=sys.stderr)
            shown = status

    while True:
        ready, _, _ = select.select([proc.stdout], [], [], throttle)

        if not ready:
            if tty:
                if proc.poll() is not None:
                    for line in proc.stdout:
                        handle(line)

                    break

                shown = render(state)
                _draw(shown)

            continue

        line = proc.stdout.readline()

        if not line:
            break

        handle(line)

    proc.wait()

    total = int(time.monotonic() - state["started"])
    mark = "✓" if proc.returncode == 0 else "✗"

    if tty:
        _clear_line()

        sys.stderr.write(
            f"{mark} {state['done']} steps finished "
            f"in {total // 60}:{total % 60:02d} "
            f"(rc={proc.returncode})\n"
        )

        sys.stderr.flush()

    elif shown:
        print(f"{mark} finished {state['done']} steps "
              f"rc={proc.returncode}", flush=True, file=sys.stderr)

    if proc.returncode != 0 and tail:
        sys.stderr.write("\nLast output:\n")

        for entry in tail:
            sys.stderr.write(entry + "\n")

        sys.stderr.flush()

    return proc.returncode
