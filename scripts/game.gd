extends Node2D
## The game: makes a cave floor and draws it.

const TILE := 16
const TILE_ART := {
	DungeonGen.Tile.WALL: "res://art/wall.png",
	DungeonGen.Tile.FLOOR: "res://art/floor.png",
	DungeonGen.Tile.STAIRS: "res://art/stairs.png",
}

@onready var tiles: TileMapLayer = $Tiles
@onready var remembered: TileMapLayer = $Remembered
@onready var player: Player = $Player
@onready var camera: Camera2D = $Player/Camera
@onready var lantern: PointLight2D = $Player/Lantern
@onready var darkness: CanvasModulate = $Darkness
@onready var hud: Hud = $HUD
@onready var items_node: Node2D = $Items
@onready var monsters_node: Node2D = $Monsters

const POTION_ART := preload("res://art/potion.png")
const RELIC_ART := preload("res://art/relic.png")
const HERO_ART := preload("res://art/player.png")
## Each hero's color (Ember Cave palette): P1 normal, P2 green, P3 orange, P4 yellow.
const HERO_TINTS := [Color.WHITE, Color("#7fae5a"), Color("#f2a33a"), Color("#ffd966")]

## TEST ONLY (card N1): how many heroes you get when playing alone.
## Tab switches which hero you move. Goes back to 1 when the online menu comes (N2).
@export var test_heroes := 2

## All heroes in the run (1-4). heroes[0] is the Player node in the scene.
var heroes: Array[Player] = []

## Dice for fights. (Only the host rolls these in co-op.)
var rng := RandomNumberGenerator.new()
## The run's seed number. Same seed = same caves, monsters and potions.
## In co-op the host makes it and sends it to everyone.
var run_seed := 0
var gen: DungeonGen
var floor_num := 1
var potions := Potions.new()
## Potions lying on this floor: tile -> Sprite2D (with meta "kind").
var floor_items := {}
## The Ember Relic (only on the last floor, else null).
var relic: Sprite2D
## Tiles the player can see right now (keys of the Dictionary).
var visible_now := {}
## Every tile the player has ever seen on this floor.
var seen_before := {}
## How many turns have passed this run.
var turn := 0
## The monsters on this floor.
var monsters: Array = []
## Steps from each tile to the player (walking around walls). Made fresh each turn.
var path_dist := {}


func _ready() -> void:
	rng.randomize()  # A new cave every run.
	tiles.tile_set = _make_tile_set()
	remembered.tile_set = tiles.tile_set
	var b := Tune.remembered_brightness
	remembered.modulate = Color(b, b, b)
	_setup_lantern()
	_make_heroes(test_heroes)
	hud.slot_pressed.connect(drink)
	start_run(rng.randi())


## Starts a run from a seed number. The same seed always makes the same run.
func start_run(seed_number: int) -> void:
	run_seed = seed_number
	floor_num = 1
	turn = 0
	potions.new_run(_seeded_rng(0))  # Floor "0" = the potion colors.
	_new_floor()
	hud.add_log("You light your lantern and enter the cave.")


