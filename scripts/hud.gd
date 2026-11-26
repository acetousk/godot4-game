class_name Hud
extends CanvasLayer
## The HUD: the info drawn on top of the game (it doesn't move with the camera).

## Sent when you click or tap a slot. 0 = slot 1.
signal slot_pressed(index: int)

const SLOT_COUNT := 4
const BONE := Color("#e8dcc4")
const BLACK := Color("#1a1410")

@onready var stats: Label = $Stats
@onready var slot_row: HBoxContainer = $Slots
@onready var log_label: Label = $Log

## The last 3 messages, oldest first.
var log_lines: Array[String] = []

## The 4 slot boxes. Each has an Icon (the potion picture) and a Key label (1-4).
var slots: Array[TextureRect] = []


func _ready() -> void:
	_make_slots()


## Shows HP, level, XP and floor at the top left.
## `waiting` is like "Waiting for P2" (empty = nobody to wait for).
func show_stats(player: Player, floor_num: int, waiting := "") -> void:
	var xp_text := "%d" % player.xp
	if player.level - 1 < Tune.level_xp.size():
		xp_text += "/%d" % Tune.level_xp[player.level - 1]  # XP needed for the next level
	stats.text = "P%d    HP %d/%d    Lv %d  XP %s    Floor %d" % [
		player.number, player.hp, player.max_hp, player.level, xp_text, floor_num]
	if waiting != "":
		stats.text += "    " + waiting


## Shows the potions you carry in the slots. Empty slots show nothing.
## Hover a slot (mouse) to see its name.
func show_slots(carried: Array[int], potions: Potions) -> void:
	var potion_tex: Texture2D = load("res://art/potion.png")
	for i in SLOT_COUNT:
		var icon: TextureRect = slots[i].get_node("Icon")
		if i < carried.size():
			icon.texture = potion_tex
			icon.self_modulate = potions.tint(carried[i])
			slots[i].tooltip_text = potions.display_name(carried[i])
		else:
			icon.texture = null
			slots[i].tooltip_text = ""


func _on_slot_input(event: InputEvent, index: int) -> void:
	var clicked: bool = event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if clicked or tapped:
		slot_pressed.emit(index)


## Big text in the middle of the screen, like "You win!".
func show_banner(text: String) -> void:
	var banner := Label.new()
	banner.name = "Banner"
	banner.text = text
	banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_theme_color_override("font_color", Color("#ffd966"))  # flame yellow
	banner.add_theme_color_override("font_outline_color", BLACK)
	banner.add_theme_constant_override("outline_size", 12)
	banner.add_theme_font_size_override("font_size", 72)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)


## Adds a message to the log. Only the newest 3 stay; the newest is at the bottom.
func add_log(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 3:
		log_lines.pop_front()
	log_label.text = "\n".join(log_lines)


## Builds the 4 slot boxes at the bottom of the screen.
func _make_slots() -> void:
	var box_tex: Texture2D = load("res://art/ui/slot.svg")
	for i in SLOT_COUNT:
		var box := TextureRect.new()
		box.texture = box_tex
		box.custom_minimum_size = Vector2(64, 64)
		box.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		box.mouse_filter = Control.MOUSE_FILTER_STOP  # Clicking or tapping a slot drinks it.
		box.gui_input.connect(_on_slot_input.bind(i))

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 12
		icon.offset_top = 12
		icon.offset_right = -12
		icon.offset_bottom = -12
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)

		var key := Label.new()
		key.name = "Key"
		key.text = str(i + 1)
		key.position = Vector2(6, 2)
		key.add_theme_color_override("font_color", BONE)
		key.add_theme_color_override("font_outline_color", BLACK)
		key.add_theme_constant_override("outline_size", 4)
		key.add_theme_font_size_override("font_size", 14)
		box.add_child(key)

		slot_row.add_child(box)
		slots.append(box)
