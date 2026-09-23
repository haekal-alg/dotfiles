#!/usr/bin/env python3
"""Two-line Claude Code statusline: model/effort/cwd/branch/5h+7d limits + context gauge."""
import getpass
import json
import os
import re
import sys
import time

BAR_CELLS = 22
LINE_BUDGET = 80   # target max display width for line 2; real width isn't detectable
MIN_PATH = 16      # never squeeze the path below this, even if the budget is blown
DIM = "\033[2m"
RESET = "\033[0m"
GREEN, YELLOW, RED = "\033[32m", "\033[33m", "\033[31m"
MODEL = "\033[1;36m"   # bold cyan: line 1's anchor, the one thing read at a glance
BRANCH = "\033[35m"    # magenta, undimmed, so it doesn't read as part of the path
SEP = f"{DIM} · {RESET}"


def human(n):
    if n is None:
        return "?"
    if n >= 1_000_000:
        v = n / 1_000_000
        return f"{v:.0f}M" if abs(v - round(v)) < 0.05 else f"{v:.1f}M"
    if n >= 1000:
        return f"{n / 1000:.0f}k"
    return str(n)


def shorten(path):
    if not path:
        return "?"
    home = os.path.expanduser("~")
    if path.startswith(home):
        return "~" + path[len(home):]
    # WSL: /mnt/c/Users/<me>/x -> C:~/x, but only when <me> is us. A different
    # Windows user keeps its own name, or "C:~" would be an outright lie.
    m = re.match(r"^/mnt/([a-z])/Users/([^/]+)(/.*)?$", path)
    if m:
        drive, winuser, rest = m.group(1).upper(), m.group(2), m.group(3) or ""
        if winuser.lower() == getpass.getuser().lower():
            return f"{drive}:~{rest}"
        return f"{drive}:/Users/{winuser}{rest}"
    m = re.match(r"^/mnt/([a-z])(/.*)?$", path)
    if m:
        return f"{m.group(1).upper()}:{m.group(2) or '/'}"
    return path


ANSI = re.compile(r"\x1b\[[0-9;]*m")


def visible_len(s):
    return len(ANSI.sub("", s))


def elide(path, budget):
    """Middle-elide to fit `budget` columns: keep the root, then as many trailing
    segments as fit. The last segment always survives (hard-truncated if it alone
    overflows) since it's what actually tells you where you are."""
    if len(path) <= budget:
        return path
    segs = path.lstrip("/").split("/")
    if len(segs) < 2:
        return path
    root = ("/" if path.startswith("/") else "") + segs[0]
    tail = "/" + segs[-1]
    for s in reversed(segs[1:-1]):
        cand = "/" + s + tail
        if len(root) + 2 + len(cand) > budget:
            break
        tail = cand
    out = root + "/…" + tail
    if len(out) > budget:
        keep = max(6, budget - len(root) - 4)
        out = root + "/…/…" + segs[-1][-keep:]
    return out


def git_branch(cwd):
    """Current branch, read straight out of .git/HEAD rather than by running git.
    The statusline is re-rendered on nearly every frame, so a subprocess per redraw
    (~10ms each, plus index locking) is a cost this can't justify for one string.

    Returns None outside a repo. Detached HEAD has no branch to name -- during a
    rebase, bisect, or on a checked-out tag this shows '@<short sha>', where git
    itself would say something like "(no branch, rebasing x)"."""
    if not cwd:
        return None
    d = cwd
    for _ in range(64):  # bounded walk: a symlink loop must not hang the line
        g = os.path.join(d, ".git")
        head = None
        if os.path.isdir(g):
            head = os.path.join(g, "HEAD")
        elif os.path.isfile(g):
            # worktree or submodule: .git is a file pointing at the real gitdir
            try:
                with open(g) as f:
                    m = re.match(r"gitdir:\s*(.+)", f.read().strip())
            except OSError:
                m = None
            if m:
                p = m.group(1)
                head = os.path.join(p if os.path.isabs(p) else os.path.join(d, p), "HEAD")
        if head:
            try:
                with open(head) as f:
                    txt = f.read().strip()
            except OSError:
                return None
            if txt.startswith("ref: refs/heads/"):
                return txt[len("ref: refs/heads/"):] or None
            if re.fullmatch(r"[0-9a-f]{7,40}", txt):
                return "@" + txt[:7]
            return None
        parent = os.path.dirname(d)
        if parent == d:
            return None
        d = parent
    return None


