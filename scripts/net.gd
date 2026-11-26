extends Node
## Net (autoload): all the online co-op code. The only file that talks to GD-Sync.
## GD-Sync docs: Getting Started, Clients, Lobbies, Remote Calls (pasted by the kid).

## The status text changed (for the menu to show).
signal status_changed(text: String)
## Someone joined or left the room.
signal players_changed
## You are inside a room now (code = the 4 digits).
signal room_joined(code: String)
## Making or joining a room did not work.
signal room_failed(text: String)

## true = local network only: no key needed, no data used. Good for testing.
## false = online through the GD-Sync servers (needs the key in Project > Tools > GD-Sync).
const LOCAL := true
const MAX_PLAYERS := 4

## True after GD-Sync says we are connected.
var online := false
## What is going on, in plain words.
var status := "Offline"
## Client ids of everyone in the room, in the order they joined.
var players: Array[int] = []
## The room you are in ("" = none). A room is a private GD-Sync lobby named by 4 digits.
var room_code := ""
## True while playing a co-op run (false = solo).
var in_coop := false
## The run's seed number, made by the host and sent to everyone.
var run_seed := 0
## Which hero is mine: 0 = P1, 1 = P2, ...
var my_index := 0

## What to do once we are connected (like "make a room"). Empty = nothing.
var _after_connect: Callable
## How many codes we tried (if a code is taken, we pick another one).
var _tries := 0


func _ready() -> void:
	GDSync.connected.connect(_on_connected)
	GDSync.connection_failed.connect(_on_connection_failed)
	GDSync.disconnected.connect(_on_disconnected)
	GDSync.client_joined.connect(_on_client_joined)
	GDSync.client_left.connect(_on_client_left)
	GDSync.lobby_created.connect(_on_lobby_created)
	GDSync.lobby_creation_failed.connect(_on_lobby_creation_failed)
	GDSync.lobby_joined.connect(_on_lobby_joined)
	GDSync.lobby_join_failed.connect(_on_lobby_join_failed)
	# Other players may call start_game on us, but only if they are the host.
	GDSync.expose_func(start_game, ENUMS.EXPOSE_PERMISSION.HOST)


## Host only: locks the room, makes the seed, and starts the game on every client
## (also on the host itself). The hero order is the join order: the host is P1.
func host_starts_game() -> void:
	if not is_host() or players.size() < 2:
		return
	GDSync.lobby_close()  # No more joining after the start.
	GDSync.call_func_all(start_game, randi(), players)


## Runs on every client (called by the host). Everyone gets the same seed,
## so everyone builds the same cave.
func start_game(seed_number: int, order: Array) -> void:
	players.assign(order)
	my_index = players.find(my_id())
	run_seed = seed_number
	in_coop = true
	get_tree().change_scene_to_file("res://scenes/game.tscn")


## Host: makes a private room with a random 4-digit code, then joins it.
## The first one in a room is the host.
## (Tests can pass a fixed code.)
func host_room(test_code := "") -> void:
	if not online:
		_after_connect = host_room.bind(test_code)
		go_online()
		return
	_tries += 1
	var code := test_code if test_code != "" else str(randi_range(1000, 9999))
	_set_status("Making room %s..." % code)
	GDSync.lobby_create(code, "", false, MAX_PLAYERS)  # false = private, not in any public list


## Join: goes into a friend's room by its 4-digit code.
func join_room(code: String) -> void:
	if not online:
		_after_connect = join_room.bind(code)
		go_online()
		return
	_set_status("Joining room %s..." % code)
	GDSync.lobby_join(code)


## Leaves the room you are in.
func leave_room() -> void:
	if room_code != "":
		GDSync.lobby_leave()
	room_code = ""
	players.clear()
	_set_status("Connected" if online else "Offline")


## Starts GD-Sync. Calls the "connected" signal when it works.
func go_online() -> void:
	if online:
		return
	_set_status("Connecting...")
	if LOCAL:
		GDSync.start_local_multiplayer()
	else:
		GDSync.start_multiplayer()


## Stops GD-Sync (back to solo).
func go_offline() -> void:
	if status == "Offline":
		return  # Never started, nothing to stop.
	GDSync.stop_multiplayer()
	online = false
	in_coop = false
	room_code = ""
	players.clear()
	_set_status("Offline")


## My own id (-1 if not connected).
func my_id() -> int:
	return GDSync.get_client_id()


## True if I am the boss of the cave (or playing solo).
func is_host() -> bool:
	return not online or GDSync.is_host()


func _on_connected() -> void:
	online = true
	_set_status("Connected (%s)" % ("local network" if LOCAL else "online"))
	if _after_connect.is_valid():
		var next := _after_connect
		_after_connect = Callable()
		next.call()


## The room exists. We have 5 seconds to join it, or GD-Sync deletes it.
func _on_lobby_created(code: String) -> void:
	_tries = 0
	GDSync.lobby_join(code)


func _on_lobby_creation_failed(code: String, error: int) -> void:
	if error == ENUMS.LOBBY_CREATION_ERROR.LOBBY_ALREADY_EXISTS and _tries < 5:
		host_room()  # That code is taken: try another one.
		return
	_tries = 0
	match error:
		ENUMS.LOBBY_CREATION_ERROR.ON_COOLDOWN:
			room_failed.emit("Wait a few seconds, then try again.")
		_:
			room_failed.emit("Couldn't make room %s (error %d)." % [code, error])


func _on_lobby_joined(code: String) -> void:
	room_code = code
	_set_status("In room %s" % code)
	room_joined.emit(code)


func _on_lobby_join_failed(code: String, error: int) -> void:
	match error:
		ENUMS.LOBBY_JOIN_ERROR.LOBBY_DOES_NOT_EXIST:
			room_failed.emit("Room %s not found." % code)
		ENUMS.LOBBY_JOIN_ERROR.LOBBY_IS_FULL:
			room_failed.emit("Room %s is full (4 players)." % code)
		ENUMS.LOBBY_JOIN_ERROR.LOBBY_IS_CLOSED:
			room_failed.emit("Room %s already started." % code)
		_:
			room_failed.emit("Couldn't join room %s (error %d)." % [code, error])


func _on_connection_failed(error: int) -> void:
	online = false
	match error:
		ENUMS.CONNECTION_FAILED.INVALID_PUBLIC_KEY:
			_set_status("Can't connect: the GD-Sync key is wrong or missing (ask your parent).")
		ENUMS.CONNECTION_FAILED.TIMEOUT:
			_set_status("Can't connect: check your internet.")
		_:
			_set_status("Can't connect (error %d)." % error)


func _on_disconnected() -> void:
	online = false
	players.clear()
	room_code = ""
	_set_status("Lost the connection.")
	players_changed.emit()


func _on_client_joined(client_id: int) -> void:
	if not players.has(client_id):
		players.append(client_id)
		players_changed.emit()


func _on_client_left(client_id: int) -> void:
	players.erase(client_id)
	players_changed.emit()


func _set_status(text: String) -> void:
	status = text
	print("Net: ", text)  # Also shows in Godot's Output panel.
	status_changed.emit(text)
