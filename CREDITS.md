# 窓ふき勇者 / WINDOW HERO — credits

Game concept and direction: **madowaku**. AI-assisted implementation, generated character/texture artwork, procedural environment composition, synthesized audio and testing: **OpenAI Codex and the built-in OpenAI image generator**. No runtime AI service is used.

## Third-party assets

| Asset used | Author / source | License | Local notice |
| --- | --- | --- | --- |
| Medieval atlas: masonry, distant windows, balcony beam and hook brackets | [Kenney Platformer Pack Medieval](https://kenney.nl/assets/platformer-pack-medieval) | CC0 1.0; unmodified atlas, runtime region selection and tint | `assets/licenses/Kenney-Medieval.txt` |
| Window borders and base button panels | [Kenney UI Pack Adventure](https://kenney.nl/assets/ui-pack-adventure) | CC0 1.0; unmodified PNGs, Godot nine-patch scaling and tint | `assets/licenses/Kenney-UI-Adventure.txt` |
| `assets/art/sparkle.png` (`star_04.png`) | [Kenney Particle Pack](https://kenney.nl/assets/particle-pack), from `C:\Dev\AssetsShared\Kenney\kenney_particle-pack` | CC0 1.0; supplied license explicitly permits commercial use | `assets/licenses/Kenney-Particle-Pack.txt` |
| `assets/audio/place.ogg` (`click3.ogg`), `retrieve.ogg` (`switch7.ogg`) | [Kenney UI Audio](https://kenney.nl/assets/ui-audio), from the shared asset library | CC0 1.0; supplied license explicitly permits commercial use | `assets/licenses/Kenney-UI-Audio.txt` |
| M PLUS Rounded 1c Regular | [Google Fonts distribution](https://github.com/google/fonts/tree/main/ofl/mplusrounded1c); Copyright 2016 The Rounded M+ Project Authors | SIL Open Font License 1.1 | `assets/licenses/MPLUS-OFL.txt` |
| Godot 4.7 runtime | [Godot Engine](https://godotengine.org/license/) and contributors | MIT and bundled third-party notices available on the linked license page | `assets/licenses/Godot-MIT.txt` |

The font binary's embedded name records 13/14 explicitly identify OFL 1.1; its Google Fonts `METADATA.pb` also records `license: "OFL"`. Because that distribution folder currently lacks a standalone license file, the included notice combines the binary's copyright attribution with the canonical [SPDX OFL-1.1 text](https://github.com/spdx/license-list-data/blob/main/text/OFL-1.1.txt). The font binary is unmodified.

## Original work for this game

- Hero master and six poses, goblin merchant with three expressions, moon-moth astronomer, five dirt overlays, style/palette references, legendary ladder and Heart Window concepts were created with the built-in OpenAI image generator. Prompts, reference inputs and intended filenames are recorded in `assets/generated/production_prompts.json`. The tool does not expose its model version; no specific Images 2.5 version is claimed. Generated images are project assets, not Kenney CC0 assets.
- Hero poses, merchant expressions, the moon-moth astronomer and all five dirt overlays are integrated in the game. Legendary ladder and Heart Window remain separate concepts in the asset review scene and are excluded from the game export.
- Roofs, flags, ivy, room furnishings, ordinary ladder, interaction marks and environment composition are drawn by project code around the Kenney scaffold. Character artwork stays separate from gameplay state.
- `tools/generate_audio.py` creates the original cleaning sound, shine chime, ending chime, climbing tick and quiet music. It uses deterministic synthesis and no sampled recordings.
- `assets/manifest.json` records repository asset paths, runtime inclusion, source/license notes and SHA-256 checksums.

The licenses and this file are copied beside the exported game in the submission ZIP. They are not changed by the game's own future licensing decisions.
