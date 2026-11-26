extends Fighter
## A bot: a capsule with a small brain.
## ROAM = walk to random spots. FIGHT = sees someone, strafes and shoots.

enum Mode { ROAM, FIGHT }

const EYE := Vector3(0, 1.5, 0)

var mode := Mode.ROAM
var target: Node3D = null
var ammo := 0
var fire_cooldown := 0.0
var reloading := false
var look_timer := 0.0
var strafe_dir := 1.0
var strafe_timer := 0.0

@onready var agent: NavigationAgent3D = $Agent


func _ready() -> void:
	add_to_group("bot")
	add_to_group("fighter")
	ammo = Tune.rifle_mag
	# Wait one frame so the island map is ready, then pick a place to walk to.
	await get_tree().physics_frame
	_pick_roam_point()


## Choose a random spot on the island and ask the map for a path there.
func _pick_roam_point() -> void:
	var half := 70.0
	agent.target_position = Vector3(randf_range(-half, half), 0.2, randf_range(-half, half))


## True if nothing solid is between my eyes and theirs.
func _can_see(other: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + EYE, other.global_position + EYE, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.collider == other


## Find the closest player or bot I can see within sight range.
func _look_for_target() -> void:
	target = null
	var best := Tune.bot_sight
	for other in get_tree().get_nodes_in_group("fighter"):
		if other == self:
			continue
		var dist := global_position.distance_to(other.global_position)
		if dist < best and _can_see(other):
			best = dist
			target = other
	mode = Mode.FIGHT if target else Mode.ROAM


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= Tune.gravity * delta

	# Look around a few times a second (not every frame, to save power).
	look_timer -= delta
	if look_timer <= 0.0:
		look_timer = 0.2
		_look_for_target()

	if mode == Mode.FIGHT and is_instance_valid(target):
		_fight(delta)
	else:
		_roam()
	move_and_slide()


func _roam() -> void:
	if agent.is_navigation_finished():
		_pick_roam_point()
	# Walk toward the next corner of the path.
	var direction := agent.get_next_path_position() - global_position
	direction.y = 0.0
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * Tune.bot_speed
		velocity.z = direction.z * Tune.bot_speed
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _fight(delta: float) -> void:
	# Face the target.
	var to_target := target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() > 0.1:
		look_at(global_position + to_target, Vector3.UP)
	# Strafe: step sideways, switch side every so often.
	strafe_timer -= delta
	if strafe_timer <= 0.0:
		strafe_timer = randf_range(0.6, 1.4)
		strafe_dir = -strafe_dir
	var side := global_basis.x * strafe_dir * Tune.bot_speed * 0.6
	velocity.x = side.x
	velocity.z = side.z
	# Shoot bursts, reload when empty.
	fire_cooldown -= delta
	if reloading:
		return
	if ammo <= 0:
		_reload()
	elif fire_cooldown <= 0.0:
		_fire_burst()


func _reload() -> void:
	reloading = true
	await get_tree().create_timer(Tune.rifle_reload_time).timeout
	ammo = Tune.rifle_mag
	reloading = false


func _fire_burst() -> void:
	fire_cooldown = Tune.rifle_fire_every
	for i in Tune.rifle_burst_shots:
		if ammo <= 0 or not is_instance_valid(target):
			return
		ammo -= 1
		_shoot_bullet()
		await get_tree().create_timer(Tune.rifle_burst_gap).timeout


## One bot bullet. Close = better aim, far = worse aim.
func _shoot_bullet() -> void:
	var dist := global_position.distance_to(target.global_position)
	var closeness := 1.0 - clampf(dist / Tune.bot_sight, 0.0, 1.0)
	var accuracy := lerpf(Tune.bot_accuracy_far, Tune.bot_accuracy_near, closeness)
	if randf() > accuracy:
		return
	if _can_see(target):
		if target.has_method("take_damage"):
			target.take_damage(Tune.rifle_damage, self)
