---
name: create-audio
description: Use when the game needs a sound effect or music - "add a jump sound", "music", "it's too quiet", "make the hit sound punchier". Makes original sounds with a Python script that writes WAV files, and plays them so they work on all 4 platforms.
---

# Create sound and music

Use the rules in `game-plan`. One sound = one step.

## 1. Ask
1. Which moment (jump, hit, pickup, win, lose, click, music)?
2. Describe it with a feeling or an object: "a soft pop", "a heavy thump", "a happy chime".

## 2. Make it, in this order
1. **You make it.** A script `tools/make_sfx.py` that writes WAV files to `sounds/`.
   - Python standard library only (`wave`, `struct`, `math`, `random`).
   - 22 050 Hz, mono, 16-bit. Short: most effects under 0.5 s.
   - One function per sound, with plain comments on each number (pitch, length, fade), so the kid can change a number and run it again.
   - A fixed `random.seed`, so a run gives the same sounds.
   - Music: `tools/make_music.py` writes one loop of 8–16 s from a short note list in the palette of the game's mood. Ask the kid for the mood.
2. **A CC0 sound** (for example kenney.nl audio packs, or freesound.org filtered to CC0). The kid downloads it into `sounds/`. You never download.
3. **The kid's own recording**, saved as WAV or OGG in `sounds/`. No voices of other people.

## 3. Play it
- One autoload `Sfx` (`scripts/sfx.gd`) with a few `AudioStreamPlayer` nodes, and `Sfx.play("jump")`.
- Buses: `Music` and `SFX`. Put the volumes in `Tune`.
- **No sound before the first click or tap** (browsers block it). The start screen gives the first click.
- Music loop: tell the kid once: select the file → Import tab → Loop Mode **Forward** → Reimport.
- Add every sound to `CREDITS.md`.

## 4. Show it
`▶ Play: <do the action> — listen for <the sound>`. Ask "keep, change, or undo?". A change → change one number, run the script again, ▶ again.
