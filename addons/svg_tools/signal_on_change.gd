@tool
class_name SignalOnChange
extends Node


signal changed


@export var path: PathShape2D:
	set(value):
		if path is PathShape2D:
			path.changed.disconnect(_on_path_changed)
		path = value
		if path is PathShape2D:
			path.changed.connect(_on_path_changed)


func _on_path_changed():
	changed.emit()
