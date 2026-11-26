class_name Player
extends Sprite2D
## The lantern guy. Moves 1 tile at a time on the grid, with a short slide.

## Sent after each step, when the slide is done.
signal moved(cell: Vector2i)
## Sent when you skip a turn (Space / A).
signal waited
## Sent when you walk into a monster: that's an attack.
signal bumped(target: Vector2i)

const TILE := 16
const DIRS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

## Which tile the player is on.
var cell: Vector2i
## The floor we walk on (to know where the walls are).
var gen: DungeonGen
## True while sliding. No new step until the slide is done.
var busy := false
## False when the run is over (win or lose): no more moving.
var active := true

# --- Stats ---
var max_hp := Tune.player_hp
var hp := Tune.player_hp
var level := 1
var xp := 0
## Extra damage from leveling up.
var damage_bonus := 0
## Asks "is there a monster on this tile?" (set by the game).
var has_monster: Callable = func(_p: Vector2i) -> bool: return false
## Potions you carry (Potions.Kind), up to 4.
var potions: Array[int] = []


## Puts the player on a tile right away (no slide).
func place(c: Vector2i) -> void:
	cell = c
	position = cell_to_pos(c)


static func cell_to_pos(c: Vector2i) -> Vector2:
	return Vector2(c * TILE) + Vector2(TILE, TILE) / 2.0


func _unhandled_input(event: InputEvent) -> void:
	if busy or not active:
		return
	if event.is_action_pressed("wait", true):
		get_viewport().set_input_as_handled()
		waited.emit()
		return
	for action in DIRS:
		# true = holding the key keeps walking
		if event.is_action_pressed(action, true):
			get_viewport().set_input_as_handled()
			try_move(DIRS[action])
			return


func try_move(dir: Vector2i) -> void:
	var target := cell + dir
	if gen.get_tile(target) == DungeonGen.Tile.WALL:
		return  # Walls block you.
	if has_monster.call(target):
		bumped.emit(target)  # Walking into a monster = attacking it.
		return
	cell = target
	busy = true
	var tween := create_tween()
	tween.tween_property(self, "position", cell_to_pos(cell), Tune.move_time)
	tween.finished.connect(_on_slide_done)


func _on_slide_done() -> void:
	busy = false
	moved.emit(cell)
