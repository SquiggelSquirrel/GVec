@tool
class_name GVecPathFollow
extends Node2D

## A [Node2D] that follows a [GVecPath]
##
## This node will set its own position based on the attached [memeber path]
## resource and the [member progress] float. It can also set its own rotation
## based on a look ahead. It can treat the path as a loop, or not, as required.


## This signal is fired when [member path] changes to reference a different
## [GVecPath], or when the structure of nested [GVecPath] resources changes.
signal structure_changed

## Possible modes for [member progress_mode]
enum ProgressMode {
	RATIO_OF_TOTAL_LENGTH, ## [member progress] as a ratio of the
		## baked points' size.
		## Use 0.0 and 1.0 for the start and end of the path.
	PIXELS, ## [member progress] represents pixel distance from
		## the start of the path. This wraps, and negative values will be
		## measured backwards from the end.
}

@export var progress_mode: ProgressMode = ProgressMode.RATIO_OF_TOTAL_LENGTH:
	set(value):
		if path is GVecPath:
			if progress_mode == ProgressMode.PIXELS:
				if value == ProgressMode.RATIO_OF_TOTAL_LENGTH:
					progress = pixels_to_ratio(progress)
			elif progress_mode == ProgressMode.RATIO_OF_TOTAL_LENGTH:
				if value == ProgressMode.PIXELS:
					progress = ratio_to_pixels(progress)
		progress_mode = value

## The [GVecPath] resource from which to generate this node's position, and
## optionally rotation
@export var path: GVecPath:
	set(value):
		GVec.disconnect_if_able(path, "changed", _on_path_changed)
		GVec.disconnect_if_able(path, "path_changed", _on_structure_changed)
		path = value
		GVec.connect_if_able(path, "changed", _on_path_changed)
		GVec.connect_if_able(path, "path_changed", _on_structure_changed)
		_on_structure_changed()
		_on_path_changed()

## This node's progress along the [member path] - from 0.0 to 1.0, wrapped if
## looping or clamped if not looping.
@export var progress: float = 0.0:
	set(value):
		progress = value
		_on_path_changed()

## If true, sets the node's rotation based on a look ahead
@export var rotates := true:
	set(value):
		rotates = value
		_on_path_changed()

## If true, treat the path as a loop - wrap the [member progress] value and
## look ahead. If false, clamp [member progress] and switch to look-back if
## unable to look ahead.
@export var loop := true:
	set(value):
		loop = value
		_on_path_changed()

## How far to look ahead, as a ratio of the path length.
@export var lookahead := 0.001:
	set(value):
		lookahead = value
		_on_path_changed()


func _enter_tree():
	# set meta for the GVecTools plugin
	set_meta("_svg_tools_path_property", "path")
	if path != null:
		_on_path_changed()


func _on_path_changed() -> void:
	if path == null:
		return
	var f := get_ratio_progress()
	position = path.sample(f)
	if ! rotates:
		return
	var lookahead := get_ratio_lookahead()
	rotation = position.angle_to_point(path.sample(lookahead.point))
	if lookahead.reversed:
		rotate(-PI)


func _on_structure_changed():
	structure_changed.emit()


## Convert a pixel distance to a ratio of path length
func pixels_to_ratio(pixels: float) -> float:
	return pixels / path.get_baked_length()


## Convert a ratio of path length to a pixel distance
func ratio_to_pixels(ratio: float) -> float:
	return ratio * path.get_baked_length()


## Get progress as a ratio of path length, clamped or wrapped as needed
func get_ratio_progress() -> float:
	var f: float
	match progress_mode:
		ProgressMode.RATIO_OF_TOTAL_LENGTH:
			f = progress
		ProgressMode.PIXELS:
			f = pixels_to_ratio(progress)
	if loop:
		f = wrapf(f, 0.0, 1.0)
	else:
		f = clamp(f, 0.0, 1.0)
	return f


## Get the lookahead as a ratio of path length, wrapped or reversed as needed
func get_ratio_lookahead() -> Dictionary:
	var f: float
	var reversed := false
	if lookahead < 0:
		reversed = true
	match progress_mode:
		ProgressMode.RATIO_OF_TOTAL_LENGTH:
			f = progress + lookahead
		ProgressMode.PIXELS:
			f = pixels_to_ratio(progress + lookahead)
	if loop:
		f = wrapf(f, 0, 1.0)
	elif f > 1.0 or f < 0.0:
		match progress_mode:
			ProgressMode.RATIO_OF_TOTAL_LENGTH:
				f = progress - lookahead
			ProgressMode.PIXELS:
				f = pixels_to_ratio(progress - lookahead)
		f = clamp(f, 0.0, 1.0)
		reversed = ! reversed
	return {
		"point": f,
		"reversed": reversed
	}
