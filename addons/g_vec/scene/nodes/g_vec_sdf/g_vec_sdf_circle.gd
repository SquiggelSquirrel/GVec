@tool
class_name GVecSdfCircle
extends GVecSdf

@export var editor_debug_preview := false
@export var editor_debug_color := Color.RED
@export var radius := 100.0


func get_distance_at_local_point(local_point: Vector2) -> float:
	return (local_point.length() - abs(radius)) * sign(radius)


func _draw() -> void:
	if ! Engine.is_editor_hint():
		return
	if ! editor_debug_preview:
		return
	draw_arc(Vector2.ZERO, radius, 0.0, 2 * PI, 36, editor_debug_color)


func _process(delta: float) -> void:
	queue_redraw()
