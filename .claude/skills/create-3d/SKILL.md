---
name: create-3d
description: Use when a 3D game needs a model - a player, enemy, weapon, item, building, tree, rock, or vehicle. Builds original low-poly models from Godot primitive meshes in the DESIGN.md palette, so they run on web and phones.
---

# Create a 3D model

Use the rules in `game-plan`. One model = one step.

## 1. Ask (one question at a time, skip what DESIGN.md already says)
1. What is it, and what does it do?
2. About how big, next to the player (the player is about 1.8 m)?
3. The 2–3 shapes that make it look right (for example "a box body, a round head, a cone hat").

## 2. Make it, in this order
1. **You make it from primitives.** One scene per model in `models/` (for example `models/tree.tscn`):
   - `Node3D` root → `MeshInstance3D` children with `BoxMesh`, `SphereMesh`, `CapsuleMesh`, `CylinderMesh`, `PrismMesh`, or `TorusMesh`.
   - A `StandardMaterial3D` per palette colour, saved as `.tres` in `models/materials/`, so models share them.
   - Collision: one simple shape on the body (box or capsule), not one per part.
2. **A CC0 model** (for example a kenney.nl kit, `.glb`). The kid downloads it and puts it in `models/`. You never download.
3. **The kid's own model** from Blender, saved as `.glb` in `models/`.

## 3. Rules
- Use only the `DESIGN.md` palette. No textures in the first playable.
- Original only. Never copy another game's characters, weapons, or look.
- Keep it low: about 3–12 parts per model.
- Many of the same thing (trees, rocks, grass): use `MultiMeshInstance3D`, not hundreds of nodes.
- Make the front easy to see (a nose, a visor, or a colour stripe), so the kid can see where it faces.
- Add it to `CREDITS.md`: file, who made it, license.

## 4. Show it
Put it in the main scene in the same step. `▶ Play: <where to look> — look for <the model>`. Ask "keep, change, or undo?".
