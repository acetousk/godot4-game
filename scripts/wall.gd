extends StaticBody3D
## A wall you built: blocks bullets until its HP runs out.

var hp := 150.0


func _ready() -> void:
	add_to_group("wall")
	hp = Tune.wall_hp
	# One build square wide and tall.
	$Mesh.mesh.size = Vector3(Tune.build_grid, Tune.build_grid, 0.2)
	$Shape.shape.size = Vector3(Tune.build_grid, Tune.build_grid, 0.2)


## Bullets that hit the wall hurt the wall instead of you.
func take_damage(amount: float, _by: Node) -> void:
	hp -= amount
	if hp <= 0.0:
		queue_free()
