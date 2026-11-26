class_name Fighter
extends CharacterBody3D
## Shared by the player and the bots: health, taking damage, and being out.

## Someone is out. `by` is who did it (can be null).
signal eliminated(who: Fighter, by: Fighter)

## Your health. At 0 you are out.
var hp := 100.0
## How many others you knocked out this match.
var eliminations := 0
## True once you are out.
var is_out := false


## Called when a bullet hits you.
func take_damage(amount: float, by: Fighter) -> void:
	if is_out:
		return
	hp = maxf(hp - amount, 0.0)
	print(name, " took ", amount, " from ", by.name if by else "?", " -> HP ", hp)
	if hp <= 0.0:
		is_out = true
		remove_from_group("fighter")
		if by:
			by.eliminations += 1
		eliminated.emit(self, by)
		_on_out()


## What happens when you are out. Bots and the player do this differently.
func _on_out() -> void:
	queue_free()
