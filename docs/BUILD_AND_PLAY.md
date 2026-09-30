# Build and play

## Current controls

The normal Start enters the fixed-ladder score attack: one tower, ten floors, sixteen optional panes, three predictable enemy types. No placement or retrieval step.

- Flick / drag sideways to run; flick up or down to climb the nearest connected ladder.
- Tap a destination ledge, window or installed ladder to approach and move.
- Swipe glass to clean. Cleaning holds the hero for at least 1.2 seconds while patrols continue.
- Arrow keys / A,D move; Up,Down / W,S climb or descend. Escape pauses.
- Reach the summit to end immediately. The clock counts upward; there is no expiry.
- Windows add 400 points, seconds cost 50, contacts cost 150; all sixteen add 1,500.
- Pause and losing browser focus freeze the clock and patrols. Retry is available immediately at the result.
- Title: Start, How to play, Personal best (local), Credits, Japanese / English, sound.

Read-only Web telemetry is `window.windowHero.state`. Release builds omit the command mutation hook. F3 shows native debug state.

## Run and export

Open `project.godot` in Godot 4.7 stable and run F5. Compatibility renderer and a single-thread Web export are configured.

```powershell
godot --headless --editor --path . --import --quit
godot --headless --path . --export-release Web build/web/index.html
python tools/package_web.py
python tools/serve.py
```

Use HTTP: http://127.0.0.1:8066/. Do not double-click the exported HTML. ZIP: `build/window-hero-itch.zip`. Packaging checks archive CRC, root entry files, credit/license notices and records SHA-256. No SharedArrayBuffer configuration is required.

## Verification

```powershell
python tools/verify.py --godot godot
```

Eleven native Godot suites plus three independent solvers. The score-attack suite checks the connected fixed route graph, optional dirty panes, all-clean bonus, time freezing, camera, patrol contacts/invulnerability and controller flicks. Legacy route solvers retain their separate authored puzzles. Warnings and runtime errors fail verification, even with a zero process exit.

`tools/playtest-score-attack-browser.js` runs with Playwright CLI `run-code --filename`. It uses actual mouse gestures at 720×1280 or CDP touch events at 360×800. Both rush and fourteen-pane detour runs reach the summit and Ending, verify the score formula, exercise title menus and check release telemetry. Screenshots go to `output/playwright/`.

The Godot skill scenarios `tests/ui_desktop.json` and `tests/ui_mobile.json` inspect title, gameplay and pause container layout. Set `PYTHONUTF8=1` for the skill Python wrappers on Japanese Windows. Run native Godot processes sequentially on this host.

## Files

- `resources/score_attack_v1.json`: floors, distinct scoring panes, fixed connections and patrol data.
- `scripts/core/score_attack_state.gd`: deterministic run state, movement, score and contacts.
- `scripts/view/score_attack_painter.gd`: continuous tower, camera, enemy silhouettes and feedback.
- `scripts/ui/tower_hud.gd`: elapsed time/score, title panels and immediate retry.
- `scripts/view/ending_painter.gd`: legendary extension and celebratory backdrop.

Historical ladder-placement controls remain in the legacy source and tested checkpoint builds; they do not describe the main Start mode. See `docs/FINAL_SPRINT_RESULTS_v1.0.md` for evidence, limitations and artifact identity.
