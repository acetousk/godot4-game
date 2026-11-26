extends Node3D
## The game: builds the walking map, spawns the bots, and decides who wins.

const BOT_SCENE := preload("res://scenes/bot.tscn")
## Where the bots start.
const BOT_SPAWNS := [Vector3(-40, 1, -10), Vector3(40, 1, 30), Vector3(0, 1, -55)]

var game_over := false
## Seconds before you can restart (so a held button does not skip the message).
var restart_wait := 0.0
var match_time := 0.0

@onready var nav_region: NavigationRegion3D = $NavRegion
@onready var player: Fighter = $Player
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	# Work out where you can walk on the island (no threads, for the web).
	nav_region.bake_navigation_mesh(false)
	for i in BOT_SPAWNS.size():
		var bot: Fighter = BOT_SCENE.instantiate()
		bot.name = "Bot%d" % (i + 1)
		bot.position = BOT_SPAWNS[i]
		add_child(bot)
		bot.eliminated.connect(_on_eliminated)
	player.eliminated.connect(_on_eliminated)


func _process(delta: float) -> void:
	if not game_over:
		match_time += delta
	else:
		restart_wait -= delta


## Someone is out: check if the match is over.
func _on_eliminated(who: Fighter, _by: Fighter) -> void:
	if game_over:
		return
	var left := get_tree().get_nodes_in_group("fighter").size()
	if who == player:
		_end("You are out", "Place #%d" % (left + 1))
	elif left == 1 and not player.is_out:
		_end("Victory!", "Place #1")


func _end(title: String, place: String) -> void:
	game_over = true
	restart_wait = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var stats := "%s   Eliminations %d   Time %d:%02d" % [place, player.eliminations, int(match_time) / 60, int(match_time) % 60]
	hud.show_end(title, stats)
	print("Match over: ", title, "  ", stats)


func _unhandled_input(event: InputEvent) -> void:
	# After the match: click, tap, or press jump to play again.
	if game_over and restart_wait <= 0.0:
		if event.is_action_pressed("jump") or event.is_action_pressed("fire") or event is InputEventScreenTouch:
			get_tree().reload_current_scene()
