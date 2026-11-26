# PLAN

## This week
First playable of Lantern Deep: 1–4 players online co-op (GD-Sync), start → play → win or lose → play again, with sound, on all 4 platforms.
Before N2: the kid pastes the GD-Sync **Clients** docs page and finds out if GD-Sync works on Web. The parent makes sure the GD-Sync key file is never committed.

## Cards
| ✓ | ID | Input | Output | Done when |
|---|---|---|---|---|
| ✓ | G1 Design + scope | The kid's answers | `DESIGN.md`, `PLAN.md` | The kid says DESIGN.md matches the game in their head |
| ✓ | G2 Core loop (15 steps) | DESIGN.md, palette | `tools/make_sprites.py`, sprites, `scripts/tune.gd`, dungeon generator, player, camera, fog, lantern, stairs | You walk through 3 new floors per run in the dark with the lantern, and the stairs can always be reached |
| ✓ | G3 Goal (8 steps) | G2 | HUD, log, potions (random colors, 3 effects), relic on floor 3, win | You find and drink potions, grab the relic, and see "You win" |
| ✓ | G4 Pressure (10 steps) | G3 | Turn manager, 3 monsters, sleep/wake, bump combat, hit flash, XP + level up, wait + heal, lose | Monsters wake, fight you, and can kill you |
| ✓ | N1 Team cave (5 steps) | G4 | One seed per run, 1–4 heroes, team turns, monsters chase the nearest hero, shared vision, win together, dead heroes watch | 2 heroes on 1 PC (Tab switches, test only) play a full run, and monsters only move after both heroes acted |
| ✓ | N2 Lobby (6 steps + kid installs GD-Sync) | N1, GD-Sync plugin, docs | `scripts/net.gd`, menu (Solo / Host / Join), 4-digit room code, number pad, Start | 2 game windows on 1 PC (local mode) join the same room and start the same cave |
|   | N3 Online turns (6 steps) — steps 11–15 ✓, 16 waits for the GD-Sync key | N2 | Moves go to the host, the host sends state, host-only monster turns, synced potions/stairs/relic/death, someone leaving | 2 windows play a full run together, and it works on Web and Android |
| ✓ | G5 Flow + sound + touch (9 steps): 1 end panel + stats, 2 solo play again, 3 co-op play again + Menu, 4 touch pad, 5 tap a tile, 6 `tools/make_sfx.py`, 7 `Sfx` + click, 8 game sounds (synced), 9 kid plays 3 games + names a fix | G4, N3 | `game.gd`, `hud.gd`, `net.gd`, `menu.gd`, `sfx.gd`, `tools/make_sfx.py`, `sfx/`, `project.godot`, `CREDITS.md` | A full game works 3 times in a row with sound, by keyboard, gamepad and touch, solo and in 2 windows |
|   | G6 Ship (5 steps) | G5 | Title + icon, the kid's fix (potion names on phones), speed check, `CHANGELOG.md` | It runs well on web and phone, and you are asked to tag `v0.1.0` |

## Bugs
- (none yet)
