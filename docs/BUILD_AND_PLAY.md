# Build and play

Asset production / review: see [ASSET_PRODUCTION_v0.1.md](ASSET_PRODUCTION_v0.1.md). Open `scenes/review/asset_review.tscn` and press F6 for the three-page art review. This scene is excluded from the game export.

## Requirements

- Godot **4.7 stable** (tested: `4.7.stable.official.5b4e0cb0f`).
- Matching Web export templates (`web_nothreads_release.zip`).
- Python 3 for the optional local server, audio regeneration and packaging script.
- No npm packages or external network access are required by the game itself.

## Play

Open `project.godot` with Godot and run the main scene (F5).

For the browser build:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --export-release Web build/web/index.html
python tools/package_web.py
python tools/serve.py
```

Open <http://127.0.0.1:8066>. Use HTTP; `file://` cannot load the WebAssembly build. The Web preset uses the Compatibility renderer and a single-threaded runtime, so cross-origin isolation headers are not required.

First import: Godot may try to read the project theme before its font has been imported. Complete the import once; subsequent runs and exports must be free of diagnostics.

## Controls

The default flow is **UX PASS v0.2**: T1 vertical, T2 bridge, T3 reposition, then the twelve-window tower. The three short teaching boards contain no instruction paragraphs and advance after polishing their windows:

- Drag across reachable glass to clean it. The hero approaches automatically; four broad zigzags suffice. The final 5.5% snaps clear.
- Tap the carried ladder beside the hero, or the installed ladder itself, to show legal destinations as full ghost ladders. Tap anywhere along a ghost to select it. The hero automatically reaches the old ladder, retrieves it, carries it and places it exactly where you chose. A destination across the current bridge is selectable when transport remains possible.
- Tap a destination window or ledge to walk, climb or cross the installed route automatically. The ladder stays in place until you choose another destination.
- An unreachable window responds with a brief trace that stops at the first missing connection. The eye button shows reachable regions, dirty windows and legal ghost ladders without showing a solution order. Idle cues pulse once after five seconds; they can be disabled in Menu.
- Clean the openable upper-left window, then tap it to enter. Tap the inner latch on the right to open the shutter; tap that window again to exit. Exterior geometry and the ladder remain visible in the same coordinates.
- Top-right Undo (or Z) returns one meaningful action, including an unfinished transport. Polished glass is retained. Undoing the permanent gallery leaves its window polished; tap it once to reactivate the mechanism.
- Menu pauses time and transport. Resume continues the same command. Menu also provides language, sound, reduced motion and access to the original three-wall run.
- Keyboard: Left/Right or A/D walks; Space toggles ladder candidates; Up/Down or W/S uses the installed ladder; Z undoes; Escape pauses.
- All twelve windows are required. Climb back to the crown after Undoing the finish to complete again without repeating cleaning. The independent minimum is four placements; there is no move limit.

### Original three-wall controls

Select **Play the original three walls** from the tower menu/result screen. Its previously validated gifts and ladder-puzzle rules are preserved:

- **Clean:** drag a mouse or one finger across a window on your current floor. The hero approaches distant windows automatically. Broad zigzags work; the final 5.5% clears automatically.
- **Walk:** tap the ledge, hold the left/right buttons, or use Left/Right (A/D).
- **Place:** tap a glowing ladder circle. The silhouette previews the entire ladder. The bottom action button also selects a nearby valid anchor.
- **Climb / descend:** tap the ladder circle again, press the action button, or use Up/Down (W/S). From farther away, the hero approaches and performs the action automatically.
- **Pick up:** the rightmost button or E. Either endpoint works.
- **Bridge:** tap a glowing ↔ between balconies to place the same ladder sideways. Cross with the action button, walk, then retrieve it from the far side. Without a bridge, the hero stops at the gap.
- **Read the rules:** the top “Map / 仕掛け” button lists window-to-mechanism connections and pauses the clock. The printed letters identify keys; this panel does not give a solved route.
- **Retry:** pause or open the map, then Retry this wall. Gifts and completed walls are preserved. Start over resets the whole run using the same castle number.
- **Pause:** the top-right button or Escape. Losing browser focus pauses automatically; Continue resumes explicitly.
- **Settings:** title offers Japanese / English and credits. Pause offers language, sound and reduced motion.
- **Debug:** F3 displays the state. Web builds expose read-only `window.windowHero.state`. Debug-only start/restart commands are omitted from release exports.

## First wall: one possible two-placement route

1. Clean both ground-floor windows. A's gears unlock the two lower hooks.
2. Place the ladder at a lower hook, climb and retrieve it from the top.
3. Clean both middle-floor windows. The resident in C extends the upper ledge.
4. Place the ladder on the new ledge, climb and clean the fifth window.