## A fresh dice box for one floor, made from the run seed and the floor number.
## Fights use other dice, so a fight can never change what the next floor looks like.
func _seeded_rng(floor_number: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([run_seed, floor_number])
	return r


func _new_floor() -> void:
	var floor_rng := _seeded_rng(floor_num)
	gen = DungeonGen.new()
	gen.generate(floor_rng, floor_num < Tune.floor_count)
	seen_before.clear()
	remembered.clear()
	var spots := _start_spots(heroes.size())
	for i in heroes.size():
		heroes[i].gen = gen
		heroes[i].place(spots[i])
		heroes[i].done = false  # A new floor starts a new round.
	_place_potions(floor_rng)
	_place_relic()
	_place_monsters(floor_rng)
	_setup_camera()
	_update_view()
	_refresh_hud()


# --- Heroes ---

## Makes the hero list. Hero 1 is the Player in the scene (it has the camera).
## The others are copies with their own lantern and color.
func _make_heroes(count: int) -> void:
	heroes = [player]
	for i in range(1, count):
		var h := Player.new()
		h.name = "Hero%d" % (i + 1)
		h.texture = HERO_ART
		var light := PointLight2D.new()
		light.texture = lantern.texture
		light.color = lantern.color
		light.energy = lantern.energy
		h.add_child(light)
		add_child(h)
		heroes.append(h)
	for i in heroes.size():
		var h := heroes[i]
		h.number = i + 1
		h.self_modulate = HERO_TINTS[i]  # The hit flash uses modulate, so the color stays.
		h.controlled = h == player
		h.moved.connect(_on_player_moved)
		h.waited.connect(_on_player_waited)
		h.bumped.connect(_on_player_bumped)
		h.has_monster = func(p: Vector2i) -> bool: return monster_at(p) != null
		h.has_friend = func(p: Vector2i) -> bool: return hero_at(p) != null


## The hero on this tile, or null.
func hero_at(p: Vector2i) -> Player:
	for h in heroes:
		if h.active and h.cell == p:  # Ghosts don't block anyone.
			return h
	return null


## Start tiles for the heroes: the floor tiles of the start room closest to the start.
func _start_spots(count: int) -> Array[Vector2i]:
	var room := _room_with(gen.start)
	var cells: Array[Vector2i] = []
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			var p := Vector2i(x, y)
			if gen.get_tile(p) == DungeonGen.Tile.FLOOR:
				cells.append(p)
	cells.sort_custom(func(a, b): return a.distance_squared_to(gen.start) < b.distance_squared_to(gen.start))
	return cells.slice(0, count)


## TEST ONLY (N1): Tab moves your keys (and the camera) to the next living hero.
func _switch_hero() -> void:
	if player.busy:
		return
	var i := heroes.find(player)
	for step in range(1, heroes.size()):
		var next := heroes[(i + step) % heroes.size()]
		if next.active:
			player.controlled = false
			player = next
			player.controlled = true
			camera.reparent(player, false)
			camera.position = Vector2.ZERO
			camera.reset_smoothing()
			_update_view()
			_refresh_hud()
			return


func _on_player_moved(cell: Vector2i) -> void:
	if gen.get_tile(cell) == DungeonGen.Tile.STAIRS:
		_go_down()
		return
	if floor_items.has(cell):
		_pick_up(cell)
	if relic and cell == gen.goal:
		_update_view()
		_refresh_hud()
		_win()
		return
	_hero_done()


## Wait: skip a turn. If no monster is awake, you rest: every 10 waits heal 1 HP.
func _on_player_waited() -> void:
	var any_awake := monsters.any(func(m): return m.awake)
	if any_awake:
		player.rest_count = 0
		hud.add_log("You wait. You can't rest with a monster awake.")
	elif player.hp < player.max_hp:
		player.rest_count += 1
		if player.rest_count >= Tune.rest_turns_per_hp:
			player.rest_count = 0
			player.hp += 1
			hud.add_log("You rest. +1 HP")
		elif player.rest_count == 1:
			hud.add_log("You rest...")
	else:
		hud.add_log("You wait.")
	_hero_done()


# --- Fighting ---

## You walked into a monster: attack it. That uses your turn.
func _on_player_bumped(target: Vector2i) -> void:
	if not player.active:
		return
	var m := monster_at(target)
	m.awake = true  # Hitting a sleeping monster wakes it up.
	if _rolls_hit(m.info.dodge):
		var dmg := rng.randi_range(Tune.player_damage_min, Tune.player_damage_max) + player.damage_bonus
		m.hp -= dmg
		_flash(m)
		if m.hp <= 0:
			hud.add_log("You kill the %s! +%d XP" % [m.info.name, m.info.xp])
			_kill(m)
			_gain_xp(m.info.xp)
		else:
			hud.add_log("You hit the %s for %d." % [m.info.name, dmg])
	else:
		hud.add_log("You miss the %s." % m.info.name)
	_hero_done()


## A monster next to a hero attacks (called from Monster.take_turn).
## Next to 2 heroes? It picks one of them at random.
func monster_attacks(m: Monster) -> void:
	var targets: Array[Player] = []
	for h in heroes:
		if h.active and (h.cell - m.cell).abs().x + (h.cell - m.cell).abs().y == 1:
			targets.append(h)
	if targets.is_empty():
		return
	var target: Player = targets[rng.randi_range(0, targets.size() - 1)]
	if _rolls_hit(0):  # Heroes have no dodge (yet).
		var dmg := rng.randi_range(m.info.damage[0], m.info.damage[1])
		target.hp = maxi(target.hp - dmg, 0)
		_flash(target)
		hud.add_log("The %s hits %s for %d." % [m.info.name, _who(target), dmg])
		if target.hp <= 0:
			_lose(target, "the " + m.info.name)
	else:
		hud.add_log("The %s misses %s." % [m.info.name, _who(target)])


## How the log names a hero: "you" when playing with 1 hero, else "P2" etc.
func _who(h: Player) -> String:
	return "you" if heroes.size() == 1 else "P%d" % h.number


## Hit chance = 80% minus the target's dodge. Roll a number from 1 to 100.
func _rolls_hit(dodge: int) -> bool:
	return rng.randi_range(1, 100) <= Tune.hit_chance - dodge


## Adds XP. Reaching 10, 25 or 45 XP = level up: +5 max HP, +1 damage, full heal.
func _gain_xp(amount: int) -> void:
	player.xp += amount
	while player.level - 1 < Tune.level_xp.size() and player.xp >= Tune.level_xp[player.level - 1]:
		player.level += 1
		player.max_hp += Tune.level_hp_gain
		player.damage_bonus += Tune.level_damage_gain
		player.hp = player.max_hp
		hud.add_log("Level up! You are level %d. Max HP +%d, damage +%d." % [
			player.level, Tune.level_hp_gain, Tune.level_damage_gain])


## Hit flash: turns the sprite blood red for a moment, then back to normal.
func _flash(sprite: CanvasItem) -> void:
	sprite.modulate = Color("#c8443a")
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, Tune.hit_flash_time)