def model_label(name):
    """'Opus 5 (1M context)' -> 'Opus 5 1M'; leaves other display names alone."""
    return re.sub(r"\s*\((\d+M) context\)", r" \1", name)


def pct_color(pct):
    return GREEN if pct < 60 else (YELLOW if pct < 85 else RED)


def until(resets_at, coarse):
    """Countdown to a unix-epoch reset. coarse='h' -> '2h 14m', coarse='d' -> '4d 06h'."""
    if not isinstance(resets_at, (int, float)):
        return None
    left = max(0, int(resets_at - time.time()))
    if coarse == "d":
        return f"{left // 86400}d {left % 86400 // 3600:02d}h"
    return f"{left // 3600}h {left % 3600 // 60:02d}m"


def limit_seg(window, label, coarse):
    """Always render, so line 1 keeps a stable width before rate_limits arrives."""
    pct = (window or {}).get("used_percentage")
    if not isinstance(pct, (int, float)):
        return f"{DIM}{label} —{RESET}"
    seg = f"{DIM}{label}{RESET} {pct_color(pct)}{pct:.0f}%{RESET}"
    left = until((window or {}).get("resets_at"), coarse)
    return f"{seg} {DIM}↺ {left}{RESET}" if left else seg


def gauge(pct):
    # threshold colors: comfortable / getting tight / compact imminent
    color = GREEN if pct < 60 else (YELLOW if pct < 85 else RED)
    filled = max(0, min(BAR_CELLS, round(pct / 100 * BAR_CELLS)))
    return f"{DIM}▕{RESET}{color}{'█' * filled}{RESET}{DIM}{'░' * (BAR_CELLS - filled)}▏{RESET}"


def main():
    try:
        d = json.load(sys.stdin)
    except Exception:
        return

    # --- line 1: model + limits (path lives on line 2 to keep this line tight) ---
    parts = [f"{MODEL}{model_label(d.get('model', {}).get('display_name') or '?')}{RESET}"]
    effort = d.get("effort", {}).get("level")
    if effort:
        parts[0] += f"{DIM} [{effort}]{RESET}"

    rl = d.get("rate_limits") or {}
    parts.append(limit_seg(rl.get("five_hour"), "5h", "h"))
    parts.append(limit_seg(rl.get("seven_day"), "7d", "d"))

    lines = [SEP.join(parts)]

    # --- line 2: context gauge + cwd + branch ---
    cw = d.get("context_window") or {}
    pct = cw.get("used_percentage")
    if isinstance(pct, (int, float)):
        used = cw.get("total_input_tokens")
        size = cw.get("context_window_size")
        seg = [
            f"{DIM}ctx{RESET} {gauge(pct)} {pct_color(pct)}{pct:.0f}%{RESET}",
            f"{DIM}{human(used)}/{human(size)}{RESET}",
        ]
    else:
        # no API call yet this session
        seg = [f"{DIM}ctx —{RESET}"]
    cwd = d.get("workspace", {}).get("current_dir")
    branch = git_branch(cwd)
    # branch is fixed-width by nature and always fully shown; the path is the one
    # elastic piece, so it absorbs the budget the ctx and branch segments leave over
    # (a cold start, with its short prefix, shows more path than a full gauge does)
    tail = f"{SEP}{DIM}⎇{RESET} {BRANCH}{branch}{RESET}" if branch else ""
    prefix = SEP.join(seg)
    room = max(MIN_PATH,
               LINE_BUDGET - visible_len(prefix) - visible_len(SEP) - visible_len(tail))
    path = elide(shorten(cwd), room)
    lines.append(f"{prefix}{SEP}{DIM}{path}{RESET}{tail}")

    sys.stdout.write("\n".join(lines))


main()
