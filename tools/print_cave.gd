extends Node
## Prints random cave floors as text, so you can check the cave maker.
## Run:  godot --headless tools/print_cave.tscn

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	for i in 3:
		var gen := DungeonGen.new()
		var last_floor := i == 2
		gen.generate(rng, not last_floor)
		print("Floor ", i + 1, " (", gen.rooms.size(), " rooms, ", gen.retries, " thrown away):")
		print(gen.to_text())

	# What the player sees from the start (spaces = can't see).
	var g := DungeonGen.new()
	g.generate(rng)
	var view := Fov.compute(g, g.start, Tune.sight_radius)
	var lines := g.to_text().split("\n")
	print("What @ can see (sight ", Tune.sight_radius, "):")
	for y in g.height:
		var line := ""
		for x in g.width:
			line += lines[y][x] if view.has(Vector2i(x, y)) else " "
		print(line)

	# Test: make 1000 floors and check that every goal can be reached.
	var bad := 0
	for i in 1000:
		var gen := DungeonGen.new()
		gen.generate(rng)
		if not gen._can_reach(gen.start, gen.goal):
			bad += 1
	print("1000 floors made, ", bad, " with an unreachable goal.")

	# Test: monster counts and types per floor (100 runs of each floor).
	var game0 = load("res://scenes/game.tscn").instantiate()
	game0.test_heroes = 1  # The solo tests. The team tests below get their own game.
	add_child(game0)

	# Test: seeds. Same seed = the same run (all 3 floors), even after a fight. Other seed = different.
	var runs := []
	for s in [1234, 1234, 999]:
		game0.start_run(s)
		var print_out := ""
		for f in Tune.floor_count:
			print_out += _floor_print(game0)
			game0._rolls_hit(0)  # Roll fight dice: this must not change the next floor.
			if f < Tune.floor_count - 1:
				game0._go_down()
		runs.append(print_out)
	print("Seed test: same seed same run: ", runs[0] == runs[1], ", other seed different: ", runs[0] != runs[2])

	# --- Team tests: a game with 2 heroes ---
	var team = load("res://scenes/game.tscn").instantiate()
	team.test_heroes = 2
	add_child(team)

	# Test: heroes. All in the start room, on different tiles. Tab moves your keys and the camera.
	var room: Rect2i = team._room_with(team.gen.start)
	var hero_cells := {}
	var in_room := true
	for h in team.heroes:
		hero_cells[h.cell] = true
		in_room = in_room and room.has_point(h.cell)
	team._switch_hero()
	var now_p: int = team.player.number
	var cam_on: bool = team.camera.get_parent() == team.player
	var keys_ok: bool = team.heroes[1].controlled and not team.heroes[0].controlled
	var p2_free: bool = team.is_free(team.heroes[1].cell)
	team._switch_hero()
	print("Hero test: ", team.heroes.size(), " heroes, different tiles: ", hero_cells.size() == team.heroes.size(),
		", in start room: ", in_room, ", after Tab: P", now_p, " camera follows: ", cam_on,
		" keys move only P2: ", keys_ok, ", monsters can walk onto P2: ", p2_free, ", Tab again: P", team.player.number)

	# Test: team turn. P1 waits: monsters don't move yet. P2 waits: now they move.
	team._new_floor()
	var mover: Monster = team.monsters[0]
	mover.awake = true
	var mover_start: Vector2i = mover.cell
	var t0: int = team.turn
	team._on_player_waited()
	var moved_after_p1: bool = mover.cell != mover_start
	var p1_blocked: bool = team.heroes[0].done
	var wait_text: String = team.hud.stats.text
	team._switch_hero()
	team._on_player_waited()
	team._switch_hero()
	print("Team turn test: after P1 monster moved: ", moved_after_p1, ", P1 must wait: ", p1_blocked,
		", HUD says Waiting for P2: ", wait_text.ends_with("Waiting for P2"), ", after P2 monster moved: ", mover.cell != mover_start,
		", turns +", team.turn - t0, ", P1 free again: ", not team.heroes[0].done)

	# Test: P2 walks far away (to the goal room). A slime next to P2 should wake,
	# chase and hit P2, not P1. Both lanterns should light the map.
	team._new_floor()
	var p1: Player = team.heroes[0]
	var p2: Player = team.heroes[1]
	p2.place(team.gen.goal)
	var beside := p2.cell
	for dir in Monster.DIRS:
		if team.gen.get_tile(p2.cell + dir) == DungeonGen.Tile.FLOOR:
			beside = p2.cell + dir
			break
	var near_p2: Monster = team.monsters[0]
	near_p2.setup("slime", beside)
	near_p2.awake = false
	team._wake_monsters()
	team._find_paths()
	team._update_view()
	var both_seen: bool = team.visible_now.has(p1.cell) and team.visible_now.has(p2.cell)
	var both_zero: bool = team.path_dist.get(p1.cell) == 0 and team.path_dist.get(p2.cell) == 0
	for t in 20:
		team.monster_attacks(near_p2)
	print("Nearest hero test: slime near P2 woke up: ", near_p2.awake, ", both heroes are targets: ", both_zero,
		", shared vision: ", both_seen, ", P1 HP ", p1.hp, ", P2 HP ", p2.hp)
	# Test: P2 is down, but P1 is still alive, so the run is not over yet.
	var banner_after_p2: bool = team.hud.has_node("Banner")
	# Test: watching. You play P2, P2 dies: the camera goes to P1. P1 can walk through the ghost.
	team._switch_hero()  # Can't: P2 is down, so you stay on P1.
	var stayed_p1: bool = team.player == p1
	team.player.controlled = false
	team.player = p2
	team.camera.reparent(p2, false)
	team._watch_friend()
	team._refresh_hud()
	print("Watch test: Tab skips the ghost: ", stayed_p1, ", camera moved to P1: ", team.camera.get_parent() == p1,
		", HUD: ", team.hud.stats.text.ends_with("Watching P1"), ", ghost blocks: ", team.hero_at(p2.cell) != null,
		", ghost lantern off: ", not p2.get_child(0).visible)
	team.player = p1
	p1.controlled = true

	# Test: stairs take the whole team down, and the round stays fair.
	p1.done = true
	team._on_player_moved(team.gen.goal)  # Floor 1 has stairs at the goal.
	print("Team stairs test: floor ", team.floor_num, ", both in the start room: ",
		team._room_with(team.gen.start).has_point(p1.cell) and team._room_with(team.gen.start).has_point(p2.cell),
		", P1 may act: ", not p1.done, ", log: ", team.hud.log_lines.back())
	team._lose(p1, "a test")
	print("Team lose test: P2 down: ", not p2.active, ", banner while P1 lived: ", banner_after_p2,
		", banner after both: ", team.hud.has_node("Banner"), ", log: ", team.hud.log_lines.back())
	team.queue_free()

	# Test: win together. P2 falls on floor 3, then P1 grabs the relic: the whole team wins.
	var team2 = load("res://scenes/game.tscn").instantiate()
	team2.test_heroes = 2
	add_child(team2)
	team2._go_down()
	team2._go_down()
	team2._lose(team2.heroes[1], "a test")
	team2._on_player_moved(team2.gen.goal)
	print("Team win test: floor ", team2.floor_num, ", banner: ", team2.hud.has_node("Banner"),
		", banner text: ", team2.hud.get_node("Banner").text if team2.hud.has_node("Banner") else "-",
		", nobody can move: ", not team2.heroes[0].active and not team2.heroes[1].active,
		", log: ", team2.hud.log_lines.back())
	team2.queue_free()

	for f in [1, 2, 3]:
		var counts := {}
		var bad_spot := 0
		var sizes := {}
		for run in 100:
			game0.run_seed = run  # A different run each time.
			game0.floor_num = f
			game0._new_floor()
			sizes[game0.monsters.size()] = true
			var start_room: Rect2i = game0._room_with(game0.gen.start)
			for m in game0.monsters:
				counts[m.type] = counts.get(m.type, 0) + 1
				if start_room.has_point(m.cell) or game0.gen.get_tile(m.cell) == DungeonGen.Tile.WALL:
					bad_spot += 1
		print("Monster test floor ", f, ": per floor ", sizes.keys(), " types ", counts, " bad spots ", bad_spot)
	# Test: waking. Put a slime 5 tiles away (stays asleep), then 4 (wakes).
	game0.floor_num = 2
	game0._new_floor()
	var slime: Monster = game0.monsters[0]
	slime.setup("slime", game0.player.cell + Vector2i(5, 0))
	game0._wake_monsters()
	var awake_at_5: bool = slime.awake
	slime.setup("slime", game0.player.cell + Vector2i(4, 0))
	game0._wake_monsters()
	var warden: Monster = game0.monsters[1]
	warden.setup("warden", game0.player.cell + Vector2i(0, 6))
	game0._wake_monsters()
	print("Wake test: slime at 5 awake: ", awake_at_5, ", at 4 awake: ", slime.awake,
		", warden at 6 awake: ", warden.awake)
	# Test: chasing. Wake every monster and pass 40 turns: they should end up next to you.
	game0.floor_num = 1
	game0._new_floor()
	for m in game0.monsters:
		m.awake = true
	game0.player.max_hp = 9999  # So the hero lives through 40 turns of attacks.
	game0.player.hp = 9999
	for t in 40:
		game0._end_turn()
	var next_to := 0
	var cells := {}
	for m in game0.monsters:
		cells[m.cell] = true
		if game0.path_dist.get(m.cell, 999) <= 2:
			next_to += 1
	print("Chase test: ", game0.monsters.size(), " monsters, ", next_to, " within 2 steps of you, ",
		"all on different tiles: ", cells.size() == game0.monsters.size())
	# Test: hit chance over 10000 rolls (should be about 80% and 50%).
	var hits := 0
	var moth_hits := 0
	for r in 10000:
		if game0._rolls_hit(0):
			hits += 1
		if game0._rolls_hit(30):
			moth_hits += 1
	print("Hit test: normal ", hits / 100.0, "%, vs moth ", moth_hits / 100.0, "%")

	# Test: fight a warden next to you until one of you drops.
	game0.player.active = true
	game0.player.max_hp = 20
	game0.player.hp = 20
	var w: Monster = game0.monsters[0]
	w.setup("warden", game0.player.cell + Vector2i.RIGHT)
	var rounds := 0
	while w.hp > 0 and game0.player.hp > 0 and rounds < 50:
		game0._on_player_bumped(w.cell)
		rounds += 1
	print("Fight test: after ", rounds, " rounds: warden HP ", w.hp, ", your HP ", game0.player.hp,
		", warden gone: ", not game0.monsters.has(w))
	# Test: losing. HP 1, a warden next to you attacks until it hits.
	game0.player.active = true
	game0.player.hp = 1
	var killer: Monster = game0.monsters[0] if not game0.monsters.is_empty() else null
	if killer == null:
		killer = Monster.new()
		killer.game = game0
		game0.monsters_node.add_child(killer)
		game0.monsters.append(killer)
	killer.setup("warden", game0.player.cell + Vector2i.LEFT)
	for t in 20:
		game0.monster_attacks(killer)
	game0._on_player_bumped(killer.cell)  # Dead heroes can't attack.
	print("Lose test: HP ", game0.player.hp, ", can move: ", game0.player.active,
		", banner: ", game0.hud.has_node("Banner"), ", log: ", game0.hud.log_lines.back())
	game0.player.active = true  # Bring the hero back for the next tests.

	# Test: resting. Clear the monsters, set HP 10, wait 30 times: +3 HP.
	for m in game0.monsters.duplicate():
		game0._kill(m)
	game0.player.hp = 10
	for t in 30:
		game0._on_player_waited()
	print("Rest test: HP 10 -> ", game0.player.hp, " after 30 waits")

	# Test: embers hits monsters next to you (diagonal too), not 2 tiles away.
	game0.floor_num = 3
	game0._new_floor()
	game0.player.hp = 20
	var near: Monster = game0.monsters[0]
	near.setup("warden", game0.player.cell + Vector2i(1, 1))
	var far: Monster = game0.monsters[1]
	far.setup("warden", game0.player.cell + Vector2i(2, 0))
	game0.player.potions.assign([Potions.Kind.EMBERS])
	game0.drink(0)
	print("Embers test: warden next to you HP ", near.hp, ", warden 2 away HP ", far.hp)

	# Test: XP and levels.
	game0.player.hp = 3
	var levels := []
	for xp in [6, 6, 6, 6, 6, 6, 6, 6]:
		game0._gain_xp(xp)
		levels.append("%d xp=Lv%d" % [game0.player.xp, game0.player.level])
	print("Level test: ", levels, " max HP ", game0.player.max_hp, " HP ", game0.player.hp,
		" damage bonus ", game0.player.damage_bonus)
	game0.queue_free()

	# Test: step on the stairs twice, and check we end on the last floor with no stairs.
	var game = load("res://scenes/game.tscn").instantiate()
	game.test_heroes = 1  # These tests play solo.
	add_child(game)
	for i in Tune.floor_count - 1:
		game._on_player_moved(game.gen.goal)
	var has_stairs: bool = game.gen.to_text().contains(">")
	print("Stairs test: on floor ", game.floor_num, ", stairs here: ", has_stairs)

	# Test: step on every potion on this floor and check they land in the slots.
	var on_floor: int = game.floor_items.size()
	for cell in game.floor_items.keys():
		game._on_player_moved(cell)
	for kind in Potions.Kind.values():
		print("  ", Potions.NAMES[kind], " is ", game.potions.color_of[kind], " this run")
	print("Potion test: ", on_floor, " on the floor, now carrying ", game.player.potions.size(),
		", left on the floor: ", game.floor_items.size())

	# Test: drink one of each kind.
	game.player.potions.assign([Potions.Kind.EMBERS, Potions.Kind.HEALING, Potions.Kind.SIGHT])
	game.drink(0)
	print("Drink test: after Embers HP ", game.player.hp)
	game.drink(0)
	print("Drink test: after Healing HP ", game.player.hp)
	var seen_before_sight: int = game.seen_before.size()
	game.drink(0)
	print("Drink test: Sight seen tiles ", seen_before_sight, " -> ", game.seen_before.size(),
		", known kinds: ", game.potions.known.size(), ", slots left: ", game.player.potions.size())
	print("Log: ", game.hud.log_lines)
	print("Relic test: relic on floor ", game.floor_num, ": ", game.relic != null,
		", at the goal: ", game.relic != null and game.relic.position == Player.cell_to_pos(game.gen.goal))

	# Test: waiting passes a turn.
	var turn_before: int = game.turn
	game._on_player_waited()
	print("Turn test: turn ", turn_before, " -> ", game.turn)

	# Test: step on the relic and win.
	game._on_player_moved(game.gen.goal)
	print("Win test: player can still move: ", game.player.active,
		", banner: ", game.hud.has_node("Banner"), ", log: ", game.hud.log_lines.back())
	get_tree().quit()


## Everything that should come from the seed on this floor, as text.
func _floor_print(game) -> String:
	var out: String = game.gen.to_text()
	for m in game.monsters:
		out += "%s@%s " % [m.type, m.cell]
	for cell in game.floor_items:
		out += "potion%d@%s " % [game.floor_items[cell].get_meta("kind"), cell]
	return out + str(game.potions.color_of)
