@tool
class_name PathShapeFollow2D
extends Node2D

## A [Node2D] that follows a [PathShape2D]
##
## This node will set its own position based on the attached [memeber path]
## resource and the [member progress] float. It can also set its own rotation
## based on a look ahead. It can treat the path as a loop, or not, as required.


## The [PathShape2D] resource from which to generate this nodes position, and
## optionally rotation
@export var path :PathShape2D:
	set(value):
		if path != null:
			if path.changed.is_connected(_on_changed):
				path.changed.disconnect(_on_changed)
		path = value
		if path != null:
			path.changed.connect(_on_changed)
		_on_changed()

## This node's progress along the [member path] - from 0.0 to 1.0, wrapped if
## looping or clamped if not looping.
@export var progress: float = 0.0:
	set(value):
		progress = value
		_on_changed()

## If true, sets the node's rotation based on a look ahead
@export var rotates := true:
	set(value):
		rotates = value
		_on_changed()

## If true, treat the path as a loop - wrap the [member progress] value and
## look ahead. If false, clamp [member progress] and switch to look-back if
## unable to look ahead.
@export var loop := true:
	set(value):
		loop = value
		_on_changed()

## How far to look ahead, as a ratio of the path length.
@export var lookahead := 0.001:
	set(value):
		lookahead = value
		_on_changed()


func _on_changed() -> void:
	if path == null:
		return
	var f: float
	if loop:
		f = wrapf(progress, 0.0, 1.0)
	else:
		f = clamp(progress, 0.0, 1.0)
	position = path.sample(f)
	if ! rotates:
		return
	
	if loop:
		rotation = position.angle_to_point(
				path.sample(wrapf(f + lookahead, 0.0, 1.0)))
	else:
		var f2 = f + lookahead
		if f2 <= 1.0:
			rotation = position.angle_to_point(path.sample(f2))
		else:
			f2 = f - lookahead
			if f2 >= 0:
				rotation = path.sample(f2).angle_to_point(position)