## A killed monster flashes, then disappears.
func _kill(m: Monster) -> void:
	monsters.erase(m)
	var tween := m.create_tween()
	tween.tween_interval(Tune.hit_flash_time)
	tween.tween_callback(m.queue_free)


# --- Turns ---

## Called after a hero's action (move, attack, wait, drink).
## That hero is done for this round. When every living hero is done,
## the monsters take their turn and a new round starts.
func _hero_done() -> void:
	player.done = true
	if _waiting_for().is_empty():
		_end_turn()
	else:
		_update_view()
		_refresh_hud()


## The living heroes that have not acted yet this round.
func _waiting_for() -> Array[Player]:
	var list: Array[Player] = []
	for h in heroes:
		if h.active and not h.done:
			list.append(h)
	return list


## The monsters' turn: every awake monster gets exactly 1 action.
## Then a new round starts and every hero may act again.
func _end_turn() -> void:
	for h in heroes:
		h.done = false
	turn += 1
	_update_view()
	_wake_monsters()
	_find_paths()
	for m in monsters:
		if m.awake:
			m.take_turn()
	_update_view()
	_refresh_hud()


## Like the flood fill check: paint spreads out from every living hero at once,
## and every tile remembers how many steps the paint needed to get there.
## So the number is the steps to the NEAREST hero.
## A monster just walks to a neighbor tile with a smaller number.
func _find_paths() -> void:
	path_dist = {}
	var todo: Array[Vector2i] = []
	for h in heroes:
		if h.active:
			path_dist[h.cell] = 0
			todo.append(h.cell)
	var i := 0
	while i < todo.size():
		var p := todo[i]
		i += 1
		for dir in Monster.DIRS:
			var n: Vector2i = p + dir
			if not path_dist.has(n) and gen.get_tile(n) != DungeonGen.Tile.WALL:
				path_dist[n] = path_dist[p] + 1
				todo.append(n)


## True if a monster may step here: no wall, no other monster, not the player.
func is_free(p: Vector2i) -> bool:
	return gen.get_tile(p) != DungeonGen.Tile.WALL and hero_at(p) == null and monster_at(p) == null


