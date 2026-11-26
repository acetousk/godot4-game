# PLAN

## This week
First playable of Lantern Deep: start → play → win or lose → play again, with sound, on all 4 platforms.

## Cards
| ✓ | ID | Input | Output | Done when |
|---|---|---|---|---|
| ✓ | G1 Design + scope | The kid's answers | `DESIGN.md`, `PLAN.md` | The kid says DESIGN.md matches the game in their head |
| ✓ | G2 Core loop (15 steps) | DESIGN.md, palette | `tools/make_sprites.py`, sprites, `scripts/tune.gd`, dungeon generator, player, camera, fog, lantern, stairs | You walk through 3 new floors per run in the dark with the lantern, and the stairs can always be reached |
|   | G3 Goal (8 steps) | G2 | HUD, log, potions (random colors, 3 effects), relic on floor 3, win | You find and drink potions, grab the relic, and see "You win" |
|   | G4 Pressure (10 steps) | G3 | Turn manager, 3 monsters, sleep/wake, bump combat, hit flash, XP + level up, wait + heal, lose | Monsters wake, fight you, and can kill you |
|   | G5 Flow + sound + touch (10 steps) | G4 | Start screen, end screen + stats, play again, touch controls, `tools/make_sfx.py`, sounds | A full game works 3 times in a row with sound, by keyboard, gamepad and touch |
|   | G6 Ship (5 steps) | G5 | Title + icon, the kid's fix, speed check, `CHANGELOG.md` | It runs well on web and phone, and you are asked to tag `v0.1.0` |

## Bugs
- (none yet)
