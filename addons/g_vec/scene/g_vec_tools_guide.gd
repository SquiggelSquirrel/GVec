@tool
class_name GVecToolsGuide
extends RefCounted

const LINE_COLOR := Color.RED
const LINE_WIDTH: float = 1.0
const LINE_DASH_LENGTH: float = 5.0
var start_point: Vector2
var end_point: Vector2


func _init(from_point: Vector2, to_point: Vector2) -> void:
	start_point = from_point
	end_point = to_point


func draw(viewport: Control, transform: Transform2D) -> void:
	viewport.draw_dashed_line(
		start_point,
		end_point,
		LINE_COLOR,
		LINE_WIDTH,
		LINE_DASH_LENGTH)
