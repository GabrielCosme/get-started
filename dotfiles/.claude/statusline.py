#!/usr/bin/env python3
"""Claude Code status line: model, effort, cost, context bar, rate-limit bars."""
import json
import sys
import time

RESET = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"
CYAN = "\033[36m"
MAGENTA = "\033[35m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"

BAR_WIDTH = 10


def color_for(pct):
    if pct >= 80:
        return RED
    if pct >= 50:
        return YELLOW
    return GREEN


def bar(pct):
    shown = max(0.0, min(100.0, pct))
    filled = round(shown / 100 * BAR_WIDTH)
    c = color_for(pct)
    return f"{c}{'█' * filled}{DIM}{'░' * (BAR_WIDTH - filled)}{RESET} {c}{pct:.0f}%{RESET}"


def until(epoch):
    secs = int(epoch - time.time())
    if secs <= 0:
        return "now"
    days, rem = divmod(secs, 86400)
    hours, rem = divmod(rem, 3600)
    mins = rem // 60
    if days:
        return f"{days}d{hours}h"
    if hours:
        return f"{hours}h{mins:02d}m"
    return f"{mins}m"


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        print("statusline: bad input")
        return

    sep = f" {DIM}│{RESET} "

    # Model, effort, cost, context window
    parts = []
    model = (data.get("model") or {}).get("display_name") or "?"
    parts.append(f"{BOLD}{CYAN}{model}{RESET}")

    effort = (data.get("effort") or {}).get("level")
    if effort:
        parts.append(f"{MAGENTA}✦ {effort}{RESET}")

    cost = (data.get("cost") or {}).get("total_cost_usd")
    if cost is not None:
        parts.append(f"${cost:.2f}")

    ctx = data.get("context_window") or {}
    used = ctx.get("used_percentage")
    if used is None:
        used = 0
    parts.append(f"ctx {bar(used)}")

    # Rate limits
    limits = data.get("rate_limits") or {}
    for key, label in (("five_hour", "5h"), ("seven_day", "7d"), ("spend_limit", "spend")):
        win = limits.get(key)
        if not win or win.get("used_percentage") is None:
            continue
        seg = f"{label} {bar(win['used_percentage'])}"
        if win.get("resets_at"):
            seg += f" {DIM}↻ {until(win['resets_at'])}{RESET}"
        parts.append(seg)

    print(sep.join(parts))


if __name__ == "__main__":
    main()
