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

Implement and polish the Vertical Slice defined in:

`docs/VERTICAL_SLICE_v0.1.md`

Do not expand scope until its Acceptance Criteria pass.

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
- hero_started_climb
- hero_finished_climb
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
- climbing feels slow
- cleaning feels like chores
- final dirt becomes pixel hunting
- reveal lacks payoff
- player does not want to reach the next window
