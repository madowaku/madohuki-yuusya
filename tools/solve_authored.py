"""Independent 0/1 BFS and reverse reachability audit for authored boards."""
from __future__ import annotations

from collections import defaultdict, deque
import json
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / "resources/challenges_v1.json").read_text(encoding="utf-8"))


def role(board: dict[str, Any], key: str, default: int = -1) -> int:
    return int(board.get(key, default))


def validate_geometry(board: dict[str, Any]) -> None:
    floors = board["floors"]
    regions = board["region_floors"]
    windows = board["windows"]
    anchors = board["anchors"]
    assert 0 < len(floors) <= 4, f"{board['stage_id']}: expected 1-4 floors"
    assert len(regions) > 0, f"{board['stage_id']}: no regions"
    for index, window in enumerate(windows):
        x, y, width, height = map(float, window["rect"])
        hit_width, hit_height = max(88.0, width), max(88.0, height)
        hx, hy = x + (width - hit_width) / 2.0, y + (height - hit_height) / 2.0
        assert 0 <= window["floor"] < len(floors), f"{board['stage_id']}: bad floor on window {index}"
        assert 0 <= window["region"] < len(regions), f"{board['stage_id']}: bad region on window {index}"
        assert regions[window["region"]] == window["floor"], f"{board['stage_id']}: window/region floor mismatch {index}"
        assert 0 <= hx and hx + hit_width <= 720 and 104 <= hy and hy + hit_height <= 1280, f"{board['stage_id']}: window hitbox out of playable board {index}"
        for other_index, other in enumerate(windows[:index]):
            ox, oy, ow, oh = map(float, other["rect"])
            if window["floor"] == other["floor"]:
                ohw, ohh = max(88.0, ow), max(88.0, oh)
                ohx, ohy = ox + (ow - ohw) / 2.0, oy + (oh - ohh) / 2.0
                assert not (hx < ohx + ohw and ohx < hx + hit_width and hy < ohy + ohh and ohy < hy + hit_height), (
                    f"{board['stage_id']}: authored windows overlap {other_index}/{index}"
                )
    for index, anchor in enumerate(anchors):
        first, second = map(int, anchor["ends"])
        assert first != second and min(first, second) >= 0 and max(first, second) < len(regions), (
            f"{board['stage_id']}: invalid endpoints on anchor {index}"
        )
        bx, by = map(float, anchor["base"])
        tx, ty = map(float, anchor["top"])
        if anchor.get("horizontal", False):
            assert abs(by - ty) < 0.01 and abs(bx - tx) >= 88, f"{board['stage_id']}: malformed bridge {index}"
        else:
            assert abs(bx - tx) < 0.01 and abs(by - ty) >= 88, f"{board['stage_id']}: malformed ladder {index}"
        assert 0 <= bx <= 720 and 0 <= tx <= 720 and 0 <= by <= 1280 and 0 <= ty <= 1280, (
            f"{board['stage_id']}: anchor out of bounds {index}"
        )
        assert regions[first] != regions[second] or anchor.get("horizontal", False), (
            f"{board['stage_id']}: vertical anchor stays on one floor {index}"
        )
    for key in ("entry", "shutter", "gallery_key"):
        value = role(board, key)
        assert value == -1 or 0 <= value < len(windows), f"{board['stage_id']}: invalid {key} window"
    for key in ("interior_region", "completion_region"):
        value = role(board, key)
        assert value == -1 or 0 <= value < len(regions), f"{board['stage_id']}: invalid {key} region"
    retired = role(board, "retired_bridge")
    assert retired == -1 or 0 <= retired < len(anchors), f"{board['stage_id']}: invalid retired bridge"


def is_unlocked(board: dict[str, Any], index: int, bits: int, shutter_open: bool) -> bool:
    window = board["windows"][index]
    required = int(window.get("requires_window", -1))
    if required >= 0 and not bits & (1 << required):
        return False
    if window.get("requires_all_other", False):
        other_mask = ((1 << len(board["windows"])) - 1) ^ (1 << index)
        if bits & other_mask != other_mask:
            return False
    if index == role(board, "shutter") and not shutter_open:
        return False
    return True


