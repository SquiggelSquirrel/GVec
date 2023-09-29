extends PanelContainer

signal action(action_name: String)

@export var button_group: ButtonGroup


func get_options() -> Dictionary:
	return $HBoxContainer/Options.get_options()


func get_state() -> String:
	var pressed = button_group.get_pressed_button()
	if pressed == null:
		return ""
	return pressed.name


func load_button_icons(plugin: EditorPlugin) -> void:
	var base := plugin.get_editor_interface().get_base_control()
	for button in $HBoxContainer.get_children():
		if ! button.has_meta("icon_name"):
			continue
		var icon_name := button.get_meta("icon_name")
		button.icon = base.get_theme_icon(icon_name, "EditorIcons")


func edit_shapes(active_shapes: Array[Dictionary]) -> void:
	if active_shapes.size() > 1 or active_shapes[0].path is GVecPathEllipse:
		set_allowed_actions([
			"Edit", "Curve", "Delete"
		])
	elif active_shapes.size() == 1:
		set_allowed_actions([
			"Edit", "Curve", "Add", "Delete", "Close"
		])
	else:
		visible = false


func set_allowed_actions(states: Array[String]) -> void:
	for button in $HBoxContainer.get_children():
		if ! button.has_meta("icon_name"):
			continue
		if button.name in states:
			button.visible = true
		else:
			button.checked = false
			button.visible = false


func _on_close_pressed() -> void:
	action.emit("Close")
