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

var rng := RandomNumberGenerator.new()
var gen: DungeonGen
var floor_num := 1
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
	print("Floor ", floor_num)
	_new_floor()


func _new_floor() -> void:
	gen = DungeonGen.new()
	gen.generate(rng, floor_num < Tune.floor_count)
	seen_before.clear()
	remembered.clear()
	player.gen = gen
	player.place(gen.start)
	_setup_camera()
	_update_view()


func _on_player_moved(cell: Vector2i) -> void:
	if gen.get_tile(cell) == DungeonGen.Tile.STAIRS:
		_go_down()
		return
	_update_view()


## Stairs: go 1 floor deeper. Every floor is brand new.
## The last floor has no stairs (the relic will be there, in card G3).
func _go_down() -> void:
	floor_num += 1
	print("Floor ", floor_num)
	_new_floor()


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