## A sleeping monster wakes up when any living hero comes within its wake range
## (4 tiles, or 6 for the Bone Warden), counted in a straight line.
func _wake_monsters() -> void:
	for m in monsters:
		if m.awake:
			continue
		var dist := INF
		for h in heroes:
			if h.active:
				dist = minf(dist, Vector2(m.cell - h.cell).length())
		if dist <= m.info.wake:
			m.awake = true
			if visible_now.has(m.cell):
				hud.add_log("The %s wakes up!" % m.info.name)


## HP 0: the run is over. Permadeath: next time is a brand new run.
## (The full end screen with stats comes in card G5.)
## With friends, the run only ends when every hero is down.
func _lose(hero: Player, killer: String) -> void:
	if not hero.active:
		return
	hero.active = false
	hero.modulate = Color("#6b5a4e", 0.6)  # A gray see-through ghost.
	for child in hero.get_children():
		if child is PointLight2D:
			child.visible = false  # Its lantern goes out.
	if heroes.size() == 1:
		hud.add_log("You were killed by %s." % killer)
	else:
		hud.add_log("P%d was killed by %s." % [hero.number, killer])
	if heroes.all(func(h: Player) -> bool: return not h.active):
		hud.show_banner("You died")
	else:
		_watch_friend()


## If the camera is on a fallen hero, it moves to a living friend.
func _watch_friend() -> void:
	var watched: Player = camera.get_parent()
	if watched.active:
		return
	for h in heroes:
		if h.active:
			camera.reparent(h, false)
			camera.position = Vector2.ZERO
			camera.reset_smoothing()
			return


## You grabbed the relic: the run is over and you won.
## (The full end screen with stats comes in card G5.)
## Anyone grabbing it wins for the whole team, even the fallen heroes.
func _win() -> void:
	for h in heroes:
		h.active = false
	relic.queue_free()
	relic = null
	if heroes.size() == 1:
		hud.add_log("You grab the Ember Relic!")
	else:
		hud.add_log("P%d grabs the Ember Relic! You win together!" % player.number)
	hud.show_banner("You win!")


# --- Monsters ---

## Puts this floor's monsters on random free tiles, never in the room you start in.
## Each one is a random type that lives on this floor.
func _place_monsters(floor_rng: RandomNumberGenerator) -> void:
	for m in monsters:
		m.queue_free()
	monsters.clear()

	var types: Array = []
	for t in Tune.monster_types:
		if floor_num in Tune.monster_types[t].floors:
			types.append(t)

	var start_room := _room_with(gen.start)
	var taken := floor_items.duplicate()
	for i in Tune.monsters_per_floor[floor_num - 1]:
		var cell := gen.random_free_spot(floor_rng, taken)
		while start_room.has_point(cell):
			cell = gen.random_free_spot(floor_rng, taken)
		taken[cell] = true
		var m := Monster.new()
		m.game = self
		m.setup(types[floor_rng.randi_range(0, types.size() - 1)], cell)
		m.visible = false  # Hidden until you see it.
		monsters_node.add_child(m)
		monsters.append(m)


## The room that has this tile in it.
func _room_with(p: Vector2i) -> Rect2i:
	for r in gen.rooms.values():
		if r.has_point(p):
			return r
	return Rect2i()


## The monster on this tile, or null.
func monster_at(p: Vector2i) -> Monster:
	for m in monsters:
		if m.cell == p:
			return m
	return null


# --- Potions ---

## Puts this floor's potions on random free floor tiles.
func _place_potions(floor_rng: RandomNumberGenerator) -> void:
	for sprite in items_node.get_children():
		sprite.queue_free()
	floor_items.clear()
	for kind in potions.by_floor[floor_num - 1]:
		var cell := gen.random_free_spot(floor_rng, floor_items)
		var sprite := Sprite2D.new()
		sprite.texture = POTION_ART
		sprite.position = Player.cell_to_pos(cell)
		sprite.set_meta("kind", kind)
		sprite.self_modulate = potions.tint(kind)  # The white bottle gets this run's color.
		sprite.visible = false  # Hidden until you see it.
		items_node.add_child(sprite)
		floor_items[cell] = sprite


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_TAB:
		get_viewport().set_input_as_handled()
		_switch_hero()  # TEST ONLY (N1)
		return
	for i in Hud.SLOT_COUNT:
		if event.is_action_pressed("drink_%d" % (i + 1)):
			get_viewport().set_input_as_handled()
			drink(i)
			return


