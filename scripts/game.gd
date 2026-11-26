extends Node3D
## The game: builds the walking map, spawns players and bots, and decides who wins.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const BOT_SCENE := preload("res://scenes/bot.tscn")
## Where the bots start.
const BOT_SPAWNS := [Vector3(-40, 1, -10), Vector3(40, 1, 30), Vector3(0, 1, -55)]
## How far from the middle the players start in the sky.
const PLAYER_SPREAD := 20.0

var game_over := false
## Seconds before you can restart (so a held button does not skip the message).
var restart_wait := 0.0
var match_time := 0.0

@onready var nav_region: NavigationRegion3D = $NavRegion
@onready var players: Node3D = $Players
@onready var hud: CanvasLayer = $HUD


func _ready() -> void:
	# Work out where you can walk on the island (no threads, for the web).
	nav_region.bake_navigation_mesh(false)
	# Every player that shows up (yours or a friend's) can be eliminated.
	players.child_entered_tree.connect(_on_player_added)

	if not Net.online:
		# Solo: one player (you) and the bots.
		var me: Fighter = PLAYER_SCENE.instantiate()
		players.add_child(me)
		me.become_local()
		_spawn_bots()
	elif Net.is_host():
		# Online: the host makes one player per person. No bots yet (step 5).
		# Wait a moment so every screen has loaded the island.
		await get_tree().create_timer(0.5).timeout
		var ids := Net.everyone()
		for i in ids.size():
			var p: Fighter = Net.spawn_for_everyone(PLAYER_SCENE, players)
			var angle := TAU * i / ids.size()
			p.position = Vector3(cos(angle), 0, sin(angle)) * PLAYER_SPREAD + Vector3(0, Tune.drop_height, 0)
			Net.give_to(p, ids[i])


func _spawn_bots() -> void:
	for i in BOT_SPAWNS.size():
		var bot: Fighter = BOT_SCENE.instantiate()
		bot.name = "Bot%d" % (i + 1)
		bot.position = BOT_SPAWNS[i]
		add_child(bot)
		bot.eliminated.connect(_on_eliminated)


func _on_player_added(node: Node) -> void:
	if node is Fighter:
		node.eliminated.connect(_on_eliminated)


## Your own player (null until the host gives it to you).
func _me() -> Fighter:
	return get_tree().get_first_node_in_group("player")


func _process(delta: float) -> void:
	if not game_over:
		match_time += delta
	else:
		restart_wait -= delta


## Someone is out: check if the match is over.
func _on_eliminated(who: Fighter, _by: Fighter) -> void:
	var me := _me()
	if game_over or me == null:
		return
	var left := get_tree().get_nodes_in_group("fighter").size()
	if who == me:
		_end("You are out", "Place #%d" % (left + 1))
	elif left == 1 and not me.is_out:
		_end("Victory!", "Place #1")


func _end(title: String, place: String) -> void:
	game_over = true
	restart_wait = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var stats := "%s   Eliminations %d   Time %d:%02d" % [place, _me().eliminations, int(match_time) / 60, int(match_time) % 60]
	hud.show_end(title, stats)
	print("Match over: ", title, "  ", stats)


func _unhandled_input(event: InputEvent) -> void:
	# After the match: click, tap, or press jump to play again.
	if game_over and restart_wait <= 0.0:
		if event.is_action_pressed("jump") or event.is_action_pressed("fire") or event is InputEventScreenTouch:
			get_tree().reload_current_scene()
