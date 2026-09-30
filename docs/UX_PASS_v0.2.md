# UX PASS v0.2 — Direct Ladder Interaction

## 0. Why this pass exists

Human play exposed a UX failure: when the player gets stuck, it is not obvious what can be done next.

The current interaction asks the player to understand hidden control rules such as:

- tap the hero to start ladder placement
- infer where the ladder can be placed
- infer when the ladder should be retrieved
- infer which object is interactive

That is the wrong kind of difficulty.

The puzzle should ask:

> **Where should this one ladder go next?**

It should not ask:

> **How do I operate the ladder system?**

Core rule for this pass:

> **操作方法を推理させない。解法だけを推理させる。**

And:

> **Reduce player input. Increase player thinking.**

No new puzzle content should be added until this control model feels obvious.

---

## 1. Scope

Implement and validate these changes:

1. Remove hero-as-ladder-control as the primary interaction
2. Directly interact with the ladder
3. Show legal ladder destinations as ghost ladders
4. Make ordinary movement destination-driven
5. Remove explicit routine retrieval from normal play
6. Give clear feedback when the player taps an unreachable window
7. Add a lightweight “what can I do?” affordance
8. Make ladder anchors readable as physical architecture
9. Add three tiny teaching floors before the 12-window tower
10. Preserve Undo, CLEAN, inside-route, shutter, solver validity, mouse/touch parity

Not in scope:

- new items
- new enemy systems
- new roguelite systems
- additional complex interior mechanics
- new tower content beyond tutorial floors
- boss implementation
- scoring redesign

---

## 2. Interaction Model

### 2.1 Move

**Tap a reachable place / window / existing ladder connection.**

The hero automatically:

- walks there
- climbs an installed vertical ladder
- crosses an installed horizontal ladder
- approaches a reachable window

The player should not need a separate WALK / CLIMB / CROSS command.

### 2.2 Clean

Tap a reachable dirty window.

The hero approaches it and the existing direct wipe interaction begins.

Do not add a separate CLEAN button.

### 2.3 Reposition the ladder

The ladder itself is the control surface.

Primary flow:

1. Tap the installed ladder, carried ladder, or ladder icon on the hero.
2. Legal destinations appear as **full ghost ladders**, not abstract arrows alone.
3. Tap a ghost ladder destination.
4. The game performs the mechanical sequence:
   - approach current ladder if needed
   - cross it first if required to reach the correct endpoint
   - retrieve it
   - carry it
   - place it at the selected destination

The destination is chosen by the player.
The mechanical retrieval is handled by the game.

### 2.4 Optional direct drag

If robust on both mouse and touch:

- press/drag the visible ladder
- ghost candidates appear while dragging
- release near a candidate to choose it

Tap-then-select must remain fully supported.
Drag is an enhancement, not a requirement.

---

## 3. Remove Retrieve as a normal verb

Routine ladder retrieval should not exist as a persistent button or required step.

The player should never have to think:

> “I forgot to pick the ladder up.”

The meaningful question is:

> “Do I want to move the ladder away from its current role?”

Rules:

- The ladder stays where it is until the player selects a new destination.
- If it is serving as a bridge or return route, it remains physically present.
- Selecting a new destination means “move this ladder there.”
- Retrieval is automatic if the move is legal.
- If moving it would destroy the currently required route before the hero can reach the ladder safely, that destination is not legal.

No hidden auto-decision may choose the destination for the player.

---

## 4. Ghost Ladder Candidates

When ladder placement mode begins, show **the object that will exist**, not only markers.

### Vertical candidate

Render a translucent ladder from lower ledge to upper ledge.

### Horizontal candidate

Render a translucent ladder laid across the gap.

### Visual states

- Gold / warm white: legal destination
- Muted red: preview of the currently installed route that will disappear
- Gray: avoid showing illegal candidates by default
- Illegal destinations may appear only in optional help mode if useful

Do not light every anchor permanently.

Candidates exist only while the player is thinking about ladder placement.

### Selection target