## Drinks the potion in slot `index` (0 = slot 1). Now you know what that color does.
func drink(index: int) -> void:
	if player.busy or not player.active or player.done or index >= player.potions.size():
		return
	var kind: int = player.potions[index]
	player.potions.remove_at(index)
	var was_known := potions.known.has(kind)
	var color_name: String = potions.color_of[kind]
	potions.learn(kind)
	if not was_known:
		hud.add_log("The %s potion was %s!" % [color_name, Potions.NAMES[kind]])

	match kind:
		Potions.Kind.HEALING:
			var before := player.hp
			player.hp = mini(player.hp + Tune.heal_amount, player.max_hp)
			hud.add_log("You feel better. +%d HP" % (player.hp - before))
		Potions.Kind.SIGHT:
			_reveal_floor()
			hud.add_log("You see the whole floor in your mind.")
		Potions.Kind.EMBERS:
			player.hp = maxi(player.hp - Tune.embers_self_damage, 0)
			_flash(player)
			hud.add_log("Embers burst around you! -%d HP" % Tune.embers_self_damage)
			_burn_neighbors()
			if player.hp <= 0:
				_lose(player, "their own embers" if heroes.size() > 1 else "your own embers")
				# No return: the round goes on for the friends who are still alive.
	_hero_done()  # Drinking takes your turn.


## Embers potion: every monster on the 8 tiles around you takes 6 damage.
func _burn_neighbors() -> void:
	for m in monsters.duplicate():
		var d: Vector2i = (m.cell - player.cell).abs()
		if maxi(d.x, d.y) != 1:
			continue
		m.awake = true
		m.hp -= Tune.embers_monster_damage
		_flash(m)
		if m.hp <= 0:
			hud.add_log("The %s burns up! +%d XP" % [m.info.name, m.info.xp])
			_kill(m)
			_gain_xp(m.info.xp)
		else:
			hud.add_log("The %s is burned for %d." % [m.info.name, Tune.embers_monster_damage])


## Sight potion: every tile of this floor counts as seen (shown dim).
func _reveal_floor() -> void:
	for y in gen.height:
		for x in gen.width:
			var p := Vector2i(x, y)
			if not seen_before.has(p):
				seen_before[p] = true
				_draw_tile(remembered, p)


# --- The Ember Relic ---

## On the last floor, the relic sits on the goal spot (where stairs would be).
## It has its own small orange glow, and it slowly pulses.
func _place_relic() -> void:
	if relic:
		relic.queue_free()
		relic = null
	if floor_num < Tune.floor_count:
		return
	relic = Sprite2D.new()
	relic.texture = RELIC_ART
	relic.position = Player.cell_to_pos(gen.goal)
	relic.visible = false  # Hidden until you see it.

	var glow := PointLight2D.new()
	glow.texture = lantern.texture  # Same round glow as the lantern, just smaller.
	glow.texture_scale = 0.35
	glow.color = Color("#f2a33a")  # lantern orange
	glow.energy = 1.0
	relic.add_child(glow)
	items_node.add_child(relic)

	var pulse := relic.create_tween().set_loops()
	pulse.tween_property(glow, "energy", 1.6, 0.8)
	pulse.tween_property(glow, "energy", 0.8, 0.8)


## Walked onto a potion: put it in a free slot, if there is one.
func _pick_up(cell: Vector2i) -> void:
	if player.potions.size() >= Hud.SLOT_COUNT:
		hud.add_log("Your slots are full.")
		return
	var sprite: Sprite2D = floor_items[cell]
	var kind: int = sprite.get_meta("kind")
	player.potions.append(kind)
	floor_items.erase(cell)
	sprite.queue_free()
	hud.add_log("You pick up a %s." % potions.display_name(kind))


