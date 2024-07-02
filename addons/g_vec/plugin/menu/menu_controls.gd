@tool
extends HBoxContainer

const TypePopup := preload("type_popup.gd")


func set_is_add_checked(pressed: bool) -> void:
	get_node("Add").button_pressed = pressed


func get_is_add_checked() -> bool:
	return get_node("Add").button_pressed


func get_add_type() -> int:
	var popup: TypePopup = get_node("TypePopup")
	match popup.current_type:
		TypePopup.Types.LINE:
			return GVecPathSVG.SegmentType.LINE
		TypePopup.Types.QUADRATIC:
			return GVecPathSVG.SegmentType.QUADRATIC
		TypePopup.Types.CUBIC:
			return GVecPathSVG.SegmentType.CUBIC
		TypePopup.Types.ARC:
			return GVecPathSVG.SegmentType.ARC_END
	return -1


func get_mirror_angles() -> bool:
	var popup: TypePopup = get_node("TypePopup")
	return popup.mirror_angles


func get_mirror_lengths() -> bool:
	var popup: TypePopup = get_node("TypePopup")
	return popup.mirror_lengths
