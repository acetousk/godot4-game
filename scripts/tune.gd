extends Node
## Tune: every feel number in the game. Change these to change how it feels.

@export_group("Moving")
@export var run_speed: float = 7.0 ## How fast you run, in meters per second
@export var jump_height: float = 1.2 ## How high a jump goes, in meters
@export var gravity: float = 20.0 ## How hard you fall (higher = snappier jumps)

@export_group("Looking")
@export var look_speed: float = 0.003 ## Mouse look speed (higher = turn faster)
@export var stick_look_speed: float = 3.0 ## Gamepad right-stick look speed
@export var normal_fov: float = 75.0 ## How wide the camera sees normally, in degrees
@export var aim_fov: float = 45.0 ## How wide the camera sees when aiming (lower = more zoom)
@export var aim_look_slow: float = 0.5 ## Look speed while aiming (0.5 = half speed)

@export_group("Drop")
@export var drop_height: float = 80.0 ## How high you start in the sky, in meters
@export var glide_fall: float = 8.0 ## How fast you sink while gliding, in meters per second
@export var glide_steer: float = 10.0 ## How fast you move sideways while gliding
