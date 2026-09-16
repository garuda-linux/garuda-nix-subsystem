import json
import subprocess
import sys


def new_state():
    return {"active": {}, "done": 0, "current": ""}


def update(state, line):
    if not line.startswith("@nix "):
        return None
    try:
        event = json.loads(line[5:])
    except ValueError:
        return None
    action = event.get("action")
    if action == "start":
        state["active"][str(event.get("id"))] = event.get("text", "")
        state["current"] = event.get("text", "")
    elif action in ("stop", "result"):
        if str(event.get("id")) in state["active"]:
            del state["active"][str(event.get("id"))]
            state["done"] += 1
    elif action == "msg":
        state["current"] = event.get("msg", "")
    else:
        return None
    current = " ".join(state["current"].split())
    if len(current) > 100:
        current = current[:99] + "\u2026"
    return f"[{state['done']} done] {current}".rstrip()


def run(cmd):
    state = new_state()
    tty = sys.stderr.isatty()
    shown = ""
    proc = subprocess.Popen(
        cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        text=True, errors="replace",
    )
    for line in proc.stdout:
        status = update(state, line.rstrip("\n"))
        if status is None:
            if tty:
                sys.stderr.write("\r" + " " * len(shown) + "\r")
                shown = ""
            sys.stderr.write(line)
        elif tty:
            sys.stderr.write("\r" + status + " " * max(0, len(shown) - len(status)))
            shown = status
        elif status != shown:
            print(status, flush=True, file=sys.stderr)
            shown = status
    proc.wait()
    if tty:
        sys.stderr.write("\n")
    elif shown:
        print(f"finished rc={proc.returncode}", flush=True, file=sys.stderr)
    return proc.returncode
