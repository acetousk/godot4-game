# PLAN

## This week
G2 core loop: island, player, movement, camera, glide start.

## Cards
| ✓ | ID | Input | Output | Done when |
|---|---|---|---|---|
| ✓ | G1 Design + scope | Kid's answers | `DESIGN.md` | Kid says it matches |
| ✓ | G2a World + player | `DESIGN.md` | `scripts/tune.gd`, `scenes/main.tscn`, `scenes/player.tscn`, `scripts/player.gd`, `project.godot`, `PLAN.md` | You run and jump on the island with keyboard or gamepad |
|  | G2b Camera + drop | G2a | `scenes/player.tscn`, `scripts/player.gd`, `scenes/main.tscn`, `scripts/tune.gd` | You glide down from 80 m, land, look, zoom, and can't leave the island |
|  | G3 Goal | G2 | chests, rifle, bots to eliminate | — |
|  | G4 Pressure | G3 | storm | — |
|  | G5 Online | G4 | `scripts/net.gd` | — |
|  | G6 Flow + sound + touch | G5 | screens, `tools/make_sfx.py`, touch | — |
|  | G7 Ship | G6 | title, icon, `CHANGELOG.md`, `v0.1.0` | — |

### G2a steps
1. `PLAN.md` + `Tune` autoload
2. Island, water, sky
3. Input Map (keyboard + gamepad)
4. Capsule player with gravity
5. Run 6 m/s
6. Jump 1.2 m

### G2b steps
7. SpringArm3D camera + look
8. Aim zoom + slower look
9. Glide start at 80 m
10. Invisible edge walls
11. Tune pass

## Bugs
(none yet)
