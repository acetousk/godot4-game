---
name: game-plan
description: Use for every request in this game repo that changes a file - a new game, feature, bug, feeling ("too hard"), art, sound, or release. Sorts the request to the right skill, checks the kid understands, plans, and gets approval before any edit.
---

# Game plan: understand → plan → approve → build

## 0. First run done?
No `DESIGN.md`, and the parent did not say "skip the first run"? Stop. Do the first run in `AGENTS.md`.

## 1. Work out the request
Sort it, then go on:

| Request | Do |
|---|---|
| A question | Answer it. No plan. |
| A feeling ("too hard", "boring"), or "Tune round" | Section 6 |
| Setup or build trouble | `doctor` skill |
| A new game, or no `DESIGN.md` | `new-game` skill |
| A bug | `bug` skill |
| A new feature or change | `feature` skill |
| Art, sound, a background, or a level | `create-2d`, `create-3d`, `create-audio`, `create-background`, `create-environment` |
| Ship, release, publish | `ship` skill |
| Anything else | Go on |

The skills use sections 2–4 below.

Read only the files you need. Find how to do it in Godot 4.7.2 on all 4 platforms.

## 2. Say if it is possible
- **Yes:** how it works, in 2–4 plain lines.
- **Yes, but big:** about how many steps, and a smaller version that fits.
- **Not possible here:** why (engine, platform, budget, or an `AGENTS.md` rule), how the real thing works, and the closest option.

Not in `DESIGN.md`? Ask: add it now, or put it in "Not in v1.0"?

## 3. Check understanding
1. Explain the idea, not the code. Use an example from games the kid knows.
2. Ask the kid to say in their own words how it will work.
3. Wrong or unsure? Explain another way. Repeat.
4. Do not plan until the kid has it right.

## 4. Plan, approve, build
1. Write cards: ID, Input, Output, Done when. One card = 5–30 minutes. Bigger → more cards.
2. Give each card numbered steps. One step = one change the kid can see, about 1 minute of your work.
3. Show **Input / Output / Steps / Test**. Ask "Approve this plan?" and stop.
4. After a yes, add the cards to `PLAN.md`. Do **one step**, run the checks, then end with:
   `How: <one line>` and `▶ Play: <what to do> — look for <what>`. Stop.
5. Act on the kid's answer:
   - `ok` → the next step
   - a tweak ("faster") → change only that, then ▶ again
   - `bug: …` → fix it if it is inside the Output; if not, add it to Bugs
   - `idea: …` → add it to "Not in v1.0", then go on
   - `?` or `why?` → explain; do no more steps until the kid understands
6. Change only the Output files. Need more? Stop and ask.
7. After the last step, check "Done when" and tick the card. Ask "Ship it now?" Yes → `ship` skill. You do every git step; never ask the kid to.

## 5. A new game
Use the `new-game` skill.

## 6. A feeling: the tune loop
1. Name 1–3 `Tune` values that can cause the feeling, and why. No value fits? Make a card instead.
2. Change **one** value. Say old → new. Ask the kid to play a full run.
3. Ask "keep or undo?". Add one line to `PLAYTEST.md`. Include the stats from `user://stats.json` if they exist.

## 7. Release
Use the `ship` skill.
