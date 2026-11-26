extends CanvasLayer
## The HUD: shows your HP, ammo, and heal kits on screen.

@onready var hp_label: Label = $HP
@onready var ammo_label: Label = $Ammo
@onready var heal_label: Label = $Heals


func _process(_delta: float) -> void:
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