Skipping a window does not end the stage prematurely. Descending and re-placing the single ladder lets you return to missed rooms.

## Verification

```powershell
python tools/verify.py --godot godot
```

On a restricted Windows host where Godot cannot read the system root certificate store, pass a PEM CA bundle with `--certificate-bundle` or set `GODOT_CA_BUNDLE`. The wrapper applies this only during test runs and restores `project.godot` afterward; the game itself has no certificate-file dependency.

The wrapper runs the original stage/art/run/route/UI suites, tower, tutorial and direct-control suites, plus independent tower/tutorial solvers. The checks cover automatic transport, destination movement, Undo, feedback, visibility, idle cues and Japanese/English UI at both resolutions. `python tools/solve_tower.py` verifies the four-placement tower minimum; `python tools/solve_tutorial.py` verifies teaching-board minima and recoverability. See [v0.2 results](UX_PASS_RESULTS_v0.2.md) for current counts and browser evidence.

The original 35 stage assertions cover locked anchors, invalid indices, reachability, stationary input, pausing, the two-placement solution, both-end retrieval, early final-window cleaning, backtracking and deterministic restart.

The UI runtime test covers both resolutions and languages: controls stay onscreen, text/buttons do not overlap, gift descriptions fit their cards, and buttons have at least 44px touch targets at 360px width. It also checks the rule map, gift selection, final records, wall retries, pause/resume and sound. Preexisting native settings are restored. The verification wrapper fails on warnings/runtime errors even if Godot exits with code zero, and writes logs under `output/verification/`.

`tests/ui_desktop.json` and `tests/ui_mobile.json` are scenarios for the Godot skill's `run_scenario.py`. On Japanese Windows set `PYTHONUTF8=1` before running its Python wrappers. They inspect actual container layout at 720×1280 and 360×800 through title, play and pause.

`tools/playtest-browser.js` is a **Playwright CLI run-code function**, not an npm dependency or a test framework. At a 720px viewport it uses mouse input; at 360px it uses actual CDP touch events. It drives the complete level without changing gameplay state and captures title, reveal, resident, final castle and result screens. Read-only state queries verify the result.

`tools/playtest-run-browser.js` covers the expanded run. Execute it three times in the same Playwright CLI session, once per wall. Desktop chooses Recall then Soap (2/4/7 placements); mobile chooses Reach then Soap (2/2/5). The first wall is played before the first gift is offered. The taller final wall has six windows and a permanent gallery that opens when E is cleaned. It also checks that reading the map pauses time. It queries visible button rectangles from read-only telemetry and clicks/drags through the actual canvas.

## Structure

- `scripts/core/stage_data.gd`: stage geometry and unlock relationships.
- `scripts/core/wall_layout.gd`: seeded authored puzzles, gap locations, keys and placement goals.
- `scripts/core/castle_run.gd`: the three-wall journey, gift offers and records per castle/gift order.
- `scripts/core/stage_state.gd`: simulation, gates, movement, ladder ownership and progression.
- `scripts/gameplay/dirt_mask.gd`: spatial grime grid and segment erasure.
- `scripts/view/castle_view.gd`: original procedural castle art, room reveals, hero and feedback.
- `scripts/view/sound_bank.gd`: audio playback.
- `scripts/ui/game_hud.gd`: container-based menus, instructions, result and settings.
- `scripts/core/main.gd`: input translation, composition, settings and browser instrumentation.

## Current scope

The default flow follows [UX PASS v0.2](UX_PASS_v0.2.md). `tools/playtest-ux-browser.js` drives all three teaching boards and the tower through actual mouse input at 720×1280 or CDP touch at 360×800, including direct ladder/ghost selection, destination movement, Undo, feedback, Help, interior/latch controls and four-placement completion. Run it with Playwright CLI `run-code --filename tools/playtest-ux-browser.js` from the title screen. Output is saved under `output/playwright/`.

### Preserved original prototype

The first wall remains the original five-window vertical slice. After the user's first-use acceptance and explicit request to develop ladder logic puzzles, it was expanded into **three authored walls / sixteen windows** with seeded positions and two gift choices. The final wall is a taller four-floor tower with a six-window route: cleaning E creates a permanent horizontal gallery, enabling an AHA sequence that reuses vertical climbing and the sideways ladder bridge. The exact solver confirms target routes of seven placements without Reach and five with Reach; human completion time and difficulty still need playtesting. See [LADDER_PUZZLE_v0.3.md](LADDER_PUZZLE_v0.3.md) for rules and route verification. The Demon King / Heart Window finale and additional NPCs remain outside this prototype.
