---
name: feature
description: Use when the kid wants to add or change something in the game - "idea:", "add …", "can it …", "I want …", a new level, enemy, weapon, mode, menu, or setting. Checks it fits, makes sure the kid understands, then builds it one step at a time.
---

# Feature: fit → understand → plan → build

Use the rules in `game-plan`, sections 2–4.

## 1. Does it fit?
1. Read `DESIGN.md` and `PLAN.md`.
2. Say one of:
   - **Yes:** how it works, in 2–4 plain lines.
   - **Yes, but big:** about how many steps, and a smaller version (fewer than 10 steps).
   - **Not possible here:** why, and the closest option.
3. Not in `DESIGN.md`? Ask: "Add it now, or put it in 'Not in v1.0'?"
4. Online game? Say what the host runs and what each player sends.

## 2. Understand
Explain with a game the kid knows. Ask for a say-back. Do not plan until it is right.

## 3. Plan
1. Cards `F<n>`: Input, Output, Done when. 5–30 minutes each.
2. Numbered steps. One step = one change the kid can see.
3. New art or sound? Make it its own step with a `create-*` skill.
4. New feel numbers go in `scripts/tune.gd`.
5. Show **Input / Output / Steps / Test**. Ask "Approve this plan?" and stop.

## 4. Build
One step, the checks, then `How:` and `▶ Play:`. Act on the kid's answer as in `game-plan` 4.5.

## 5. Done
1. Check "Done when" in play. Online feature: the 2-instance test.
2. Tick the card. Add `Added: <what the kid can do>` to `CHANGELOG.md`.
3. Ask: "Ship it now?" Yes → `ship`.
