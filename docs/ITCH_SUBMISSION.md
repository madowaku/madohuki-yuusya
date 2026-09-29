# itch.io submission draft

Status: **local build prepared; no itch.io page has been published and no jam entry submitted by this task.**

## Jam check

Source checked 2026-09-29: <https://itch.io/jam/slapjam-ai-1>

- Theme: **Castles**. The whole puzzle is a castle facade whose rooms and residents are discovered by cleaning.
- Format: portrait browser game with touch controls. Native reference 720×1280, tested at 360×800 as well.
- AI assistance must be credited; tools and credits are listed below.
- Existing engines and asset packs are allowed. The supplied repository's design was used for the implementation made during the jam window.
- Page timestamps: submissions open 2026-09-28 15:00 UTC, close **2026-09-30 14:59:59 UTC / 2026-09-30 23:59:59 JST**. Recheck the live jam page before submission.

## Page fields

- Title: **WINDOW HERO / 窓ふき勇者**
- Short description: **One ladder. Up or across? Clean windows, unlock paths, and rethink your route.**
- Kind: HTML / playable in browser.
- Upload: `build/window-hero-itch.zip`; `index.html` is at archive root.
- Enable “This file will be played in the browser.”
- Enable mobile-friendly and portrait orientation.
- Suggested embed: 450×800 or viewport/fullscreen. The game fits a 9:16 playfield inside narrower/taller screens.
- No SharedArrayBuffer setting is needed; threading is disabled in the preset.
- Suggested tags: puzzle, cozy, short, 2d, touch-friendly, castles, ai-assisted.
- Suggested screenshots: `output/playwright/run-title.png`, `run-mouse-wall-3-bridge-5.png`, `run-touch-wall-2-bridge-4.png` (refresh captures when changing the build).

## English description

**A little castle. A little kindness.**

The castle's windows have been dirty for so long that everyone has forgotten the world outside. You arrive with a ladder and a squeegee. That's all a hero needs today.

Drag to wipe away the grime. Find a tiny greenhouse, a dusty library, and a friendly resident with a useful surprise. Every clean window brings a little more light—and sometimes a new way up.

One ladder can be an upright route or a sideways bridge. Across three walls and sixteen windows, read the shutter keys, discover new paths, and decide when to retrieve your ladder—and when to leave a return route in place. Later walls put gaps on two levels. Gifts change the possible routes; each puzzle has a verified placement target.

**Play:** Drag a finger or mouse over the glass. Tap a glowing circle for an upright ladder or ↔ for a bridge. Climb or cross, then retrieve the same ladder from either end. Read the Map to inspect connections with the clock paused. Extra placements are allowed, and you can retry just the current wall. Japanese and English are included.

**Made for Slapjam AI — Castles.** A three-puzzle prototype with no combat and no game-over timer. Replay the same castle to rethink your route or visit a new castle number.

**Credits:** Concept and direction by madowaku. AI-assisted code, procedural scene composition and audio synthesis with OpenAI Codex. Hero, goblin merchant and dirt textures created using the built-in OpenAI image generator. Godot Engine 4.7. Kenney Medieval, UI Adventure, UI Audio and Particle Pack (CC0). M PLUS Rounded 1c (SIL OFL 1.1). Full notices are included in the download and at the game's credits screen. Godot third-party licensing: <https://godotengine.org/license/>.

## 日本語紹介文

**剣をおいて、ハシゴを持とう。**

汚れた魔王城を、戦わずにきれいにする小さな冒険。窓をゴシゴシ磨くと、温室や書庫、ちょっと親切な住人が見えてきます。

ハシゴはたった1本。縦に掛ければ上への道、横に掛ければベランダの橋。3つの城壁・16枚の窓で、仕掛けの文字を読み、掛ける向きと回収する順番を考えます。最後は上下二段の切れ目へ。同じハシゴをどう使い回す？

指やマウスでドラッグして窓ふき。光る丸へ縦掛け、↔へ横掛け。「のぼる」「わたる」「回収」で道をつなぎます。「仕掛け」で時計を止めて考えられます。住人のお礼から選ぶ道具によって、最少手順も変わります。

3問の試遊版。目標回数を超えてもクリア可能で、今の城壁だけやり直せます。タイムリミットも戦闘もありません。日本語・英語対応。

## Final publishing steps

1. Upload the ZIP to the intended itch.io account and use the fields above.
2. Run the **hosted** version once on a real phone: audio unlock, touch cleaning, pause/resume and full clear.
3. Check screenshots, AI disclosures and credits on the page, then publish it.
4. Join / submit that published game from the Slapjam AI jam page before the deadline.

Publication, account choice and jam submission still require the owner's final action or explicit authorization.
