extends Node
## Tune: every "feel" number in Lantern Deep, in one place.
## Change a number here, press F5, and play to feel the difference.

# --- Moving ---
## How long one step slides, in seconds. Smaller = snappier.
@export var move_time: float = 0.06

# --- Player ---
## HP at the start of a run.
@export var player_hp: int = 20
## XP needed for level 2, 3 and 4.
@export var level_xp: Array[int] = [10, 25, 45]

# --- Potions ---
## HP a Healing potion gives back.
@export var heal_amount: int = 10
## Damage an Embers potion does to you.
@export var embers_self_damage: int = 4
## Damage an Embers potion does to each monster next to you.
@export var embers_monster_damage: int = 6

# --- Seeing ---
## How many tiles your lantern lets you see.
@export var sight_radius: int = 6
## How bright the lantern glow is. 1.0 = normal.
@export var lantern_energy: float = 1.2
## How dark the cave is outside the lantern. 0 = pitch black, 1 = no darkness.
@export var cave_darkness: float = 0.5
## How bright tiles you saw before (but can't see now) look. 0 = black, 1 = full.
@export var remembered_brightness: float = 0.4

# --- Camera ---
## How close the camera is. Bigger = bigger pixels, less of the cave on screen.
@export var camera_zoom: float = 3.0

# --- The cave ---
## Size of one floor, in tiles.
@export var map_width: int = 32
@export var map_height: int = 24
## How many rooms a floor has (the 3x3 grid has room for 9).
@export var rooms_min: int = 6
@export var rooms_max: int = 9
## Smallest and biggest room size, in tiles (floor inside the walls).
@export var room_size_min: int = 3
@export var room_size_max: int = 7
## How many floors deep the cave goes.
@export var floor_count: int = 3