def neighbors(board: dict[str, Any], state: tuple[int, int, int, bool, bool]):
    bits, region, ladder, shutter_open, gallery_open = state
    windows = board["windows"]
    anchors = board["anchors"]
    entry = role(board, "entry")
    shutter = role(board, "shutter")
    gallery_key = role(board, "gallery_key")
    interior = role(board, "interior_region")
    gallery_regions = list(map(int, board.get("gallery_regions", [])))
    all_clean = (1 << len(windows)) - 1
    completion = (
        bits == all_clean
        and region == role(board, "completion_region")
        and (shutter < 0 or shutter_open)
        and (gallery_key < 0 or gallery_open)
    )
    if completion:
        return

    if region != interior:
        for index, window in enumerate(windows):
            if int(window["region"]) != region or bits & (1 << index) or not is_unlocked(board, index, bits, shutter_open):
                continue
            next_gallery = gallery_open or index == gallery_key
            yield (bits | (1 << index), region, ladder, shutter_open, next_gallery), 0, f"clean {index}"
        if gallery_key >= 0 and bits & (1 << gallery_key) and not gallery_open and int(windows[gallery_key]["region"]) == region:
            yield (bits, region, ladder, shutter_open, True), 0, "reactivate polished gallery"

    if interior >= 0 and region == interior:
        if shutter >= 0 and not shutter_open:
            yield (bits, region, ladder, True, gallery_open), 0, "open shutter"
        if entry >= 0 and bits & (1 << entry):
            yield (bits, int(windows[entry]["region"]), ladder, shutter_open, gallery_open), 0, "exit entry"
        if shutter >= 0 and shutter_open:
            yield (bits, int(windows[shutter]["region"]), ladder, shutter_open, gallery_open), 0, "exit shutter"
    elif interior >= 0:
        portals = [entry]
        if shutter >= 0 and shutter_open:
            portals.append(shutter)
        for portal in portals:
            portal_open = portal == shutter and shutter_open or portal >= 0 and bool(bits & (1 << portal))
            if portal >= 0 and region == int(windows[portal]["region"]) and portal_open:
                yield (bits, interior, ladder, shutter_open, gallery_open), 0, f"enter {portal}"

    if gallery_open and len(gallery_regions) == 2 and region in gallery_regions:
        other = gallery_regions[1] if region == gallery_regions[0] else gallery_regions[0]
        yield (bits, other, ladder, shutter_open, gallery_open), 0, "gallery"

    for index, anchor in enumerate(anchors):
        ends = list(map(int, anchor["ends"]))
        if region not in ends:
            continue
        if ladder == index:
            next_region = ends[1] if region == ends[0] else ends[0]
            yield (bits, next_region, ladder, shutter_open, gallery_open), 0, f"cross {index}"
            yield (bits, region, -1, shutter_open, gallery_open), 0, f"retrieve {index}"
        elif ladder < 0:
            required = int(anchor.get("requires_window", anchor.get("key", -1)))
            retired = index == role(board, "retired_bridge") and gallery_open
            if not retired and (required < 0 or bits & (1 << required)):
                yield (bits, region, index, shutter_open, gallery_open), 1, f"place {index}"


def solve_board(board: dict[str, Any]) -> dict[str, Any]:
    validate_geometry(board)
    windows = board["windows"]
    all_clean = (1 << len(windows)) - 1
    start = (0, int(board["initial_region"]), int(board.get("initial_ladder", -1)), False, False)
    distance = {start: 0}
    previous: dict[tuple[int, int, int, bool, bool], tuple[tuple[int, int, int, bool, bool], str]] = {}
    reverse: dict[tuple[int, int, int, bool, bool], set[tuple[int, int, int, bool, bool]]] = defaultdict(set)
    queue = deque([start])
    terminals = set()
    while queue:
        current = queue.popleft()
        bits, region, _ladder, shutter_open, gallery_open = current
        if (
            bits == all_clean
            and region == role(board, "completion_region")
            and (role(board, "shutter") < 0 or shutter_open)
            and (role(board, "gallery_key") < 0 or gallery_open)
        ):
            terminals.add(current)
        for target, cost, action in neighbors(board, current):
            reverse[target].add(current)
            candidate = distance[current] + cost
            if candidate < distance.get(target, 1 << 30):
                distance[target] = candidate
                previous[target] = (current, action)
                (queue.append if cost else queue.appendleft)(target)

    assert terminals, f"{board['stage_id']}: no clear state is reachable"
    best = min(terminals, key=distance.__getitem__)
    minimum = distance[best]
    route = []
    cursor = best
    while cursor in previous:
        parent, action = previous[cursor]
        route.append({"action": action, "state": cursor})
        cursor = parent
    route.reverse()

    recoverable = set(terminals)
    queue = deque(terminals)
    while queue:
        for parent in reverse[queue.popleft()]:
            if parent not in recoverable:
                recoverable.add(parent)
                queue.append(parent)

    report = {
        "stage_id": board["stage_id"],
        "minimum": minimum,
        "expected": int(board["placement_goal"]),
        "states": len(distance),
        "recoverable": len(recoverable),
        "unrecoverable": len(distance) - len(recoverable),
        "route": route,
    }
    assert minimum == int(board["placement_goal"]), report
    assert len(recoverable) == len(distance), report
    return report


def solve() -> list[dict[str, Any]]:
    reports = [solve_board(board) for board in DATA["boards"]]
    folder = ROOT / "output" / "verification"
    folder.mkdir(parents=True, exist_ok=True)
    (folder / "authored-solver.json").write_text(json.dumps(reports, indent=2) + "\n", encoding="utf-8")
    for report in reports:
        print(
            f"[AUTHORED SOLVER] {report['stage_id']}: minimum {report['minimum']}; "
            f"{report['recoverable']}/{report['states']} states can finish; 0 failures"
        )
    return reports


if __name__ == "__main__":
    solve()
