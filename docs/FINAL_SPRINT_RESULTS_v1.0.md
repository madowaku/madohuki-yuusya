# FINAL JAM SPRINT — current implementation and evidence

## Current main mode: fixed-ladder score attack

The user's approved pivot supersedes the earlier ladder-placement campaign. Start enters one continuous ten-floor tower with sixteen optional panes, eighteen fixed ladders/bridges and six deterministic patrols across three enemy types. Horizontal flicks run; vertical flicks climb/descend. Destination taps remain available. No ladder placement/retrieval step or countdown.

Cleaning holds the hero for at least 1.2 seconds while patrols continue. Score: 10,000 base +400 per pane -50 per elapsed second -150 per contact, plus 1,500 for all sixteen. Arrival at the summit ends immediately. Time and score freeze; the result shows TIME / WINDOWS / DAMAGE / SCORE / BEST with immediate Retry. Personal best persists locally.

The user-supplied title and Ending concepts were edited with the built-in image generator to remove painted controls. Real title menus offer Start, How to play, Personal best and Credits. The user-supplied skeleton/bat/ghost PNGs retain transparency. A generated repeatable blue wall joins wooden platforms and live actors. Ending exaggerates the extending legendary ladder, then crossfades to the celestial celebration. “Only a true hero can extend this legendary ladder.”

## Verification

- Eleven native Godot suites and three independent solvers passed: zero failures, warnings or runtime errors. Score suite: 119 checks; art: 127; legacy routes remain verified.
- Whole-project validation: 42 resources/scripts/scenes checked, zero diagnostics.
- Native UI title/play/pause at 720×1280 and 360×800: passed, zero reported layout issues.
- Actual release Web: mouse at 720×1280 and CDP touch at 360×800; both rush and fourteen-pane detour routes reach the summit and Ending. Four flick directions, descending, cleaning, contacts, pause/resume, title information panels, credits/back, immediate Retry and return to title passed. No gameplay mutation hooks used or exposed. Zero browser warnings/errors.
- All sixteen panes and all-clean bonus are covered natively; the browser detour route deliberately leaves two optional branches dirty.

| Input / route | Elapsed seconds | CLEAN | Contacts | Score |
| --- | ---: | ---: | ---: | ---: |
| mouse / rush | 24.66 | 0/16 | 4 | 8167 |
| mouse / detour | 74.32 | 14/16 | 7 | 10834 |
| touch / rush | 24.03 | 0/16 | 4 | 8199 |
| touch / detour | 66.60 | 14/16 | 8 | 11070 |

These are automated routes, not human skill benchmarks. They demonstrate that productive detours beat the no-clean rush under the chosen score rule.

## Upload artifact

- `build/window-hero-itch.zip`, 31.94 MiB; root index.html/index.js/index.wasm/index.pck, credits, asset manifest and license notices included. ZIP CRC checks passed.
- SHA-256: `4f3a031882067a5ffa0f4c8201ef302d836d7d3bc4e38c21543259a2e3a974b0`.
- Exact frozen checkpoint: `build/checkpoints/score-attack/window-hero-itch.zip`.
- Older verified puzzle fallback: `build/checkpoints/should-ship/window-hero-itch.zip`, SHA-256 `00a64d83a264f2fb0f1ddc491b8029770b35d99c9d23f38a08d6f55ed53fe5ff`.
- Screenshots: `docs/images/score-attack-*.png`.

## Practical limits

CDP touch verifies browser event handling and layout; a physical phone and the hosted itch.io build still need a final play check. Fresh human observation is still needed for flick feel, first-use clarity and score balance. PR #3 remains Draft for that review. No itch.io page publication or jam submission was performed by this task. The old puzzle is retained in source/checkpoints and is not the default Start mode.