The entire ghost ladder should be tappable, with at least 44px-equivalent touch coverage at 360×800.

Do not require tapping a tiny hook.

---

## 5. Physical ladder anchors

Current logical hooks must read as part of the castle.

Replace or augment abstract hook circles with visible architectural affordances:

- iron ladder brackets on walls
- paired sockets on balcony edges
- worn stone grooves
- small metal rings / clamps

The shape itself should hint at orientation.

Vertical support:
- upper/lower aligned brackets

Horizontal bridge:
- paired facing brackets across a gap

The player should be able to think:

> “A ladder could fit there.”

before entering placement mode.

---

## 6. Unreachable-window feedback

Tapping an unreachable dirty window must never feel like a dead input.

Sequence:

1. The chosen window gives a small response.
2. Show a subtle path trace from hero toward it.
3. The path stops at the first missing connection.
4. Pulse the missing gap / relevant bracket once.
5. Give the visible ladder a tiny attention animation if ladder movement could solve the connectivity problem.

No text such as “You cannot reach this window” is required.

The feedback answers:

> “Why can’t I go there?”

without answering:

> “Where exactly should the ladder go?”

This preserves the puzzle.

---

## 7. What-can-I-do visibility

Add one optional, quiet help affordance.

Suggested icon: ? or an eye-like route icon in the HUD.

While held/toggled briefly, show:

- reachable floor regions
- currently cleanable windows
- legal ladder placements

Do **not** show:

- optimal move
- required order
- shortest path
- exact next step

This is an interaction-legibility tool, not a puzzle hint.

### Idle nudge

If the player has made no meaningful input for approximately 4–6 seconds and has not disabled hints:

- pulse the ladder once
- pulse currently reachable dirty windows once

Do not repeat continuously.
Do not flash the full solution graph.

---

## 8. Tutorial by level design

Before the current 12-window tower, add three very short teaching floors.

No tutorial paragraph.

### Floor T1 — Vertical

Purpose:
- touching the ladder enters placement mode
- ghost ladder means “place here”
- installed ladder can be climbed

Board:
- one legal ladder destination
- one dirty window above

Expected discovery:
> ladder → ghost → tap → climb → clean

### Floor T2 — Bridge

Purpose:
- the same ladder can lie horizontally

Board:
- hero and target window separated by one gap
- one obvious horizontal candidate
- no competing destinations

Expected discovery:
> the ladder is not only vertical

### Floor T3 — Reposition

Purpose:
- installed ladder can be moved again
- explicit retrieval is unnecessary

Board:
- first use ladder vertically
- then a second target requires moving it horizontally or to another vertical connection

Expected discovery:
> touch the ladder again and choose where it goes next

After T3, enter the 12-window tower.

Do not add inner shutter or interior traversal until the player has learned the ladder language.

---

## 9. Interior-route controls

Preserve the current same-screen cutaway.

For an open enterable window:

- tapping the open window means enter
- tapping a reachable exit window inside means move / exit
- tapping the inner shutter latch means open

Do not require switching to a separate interaction mode.

While inside:

- exterior ladder remains visible
- ladder placement is unavailable unless the current design explicitly supports manipulating it from inside
- the player must always know which outside region the room connects

---

## 10. Undo

Undo remains prominent because puzzle experimentation should be cheap.

Undo must reverse one **meaningful decision**, not each animation sub-step.

Examples:

- ladder destination choice = one Undo
- opening inner shutter = one Undo
- activating permanent gallery = one Undo
- movement alone may be excluded from history unless it changes puzzle state

Do not force the player to re-clean already polished glass merely because they are testing ladder routes.

---

## 11. HUD

Keep HUD minimal.

Recommended:

- left: floor
- center: cleaned required windows
- right: Undo, Help, Menu

Do not put ladder controls in the HUD.

The ladder is controlled by touching the ladder.

This direct mapping is the central UX change.

---

## 12. Visual feedback

### Ladder selected

- slight warm outline
- surrounding world dims very slightly
- ghost candidates fade in within 120–180 ms

