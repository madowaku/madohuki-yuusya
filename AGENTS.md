# AGENTS.md

## Project

窓ふき勇者 / WINDOW HERO

Godot 4.7, portrait-first game.

## Product Rule

Do not turn this into a generic action game.

The core is:

**CLIMB → CLEAN → DISCOVER → OPTIMIZE**

Combat is not the default solution.

## Current Priority

Implement and polish the Visual / UX Pass defined in:

`docs/VISUAL_UX_PASS_v0.1.md`

The current design direction is a hand-crafted tower logic puzzle:

- many small windows arranged irregularly
- one ladder reused as vertical ladder and horizontal bridge
- meaningful ladder placement / leaving / repositioning decisions
- occasional exterior-to-interior routes through windows
- inner shutters opened from inside
- minimal explanatory UI and no unnecessary item systems

Preserve the validated ladder-puzzle behavior in `docs/LADDER_PUZZLE_v0.3.md`.

Do not broaden scope beyond the current pass until its Acceptance Criteria are checked.

## Engineering Rules

- Keep gameplay data separate from presentation where practical.
- Prefer small composable scenes/resources over one giant script.
- Support mouse and touch from the start.
- Portrait reference: 720x1280.
- Also verify 360x800 usability.
- Avoid hard-coded screen coordinates where anchors/containers can be used.
- Keep game state restartable and deterministic enough for automated tests.
- Add debug hooks that help AI agents inspect state.
- Warnings and runtime errors are treated as failures.
- Do not add dependencies without a clear reason.
- Keep visual windows small if desired, but keep mobile hit targets at least 44px-equivalent and non-overlapping.
- Automate routine ladder retrieval; preserve only meaningful player decisions about whether and where to move the ladder.
- Prefer visual feedback over explanatory text.
- Undo should support puzzle experimentation without forcing repeated cleaning work.

## Suggested Structure

```
project.godot
scenes/
  main/
  hero/
  ladder/
  window/
  rooms/
scripts/
  core/
  gameplay/
  ui/
resources/
  ladders/
  windows/
  rooms/
assets/
  art/
  audio/
docs/
tests/
```

## Core Signals / Events

Prefer explicit gameplay events such as:

- ladder_placed
- ladder_retrieved
- ladder_repositioned
- hero_started_climb
- hero_finished_climb
- hero_entered_window
- hero_exited_window
- shutter_opened
- window_clean_progress
- window_cleaned
- window_revealed
- mechanism_activated
- stage_cleared

## AI Agent Workflow

For each task:

1. Read README + relevant docs.
2. State the acceptance criteria being implemented.
3. Make the smallest coherent change.
4. Run available validation.
5. Inspect actual game behavior, not only static checks.
6. Record known limitations.
7. Do not silently broaden scope.

## Feel Before Content

If any of these fail, stop adding content:

- ladder placement feels awkward
- routine ladder retrieval creates busywork
- small windows are hard to tap
- interior traversal loses spatial clarity
- climbing feels slow
- cleaning feels like chores
- final dirt becomes pixel hunting
- reveal lacks payoff
- player does not want to reach the next window
