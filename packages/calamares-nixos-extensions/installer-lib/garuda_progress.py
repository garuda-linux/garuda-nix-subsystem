import json
import subprocess
import sys
import time
from collections import deque

SPINNER = "⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

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


def render(state, tick=0):
    active = len(state["active"])
    elapsed = int(time.monotonic() - state.get("started", time.monotonic()))
    spin = SPINNER[tick % len(SPINNER)]
    current = _clean(state.get("current", ""))
    head = f"{spin} {state['done']} done, {active} active [{elapsed // 60}:{elapsed % 60:02d}]"

    if current:
        return f"{head} {current}".rstrip()

    return head


def _clear_line():
    sys.stderr.write("\r\x1b[2K")


def run(cmd, throttle=0.1):
    state = new_state()
    tail = deque(maxlen=30)
    tty = sys.stderr.isatty()
    shown = ""
    tick = 0
    last_draw = 0.0

    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace",
    )

    assert proc.stdout is not None

    for line in proc.stdout:
        line = line.rstrip("\n")
        status = update(state, line, tail)
        now = time.monotonic()

        if status is None:
            tail.append(line)

            if any(line.lower().startswith(p) for p in NOISY_PREFIXES):
                continue

            if tty:
                _clear_line()
                shown = ""

            sys.stderr.write(line + "\n")
            sys.stderr.flush()

        elif tty:
            tick += 1

            if status != shown or now - last_draw >= throttle:
                _clear_line()
                status = render(state, tick)
                sys.stderr.write(status)
                sys.stderr.flush()
                shown = status
                last_draw = now

        elif status != shown:
            print(status, flush=True, file=sys.stderr)
            shown = status

    proc.wait()

    total = int(time.monotonic() - state["started"])

    if tty:
        _clear_line()

        sys.stderr.write(
            f"✓ {state['done']} steps finished "
            f"in {total // 60}:{total % 60:02d} "
            f"(rc={proc.returncode})\n"
        )

        sys.stderr.flush()

    elif shown:
        print(f"finished {state['done']} steps "
              f"rc={proc.returncode}", flush=True, file=sys.stderr)

    if proc.returncode != 0 and tail:
        sys.stderr.write("\nLast output:\n")

        for entry in tail:
            sys.stderr.write(entry + "\n")

        sys.stderr.flush()

    return proc.returncode
