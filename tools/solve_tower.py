"""Independent 0/1 BFS over every legal tower state. No calls into the game model.

Cleaning/entering/opening/crossing/retrieving cost zero; placing costs one.
Explicit retrieval and walking simulate Smart Reposition's mechanical operations.
Full reverse reachability audits all reachable states, not just the winning route.
"""
from collections import deque, defaultdict
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / "resources/tower_v01.json").read_text())
WINDOWS, ANCHORS = DATA["windows"], DATA["anchors"]
ENTRY, SHUTTER, KEY = DATA["entry"], DATA["shutter"], DATA["gallery_key"]
ALL = (1 << len(WINDOWS)) - 1


def neighbors(state):
    bits, region, ladder, opened, gallery = state
    if bits == ALL and opened and gallery and region == 5:
        return
    for i, window in enumerate(WINDOWS):
        if window["region"] == region and not bits & (1 << i) and (i != SHUTTER or opened):
            yield (bits | (1 << i), region, ladder, opened, gallery or i == KEY), 0, f"clean {i}"
    if region == 6:
        if not opened:
            yield (bits, region, ladder, True, gallery), 0, "open shutter"
        yield (bits, WINDOWS[ENTRY]["region"], ladder, opened, gallery), 0, "exit entry"
        if opened:
            yield (bits, WINDOWS[SHUTTER]["region"], ladder, opened, gallery), 0, "exit shutter"
    elif (region == WINDOWS[ENTRY]["region"] and bits & (1 << ENTRY)) or (region == WINDOWS[SHUTTER]["region"] and opened and bits & (1 << SHUTTER)):
        yield (bits, 6, ladder, opened, gallery), 0, "enter"
    if gallery and region in (1, 2):
        yield (bits, 3 - region, ladder, opened, gallery), 0, "gallery"
    for i, anchor in enumerate(ANCHORS):
        if region not in anchor["ends"]:
            continue
        if ladder == i:
            yield (bits, region, -1, opened, gallery), 0, "retrieve"
            yield (bits, next(r for r in anchor["ends"] if r != region), ladder, opened, gallery), 0, "cross"
        elif ladder == -1 and bits & (1 << anchor["key"]) and not (gallery and i == 4):
            yield (bits, region, i, opened, gallery), 1, f"place {i}"


def solve():
    start = (0, 0, -1, False, False)
    distance = {start: 0}
    parent = {}
    reverse = defaultdict(set)
    queue = deque([start])
    terminals = set()
    while queue:
        current = queue.popleft()
        if current[0] == ALL and current[3] and current[4] and current[1] == 5:
            terminals.add(current)
        for target, cost, action in neighbors(current):
            reverse[target].add(current)
            candidate = distance[current] + cost
            if candidate < distance.get(target, 999):
                distance[target] = candidate
                parent[target] = current, action
                (queue.append if cost else queue.appendleft)(target)
    best = min(terminals, key=lambda item: distance[item])
    minimum = distance[best]
    route = []
    cursor = best
    while cursor in parent:
        previous, action = parent[cursor]
        route.append({"action": action, "state": cursor})
        cursor = previous
    route.reverse()
    recoverable = set(terminals)
    queue = deque(terminals)
    while queue:
        for previous in reverse[queue.popleft()]:
            if previous not in recoverable:
                recoverable.add(previous)
                queue.append(previous)
    report = {"minimum": minimum, "expected": DATA["placement_goal"],
              "states": len(distance), "recoverable": len(recoverable),
              "unrecoverable": len(distance) - len(recoverable), "route": route}
    folder = ROOT / "output" / "verification"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "tower-solver.json").write_text(json.dumps(report, indent=2) + "\n")
    assert minimum == DATA["placement_goal"], report
    assert len(recoverable) == len(distance), report
    print(f"[TOWER SOLVER] minimum {minimum}; {len(recoverable)}/{len(distance)} states can finish; 0 failures")
    return report


if __name__ == "__main__":
    solve()
