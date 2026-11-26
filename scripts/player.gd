extends CharacterBody3D
## The player: reads your controls, moves the capsule, and turns the camera.

## True while you float down from the sky at the start.
var gliding := false

@onready var cam_yaw: Node3D = $CamYaw
@onready var cam_pitch: Node3D = $CamYaw/CamPitch
@onready var spring_arm: SpringArm3D = $CamYaw/CamPitch/SpringArm
@onready var camera: Camera3D = $CamYaw/CamPitch/SpringArm/Camera


func _ready() -> void:
	# The selfie stick must not bump into your own body.
	spring_arm.add_excluded_object(get_rid())
	# Start high in the sky and glide down.
	global_position.y = Tune.drop_height
	gliding = true


func _unhandled_input(event: InputEvent) -> void:
	# Click to grab the mouse, Esc to let it go.
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Mouse look.
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look(-event.relative * Tune.look_speed)


func _look(amount: Vector2) -> void:
	# Aiming slows the look so small moves are easier.
	if Input.is_action_pressed("aim"):
		amount *= Tune.aim_look_slow
	cam_yaw.rotate_y(amount.x)
	cam_pitch.rotation.x = clamp(cam_pitch.rotation.x + amount.y, deg_to_rad(-70), deg_to_rad(50))


func _physics_process(delta: float) -> void:
	# Gamepad look with the right stick.
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick != Vector2.ZERO:
		_look(-stick * Tune.stick_look_speed * delta)

	# Aim: zoom the camera in smoothly while held, back out when let go.
	var target_fov := Tune.aim_fov if Input.is_action_pressed("aim") else Tune.normal_fov
	camera.fov = lerp(camera.fov, target_fov, 12.0 * delta)

	# Glide: sink at a steady speed until you touch the ground.
	if gliding and is_on_floor():
		gliding = false
	var speed := Tune.glide_steer if gliding else Tune.run_speed

	# Gravity pulls you down when you are in the air.
	if gliding:
		velocity.y = -Tune.glide_fall
	elif not is_on_floor():
		velocity.y -= Tune.gravity * delta

	# Jump: the speed you need to reach exactly Tune.jump_height.
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = sqrt(2.0 * Tune.gravity * Tune.jump_height)

	# Read the move keys or left stick (-1 to 1 on each side).
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Turn the input so "forward" means "the way the camera looks".
	var direction := Vector3(input.x, 0.0, input.y).rotated(Vector3.UP, cam_yaw.global_rotation.y)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	move_and_slide()
