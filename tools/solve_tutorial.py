"""Independent graph solver for the three authored silent tutorial boards."""
from collections import defaultdict, deque
import heapq
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / "resources/tutorial_v02.json").read_text(encoding="utf-8"))


def neighbors(board, state):
    bits, region, ladder = state
    all_clean = (1 << len(board["windows"])) - 1
    if bits == all_clean:
        return

    for index, window in enumerate(board["windows"]):
        required = window.get("requires_window", -1)
        if window["region"] == region and not bits & (1 << index) and (required < 0 or bits & (1 << required)):
            yield (bits | (1 << index), region, ladder), 0, f"clean {index}"

    if ladder >= 0:
        ends = board["anchors"][ladder]["ends"]
        if region in ends:
            other = ends[1] if region == ends[0] else ends[0]
            yield (bits, other, ladder), 0, f"cross {ladder}"

    for index, anchor in enumerate(board["anchors"]):
        required = anchor.get("requires_window", -1)
        if index == ladder or (required >= 0 and not bits & (1 << required)):
            continue
        recovery_regions = [region] if ladder < 0 else board["anchors"][ladder]["ends"]
        for recovery in recovery_regions:
            # The installed ladder can reach either endpoint. After retrieving it,
            # tutorial boards have no remaining route except staying on that region.
            if recovery != region and (ladder < 0 or region not in board["anchors"][ladder]["ends"]):
                continue
            for destination in anchor["ends"]:
                if destination == recovery:
                    yield (bits, destination, index), 1, f"place {index} at {destination}"


def solve_board(board):
    start = (0, 0, int(board.get("initial_ladder", -1)))
    reachable = {start}
    transitions = defaultdict(list)
    reverse = defaultdict(set)
    pending = deque([start])
    while pending:
        current = pending.popleft()
        for target, cost, action in neighbors(board, current):
            transitions[current].append((target, cost, action))
            reverse[target].add(current)
            if target not in reachable:
                reachable.add(target)
                pending.append(target)

    all_clean = (1 << len(board["windows"])) - 1
    terminals = {state for state in reachable if state[0] == all_clean}
    distance = {start: 0}
    parent = {}
    queue = [(0, 0, start)]
    order = 0
    while queue:
        cost, _, current = heapq.heappop(queue)
        if cost != distance[current]:
            continue
        for target, edge_cost, action in transitions[current]:
            candidate = cost + edge_cost
            if candidate >= distance.get(target, float("inf")):
                continue
            distance[target] = candidate
            parent[target] = (current, action)
            order += 1
            heapq.heappush(queue, (candidate, order, target))

    best = min(terminals, key=lambda state: distance[state])
    route = []
    cursor = best
    while cursor in parent:
        previous, action = parent[cursor]
        route.append({"action": action, "state": cursor})
        cursor = previous
    route.reverse()

    recoverable = set(terminals)
    pending = deque(terminals)
    while pending:
        for previous in reverse[pending.popleft()]:
            if previous not in recoverable:
                recoverable.add(previous)
                pending.append(previous)

    return {
        "step": board["step"],
        "minimum": distance[best],
        "expected": board["placement_goal"],
        "states": len(reachable),
        "recoverable": len(recoverable),
        "unrecoverable": len(reachable) - len(recoverable),
        "route": route,
    }


def solve():
    reports = [solve_board(board) for board in DATA["boards"]]
    for report in reports:
        assert report["minimum"] == report["expected"], report
        assert report["recoverable"] == report["states"], report
    folder = ROOT / "output" / "verification"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "tutorial-solver.json").write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
    counts = ", ".join(f"T{item['step']} {item['minimum']} ({item['recoverable']}/{item['states']} recoverable)" for item in reports)
    print(f"[TUTORIAL SOLVER] {counts}; 0 failures")


if __name__ == "__main__":
    solve()
