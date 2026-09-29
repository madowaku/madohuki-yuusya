# Implementation Sprint v0.1

## Principle

コンテンツ量ではなく Core Feel を先に完成させる。

## Phase 0: Project Boot

- Godot 4.7 project
- 720x1280 portrait
- mouse/touch input abstraction
- web export preset
- debug overlay
- deterministic restart

## Phase 1: Hero + Ladder

- Hero movement
- Ladder carry state
- Ladder anchor points
- Placement preview
- Place/retrieve
- Climb/descend
- invalid placement feedback

Exit condition:
ハシゴを掛けるだけで分かりやすく、軽く気持ちいい。

## Phase 2: Window Cleaning

- Dirt mask
- drag-to-clean
- dirt percentage
- DIRTY/PARTIAL/CLEAN
- final clean feedback
- clean persistence during run

Exit condition:
窓1枚を何度か意味なく磨きたくなる。

## Phase 3: Reveal

- window interior layer
- resident reveal
- mechanism reveal
- CLEAN signal
- simple event triggers

Exit condition:
窓を磨く理由が「清掃」だけでなく「見たい」に変わる。

## Phase 4: First Puzzle

5 windows / 1 ladder / 2 unlock events.

- A opens upper hook
- C reveals resident
- resident activates final access
- final window clears stage

Exit condition:
説明文なしで3分以内にクリア可能。

## Phase 5: Juice

優先順:

1. final "キュッ!"
2. dirt wipe visuals
3. glass transparency
4. ladder placement sound
5. resident reaction
6. particles
7. small camera response

## Phase 6: Jam Expansion

Vertical Slice成功後のみ追加。

- 5 areas
- 4 ladder variants
- 3 cleaning upgrades
- 3 enemies
- 5 residents
- 8 upgrade choices
- 1 boss
- Demon King
- Legendary Ladder ending

## Non-Goals Until Slice Passes

- procedural generation
- save/meta progression
- 30 ladder types
- multiple castles
- large narrative system
- complex combat
- inventory grid
- online features

## Test Matrix

### Desktop
- 720x1280
- mouse
- keyboard

### Mobile-like
- 360x800
- touch emulation
- one-hand readability

### Web
- fresh load
- reload
- focus lost/restored
- audio unlock after user gesture

## Definition of Done

A build is not "done" because tests are green.

It is done when:

- first-time player understands what to do
- ladder placement has no friction
- cleaning has tactile satisfaction
- reveal causes curiosity
- one run ends cleanly
