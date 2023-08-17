@tool
extends Node2D


@export var path: PathShape2D:
	set(value):
		if path != null:
			if path.changed.is_connected(_on_path_changed):
				path.changed.disconnect(_on_path_changed)
		path = value
		if path != null:
			if ! path.changed.is_connected(_on_path_changed):
				path.changed.connect(_on_path_changed)
		_on_path_changed()
@export var width: float = 10.0
@export var width_curve: Curve
@export var fill_color := Color.OLIVE_DRAB
@export var fill_texture: Texture
enum UVMode {LINE2D, BRUSH}
@export var uv_mode := UVMode.BRUSH
@export var stroke_width: float = 2.0
@export var stroke_width_curve: Curve
@export var stroke_color := Color.DARK_GREEN
var polygon: Polygon2D


func _ready():
	polygon = Polygon2D.new()
	polygon.show_behind_parent = true


func _draw():
	pass


func _on_path_changed():
	pass


func draw_stroke(
		points: PackedVector2Array,
		widths: PackedFloat32Array,
		color: Color) -> void:
	pass


class Scrunch extends Resource:
	var start: float = 0.0
	var end: float = 0.1
	var curve_depth: float = 0.5
	var angle_depth: float = 0.0
