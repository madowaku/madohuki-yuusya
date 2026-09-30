# AGENTS.md

## Project

窓ふき勇者 / WINDOW HERO

Godot 4.7, portrait-first game.

## Product Rule

Do not turn this into a generic action game.

The core is:

**CLIMB → CLEAN → DISCOVER → OPTIMIZE**

The current main mode is a fixed-ladder tower route and window-cleaning score attack.

## Current Priority

Execute docs/SCORE_ATTACK_v1.0.md, following the user's 2026-09-30 playtest direction.

All ladders are installed. Remove placement/retrieval from the main mode. Horizontal flicks walk; vertical flicks climb or descend. Show elapsed time, never a countdown. Score is 10,000 plus 400 per polished window, minus 50 per elapsed second and 150 per monster contact; all sixteen panes add 1,500. Reaching the summit ends immediately; Heart Window and other panes are optional. Preserve the exaggerated legendary ladder Ending and immediate Retry.

The older authored puzzle campaign and its tested ZIP are preserved as a fallback. Its rules below apply only when working on that campaign.

This is the final jam shipping target.

Work top-to-bottom by PHASE and keep a shippable Web build after every completed phase.

Primary UX principle:

**操作方法を推理させない。解法だけを推理させる。**

Primary production principle:

**Always preserve a submission-ready build.**

Relevant source docs:

- docs/UX_PASS_v0.2.md
- docs/VISUAL_UX_PASS_v0.1.md
- docs/VISUAL_UX_PASS_RESULTS_v0.1.md
- docs/LADDER_PUZZLE_v0.3.md

## Autonomous Execution

Time is limited. Make reasonable implementation decisions without waiting for small approvals.

Do stop and avoid scope expansion when a choice would:

- change the core puzzle identity
- add a large new system
- risk the working Web submission
- weaken first-use control clarity

Commit coherent milestones and keep the itch ZIP current.

## Engineering Rules

- Keep gameplay data separate from presentation where practical.
- Prefer small composable scenes/resources over one giant script.
- Support mouse and touch.
- Portrait reference: 720x1280.
- Verify 360x800.
- Mobile hit targets >=44px-equivalent.
- No warnings or runtime errors.
- Keep game state deterministic enough for solver/tests.
- Direct manipulation: ladder controls ladder; destination controls movement.
- Routine ladder retrieval is automatic.
- Destination choice always belongs to the player.
- Prefer ghost ladders over abstract hook-only UI.
- Unreachable taps must respond visually.
- Undo restores meaningful decisions.
- Do not make players repeat cleaning work due to route experimentation.

## Shipping Priority

1. UX PASS v0.2
2. Silent tutorial T1/T2/T3
3. Polish the 12-window tower
4. Preserve shippable itch build
5. Tower ascent flow
6. Heart Window final floor
7. Ending
8. Extra authored floors only if time remains

A strong short game is better than a long weak game.

## Do Not Build

Before submission, do not add:

- roguelite progression
- procedural runs
- shop
- meta upgrades
- combat
- enemy AI
- inventory
- large item systems
- interior maze systems
- multiple ladder management
- 3D conversion
- large art rewrites

## Validation Gate

After each meaningful milestone:

1. run available tests
2. run solver when puzzle topology changed
3. inspect actual game behavior
4. verify mouse
5. verify touch
6. export Web
7. rebuild itch ZIP
8. record limitations

## Feel Before Content

Stop adding content if:

- player does not know what to tap
- player searches for Retrieve
- ladder destinations are ambiguous
- unreachable targets fail silently
- control confusion is mistaken for puzzle difficulty
- cleaning becomes chores
- a new floor adds length but no AHA
- the current build is no longer safely submittable
