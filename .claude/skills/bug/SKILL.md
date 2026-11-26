---
name: bug
description: Use when the kid reports something broken - "bug:", "broken", "crash", "freezes", "doesn't work", a red error in Output, or a failed build. Finds the real cause from proof, fixes only that, and has the kid confirm it in play.
---

# Bug: proof → cause → fix → play

Use the rules in `game-plan` (approve before edit, one step, `How:` and `▶ Play:` lines).

## 1. Get proof
Do not guess. Ask for one of these, then stop:
- the first red line in Output (Godot: the Output panel at the bottom, or the Debugger → Errors tab)
- a screenshot
- the exact steps: "I did X, then Y, and Z happened"

No error and the kid can't make it happen again? Plan one step that adds a `print()` near the problem. The kid plays until it happens and pastes the new lines.

A failed build on GitHub? Use the `doctor` skill.

## 2. Find the cause
1. Read only the files in the error, and the code they call.
2. Find the line that causes it. Check with a headless run if you can: `godot --headless --quit-after <frames>`.
3. Explain the cause in 1–3 plain lines, as a story of what the game does. No code.

## 3. Plan
- The fix changes how the game plays? Ask for a say-back first.
- A small fix (a typo, a wrong number, a missing node)? No say-back.

Show a plan: one card `B<n>`, 1–3 steps, Output files, Test, Done when. Ask "Approve this plan?" and stop.

## 4. Fix
1. Change only the Output files. Fix the cause, not the symptom. Do not hide the error.
2. Run the checks. Add a line under "not released yet" in `CHANGELOG.md`: `Fixed: <what the kid saw>`.
3. End with `How:` and `▶ Play: <do the steps that broke it> — look for <the right result>`.

## 5. Confirm
- `ok` → tick the card, move it out of Bugs in `PLAN.md`. Ask: "Ship it now, or with the next change?" Now → `ship`.
- Still broken → back to step 1 with the new proof. After 2 failed fixes, say so. Offer to undo the change.
- A new, different bug → add it to Bugs in `PLAN.md`. Finish this one first.

You run tests in `tools/` yourself. Never ask the kid to run a command.
