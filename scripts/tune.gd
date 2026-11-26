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

@export_group("Loot")
@export var chest_open_time: float = 0.5 ## Seconds you hold the action button to open a chest
@export var max_heal_kits: int = 2 ## Most heal kits you can carry
@export var heal_amount: float = 50.0 ## HP one heal kit gives back
@export var heal_time: float = 3.0 ## Seconds a heal kit takes to finish
@export var max_hp: float = 100.0 ## Most HP anyone can have

@export_group("Burst rifle")
@export var rifle_mag: int = 15 ## Shots in one magazine before you reload
@export var rifle_damage: int = 12 ## Damage from one bullet
@export var rifle_burst_shots: int = 3 ## Bullets in one burst
@export var rifle_burst_gap: float = 0.07 ## Seconds between bullets inside a burst
@export var rifle_fire_every: float = 0.6 ## Seconds from one burst to the next
@export var rifle_range: float = 60.0 ## How far a bullet reaches, in meters
@export var rifle_reload_time: float = 1.8 ## Seconds to reload

@export_group("Bots")
@export var bot_speed: float = 5.0 ## How fast bots walk, in meters per second
@export var bot_sight: float = 50.0 ## How far bots can see someone, in meters
@export var bot_accuracy_far: float = 0.2 ## Chance a bot bullet hits at the edge of sight (0.2 = 20%)
@export var bot_accuracy_near: float = 0.6 ## Chance a bot bullet hits up close (0.6 = 60%)

@export_group("Storm")
@export var storm_start_radius: float = 80.0 ## Size of the safe circle at the start, in meters
@export var storm_wait: float = 35.0 ## Seconds before the storm starts to shrink
@export var storm_shrink_time: float = 90.0 ## Seconds the storm takes to shrink all the way to 0
@export var storm_dps_start: float = 2.0 ## HP per second lost outside the circle at the start
@export var storm_dps_end: float = 10.0 ## HP per second lost outside the circle when it is fully closed

@export_group("Drop")
@export var drop_height: float = 80.0 ## How high you start in the sky, in meters
@export var glide_fall: float = 8.0 ## How fast you sink while gliding, in meters per second
@export var glide_steer: float = 10.0 ## How fast you move sideways while gliding
