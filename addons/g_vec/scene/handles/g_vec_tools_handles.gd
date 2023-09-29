@tool
class_name GVecToolsHandles
extends Node


var shape: GVecPath
var transform: Transform2D
var anchors: Array[GVecToolsAnchor]
var guides: Array[GVecToolsGuide]


func _init(init_shape: GVecPath = GVecPathSVG.new()) -> void:
	shape = init_shape


func forward_draw(viewport: Control) -> void:
	for guide in guides:
		guide.draw(viewport, transform)
	for anchor in anchors:
		anchor.draw(viewport, transform)


func forward_input(
		event: InputEvent,
		state: String,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager
		) -> bool:
	return false


func forward_action(
		action: String,
		options: Dictionary,
		undo_redo: EditorUndoRedoManager) -> void:
	pass


func _add_anchor(
		position: Vector2,
		key: Dictionary,
		shape: GVecToolsAnchor.AnchorShape
		) -> GVecToolsAnchor:
	var anchor := GVecToolsAnchor.new(position, key, shape)
	anchor.drag_start.connect(_on_anchor_drag_start.bind(anchor))
	anchor.drag.connect(_on_anchor_drag.bind(anchor))
	anchor.drag_end.connect(_on_anchor_drag.bind(anchor))
	anchors.append(anchor)
	return anchor


func _on_anchor_drag_start(anchor: GVecToolsAnchor) -> void:
	pass


func _on_anchor_drag(anchor: GVecToolsAnchor) -> void:
	pass


func _on_anchor_drag_end(anchor: GVecToolsAnchor) -> void:
	pass
