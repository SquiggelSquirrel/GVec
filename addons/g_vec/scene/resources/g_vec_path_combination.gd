@tool
class_name GVecPathCombination
extends GVecPath

## Base class for combining multiple [GVecPath] resource to create one.
##
## This class is abstract (not intended for direct instantiation). It represents
## a [GVecPath] resource that generates values from an [Array] of other
## [GVecPath] resources - such as concatenation, tweening, or intersection.


## This signal is fired when [member path] changes to reference a different
## [GVecPath], or when the structure of nested [GVecPath] resources changes.
signal structure_changed

## An array of [GVecPath] resources to combine
@export var paths: Array[GVecPath] = []:
	set(value):
		for path in value:
			if path is GVecPath:
				assert( ! path.contains_path(self))
		for path in paths:
			GVecGlobals.disconnect_if_able(path, "changed", _on_path_changed)
			GVecGlobals.disconnect_if_able(path, "path_changed", _on_structure_changed)
		paths = value
		for path in paths:
			GVecGlobals.connect_if_able(path, "changed", _on_path_changed)
			GVecGlobals.connect_if_able(path, "path_changed", _on_structure_changed)
		_on_structure_changed()
		_on_path_changed()


## Test if this path contains a dependency on another path
## - used to prevent cyclic references
func contains_path(test_path: GVecPath) -> bool:
	for path in paths:
		if path == null:
			continue
		if path == test_path or path.contains_path(test_path):
			return true
	return false


# Meta property used for SVGTools plugin
func _init():
	set_meta("_svg_tools_path_property", "paths")


func _on_path_changed() -> void:
	if caching_enabled:
		cache_clear()
	emit_changed()


func _on_structure_changed():
	structure_changed.emit()