### Candidate selected

- chosen ghost brightens
- current ladder route pulses muted red if it will disappear
- then hero performs transport automatically

### Failed / impossible request

- no modal
- no error text
- short soft “no route” response
- highlight missing connectivity once

### Placement

- short metal/wood placement sound
- brief ladder settle
- hero recovery animation

The feedback must be readable without stopping the player’s train of thought.

---

## 13. Acceptance Criteria

### First-use discoverability

With no spoken explanation:

- [ ] Player can move by tapping a destination.
- [ ] Player discovers that touching the ladder controls the ladder.
- [ ] Player can understand a ghost ladder as a placement destination.
- [ ] Player learns vertical placement in T1.
- [ ] Player learns horizontal placement in T2.
- [ ] Player learns repositioning without a Retrieve button in T3.

### Stuck-state clarity

On the 12-window tower:

- [ ] Tapping an unreachable window produces meaningful feedback.
- [ ] Player can tell which connections are missing.
- [ ] Player can intentionally ask “what can I do?” without receiving the solution.
- [ ] Player is not left wondering whether the game is waiting for an invisible command.

### Ladder UX

- [ ] No routine manual Retrieve action is required.
- [ ] Existing ladder remains until the player chooses to move it.
- [ ] All legal destinations are represented by readable ghost ladders.
- [ ] Horizontal vs vertical use is visually obvious before selection.
- [ ] Smart reposition never chooses a destination autonomously.
- [ ] Transport animation never changes puzzle state in unexpected intermediate steps.

### Mobile

- [ ] 360×800 touch targets remain >=44px-equivalent.
- [ ] Ghost candidates do not overlap ambiguously.
- [ ] Same action semantics on mouse and touch.
- [ ] Drag gesture does not conflict with window-cleaning gestures.
- [ ] If drag proves fragile, tap-select remains the canonical control.

### Technical

- [ ] Original v0.1 tower minimum remains solver-verified unless tutorial integration intentionally changes authored data.
- [ ] Every reachable legal puzzle state remains recoverable or Undo-safe.
- [ ] 720×1280 mouse full run passes.
- [ ] 360×800 touch full run passes.
- [ ] Existing three-wall mode still passes regression.
- [ ] 0 runtime warnings/errors.

---

## 14. Human Playtest Questions

Observe:

1. What do they tap first when they want to move the ladder?
2. When stuck, do they tap a target window or random UI?
3. Do they understand why an unreachable window cannot be reached?
4. Do they ever behave like they are searching for a Retrieve button?
5. After T2, do they independently try the ladder horizontally later?
6. After T3, do they understand that choosing a new ladder location implies retrieval?
7. On the 12-window tower, are pauses caused by puzzle thinking or control confusion?

Success criterion:

> **Long pauses should increasingly mean “I’m thinking about the route,” not “I don’t know what the game wants me to tap.”**

---

## 15. Implementation Order

### PASS A — Direct control
Replace hero-tap placement entry with ladder-tap placement entry.

### PASS B — Ghost ladders
Render full vertical/horizontal placement previews and make them large targets.

### PASS C — Destination movement
Unify walk / climb / cross / approach under destination taps.

### PASS D — Stuck feedback
Add unreachable-window path break feedback and optional “what can I do?” overlay.

### PASS E — Tutorial floors
Build T1/T2/T3 as tiny authored boards.

### PASS F — Human validation
Run fresh-player observation before adding any new puzzle mechanics.

---

## 16. Stop Conditions

Stop adding content and fix UX if any of these occur:

- player taps the hero expecting movement but gets ladder mode
- player searches for a Retrieve button
- player cannot tell horizontal from vertical candidate
- player sees no reaction from an unreachable target
- ghost candidates look like decoration instead of choices
- touch gestures accidentally initiate cleaning while moving the ladder
- tutorial requires explanatory paragraphs
- the player’s confusion is about controls rather than routes

The goal is not to make the puzzle easy.

The goal is to make the **controls disappear**, so the hard part is the route.
