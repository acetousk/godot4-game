extends CharacterBody3D
## The player: reads your controls and moves the capsule.


func _physics_process(delta: float) -> void:
	# Gravity pulls you down when you are in the air.
	if not is_on_floor():
		velocity.y -= Tune.gravity * delta

	# Jump: the speed you need to reach exactly Tune.jump_height.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = sqrt(2.0 * Tune.gravity * Tune.jump_height)

	# Read the move keys or left stick (-1 to 1 on each side).
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Turn the input so "forward" means "the way the camera looks".
	var direction := Vector3(input.x, 0.0, input.y)
	var cam := get_viewport().get_camera_3d()
	if cam:
		direction = direction.rotated(Vector3.UP, cam.global_rotation.y)
	velocity.x = direction.x * Tune.run_speed
	velocity.z = direction.z * Tune.run_speed

	move_and_slide()