## Stairs: go 1 floor deeper. Every floor is brand new.
## The last floor has no stairs (the relic is there instead).
## With friends: 1 hero on the stairs takes the whole team down (ghosts too).
func _go_down() -> void:
	floor_num += 1
	_new_floor()
	if heroes.size() > 1:
		hud.add_log("P%d found the stairs. The team goes down together." % player.number)
	if floor_num == Tune.floor_count:
		hud.add_log("You go down to floor %d. The relic is near..." % floor_num)
	else:
		hud.add_log("You go down to floor %d." % floor_num)


func _refresh_hud() -> void:
	var waiting := ""
	var watched: Player = camera.get_parent()
	if watched != player:
		waiting = "You are down. Watching P%d" % watched.number
	elif player.done:
		var names: Array[String] = []
		for h in _waiting_for():
			names.append("P%d" % h.number)
		waiting = "Waiting for " + ", ".join(names)
	hud.show_stats(player, floor_num, waiting)
	hud.show_slots(player.potions, potions)


## Works out what the heroes can see, then redraws.
## Shared vision: you see everything any living hero's lantern lights.
## Fog has 3 looks: clear = you see it now, dim = you saw it before, black = never seen.
func _update_view() -> void:
	visible_now = {}
	var anyone_alive := heroes.any(func(h: Player) -> bool: return h.active)
	for h in heroes:
		if h.active or not anyone_alive:  # Game over: show what everyone saw last.
			visible_now.merge(Fov.compute(gen, h.cell, Tune.sight_radius))
	tiles.clear()
	for p in visible_now:
		_draw_tile(tiles, p)
		if not seen_before.has(p):
			seen_before[p] = true
			_draw_tile(remembered, p)  # The dim layer sits under the clear one.
	# Potions show only while you can see their tile.
	for cell in floor_items:
		floor_items[cell].visible = visible_now.has(cell)
	if relic:
		relic.visible = visible_now.has(gen.goal)
	for m in monsters:
		m.visible = visible_now.has(m.cell)


## The whole cave is made darker (Darkness), and the lantern adds a warm glow
## around the player that fades out at the edge of your sight.
func _setup_lantern() -> void:
	var d := Tune.cave_darkness
	darkness.color = Color(d, d, d)

	var glow := Gradient.new()
	glow.set_color(0, Color.WHITE)
	glow.set_color(1, Color(1, 1, 1, 0))
	var tex := GradientTexture2D.new()
	var size := int((Tune.sight_radius + 0.5) * TILE * 2)
	tex.width = size
	tex.height = size
	tex.gradient = glow
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)

	lantern.texture = tex
	lantern.color = Color("#ffd966")  # flame yellow
	lantern.energy = Tune.lantern_energy


## The camera rides on the player, zoomed in, and stops at the edges of the cave.
func _setup_camera() -> void:
	camera.zoom = Vector2.ONE * Tune.camera_zoom
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = gen.width * TILE
	camera.limit_bottom = gen.height * TILE
	camera.reset_smoothing()


## Puts the right picture on one tile.
## Walls deep inside the rock are left empty (black), so only the cave's edges show.
func _draw_tile(layer: TileMapLayer, p: Vector2i) -> void:
	var t := gen.get_tile(p)
	if t == DungeonGen.Tile.WALL and not _touches_floor(p):
		return
	layer.set_cell(p, t, Vector2i.ZERO)


func _touches_floor(p: Vector2i) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if gen.get_tile(p + Vector2i(dx, dy)) != DungeonGen.Tile.WALL:
				return true
	return false


## Builds the tile set from our 3 tile pictures. Each tile type gets its own source id.
func _make_tile_set() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	for t in TILE_ART:
		var src := TileSetAtlasSource.new()
		src.texture = load(TILE_ART[t])
		src.texture_region_size = Vector2i(TILE, TILE)
		src.create_tile(Vector2i.ZERO)
		ts.add_source(src, t)
	return ts
