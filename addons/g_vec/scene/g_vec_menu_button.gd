extends MenuButton

const ANGLES: int = 0
const LENGTHS: int = 1
signal options_changed()


func _ready() -> void:
	var popup := get_popup()
	popup.index_pressed.connect(_on_index_pressed)


func get_options() -> Dictionary:
	var popup := get_popup()
	return {
		"mirror_angles": popup.is_item_checked(ANGLES),
		"mirror_lengths": (
				popup.is_item_checked(ANGLES)
				and popup.is_item_checked(LENGTHS)
		)
	}


func _on_index_pressed(index: int) -> void:
	var popup := get_popup()
	popup.set_item_checked(
			index,
			! popup.is_item_checked(index))
	if index == ANGLES:
		popup.set_item_disabled(
				LENGTHS,
				! popup.is_item_checked(ANGLES))
	options_changed.emit()
