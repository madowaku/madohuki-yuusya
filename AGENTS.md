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

Implement and polish:

docs/UX_PASS_v0.2.md

Human testing found that the current ladder controls are harder to understand than the puzzle itself. Fix control legibility before adding content.

Primary UX principle:

**操作方法を推理させない。解法だけを推理させる。**

The intended interaction language is:

- tap a reachable destination to move
- tap the ladder to manipulate the ladder
- show legal destinations as full ghost ladders
- selecting a new ladder destination implies automatic routine retrieval and transport
- keep the ladder in place until the player explicitly chooses a new destination
- tapping an unreachable window must explain the missing connection visually, not fail silently

Add three tiny teaching floors before the twelve-window tower:

1. vertical ladder
2. horizontal bridge
3. reposition without Retrieve

Preserve the validated puzzle behavior and solver coverage from:

- docs/VISUAL_UX_PASS_v0.1.md
- docs/VISUAL_UX_PASS_RESULTS_v0.1.md
- docs/LADDER_PUZZLE_v0.3.md

Do not add new items, combat, roguelite systems, puzzle mechanics or tower content until UX PASS v0.2 human checks pass.

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
- Keep mobile hit targets at least 44px-equivalent and non-overlapping.
- Direct manipulation should map object-to-action: ladder controls ladder, destination controls movement.
- Routine ladder retrieval is automatic; destination choice always belongs to the player.
- Prefer full ghost-ladder previews over abstract hook markers.
- Unreachable interactions must respond visually instead of silently failing.
- Prefer visual feedback over explanatory text.
- Undo should restore meaningful puzzle decisions without forcing repeated cleaning work.

## Core Signals / Events

Prefer explicit gameplay events such as:

- ladder_selected
- ladder_candidate_previewed
- ladder_repositioned
- hero_destination_selected
- hero_started_climb
- hero_finished_climb
- unreachable_target_selected
- route_gap_indicated
- hero_entered_window
- hero_exited_window
- shutter_opened
- window_clean_progress
- window_cleaned
- window_revealed
- mechanism_activated
- state_undone
- stage_cleared

## AI Agent Workflow

For each task:

1. Read README + relevant docs.
2. State the acceptance criteria being implemented.
3. Make the smallest coherent change.
4. Run available validation.
5. Inspect actual game behavior, not only static checks.
6. Test both mouse and touch interaction semantics.
7. Record known limitations.
8. Do not silently broaden scope.

## Feel Before Content

If any of these fail, stop adding content:

- player does not know what to tap to move the ladder
- player searches for Retrieve
- ladder destinations are visually ambiguous
- unreachable targets fail silently
- control confusion is mistaken for puzzle difficulty
- drag gestures conflict with CLEAN
- small windows are hard to tap
- interior traversal loses spatial clarity
- cleaning feels like chores
- reveal lacks payoff
- player does not want to reach the next window
