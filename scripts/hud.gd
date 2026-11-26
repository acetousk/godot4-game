extends CanvasLayer
## The HUD: shows your HP, ammo, and heal kits on screen.

@onready var hp_label: Label = $HP
@onready var ammo_label: Label = $Ammo
@onready var heal_label: Label = $Heals
@onready var left_label: Label = $Left
@onready var end_box: Control = $End
@onready var storm_label: Label = $StormTimer
@onready var warning_label: Label = $StormWarning


func _ready() -> void:
	end_box.visible = false
	warning_label.visible = false


## Show the end-of-match message.
func show_end(title: String, stats: String) -> void:
	$End/Title.text = title
	$End/Stats.text = stats
	end_box.visible = true


func _process(_delta: float) -> void:
	# Everyone still in the match is in the "fighter" group.
	left_label.text = "Players left %d" % get_tree().get_nodes_in_group("fighter").size()

	# Storm timer, and a warning when you stand outside the circle.
	var storm := get_tree().get_first_node_in_group("storm")
	var player_node := get_tree().get_first_node_in_group("player")
	if storm:
		var secs := ceili(storm.time_left())
		var clock := "%d:%02d" % [floori(secs / 60.0), secs % 60]
		storm_label.text = ("Storm shrinking " if storm.shrinking else "Storm in ") + clock
		warning_label.visible = player_node != null and not player_node.is_out \
				and not storm.is_safe(player_node.global_position)
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	hp_label.text = "HP %d" % ceili(player.hp)
	if player.heal_left > 0.0:
		hp_label.text += "  healing..."
	if player.reloading:
		ammo_label.text = "Reloading..."
	elif player.has_rifle:
		ammo_label.text = "Burst rifle  %d / %d" % [player.ammo, Tune.rifle_mag]
	else:
		ammo_label.text = "No gun - open a chest"
	heal_label.text = "Heal kits  %d" % player.heal_kits
