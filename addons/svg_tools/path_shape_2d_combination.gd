@tool
class_name PathShape2DCombination
extends PathShape2D

## Base class for combining multiple [PathShape2D] resource to create one.
##
## This class is abstract (not intended for direct instantiation). It represents
## a [PathShape2D] resource that generates values from an [Array] of other
## [PathShape2D] resources - such as concatenation, tweening, or intersection.


## An array of [PathShape2D] resources to combine
@export var paths: Array[PathShape2D] = []:
	set(value):
		for path in paths:
			if path != null:
				if path.changed.is_connected(_on_path_changed):
					path.changed.disconnect(_on_path_changed)
		paths = value
		for path in paths:
			if path != null:
				if ! path.changed.is_connected(_on_path_changed):
					path.changed.connect(_on_path_changed)
		_on_path_changed()


# Meta property used for SVGTools plugin
func _init():
	set_meta("_svg_tools_path_property", "paths")


func _on_path_changed() -> void:
	if caching_enabled:
		cache_clear()
	emit_changed()
