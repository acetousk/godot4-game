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

	# Test: step on the stairs twice, and check we end on the last floor with no stairs.
	var game = load("res://scenes/game.tscn").instantiate()
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

	# Test: step on the relic and win.
	game._on_player_moved(game.gen.goal)
	print("Win test: player can still move: ", game.player.active,
		", banner: ", game.hud.has_node("Banner"), ", log: ", game.hud.log_lines.back())
	get_tree().quit()
