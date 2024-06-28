@tool
extends MenuButton
# This script handles enabling/disabling options such as "mirror angles"
# and "mirror lengths", depending on the segment type selected.

enum Types {
	LINE = 0,
	QUADRATIC = 1,
	CUBIC = 2,
	ARC = 3
}
# Separator = 4
enum Options {
	MIRROR_ANGLES = 5,
	MIRROR_LENGTHS = 6
}
var current_type := Types.CUBIC
var mirror_angles := true
var mirror_lengths := true


func _ready() -> void:
	get_popup().index_pressed.connect(_on_pressed)


func _on_pressed(pressed_index: int) -> void:
	var p := get_popup()
	
	if pressed_index in Types.values():
		_on_type_change(pressed_index)
		_update_mirror_angles_disabled()
		_update_mirror_lengths_disabled()
	
	if pressed_index == Options.MIRROR_ANGLES:
		mirror_angles = ! p.is_item_checked(Options.MIRROR_ANGLES)
		p.set_item_checked(Options.MIRROR_ANGLES, mirror_angles)
		_update_mirror_lengths_disabled()
	
	if pressed_index == Options.MIRROR_LENGTHS:
		mirror_lengths = ! p.is_item_checked(Options.MIRROR_LENGTHS)
		p.set_item_checked(Options.MIRROR_LENGTHS, mirror_lengths)


func _on_type_change(pressed_index: int) -> void:
	current_type = pressed_index
	var p := get_popup()
	for index in Types.values():
		p.set_item_checked(index, index == pressed_index)


func _update_mirror_angles_disabled() -> void:
	var p := get_popup()
	if current_type == Types.LINE:
		p.set_item_disabled(Options.MIRROR_ANGLES, true)
		mirror_angles = false
	else:
		p.set_item_disabled(Options.MIRROR_ANGLES, false)
		mirror_angles = p.is_item_checked(Options.MIRROR_ANGLES)


func _update_mirror_lengths_disabled() -> void:
	var p := get_popup()
	if mirror_angles:
		p.set_item_disabled(Options.MIRROR_LENGTHS, false)
		mirror_lengths = p.is_item_checked(Options.MIRROR_LENGTHS)
	else:
		p.set_item_disabled(Options.MIRROR_LENGTHS, true)
		mirror_angles = false
