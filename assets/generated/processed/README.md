# Processed assets

Raw PNGs already contain alpha and are used directly. There are no raster retouches in v0.1. Keep this directory for future `_proc_outline` / `_proc_colorfix` versions; never overwrite raw originals.

Godot import caps the generated textures at 512 pixels; source PNGs retain their full resolution. CharacterArt aligns visible alpha bounds at runtime. DirtArt resamples in memory and combines the art with the deterministic cleaning mask; this is presentation, not a replacement raw texture.
