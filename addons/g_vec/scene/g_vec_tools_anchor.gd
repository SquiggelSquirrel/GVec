@tool
class_name GVecToolsAnchor
extends RefCounted

signal drag_start
signal drag
signal drag_end(drag_info)
signal right_click

const ANCHOR_INNER_RADIUS: float = 8.0
const ANCHOR_OUTER_RADIUS: float = 10.0
const ANCHOR_INNER_COLOR := Color.WHITE
const ANCHOR_OUTER_COLOR := Color.RED
enum AnchorShape {SQUARE, CIRCLE}

var position: Vector2
var key: Dictionary
var linked_anchors: Array[GVecToolsAnchor] = []
var shape: AnchorShape
var _linked_anchor_start_positions: Array[Vector2] = []
var _drag_start_position: Vector2
var _rect: Rect2
var _is_dragging := false


func _init(
		init_position: Vector2,
		init_key: Dictionary,
		init_shape: AnchorShape) -> void:
	shape = init_shape
	position = init_position
	key = init_key
	_rect = Rect2(
			position - Vector2.ONE * ANCHOR_OUTER_RADIUS,
			2.0 * Vector2.ONE * ANCHOR_OUTER_RADIUS)


func start_dragging() -> void:
	_drag_start_position = position
	_is_dragging = true


func draw(viewport: Control, transform: Transform2D) -> void:
	match shape:
		AnchorShape.SQUARE:
			_draw_square(viewport, transform)
		AnchorShape.CIRCLE:
			_draw_circle(viewport, transform)


func forward_input(local_position: Vector2, event: InputEvent) -> bool:
	if _event_is_drag_start(local_position, event):
		_handle_drag_start(local_position, event)
	elif _event_is_drag_end(local_position, event):
		_handle_drag_end(local_position, event)
	elif _event_is_drag(local_position, event):
		_handle_drag(local_position, event)
	else:
		return false
	return true


func _draw_square(viewport: Control, transform: Transform2D) -> void:
	var rect_position = (
			transform * position - Vector2.ONE * ANCHOR_INNER_RADIUS)
	var rect = Rect2(rect_position, Vector2.ONE * ANCHOR_INNER_RADIUS * 2.0)
	viewport.draw_rect(rect, ANCHOR_INNER_COLOR, true)
	viewport.draw_rect(rect,ANCHOR_OUTER_COLOR, false, 2.0)


func _draw_circle(viewport: Control, transform: Transform2D) -> void:
	var center = transform * position
	viewport.draw_circle(center, ANCHOR_OUTER_RADIUS, ANCHOR_OUTER_COLOR)
	viewport.draw_circle(center, ANCHOR_INNER_RADIUS, ANCHOR_INNER_COLOR)


func _handle_drag_start(local_position: Vector2, event: InputEvent) -> void:
	_drag_start_position = position
	_is_dragging = true
	_linked_anchor_start_positions = []
	for linked_anchor in linked_anchors:
		_linked_anchor_start_positions.append(linked_anchor.position)
	drag_start.emit()


func _handle_drag_end(local_position: Vector2, event: InputEvent) -> void:
	_is_dragging = false
	var drag_info = {
		"anchors": [self] + linked_anchors,
		"start_positions":
				[_drag_start_position] + _linked_anchor_start_positions,
		"end_positions": [position]
	}
	for linked_anchor in linked_anchors:
		drag_info.end_positions.append(linked_anchor.position)
	drag_end.emit(drag_info)


func _handle_drag(local_position: Vector2, event: InputEvent) -> void:
	position = local_position
	var offset = position - _drag_start_position
	for i in linked_anchors.size():
		linked_anchors[i].position = _linked_anchor_start_positions[i] + offset
	drag.emit()


func _event_is_drag_start(local_position: Vector2, event: InputEvent) -> bool:
	if _is_dragging:
		return false
	if ! event is InputEventMouseButton:
		return false
	if ! event.button_index != MOUSE_BUTTON_LEFT:
		return false
	if ! event.pressed:
		return false
	if ! _rect.has_point(local_position):
		return false
	return true


func _event_is_drag_end(local_position: Vector2, event: InputEvent) -> bool:
	if ! _is_dragging:
		return false
	if ! event is InputEventMouseButton:
		return false
	if ! event.button_index != MOUSE_BUTTON_LEFT:
		return false
	if event.pressed:
		return false
	return true


func _event_is_drag(local_position: Vector2, event: InputEvent) -> bool:
	if ! _is_dragging:
		return false
	if ! event is InputEventMouseMotion:
		return false
	return true
