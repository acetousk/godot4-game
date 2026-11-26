---
name: ship
description: Use when the kid says "ship", "release", "publish", "put it online", "update my phone", or a card or fix ends with "ship it". Commits, tags, and pushes a release, then checks the builds and the web link.
---

# Ship: release a version

You do every git step. The kid only says "go" and clicks **Allow** on each pop-up. Never ask the kid to type a command.

## 1. Ready?
1. `git status`. Nothing changed and no new commits since the last tag? Say "Nothing new to ship." Stop.
2. Run the checks: `godot --headless --import`, then `godot --headless --quit-after 60`. Errors → use `bug`. Stop.
3. Tests in `tools/` (for example `python3 tools/net_test.py`)? Run them yourself. They fail → use `bug`. Stop.
4. A step the kid has not played yet? Ask for one ▶ Play round first.

## 2. Pick the version
Read `git tag --sort=-v:refname`.
- Only fixes → the patch goes up: `v1.2.0` → `v1.2.1`
- New features → the minor goes up: `v1.2.1` → `v1.3.0`
- The first playable → `v0.1.0`, or the next free minor if older tags exist.

In `CHANGELOG.md`, change "not released yet" to the version and today's date.

## 3. Tell the kid, then go
Say, in 3 lines:
> Ready to ship **v1.2.1**: <the 1–3 changes>.
> I'll save it (commit), name it (tag), and send it to GitHub (push). Claude Code shows a pop-up for the name and the send. Click **Allow** each time.
> Say **go**.

After `go`:
1. `git add` the changed files by name. Never `git add -A`. Never add secrets (`keys.cfg`, `*.keystore`).
2. `git commit -m "v1.2.1: <one line>"`
3. `git tag v1.2.1`
4. `git push`, then `git push origin v1.2.1`

A command was denied? Say once: "That pop-up needs a click on **Allow**. Say go when you're ready." Do not retry until the kid answers. Never ask the kid to do the git steps by hand.

## 4. After the push
Say:
> Sent! GitHub builds it now, about 10 minutes.
> Then: web — `<the Pages link from README.md>` (press Ctrl+Shift+R the first time). Phone — open Obtainium and tap update. PC — the Releases page.
> Tell me what you see.

The kid says a build is red, or the game did not change? Use `doctor`.
