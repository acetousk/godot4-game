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

var rng := RandomNumberGenerator.new()
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
## Waits in a row with no monster awake. Every 10 = +1 HP.
var rest_count := 0


func _ready() -> void:
	rng.randomize()  # A new cave every run.
	tiles.tile_set = _make_tile_set()
	remembered.tile_set = tiles.tile_set
	var b := Tune.remembered_brightness
	remembered.modulate = Color(b, b, b)
	_setup_lantern()
	player.moved.connect(_on_player_moved)
	player.waited.connect(_on_player_waited)
	player.bumped.connect(_on_player_bumped)
	player.has_monster = func(p: Vector2i) -> bool: return monster_at(p) != null
	hud.slot_pressed.connect(drink)
	potions.new_run(rng)
	_new_floor()
	hud.add_log("You light your lantern and enter the cave.")


func _new_floor() -> void:
	gen = DungeonGen.new()
	gen.generate(rng, floor_num < Tune.floor_count)
	seen_before.clear()
	remembered.clear()
	player.gen = gen
	player.place(gen.start)
	_place_potions()
	_place_relic()
	_place_monsters()
	_setup_camera()
	_update_view()
	_refresh_hud()


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
	_end_turn()


## Wait: skip a turn. If no monster is awake, you rest: every 10 waits heal 1 HP.
func _on_player_waited() -> void:
	var any_awake := monsters.any(func(m): return m.awake)
	if any_awake:
		rest_count = 0
		hud.add_log("You wait. You can't rest with a monster awake.")
	elif player.hp < player.max_hp:
		rest_count += 1
		if rest_count >= Tune.rest_turns_per_hp:
			rest_count = 0
			player.hp += 1
			hud.add_log("You rest. +1 HP")
		elif rest_count == 1:
			hud.add_log("You rest...")
	else:
		hud.add_log("You wait.")
	_end_turn()


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
	_end_turn()


## A monster next to you attacks (called from Monster.take_turn).
func monster_attacks(m: Monster) -> void:
	if not player.active:
		return
	if _rolls_hit(0):  # You have no dodge (yet).
		var dmg := rng.randi_range(m.info.damage[0], m.info.damage[1])
		player.hp = maxi(player.hp - dmg, 0)
		_flash(player)
		hud.add_log("The %s hits you for %d." % [m.info.name, dmg])
		if player.hp <= 0:
			_lose("the " + m.info.name)
	else:
		hud.add_log("The %s misses you." % m.info.name)


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

## Called after every player action (move, wait, drink).
## Then every awake monster gets exactly 1 action.
func _end_turn() -> void:
	turn += 1
	_update_view()
	_wake_monsters()
	_find_paths()
	for m in monsters:
		if m.awake:
			m.take_turn()
	_update_view()
	_refresh_hud()


## Like the flood fill check: paint spreads out from the player, and every tile
## remembers how many steps the paint needed to get there.
## A monster just walks to a neighbor tile with a smaller number.
func _find_paths() -> void:
	path_dist = {player.cell: 0}
	var todo: Array[Vector2i] = [player.cell]
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
	return gen.get_tile(p) != DungeonGen.Tile.WALL and p != player.cell and monster_at(p) == null


## A sleeping monster wakes up when you come within its wake range
## (4 tiles, or 6 for the Bone Warden), counted in a straight line.
func _wake_monsters() -> void:
	for m in monsters:
		if m.awake:
			continue
		var dist := Vector2(m.cell - player.cell).length()
		if dist <= m.info.wake:
			m.awake = true
			if visible_now.has(m.cell):
				hud.add_log("The %s wakes up!" % m.info.name)


## HP 0: the run is over. Permadeath: next time is a brand new run.
## (The full end screen with stats comes in card G5.)
func _lose(killer: String) -> void:
	if not player.active:
		return
	player.active = false
	player.modulate = Color("#6b5a4e")  # The hero turns to gray rock color.
	hud.add_log("You were killed by %s." % killer)
	hud.show_banner("You died")


## You grabbed the relic: the run is over and you won.
## (The full end screen with stats comes in card G5.)
func _win() -> void:
	player.active = false
	relic.queue_free()
	relic = null
	hud.add_log("You grab the Ember Relic!")
	hud.show_banner("You win!")


# --- Monsters ---

## Puts this floor's monsters on random free tiles, never in the room you start in.
## Each one is a random type that lives on this floor.
func _place_monsters() -> void:
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
		var cell := gen.random_free_spot(rng, taken)
		while start_room.has_point(cell):
			cell = gen.random_free_spot(rng, taken)
		taken[cell] = true
		var m := Monster.new()
		m.game = self
		m.setup(types[rng.randi_range(0, types.size() - 1)], cell)
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
func _place_potions() -> void:
	for sprite in items_node.get_children():
		sprite.queue_free()
	floor_items.clear()
	for kind in potions.by_floor[floor_num - 1]:
		var cell := gen.random_free_spot(rng, floor_items)
		var sprite := Sprite2D.new()
		sprite.texture = POTION_ART
		sprite.position = Player.cell_to_pos(cell)
		sprite.set_meta("kind", kind)
		sprite.self_modulate = potions.tint(kind)  # The white bottle gets this run's color.
		sprite.visible = false  # Hidden until you see it.
		items_node.add_child(sprite)
		floor_items[cell] = sprite


func _unhandled_input(event: InputEvent) -> void:
	for i in Hud.SLOT_COUNT:
		if event.is_action_pressed("drink_%d" % (i + 1)):
			get_viewport().set_input_as_handled()
			drink(i)
			return


## Drinks the potion in slot `index` (0 = slot 1). Now you know what that color does.
func drink(index: int) -> void:
	if player.busy or not player.active or index >= player.potions.size():
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
				_lose("your own embers")
				_refresh_hud()
				return
	_end_turn()  # Drinking takes your turn.


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
func _go_down() -> void:
	floor_num += 1
	_new_floor()
	if floor_num == Tune.floor_count:
		hud.add_log("You go down to floor %d. The relic is near..." % floor_num)
	else:
		hud.add_log("You go down to floor %d." % floor_num)


func _refresh_hud() -> void:
	hud.show_stats(player, floor_num)
	hud.show_slots(player.potions, potions)


## Works out what the player can see, then redraws.
## Fog has 3 looks: clear = you see it now, dim = you saw it before, black = never seen.
func _update_view() -> void:
	visible_now = Fov.compute(gen, player.cell, Tune.sight_radius)
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
