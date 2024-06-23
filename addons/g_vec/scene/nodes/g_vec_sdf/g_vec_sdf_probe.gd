@tool
class_name GVecSdfProbe
extends Marker2D

@onready var default_font = ThemeDB.fallback_font
@onready var default_font_size = ThemeDB.fallback_font_size


func _process(delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if ! Engine.is_editor_hint():
		return
	var source := get_parent() as GVecSdf
	if source == null:
		return
	var value := source.get_distance_at_global_point(global_position)
	draw_string(
			default_font,
			Vector2.ZERO,
			String.num(value),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			default_font_size)
