# PLAN

## This week
G2 core loop: island, player, movement, camera, glide start.

## Cards
| ✓ | ID | Input | Output | Done when |
|---|---|---|---|---|
| ✓ | G1 Design + scope | Kid's answers | `DESIGN.md` | Kid says it matches |
| ✓ | G2a World + player | `DESIGN.md` | `scripts/tune.gd`, `scenes/main.tscn`, `scenes/player.tscn`, `scripts/player.gd`, `project.godot`, `PLAN.md` | You run and jump on the island with keyboard or gamepad |
| ✓ | G2b Camera + drop | G2a | `scenes/player.tscn`, `scripts/player.gd`, `scenes/main.tscn`, `scripts/tune.gd` | You glide down from 80 m, land, look, zoom, and can't leave the island |
| ✓ | G3a Loot + rifle | G2 | `scenes/main.tscn`, `scenes/chest.tscn`, `scripts/chest.gd`, `scripts/player.gd`, `scenes/hud.tscn`, `scripts/hud.gd`, `scripts/tune.gd`, `project.godot`, `DESIGN.md` | You open a chest, shoot a target, reload, and heal |
| ✓ | G3b Bots + win | G3a | `scenes/bot.tscn`, `scripts/bot.gd`, `scripts/health.gd`, `scripts/game.gd`, `scenes/main.tscn`, `scenes/hud.tscn`, `scripts/hud.gd`, `scripts/tune.gd` | 3 bots roam and fight; you win when last one left, lose at 0 HP |
|  | Build | G3 | pickaxe, material, Wall | — |
| ✓ | G4 Storm | G3 | `scripts/storm.gd`, `scenes/main.tscn`, `scripts/tune.gd`, `scripts/bot.gd`, `scripts/hud.gd`, `scenes/hud.tscn`, `PLAN.md` | Storm waits, shrinks to 0, hurts anyone outside (more as it shrinks), bots run inside, HUD shows the timer |
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

### G3a steps
1. 2 box buildings, 10 trees, 8 rocks
2. 6 chests: hold E 0.5 s → rifle + heal kit
3. HUD: HP, ammo, heal kits, crosshair
4. Burst rifle: 3 × 12, 60 m, every 0.6 s, mag 15
5. Reload: R / RB or auto, 1.8 s
6. Heal kit: H / B, +50 HP over 3 s

### G3b steps
7. Navigation + 3 bots roam
8. Bot sight 50 m + shooting (30–60% accuracy)
9. Shared health: 0 HP → out
10. HUD: players left
11. Win / lose message + restart
12. Tune pass (bot aim)

### G4 steps
1. Purple see-through storm wall, radius 80, center near middle
2. Timer: wait 45 s, shrink to 0 over 90 s
3. Damage once per second outside: 2 → 10 HP as it shrinks
4. HUD: storm timer + "IN THE STORM!"
5. Bots outside walk inside first
6. Tune pass

## Bugs
(none yet)
