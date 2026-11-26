extends CharacterBody3D
## The player: reads your controls, moves the capsule, and turns the camera.

## True while you float down from the sky at the start.
var gliding := false
## True once you have the Burst rifle.
var has_rifle := false
## How many heal kits you carry.
var heal_kits := 0
## Your health. At 0 you are out.
var hp := 100.0
## HP still to come from the heal kit you are using (0 = not healing).
var heal_left := 0.0
## Shots left in the rifle before you must reload.
var ammo := 0
## Seconds until you can fire the next burst.
var fire_cooldown := 0.0
## True while you reload (you cannot shoot).
var reloading := false

@onready var cam_yaw: Node3D = $CamYaw
@onready var cam_pitch: Node3D = $CamYaw/CamPitch
@onready var spring_arm: SpringArm3D = $CamYaw/CamPitch/SpringArm
@onready var camera: Camera3D = $CamYaw/CamPitch/SpringArm/Camera


func _ready() -> void:
	add_to_group("player")
	# The selfie stick must not bump into your own body.
	spring_arm.add_excluded_object(get_rid())
	# Start high in the sky and glide down.
	global_position.y = Tune.drop_height
	gliding = true


## A chest calls this when you open it.
func give_loot() -> void:
	if not has_rifle:
		has_rifle = true
		ammo = Tune.rifle_mag
	heal_kits = mini(heal_kits + 1, Tune.max_heal_kits)


## Fire one burst: a few bullets, a tiny gap between each.
func _fire_burst() -> void:
	fire_cooldown = Tune.rifle_fire_every
	for i in Tune.rifle_burst_shots:
		if ammo <= 0 or reloading:
			return
		ammo -= 1
		_shoot_bullet()
		await get_tree().create_timer(Tune.rifle_burst_gap).timeout


## Reload: wait, then fill the magazine.
func _reload() -> void:
	reloading = true
	await get_tree().create_timer(Tune.rifle_reload_time).timeout
	ammo = Tune.rifle_mag
	reloading = false


## One bullet: an invisible line from the middle of the screen.
func _shoot_bullet() -> void:
	var center := get_viewport().get_visible_rect().size / 2.0
	var from := camera.project_ray_origin(center)
	var to := from + camera.project_ray_normal(center) * Tune.rifle_range
	var query := PhysicsRayQueryParameters3D.create(from, to, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	# Whatever the line touches first takes the damage (if it can).
	if hit.collider.has_method("take_damage"):
		hit.collider.take_damage(Tune.rifle_damage, self)
	print("Hit ", hit.collider.name)


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

	# Fire: hold the fire button to keep shooting bursts.
	fire_cooldown -= delta
	if has_rifle and not reloading:
		if Input.is_action_pressed("fire") and fire_cooldown <= 0.0 and ammo > 0:
			_fire_burst()
		# Reload when you press the button, or by itself when empty.
		elif ammo < Tune.rifle_mag and (Input.is_action_just_pressed("reload") or (ammo == 0 and fire_cooldown <= 0.0)):
			_reload()

	# Heal: use a kit if you have one and are hurt. HP comes back bit by bit.
	if Input.is_action_just_pressed("heal") and heal_kits > 0 and heal_left <= 0.0 and hp < Tune.max_hp:
		heal_kits -= 1
		heal_left = Tune.heal_amount
	if heal_left > 0.0:
		var step := minf(Tune.heal_amount / Tune.heal_time * delta, heal_left)
		heal_left -= step
		hp = minf(hp + step, Tune.max_hp)
		if hp >= Tune.max_hp:
			heal_left = 0.0

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
