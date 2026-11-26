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


func _ready() -> void:
	rng.randomize()  # A new cave every run.
	tiles.tile_set = _make_tile_set()
	remembered.tile_set = tiles.tile_set
	var b := Tune.remembered_brightness
	remembered.modulate = Color(b, b, b)
	_setup_lantern()
	player.moved.connect(_on_player_moved)
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
	_setup_camera()
	_update_view()
	_refresh_hud()


func _on_player_moved(cell: Vector2i) -> void:
	if gen.get_tile(cell) == DungeonGen.Tile.STAIRS:
		_go_down()
		return
	if floor_items.has(cell):
		_pick_up(cell)
	_update_view()
	_refresh_hud()
	if relic and cell == gen.goal:
		_win()


## You grabbed the relic: the run is over and you won.
## (The full end screen with stats comes in card G5.)
func _win() -> void:
	player.active = false
	relic.queue_free()
	relic = null
	hud.add_log("You grab the Ember Relic!")
	hud.show_banner("You win!")


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
			# The damage to monsters next to you is added in card G4.
			player.hp = maxi(player.hp - Tune.embers_self_damage, 0)
			hud.add_log("Embers burst around you! -%d HP" % Tune.embers_self_damage)
	_refresh_hud()


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
